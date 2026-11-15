/**
 * pi-unlimited — wire pi-bansos to the pi-unlimited gateway, and keep an honest
 * ledger of what OpenCode's free tier actually did to you.
 *
 * Architecture
 * ------------
 *
 *   pi (provider "bansos")
 *     └─ pi-bansos local proxy :18080
 *          └─ relay ──► pi-unlimited-gateway :18790
 *                         ├─ egress pool (WARP socks5, other proxies, direct)
 *                         ├─ rotates on 429/403, quarantine + backoff
 *                         └─ TLS shape (JA4 cipher list + ALPN) for opencode.ai
 *
 * This extension owns the seam and the bookkeeping; the gateway owns the
 * routing. pi-bansos still builds the request (UA, project/session headers,
 * `read`+`shell` tools, `<env>` prompt block) — that fingerprint is pi-bansos's
 * job and is deliberately not duplicated here.
 *
 * The extension also registers `bansos/auto`, a virtual model that fails a
 * 429/403 retry over to the next free model instead of replaying the refusal.
 * That is the one axis that still has headroom when the bucket being spent is
 * per model rather than global.
 *
 * Honest limits
 * -------------
 * Nothing here creates budget. Measured 2026-11-15: OpenCode returned the same
 * `429 FreeUsageLimitError` and the same `Retry-After` (~00:00 UTC) to a direct
 * connection and to a Cloudflare WARP exit, i.e. the spent bucket was global.
 * When the gateway sees that, it reports `poolWide` and this extension says so
 * instead of inviting another lap around the pool.
 *
 * Commands
 * --------
 *   /unlimited                status
 *   /unlimited usage          today's refusals, grouped
 *   /unlimited egress         gateway egress health
 *   /unlimited apply          point pi-bansos at the gateway (+ reload)
 *   /unlimited off            remove the gateway relay (+ reload)
 *   /unlimited auto on|off    select the bansos/auto failover model
 *   /unlimited watch on|off   notifications only
 *   /unlimited clear          clear local history only
 *   /unlimited doctor         wiring checks
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

// ── Paths ──────────────────────────────────────────────────────────────────

const AGENT_DIR =
  process.env.PI_CODING_AGENT_DIR?.trim() || path.join(os.homedir(), ".pi", "agent");
const STATE_FILE = path.join(AGENT_DIR, "pi-unlimited-state.json");
const RELAY_FILE = path.join(AGENT_DIR, "pi-bansos-relay-state.json");
const GATEWAY_STATE_FILE = path.join(AGENT_DIR, "pi-unlimited-gateway.json");

/** Must match PI_UNLIMITED_PORT / PI_UNLIMITED_HOST in the Nix service. */
const GATEWAY_URL = process.env.PI_UNLIMITED_URL?.trim() || "http://127.0.0.1:18790";
const RELAY_LABEL = "pi-unlimited gateway";
const MAX_EVENTS = 300;

// ── Types ──────────────────────────────────────────────────────────────────

type RefusalKind = "quota" | "egress" | "shape" | "other";

type LimitEvent = {
  at: number;
  status: number;
  kind: RefusalKind;
  source: "http" | "pi-error";
  model?: string;
  retryAfterSeconds?: number;
  viaGateway?: boolean;
  poolWide?: boolean;
  message: string;
};

type State = {
  version: 3;
  /** Only controls TUI notifications; recording is always on. */
  watch: boolean;
  /** True while this extension owns pi-bansos's relay setting. */
  managed: boolean;
  events: LimitEvent[];
};

type GatewayEgress = {
  id: string;
  healthy: boolean;
  requests: number;
  failures: number;
  lastOkAt: number;
  lastLatencyMs: number;
  lastError: string;
  quarantineUntil: number;
};

type GatewayState = {
  bind?: string;
  startedAt?: number;
  savedAt?: number;
  egress?: Record<string, Omit<GatewayEgress, "id" | "healthy">>;
  requests?: { total: number; byDay: Record<string, number> };
  events?: { at: number; egress: string; status: number; kind: RefusalKind; retryAfterSeconds?: number }[];
};

type RelayFile = {
  enabled: boolean;
  url: string;
  relays: { url: string; label?: string; addedAt?: string; auth?: string }[];
  statusBar: "shown" | "hidden";
};

// ── State I/O ──────────────────────────────────────────────────────────────

function freshState(): State {
  return { version: 3, watch: true, managed: false, events: [] };
}

function parseEvent(value: unknown): LimitEvent | undefined {
  if (!value || typeof value !== "object") return undefined;
  const event = value as Partial<LimitEvent>;
  if (typeof event.at !== "number" || typeof event.status !== "number") return undefined;
  if (typeof event.message !== "string") return undefined;
  const kind =
    event.kind === "egress" || event.kind === "shape" || event.kind === "other"
      ? event.kind
      : "quota";
  return {
    at: event.at,
    status: event.status,
    kind,
    source: event.source === "pi-error" ? "pi-error" : "http",
    model: typeof event.model === "string" ? event.model : undefined,
    retryAfterSeconds:
      typeof event.retryAfterSeconds === "number" && event.retryAfterSeconds >= 0
        ? event.retryAfterSeconds
        : undefined,
    viaGateway: event.viaGateway === true,
    poolWide: event.poolWide === true,
    message: event.message,
  };
}

function loadState(): State {
  try {
    const raw = JSON.parse(fs.readFileSync(STATE_FILE, "utf8")) as Partial<State>;
    return {
      version: 3,
      watch: raw.watch ?? true,
      managed: raw.managed === true,
      // v2 recorded only quota events; carry them forward rather than dropping
      // the operator's history.
      events: Array.isArray(raw.events)
        ? raw.events
            .map(parseEvent)
            .filter((event): event is LimitEvent => Boolean(event))
            .slice(-MAX_EVENTS)
        : [],
    };
  } catch {
    return freshState();
  }
}

function writeJsonAtomic(file: string, value: unknown): boolean {
  const tmp = `${file}.${process.pid}.tmp`;
  try {
    fs.mkdirSync(path.dirname(file), { recursive: true });
    fs.writeFileSync(tmp, JSON.stringify(value));
    fs.renameSync(tmp, file);
    return true;
  } catch {
    try {
      fs.rmSync(tmp, { force: true });
    } catch {
      // Best effort: bookkeeping must never disturb a model request.
    }
    return false;
  }
}

const saveState = (state: State): void => void writeJsonAtomic(STATE_FILE, state);

function loadRelayFile(): RelayFile {
  try {
    const raw = JSON.parse(fs.readFileSync(RELAY_FILE, "utf8"));
    return {
      enabled: Boolean(raw?.enabled),
      url: typeof raw?.url === "string" ? raw.url : "",
      relays: Array.isArray(raw?.relays) ? raw.relays : [],
      statusBar: raw?.statusBar === "hidden" ? "hidden" : "shown",
    };
  } catch {
    return { enabled: false, url: "", relays: [], statusBar: "shown" };
  }
}

function loadGatewayState(): GatewayState | undefined {
  try {
    return JSON.parse(fs.readFileSync(GATEWAY_STATE_FILE, "utf8")) as GatewayState;
  } catch {
    return undefined;
  }
}

// ── Time helpers ───────────────────────────────────────────────────────────

const utcDay = (now = Date.now()): string => new Date(now).toISOString().slice(0, 10);

function nextUtcMidnight(now = Date.now()): number {
  const date = new Date(now);
  return Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate() + 1);
}

function humanDuration(seconds: number): string {
  if (!Number.isFinite(seconds) || seconds <= 0) return "now";
  const total = Math.ceil(seconds);
  const hours = Math.floor(total / 3600);
  const minutes = Math.floor((total % 3600) / 60);
  const secs = total % 60;
  if (hours > 0) return `${hours}h ${minutes}m`;
  if (minutes > 0) return `${minutes}m ${secs}s`;
  return `${secs}s`;
}

// ── Classification ─────────────────────────────────────────────────────────

/** Same three axes the gateway distinguishes, so both report the same thing. */
function classify(status: number, message: string): RefusalKind {
  const text = message.toLowerCase();
  // Shape gate first: "abusive traffic" bodies also mention an IP address, and
  // a FreeTierError is never fixed by rotating egress.
  if (/freetiererror|can only be used from within opencode|fingerprint/.test(text)) return "shape";
  if (/abusive traffic|from this ip address/.test(text)) return "egress";
  if (status === 429 || /free\s*usage\s*limit|free[- ]quota|rate limit|quota/.test(text)) return "quota";
  return "other";
}

function parseRetryAfter(value: unknown): number | undefined {
  if (typeof value === "number" && Number.isFinite(value) && value >= 0) return Math.ceil(value);
  if (typeof value !== "string") return undefined;
  if (/^\d+$/.test(value.trim())) return Number(value.trim());
  const at = Date.parse(value);
  return Number.isNaN(at) ? undefined : Math.max(0, Math.ceil((at - Date.now()) / 1000));
}

function retryFromMessage(message: string): number | undefined {
  // Pi renders long server Retry-After values in exactly this form.
  const piDelay = message.match(/Server requested\s+(\d+)s\s+retry delay/i);
  if (piDelay) return Number(piDelay[1]);
  const retry = message.match(/(?:retry[- ]after|retry in)\D{0,12}(\d+)\s*(?:s|sec|second)?/i);
  return retry ? Number(retry[1]) : undefined;
}

function eventKey(event: LimitEvent): string {
  // Pi exposes both the raw HTTP response and its final error message; collapse
  // those two observations when they describe the same failure.
  return `${event.status}|${event.kind}|${event.model ?? ""}|${event.retryAfterSeconds ?? ""}`;
}

function appendEvent(state: State, event: LimitEvent): boolean {
  const latest = state.events[state.events.length - 1];
  if (latest && eventKey(latest) === eventKey(event) && event.at - latest.at < 10_000) return false;
  state.events.push(event);
  if (state.events.length > MAX_EVENTS) state.events = state.events.slice(-MAX_EVENTS);
  saveState(state);
  return true;
}

function eventsToday(state: State): LimitEvent[] {
  const today = utcDay();
  return state.events.filter((event) => utcDay(event.at) === today);
}

// ── Gateway coordination ───────────────────────────────────────────────────

async function gatewayHealth(timeoutMs = 1500): Promise<GatewayState | undefined> {
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);
    const response = await fetch(`${GATEWAY_URL}/__unlimited/health`, {
      signal: controller.signal,
    });
    clearTimeout(timer);
    if (!response.ok) return undefined;
    return (await response.json()) as GatewayState;
  } catch {
    return undefined;
  }
}

/** Point pi-bansos at the gateway, preserving relays the operator added itself. */
function applyRelay(state: State): { ok: boolean; message: string } {
  const relay = loadRelayFile();
  const others = relay.relays.filter((entry) => entry.url !== GATEWAY_URL);
  const next: RelayFile = {
    enabled: true,
    url: GATEWAY_URL,
    relays: [{ url: GATEWAY_URL, label: RELAY_LABEL, addedAt: new Date().toISOString() }, ...others],
    statusBar: relay.statusBar,
  };
  if (!writeJsonAtomic(RELAY_FILE, next)) {
    return { ok: false, message: `could not write ${RELAY_FILE}` };
  }
  state.managed = true;
  saveState(state);
  return { ok: true, message: `pi-bansos relay → ${GATEWAY_URL}` };
}

function removeRelay(state: State): { ok: boolean; message: string } {
  const relay = loadRelayFile();
  const others = relay.relays.filter((entry) => entry.url !== GATEWAY_URL);
  const wasActive = relay.url === GATEWAY_URL;
  const next: RelayFile = {
    enabled: wasActive && others.length > 0 ? relay.enabled : relay.url === GATEWAY_URL ? false : relay.enabled,
    url: wasActive ? (others[0]?.url ?? "") : relay.url,
    relays: others,
    statusBar: relay.statusBar,
  };
  if (!writeJsonAtomic(RELAY_FILE, next)) {
    return { ok: false, message: `could not write ${RELAY_FILE}` };
  }
  state.managed = false;
  saveState(state);
  return {
    ok: true,
    message: wasActive ? "pi-bansos relay removed; back to direct egress" : "gateway relay was not active",
  };
}

function relayStatus(): { active: boolean; url: string; managed: boolean } {
  const relay = loadRelayFile();
  return { active: relay.enabled && relay.url === GATEWAY_URL, url: relay.url, managed: relay.url === GATEWAY_URL };
}

// ── Reports ────────────────────────────────────────────────────────────────

function statusText(state: State): string {
  const latest = state.events[state.events.length - 1];
  const relay = relayStatus();
  const route = relay.active ? "gateway" : "direct";
  if (!latest) return `unlimited: ${route} · no refusal recorded`;
  const retry = latest.retryAfterSeconds != null ? ` · ${humanDuration(latest.retryAfterSeconds)}` : "";
  const wide = latest.poolWide ? " · pool-wide" : "";
  return `unlimited: ${route} · HTTP ${latest.status} ${latest.kind}${retry}${wide}`;
}

function statusReport(state: State, gateway?: GatewayState): string {
  const now = Date.now();
  const latest = state.events[state.events.length - 1];
  const today = eventsToday(state);
  const relay = relayStatus();
  const lines = [
    "pi-unlimited — OpenCode free tier",
    `route: ${relay.active ? `gateway ${GATEWAY_URL}` : `direct (relay: ${relay.url || "none"})`}`,
    `gateway: ${gateway ? `up on ${gateway.bind ?? GATEWAY_URL}` : "not reachable"}`,
    latest
      ? `last refusal: HTTP ${latest.status} (${latest.kind}) at ${new Date(latest.at).toISOString().slice(11, 19)} UTC${latest.model ? ` · ${latest.model}` : ""}`
      : "last refusal: none recorded",
    latest?.retryAfterSeconds != null
      ? `provider retry-after: ${humanDuration(latest.retryAfterSeconds)}`
      : "provider retry-after: unavailable",
    `refusals today: ${today.length} · notifications ${state.watch ? "ON" : "OFF"}`,
    `UTC midnight (free-tier reset) in ${humanDuration(Math.ceil((nextUtcMidnight(now) - now) / 1000))}`,
  ];
  if (latest?.poolWide) {
    lines.push(
      "note: every egress in the pool got the same refusal — that bucket is not per-IP.",
    );
  }
  return lines.join("\n");
}

function usageReport(state: State): string {
  const today = eventsToday(state);
  if (!today.length) return `No refusals recorded for ${utcDay()}.`;
  const counts = new Map<string, number>();
  for (const event of today) {
    const key = `HTTP ${event.status} ${event.kind}${event.model ? ` · ${event.model}` : ""}`;
    counts.set(key, (counts.get(key) ?? 0) + 1);
  }
  const rows = [...counts.entries()]
    .sort((a, b) => b[1] - a[1])
    .map(([key, count]) => `- ${count}× ${key}`);
  const last = today.at(-1);
  return [
    `Refusals today (${today.length}) — ${utcDay()}:`,
    ...rows,
    last?.retryAfterSeconds != null
      ? `last retry-after: ${humanDuration(last.retryAfterSeconds)}`
      : "last retry-after: unavailable",
  ].join("\n");
}

function egressReport(gateway?: GatewayState): string {
  if (!gateway?.egress) return `Gateway not reachable at ${GATEWAY_URL}.`;
  const now = Date.now();
  const rows = Object.entries(gateway.egress).map(([id, record]) => {
    const parked =
      record.quarantineUntil && record.quarantineUntil > now
        ? `parked ${humanDuration((record.quarantineUntil - now) / 1000)}`
        : "ready";
    const latency = record.lastLatencyMs ? `${record.lastLatencyMs}ms` : "—";
    return `- ${id.padEnd(28)} ${parked.padEnd(16)} ok=${record.requests} fail=${record.failures} last=${latency}${
      record.lastError ? ` · ${record.lastError}` : ""
    }`;
  });
  const total = gateway.requests?.total ?? 0;
  return [`Gateway egress (${total} request(s) relayed):`, ...rows].join("\n");
}

// ── Free-model failover ladder ─────────────────────────────────────────────

/**
 * Preferred order when several free models have headroom. Deliberately a
 * stable hand-written ladder: quality order is an operator decision, and the
 * catalog changes without notice. Anything alive that is not listed still gets
 * used, appended after these.
 */
const PREFERRED_FREE_MODELS = [
  "deepseek-v4.1-flash-free",
  "big-pickle",
  "glm-5.3-flash-free",
  "mimo-v2.6-flash-free",
  "minimax-m3.1-flash-free",
  "qwen3.8-flash",
  "iceman-free",
  "beam-free",
  "flint-40b-free",
  "longcat-2.5-free",
  "inkling-2-small-free",
  "nemotron-3.5-lightning-free",
  "nemotron-3.5-super-vl-free",
];

/** model id → epoch ms until which it is considered spent. */
const modelCooldown = new Map<string, number>();

function coolingDown(id: string): boolean {
  const until = modelCooldown.get(id);
  if (!until) return false;
  if (until <= Date.now()) {
    modelCooldown.delete(id);
    return false;
  }
  return true;
}

function coolModel(id: string, seconds?: number): void {
  // OpenCode's synthetic Retry-After points at the UTC reset. Use it when it
  // looks like a real rest, otherwise a short reactive cooldown so one wave
  // does not lock a model out for the day (same rule pi-bansos applies).
  const window = seconds != null && seconds > 0 && seconds <= 3600 ? seconds : 90;
  modelCooldown.set(id, Date.now() + window * 1000);
}

type AvailableModel = { provider: string; id: string };

function freeModelLadder(ctx: { modelRegistry?: { getAvailable?: () => AvailableModel[] } }): string[] {
  const available = (ctx.modelRegistry?.getAvailable?.() ?? []).filter(
    (model) => model.provider === "bansos",
  );
  const ids = available.map((model) => model.id);
  const preferred = PREFERRED_FREE_MODELS.filter((id) => ids.includes(id));
  const rest = ids.filter((id) => !preferred.includes(id)).sort();
  return [...preferred, ...rest];
}

export default function (pi: ExtensionAPI) {
  let state = loadState();

  const notify = (
    ctx: { ui?: { notify?: (message: string, level?: "info" | "warning" | "error") => void } },
    message: string,
    level: "info" | "warning" | "error" = "info",
  ) => {
    try {
      ctx.ui?.notify?.(message, level);
    } catch {
      // Rendering must never affect model traffic.
    }
  };

  const setStatus = (ctx: { ui?: { setStatus?: (key: string, text: string) => void } }) => {
    try {
      ctx.ui?.setStatus?.("unlimited", statusText(state));
    } catch {
      // Cosmetic only.
    }
  };

  const record = (
    ctx: {
      model?: { provider?: string; id?: string };
      ui?: {
        notify?: (message: string, level?: "info" | "warning" | "error") => void;
        setStatus?: (key: string, text: string) => void;
      };
    },
    event: LimitEvent,
  ) => {
    if (event.model?.startsWith("bansos/") && event.status === 429) {
      coolModel(event.model.slice("bansos/".length), event.retryAfterSeconds);
    }
    if (!appendEvent(state, event)) return;
    setStatus(ctx);
    if (!state.watch) return;
    const retry = event.retryAfterSeconds != null ? ` Retry in ${humanDuration(event.retryAfterSeconds)}.` : "";
    const wide = event.poolWide ? " Every egress was refused, so rotating cannot help." : "";
    notify(
      ctx,
      `OpenCode ${event.status} ${event.kind}.${retry}${wide}`,
      event.kind === "quota" ? "warning" : "error",
    );
  };

  pi.on("session_start", (_event, ctx) => {
    state = loadState();
    setStatus(ctx);
  });

  pi.on("session_shutdown", () => saveState(state));

  // Raw status/headers, before the stream body is consumed.
  pi.on("after_provider_response", (event, ctx) => {
    const provider = (event as { provider?: string }).provider ?? ctx.model?.provider;
    if (provider !== "bansos") return;
    const status = Number((event as { status?: number }).status ?? 0);
    if (status !== 429 && status !== 403) return;
    const headers = (event as { headers?: Record<string, string> }).headers;
    const message = String((event as { body?: unknown }).body ?? `HTTP ${status}`);
    const relay = relayStatus();
    record(ctx, {
      at: Date.now(),
      status,
      kind: classify(status, message),
      source: "http",
      model:
        ctx.model?.provider === "bansos" && ctx.model.id
          ? `${ctx.model.provider}/${ctx.model.id}`
          : undefined,
      retryAfterSeconds: parseRetryAfter(headers?.["retry-after"]),
      viaGateway: relay.active,
      message: message.slice(0, 1000),
    });
  });

  // Pi's final error string, e.g.
  // "Server requested 11572s retry delay (max: 120s). 429 Free usage limit…"
  pi.on("message_end", (event, ctx) => {
    const message = (event as { message?: { role?: string; provider?: string; errorMessage?: string } })
      .message;
    if (message?.role !== "assistant") return;
    const text = message.errorMessage;
    const provider = message.provider ?? ctx.model?.provider;
    if (provider !== "bansos" || !text) return;
    const statusMatch = text.match(/\b(429|403)\b/);
    if (
      !statusMatch ||
      !/(?:free usage limit|free[- ]quota|rate limit|abusive traffic|freetiererror|fingerprint|retry delay)/i.test(
        text,
      )
    ) {
      return;
    }
    const status = Number(statusMatch[1]);
    record(ctx, {
      at: Date.now(),
      status,
      kind: classify(status, text),
      source: "pi-error",
      model:
        ctx.model?.provider === "bansos" && ctx.model.id
          ? `${ctx.model.provider}/${ctx.model.id}`
          : undefined,
      retryAfterSeconds: retryFromMessage(text),
      viaGateway: relayStatus().active,
      message: text.slice(0, 1000),
    });
  });

  // ── Virtual model: fail a refusal over to the next healthy free model ────
  // Registered defensively: virtual models are optional, and an older runtime
  // must keep the ledger working rather than fail to load the extension.
  const register = (pi as unknown as { registerVirtualModel?: (definition: unknown) => void })
    .registerVirtualModel;
  if (typeof register === "function") {
    register.call(pi, {
      provider: "bansos",
      id: "auto",
      name: "Auto (free-tier failover)",
      thinkingLevels: ["off", "low", "medium", "high"],
      contextWindow: 128_000,
      maxTokens: 16_384,
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      route(request: any, ctx: any) {
        const ladder = freeModelLadder(ctx);
        const usable = ladder.filter((id) => !coolingDown(id));
        const pick = (id: string) => ctx.modelRegistry.find("bansos", id);

        const previousId = request.previous?.model?.id as string | undefined;
        const failedId = request.failed?.model?.id as string | undefined;
        const failureText = String(request.failed?.message?.errorMessage ?? "");
        const failureStatus = Number((failureText.match(/\b(429|403)\b/) ?? [])[1] || 0);
        const refused =
          failureStatus === 429 ||
          failureStatus === 403 ||
          /free usage limit|rate limit|abusive traffic|freetiererror/i.test(failureText);

        // A refusal is the one case where leaving the previous model is correct.
        if (request.reason === "retry" && refused && failedId) {
          coolModel(failedId, retryFromMessage(failureText));
          const next = usable.find((id) => id !== failedId) ?? usable[0];
          const model = next ? pick(next) : undefined;
          if (model) return { model, thinkingLevel: request.thinkingLevel };
        }

        // Otherwise stay on whatever already answered: switching mid-turn
        // throws away the prompt cache and the thinking signature.
        const sticky = previousId && ladder.includes(previousId) ? previousId : undefined;
        const target = sticky ?? usable[0] ?? ladder[0];
        const model = target ? pick(target) : undefined;
        if (!model) throw new Error("no bansos free model available");
        return { model, thinkingLevel: request.thinkingLevel };
      },
    });
  }

  pi.registerCommand("unlimited", {
    description: "OpenCode free tier: status | usage | egress | apply | off | auto | watch | clear | doctor",
    getArgumentCompletions: (prefix) =>
      [
        "status",
        "usage",
        "egress",
        "apply",
        "off",
        "auto on",
        "auto off",
        "watch on",
        "watch off",
        "clear",
        "doctor",
      ]
        .filter((item) => item.startsWith(prefix))
        .map((value) => ({ value, label: value })),
    handler: async (args, ctx) => {
      state = loadState();
      const [command = "status", option] = String(args ?? "").trim().split(/\s+/).filter(Boolean);
      switch (command) {
        case "status": {
          const gateway = await gatewayHealth();
          notify(ctx, statusReport(state, gateway));
          return;
        }
        case "usage":
          notify(ctx, usageReport(state));
          return;
        case "egress": {
          const gateway = await gatewayHealth();
          notify(ctx, egressReport(gateway));
          return;
        }
        case "apply": {
          const gateway = await gatewayHealth();
          if (!gateway) {
            notify(
              ctx,
              `Gateway not reachable at ${GATEWAY_URL}. Start it: systemctl --user start pi-unlimited-gateway`,
              "error",
            );
            return;
          }
          const result = applyRelay(state);
          notify(ctx, result.ok ? `${result.message}. Reloading pi-bansos…` : result.message, result.ok ? "info" : "error");
          if (result.ok) setStatus(ctx);
          if (result.ok) await ctx.reload();
          return;
        }
        case "off": {
          const result = removeRelay(state);
          notify(ctx, `${result.message}. Reloading…`, result.ok ? "info" : "error");
          if (result.ok) setStatus(ctx);
          if (result.ok) await ctx.reload();
          return;
        }
        case "auto": {
          if (option === "on" || option === "off") {
            const id = option === "on" ? "auto" : "deepseek-v4.1-flash-free";
            const model = ctx.modelRegistry.find("bansos", id);
            if (!model) {
              notify(ctx, `bansos/${id} is not in the catalog`, "error");
              return;
            }
            const ok = await pi.setModel(model);
            notify(ctx, ok ? `Model → bansos/${id}` : `No credentials for bansos/${id}`, ok ? "info" : "error");
          } else {
            notify(ctx, "usage: /unlimited auto on|off");
          }
          return;
        }
        case "watch":
          if (option === "on" || option === "off") {
            state.watch = option === "on";
            saveState(state);
            setStatus(ctx);
            notify(ctx, `Notifications ${state.watch ? "ON" : "OFF"}.`);
          } else {
            notify(ctx, `Notifications are ${state.watch ? "ON" : "OFF"}.`);
          }
          return;
        case "clear":
          state.events = [];
          modelCooldown.clear();
          saveState(state);
          setStatus(ctx);
          notify(ctx, "Cleared local history only; the provider quota is unchanged.");
          return;
        case "doctor": {
          const gateway = await gatewayHealth();
          const relay = relayStatus();
          const lines = [
            "pi-unlimited doctor:",
            `- state file: ${STATE_FILE}`,
            `- relay file: ${RELAY_FILE}`,
            `- gateway: ${gateway ? `up (${gateway.bind})` : `DOWN (${GATEWAY_URL})`}`,
            `- pi-bansos relay: ${relay.active ? "gateway" : relay.url || "direct"}`,
            `- virtual model bansos/auto: ${typeof register === "function" ? "registered" : "unsupported runtime"}`,
            `- recorded refusals: ${state.events.length}`,
            `- agent directory writable: ${canWrite(AGENT_DIR) ? "yes" : "no"}`,
          ];
          notify(ctx, lines.join("\n"));
          return;
        }
        default:
          notify(ctx, "usage: /unlimited status|usage|egress|apply|off|auto on|off|watch on|off|clear|doctor", "warning");
      }
    },
  });
}

function canWrite(directory: string): boolean {
  try {
    fs.accessSync(directory, fs.constants.W_OK);
    return true;
  } catch {
    return false;
  }
}
