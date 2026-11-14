/**
 * pi-unlimited — an opencode-unlimited-style route controller for pi's
 * `bansos` provider (pi-bansos: OpenCode Zen + KiloCode free models).
 *
 * Why this exists
 * ---------------
 * The free budget on the OpenCode Zen side is counted per *egress block* per
 * UTC day — one IPv4 `/32`, one IPv6 `/64`. It is not per project, per session,
 * per model or per device id, so rotating an identity string changes nothing.
 * The honest levers are:
 *
 *   1. leave through a different address block, and
 *   2. move the session onto an upstream that is not billing that block.
 *
 * pi-bansos already ships a relay failover path (Cloudflare Worker / Vercel
 * pass-through) and classifies 429/403 per request, but it keeps its route
 * list in a single flat file with no memory of what a route did yesterday, no
 * egress ledger, and no operator surface. This extension is the operator
 * surface: it owns a ranked relay pool with health records and quarantine, an
 * egress-block ledger, a local usage meter, and the one-shot `reset` that
 * rotates the route and reloads so pi-bansos actually picks it up.
 *
 * What it deliberately does NOT do
 * --------------------------------
 * - It does not invent proxies. Public proxy lists are mostly dead and a dead
 *   exit costs a real request; routes are added explicitly by the operator.
 * - It does not patch pi-bansos. The two processes share
 *   `pi-bansos-relay-state.json`, which pi-bansos re-reads on every
 *   `session_start`. That is why `apply`/`reset` end with `ctx.reload()`: the
 *   file write alone would leave pi-bansos's in-memory pool stale.
 * - It does not claim to unlock anything. The server-side quota stays in force.
 *
 * Commands
 * --------
 *   /unlimited                 status (default)
 *   /unlimited on | off        enable/disable routing + watcher
 *   /unlimited usage           local meter, last hit, UTC reset clock
 *   /unlimited block [check]   probe current egress, classify, spent?
 *   /unlimited pool ...        list | add <url> | remove <url> | test | next | clear
 *   /unlimited watch [on|off]  auto-queue a route change on 429/403
 *   /unlimited apply           write the active route into pi-bansos + reload
 *   /unlimited reset [--dry]   rotate route, clear today's block, reload
 *   /unlimited doctor          environment + wiring checks
 *
 * State lives in `<agent-dir>/pi-unlimited-state.json`.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import * as fs from "node:fs";
import * as https from "node:https";
import * as os from "node:os";
import * as path from "node:path";

// ── Paths ──────────────────────────────────────────────────────────────────

const AGENT_DIR =
  process.env.PI_CODING_AGENT_DIR?.trim() || path.join(os.homedir(), ".pi", "agent");
const STATE_FILE = path.join(AGENT_DIR, "pi-unlimited-state.json");
const BANSOS_RELAY_FILE = path.join(AGENT_DIR, "pi-bansos-relay-state.json");

// ── Tuning ─────────────────────────────────────────────────────────────────

/** A route slower than this is treated as bad even when it answers. */
const SLOW_ROUTE_MS = 3500;
/** Rotation budget, mirroring opencode-unlimited's "five moves per 30 min". */
const MAX_ROTATIONS = 5;
const ROTATION_WINDOW_MS = 30 * 60_000;
/** Quarantine base for a route that just got refused; doubles per failure. */
const QUARANTINE_BASE_MS = 90_000;
const QUARANTINE_MAX_MS = 6 * 3600_000;
/** Opportunistic egress probing is cheap but not free — keep it rare. */
const EGRESS_PROBE_INTERVAL_MS = 10 * 60_000;

// ── Types ──────────────────────────────────────────────────────────────────

type PoolEntry = {
  url: string;
  label?: string;
  addedAt: number;
  failures: number;
  lastLatencyMs?: number;
  lastOkAt?: number;
  lastError?: string;
  quarantineUntil: number;
};

type LedgerEntry = {
  /** UTC day this block last spent budget on. */
  day: string;
  hits: number;
  first: number;
  last: number;
  kind: "quota" | "egress" | "gate";
};

type Hit = {
  at: number;
  status: number;
  kind: "quota" | "egress" | "gate";
  model?: string;
  block?: string;
  retryAfter?: string;
};

type State = {
  version: 1;
  enabled: boolean;
  watch: boolean;
  pool: PoolEntry[];
  activeUrl: string;
  ledger: Record<string, LedgerEntry>;
  egress: { ip: string; block: string; at: number };
  requests: { total: number; byDay: Record<string, number>; byModel: Record<string, number> };
  hits: Hit[];
  rotations: number[];
};

type RelayFile = {
  enabled: boolean;
  url: string;
  relays: { url: string; label?: string; addedAt?: string; auth?: string }[];
  statusBar: "shown" | "hidden";
};

// ── Small utilities ────────────────────────────────────────────────────────

function utcDay(now = Date.now()): string {
  return new Date(now).toISOString().slice(0, 10);
}

function nextUtcMidnight(now = Date.now()): number {
  const d = new Date(now);
  return Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate() + 1);
}

function humanMs(ms: number): string {
  if (!Number.isFinite(ms) || ms <= 0) return "now";
  const s = Math.floor(ms / 1000);
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  if (h > 0) return `${h}h ${m}m`;
  if (m > 0) return `${m}m ${s % 60}s`;
  return `${s}s`;
}

function ago(ts: number | undefined): string {
  if (!ts) return "never";
  return `${humanMs(Date.now() - ts)} ago`;
}

/** Expand an IPv6 address (incl. `::` compression and IPv4-mapped tail) to 8 hextets. */
function expandIpv6(ip: string): string[] {
  let s = ip.trim().toLowerCase();
  if (s.includes(".")) {
    const cut = s.lastIndexOf(":");
    const v4 = s.slice(cut + 1).split(".").map(Number);
    if (v4.length === 4 && v4.every((n) => Number.isInteger(n) && n >= 0 && n <= 255)) {
      s = `${s.slice(0, cut + 1)}${((v4[0] << 8) | v4[1]).toString(16)}:${((v4[2] << 8) | v4[3]).toString(16)}`;
    }
  }
  if (s.includes("::")) {
    const [head = "", tail = ""] = s.split("::");
    const h = head ? head.split(":") : [];
    const t = tail ? tail.split(":") : [];
    const fill = Math.max(0, 8 - h.length - t.length);
    return [...h, ...Array<string>(fill).fill("0"), ...t].map((g) => g || "0");
  }
  return s.split(":").map((g) => g || "0");
}

/**
 * The bucket the quota is counted against: a bare IPv4 address (`/32`) or the
 * first four hextets of an IPv6 address (`/64`). Two addresses inside one `/64`
 * are the same bucket, which a naive string compare would miss.
 */
function egressBlock(ip: string): string {
  const clean = ip.trim().replace(/%.*$/, "");
  if (!clean) return "";
  if (!clean.includes(":")) return clean;
  const groups = expandIpv6(clean)
    .slice(0, 4)
    .map((g) => g.replace(/^0+(?=.)/, ""));
  // Compress trailing zero groups so the label reads like a real prefix.
  while (groups.length > 0 && groups[groups.length - 1] === "0") groups.pop();
  return `${groups.join(":")}::/64`;
}

// ── HTTP (no deps, explicit timeout) ───────────────────────────────────────

type HttpResult = { status: number; body: string; latencyMs: number };

function httpGet(url: string, timeoutMs = 8000, method = "GET"): Promise<HttpResult> {
  return new Promise((resolve, reject) => {
    const started = Date.now();
    const req = https.request(
      url,
      { method, timeout: timeoutMs, headers: { "user-agent": "pi-unlimited/1.0" } },
      (res) => {
        let body = "";
        res.setEncoding("utf8");
        res.on("data", (chunk: string) => {
          if (body.length < 4096) body += chunk;
        });
        res.on("end", () =>
          resolve({ status: res.statusCode ?? 0, body, latencyMs: Date.now() - started }),
        );
      },
    );
    req.on("timeout", () => req.destroy(new Error(`timeout after ${timeoutMs}ms`)));
    req.on("error", reject);
    req.end();
  });
}

const EGRESS_ENDPOINTS = [
  "https://api.ipify.org",
  "https://icanhazip.com",
  "https://ifconfig.me/ip",
];

async function probeEgress(): Promise<{ ip: string; block: string; latencyMs: number } | null> {
  for (const url of EGRESS_ENDPOINTS) {
    try {
      const { status, body, latencyMs } = await httpGet(url, 6000);
      const ip = body.trim().split(/\s+/)[0] ?? "";
      if (status === 200 && ip && /^[0-9a-fA-F:.]+$/.test(ip)) {
        return { ip, block: egressBlock(ip), latencyMs };
      }
    } catch {
      // try the next endpoint
    }
  }
  return null;
}

/** Any HTTP answer (even 400/404) means the relay host is reachable. */
async function probeRoute(url: string): Promise<{
  ok: boolean;
  latencyMs: number;
  status?: number;
  error?: string;
}> {
  try {
    const { status, latencyMs } = await httpGet(url, 8000, "GET");
    return { ok: true, latencyMs, status };
  } catch (error) {
    return { ok: false, latencyMs: Number.POSITIVE_INFINITY, error: String(error) };
  }
}

// ── Shared relay file (pi-bansos owns the schema) ──────────────────────────

function readRelayFile(): RelayFile {
  try {
    const raw = JSON.parse(fs.readFileSync(BANSOS_RELAY_FILE, "utf8")) as Partial<RelayFile>;
    return {
      enabled: Boolean(raw?.enabled),
      url: typeof raw?.url === "string" ? raw.url.trim() : "",
      relays: Array.isArray(raw?.relays)
        ? raw.relays.filter((r): r is RelayFile["relays"][number] =>
            Boolean(r && typeof r.url === "string" && r.url.trim()),
          )
        : [],
      statusBar: raw?.statusBar === "hidden" ? "hidden" : "shown",
    };
  } catch {
    return { enabled: false, url: "", relays: [], statusBar: "shown" };
  }
}

/**
 * Merge our pool into pi-bansos's known-relay list and set the active route.
 * Written temp-file + rename because pi-bansos re-reads this file from other
 * processes and must never observe a half-written document.
 */
function writeRelayFile(
  state: State,
  activeUrl: string,
  enabled: boolean,
): { ok: true } | { ok: false; error: string } {
  const current = readRelayFile();
  const byUrl = new Map<string, RelayFile["relays"][number]>();
  for (const relay of current.relays) byUrl.set(relay.url, relay);
  for (const entry of state.pool) {
    const existing = byUrl.get(entry.url);
    byUrl.set(entry.url, {
      url: entry.url,
      label: entry.label ?? existing?.label,
      addedAt: existing?.addedAt ?? new Date(entry.addedAt).toISOString(),
      ...(existing?.auth ? { auth: existing.auth } : {}),
    });
  }
  const next: RelayFile = {
    enabled,
    url: activeUrl || current.url,
    relays: [...byUrl.values()],
    statusBar: current.statusBar,
  };
  const tmp = `${BANSOS_RELAY_FILE}.${process.pid}.tmp`;
  try {
    fs.mkdirSync(path.dirname(BANSOS_RELAY_FILE), { recursive: true });
    fs.writeFileSync(tmp, JSON.stringify(next));
    fs.renameSync(tmp, BANSOS_RELAY_FILE);
    return { ok: true };
  } catch (error) {
    try {
      fs.rmSync(tmp, { force: true });
    } catch {
      // best effort
    }
    return { ok: false, error: String(error) };
  }
}

// ── State ──────────────────────────────────────────────────────────────────

function freshState(): State {
  const relay = readRelayFile();
  return {
    version: 1,
    enabled: relay.enabled,
    watch: false,
    pool: relay.relays.map((r) => ({
      url: r.url,
      label: r.label,
      addedAt: Date.parse(r.addedAt ?? "") || Date.now(),
      failures: 0,
      quarantineUntil: 0,
    })),
    activeUrl: relay.url,
    ledger: {},
    egress: { ip: "", block: "", at: 0 },
    requests: { total: 0, byDay: {}, byModel: {} },
    hits: [],
    rotations: [],
  };
}

function loadState(): State {
  const base = freshState();
  try {
    const raw = JSON.parse(fs.readFileSync(STATE_FILE, "utf8")) as Partial<State>;
    const state: State = {
      ...base,
      ...raw,
      ledger: { ...(raw.ledger ?? {}) },
      requests: {
        total: raw.requests?.total ?? 0,
        byDay: { ...(raw.requests?.byDay ?? {}) },
        byModel: { ...(raw.requests?.byModel ?? {}) },
      },
      hits: Array.isArray(raw.hits) ? raw.hits.slice(-200) : [],
      rotations: Array.isArray(raw.rotations) ? raw.rotations : [],
      pool: Array.isArray(raw.pool) ? raw.pool : base.pool,
    };
    // First run, or the relay file gained routes pi-unlimited has not seen yet.
    if (!state.pool.length) state.pool = base.pool;
    if (!state.activeUrl) state.activeUrl = base.activeUrl;
    return state;
  } catch {
    return base;
  }
}

function saveState(state: State): void {
  const tmp = `${STATE_FILE}.${process.pid}.tmp`;
  try {
    fs.mkdirSync(path.dirname(STATE_FILE), { recursive: true });
    fs.writeFileSync(tmp, JSON.stringify(state));
    fs.renameSync(tmp, STATE_FILE);
  } catch {
    try {
      fs.rmSync(tmp, { force: true });
    } catch {
      // best effort
    }
  }
}

// ── Pool ranking ───────────────────────────────────────────────────────────

/** fast-healthy (1) → untested (2) → slow (3) → parked (4). */
function rankOf(entry: PoolEntry, now: number): number {
  if (entry.quarantineUntil > now) return 4;
  if (entry.lastLatencyMs == null) return 2;
  if (entry.lastLatencyMs > SLOW_ROUTE_MS) return 3;
  return 1;
}

function rankPool(pool: PoolEntry[]): PoolEntry[] {
  const now = Date.now();
  return [...pool].sort(
    (a, b) =>
      rankOf(a, now) - rankOf(b, now) ||
      (a.lastLatencyMs ?? Number.POSITIVE_INFINITY) -
        (b.lastLatencyMs ?? Number.POSITIVE_INFINITY),
  );
}

function labelOf(entry: PoolEntry | undefined): string {
  if (!entry) return "direct";
  return entry.label ? `${entry.label} (${entry.url})` : entry.url;
}

function pickNext(state: State, currentUrl: string): PoolEntry | undefined {
  return rankPool(state.pool).find(
    (entry) =>
      entry.url && entry.url !== currentUrl && entry.quarantineUntil <= Date.now(),
  );
}

function quarantine(state: State, url: string, baseMs = QUARANTINE_BASE_MS): void {
  const entry = state.pool.find((p) => p.url === url);
  if (!entry) return;
  entry.failures += 1;
  entry.quarantineUntil = Date.now() + Math.min(baseMs * 2 ** (entry.failures - 1), QUARANTINE_MAX_MS);
}

// ── Counters / ledger ──────────────────────────────────────────────────────

function bumpRequests(state: State, model?: string): void {
  const day = utcDay();
  state.requests.total += 1;
  state.requests.byDay[day] = (state.requests.byDay[day] ?? 0) + 1;
  if (model) state.requests.byModel[model] = (state.requests.byModel[model] ?? 0) + 1;
  // keep the per-day map from growing without bound
  const days = Object.keys(state.requests.byDay).sort();
  for (const old of days.slice(0, Math.max(0, days.length - 30))) {
    delete state.requests.byDay[old];
  }
}

function classify(status: number): Hit["kind"] {
  // 429 = the day's quota landed. 403 = either the egress IP is flagged or the
  // fingerprint gate fired; both mean "this route cannot serve right now".
  return status === 429 ? "quota" : "gate";
}

function recordHit(
  state: State,
  status: number,
  model: string | undefined,
  headers: Record<string, string> | undefined,
  block: string | undefined,
): Hit {
  const now = Date.now();
  const kind = classify(status);
  const hit: Hit = {
    at: now,
    status,
    kind,
    model,
    block,
    retryAfter: headers?.["retry-after"],
  };
  state.hits.push(hit);
  if (state.hits.length > 200) state.hits = state.hits.slice(-200);

  if (block) {
    const day = utcDay(now);
    const existing = state.ledger[block];
    state.ledger[block] =
      existing && existing.day === day
        ? { ...existing, hits: existing.hits + 1, last: now }
        : { day, hits: 1, first: now, last: now, kind };
  }
  return hit;
}

function ledgerToday(state: State): { hits: number; blocks: number } {
  const day = utcDay();
  let hits = 0;
  let blocks = 0;
  for (const entry of Object.values(state.ledger)) {
    if (entry.day === day) {
      hits += entry.hits;
      blocks += 1;
    }
  }
  return { hits, blocks };
}

// ── Formatting ─────────────────────────────────────────────────────────────

function statusLine(state: State): string {
  const now = Date.now();
  const healthy = state.pool.filter((e) => e.quarantineUntil <= now).length;
  const { hits } = ledgerToday(state);
  const mode = state.enabled ? "on" : "off";
  const watch = state.watch ? "watch" : "no-watch";
  return `unlimited: ${mode}/${watch} · routes ${healthy}/${state.pool.length} · ${hits} hit(s) today`;
}

function renderStatus(state: State): string {
  const now = Date.now();
  const healthy = state.pool.filter((e) => e.quarantineUntil <= now).length;
  const { hits, blocks } = ledgerToday(state);
  const today = state.requests.byDay[utcDay()] ?? 0;
  const active = state.activeUrl || readRelayFile().url || "direct";
  const lines = [
    `pi-unlimited — ${state.enabled ? "ON" : "OFF"} | watch ${state.watch ? "ON" : "OFF"}`,
    `routes: ${healthy} healthy / ${state.pool.length} total | active: ${active || "direct"}`,
    state.egress.ip
      ? `egress: ${state.egress.ip} (${state.egress.block}) · ${ago(state.egress.at)}`
      : "egress: not probed yet — run /unlimited block",
    `today (UTC ${utcDay()}): ${hits} limit hit(s) across ${blocks} block(s) | ${today} request(s)`,
    `quota window resets at 00:00 UTC — in ${humanMs(nextUtcMidnight() - now)}`,
  ];
  return lines.join("\n");
}

function renderPool(state: State): string {
  const now = Date.now();
  if (!state.pool.length) {
    return "pool is empty — add a relay with /unlimited pool add <url>";
  }
  const rows = rankPool(state.pool).map((entry, i) => {
    const parked = entry.quarantineUntil > now;
    const stateTag = parked ? `parked ${humanMs(entry.quarantineUntil - now)}` : "ready";
    const latency = entry.lastLatencyMs == null ? "untested" : `${entry.lastLatencyMs}ms`;
    const active = entry.url === state.activeUrl ? " *" : "";
    const label = entry.label ? `${entry.label} ` : "";
    return `${i + 1}. ${label}${entry.url}${active} — ${stateTag}, ${latency}, ${entry.failures} failure(s)`;
  });
  return [`relay pool (${state.pool.length}):`, ...rows].join("\n");
}

function renderUsage(state: State): string {
  const day = utcDay();
  const today = state.requests.byDay[day] ?? 0;
  const last = state.hits[state.hits.length - 1];
  const top = Object.entries(state.requests.byModel)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 3)
    .map(([model, count]) => `${model} ×${count}`);
  return [
    `usage (UTC ${day})`,
    `requests: ${today} today / ${state.requests.total} total`,
    last
      ? `last limit: HTTP ${last.status} (${last.kind}) at ${new Date(last.at).toISOString().slice(11, 16)} UTC${last.model ? ` on ${last.model}` : ""}`
      : "last limit: none recorded",
    `resets at 00:00 UTC — in ${humanMs(nextUtcMidnight() - Date.now())}`,
    top.length ? `top models: ${top.join(", ")}` : "top models: —",
  ].join("\n");
}

// ── Extension ──────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  let state = loadState();
  let egressProbeInFlight = false;
  let lastProbeAttempt = 0;

  const setStatus = (ctx: { ui?: { setStatus?: (key: string, text: string) => void } }) => {
    try {
      ctx.ui?.setStatus?.("unlimited", statusLine(state));
    } catch {
      // status bar is cosmetic
    }
  };

  const notify = (
    ctx: { ui?: { notify?: (text: string, level?: string) => void } },
    text: string,
    level: "info" | "warning" | "error" = "info",
  ) => {
    try {
      ctx.ui?.notify?.(text, level);
    } catch {
      // notifications are best effort
    }
  };

  const refreshEgress = async (ctx: Parameters<typeof notify>[0]): Promise<void> => {
    if (egressProbeInFlight) return;
    egressProbeInFlight = true;
    lastProbeAttempt = Date.now();
    try {
      const probe = await probeEgress();
      if (probe) {
        state.egress = { ip: probe.ip, block: probe.block, at: Date.now() };
        saveState(state);
        setStatus(ctx);
      }
    } finally {
      egressProbeInFlight = false;
    }
  };

  const maybeRefreshEgress = (ctx: Parameters<typeof notify>[0]): void => {
    // Throttle on the *attempt*, not on success: a blocked probe endpoint must
    // not turn every successful request into another outbound call.
    if (Date.now() - lastProbeAttempt < EGRESS_PROBE_INTERVAL_MS) return;
    void refreshEgress(ctx).catch(() => undefined);
  };

  /**
   * Queue a route change after a limit hit. Writes the shared relay file so
   * the next `session_start` (or `/unlimited apply`) lands on the new route.
   * Rotation is capped, because a cap is the difference between "resilient"
   * and "hammering every exit you own into the same wall".
   */
  const queueRotation = (ctx: Parameters<typeof notify>[0]): void => {
    const now = Date.now();
    state.rotations = state.rotations.filter((t) => now - t < ROTATION_WINDOW_MS);
    if (state.rotations.length >= MAX_ROTATIONS) {
      notify(
        ctx,
        `unlimited: rotation cap reached (${MAX_ROTATIONS} per 30 min) — wait for 00:00 UTC or change the connection manually`,
        "warning",
      );
      return;
    }
    const current = state.activeUrl || readRelayFile().url;
    quarantine(state, current);
    const next = pickNext(state, current);
    if (!next) {
      notify(
        ctx,
        "unlimited: no other healthy route — add one with /unlimited pool add <url>",
        "warning",
      );
      return;
    }
    state.activeUrl = next.url;
    state.rotations.push(now);
    const written = writeRelayFile(state, next.url, true);
    if (!written.ok) {
      notify(ctx, `unlimited: could not write ${BANSOS_RELAY_FILE}: ${written.error}`, "error");
      return;
    }
    notify(
      ctx,
      `unlimited: limit hit → queued ${labelOf(next)}. Run /unlimited apply to switch now.`,
      "info",
    );
  };

  // ── Lifecycle ────────────────────────────────────────────────────────────

  pi.on("session_start", async (_event, ctx) => {
    state = loadState();
    setStatus(ctx);
    maybeRefreshEgress(ctx);
  });

  pi.on("session_shutdown", () => {
    saveState(state);
  });

  /**
   * The meter. `after_provider_response` sees the HTTP status before the stream
   * body is consumed, so this costs nothing and needs no provider cooperation.
   * Only `bansos` is tracked: other providers do not share this quota.
   */
  pi.on("after_provider_response", (event, ctx) => {
    const provider = (event as { provider?: string }).provider ?? ctx.model?.provider;
    if (provider !== "bansos") return;

    const status = Number((event as { status?: number }).status ?? 0);
    const model = ctx.model ? `${ctx.model.provider}/${ctx.model.id}` : undefined;
    bumpRequests(state, model);

    if (status === 429 || status === 403) {
      const headers = (event as { headers?: Record<string, string> }).headers;
      const block = state.egress.block || undefined;
      const hit = recordHit(state, status, model, headers, block);
      saveState(state);
      setStatus(ctx);
      notify(
        ctx,
        `unlimited: HTTP ${status} (${hit.kind})${hit.retryAfter ? `, Retry-After ${hit.retryAfter}` : ""}` +
          `${block ? ` on ${block}` : ""}`,
        status === 429 ? "warning" : "error",
      );
      if (state.watch) queueRotation(ctx);
      return;
    }

    if (status >= 200 && status < 300) {
      maybeRefreshEgress(ctx);
    }
  });

  // ── Commands ─────────────────────────────────────────────────────────────

  pi.registerCommand("unlimited", {
    description:
      "Bansos route control: status | on | off | usage | block | pool | watch | apply | reset | doctor",
    getArgumentCompletions: (prefix: string) => {
      const subs = [
        "status",
        "on",
        "off",
        "usage",
        "block",
        "pool",
        "pool list",
        "pool add",
        "pool remove",
        "pool test",
        "pool next",
        "pool clear",
        "watch",
        "watch on",
        "watch off",
        "apply",
        "reset",
        "doctor",
      ];
      return subs
        .filter((s) => s.startsWith(prefix))
        .map((s) => ({ value: s, label: s }));
    },
    handler: async (args, ctx) => {
      state = loadState();
      const parts = String(args ?? "")
        .trim()
        .split(/\s+/)
        .filter(Boolean);
      const sub = parts[0] ?? "status";
      const rest = parts.slice(1);

      const addRoute = (url: string): boolean => {
        const clean = url.trim().replace(/\/$/, "");
        let parsed: URL;
        try {
          parsed = new URL(clean);
        } catch {
          notify(ctx, `unlimited: not a URL: ${url}`, "error");
          return false;
        }
        if (parsed.protocol !== "https:" && parsed.protocol !== "http:") {
          notify(ctx, "unlimited: route must be http(s)", "error");
          return false;
        }
        if (state.pool.some((e) => e.url === clean)) {
          notify(ctx, `unlimited: already in the pool: ${clean}`, "info");
          return false;
        }
        state.pool.push({
          url: clean,
          // rest is ["add", url, ...labelWords]
          label: rest.slice(2).join(" ") || undefined,
          addedAt: Date.now(),
          failures: 0,
          quarantineUntil: 0,
        });
        return true;
      };

      switch (sub) {
        case "status": {
          notify(ctx, renderStatus(state), "info");
          return;
        }

        case "on": {
          state.enabled = true;
          state.watch = true;
          if (!state.activeUrl && state.pool.length) state.activeUrl = rankPool(state.pool)[0].url;
          const written = writeRelayFile(state, state.activeUrl, true);
          saveState(state);
          setStatus(ctx);
          if (!written.ok) {
            notify(ctx, `unlimited: relay file write failed: ${written.error}`, "error");
            return;
          }
          notify(
            ctx,
            `unlimited: ON (watch) · ${state.pool.length} route(s) · active ${state.activeUrl || "direct"}\n` +
              "Changes land on the next session; /unlimited apply forces it now.",
            "info",
          );
          return;
        }

        case "off": {
          state.enabled = false;
          state.watch = false;
          writeRelayFile(state, state.activeUrl, false);
          saveState(state);
          setStatus(ctx);
          notify(ctx, "unlimited: OFF — watcher stopped, relay disabled (direct egress).", "info");
          return;
        }

        case "usage": {
          notify(ctx, renderUsage(state), "info");
          return;
        }

        case "block": {
          const probe = await probeEgress();
          if (!probe) {
            notify(ctx, "unlimited: could not reach an egress probe endpoint", "error");
            return;
          }
          state.egress = { ip: probe.ip, block: probe.block, at: Date.now() };
          const entry = state.ledger[probe.block];
          const spent = entry && entry.day === utcDay();
          saveState(state);
          setStatus(ctx);
          notify(
            ctx,
            [
              `egress: ${probe.ip} → block ${probe.block} (${probe.latencyMs}ms)`,
              spent
                ? `status: SPENT — ${entry.hits} hit(s) today, last ${ago(entry.last)}`
                : "status: clean today (no recorded limit on this block)",
              `resets at 00:00 UTC — in ${humanMs(nextUtcMidnight() - Date.now())}`,
            ].join("\n"),
            spent ? "warning" : "info",
          );
          return;
        }

        case "pool": {
          const action = rest[0] ?? "list";
          if (action === "list") {
            notify(ctx, renderPool(state), "info");
            return;
          }
          if (action === "add") {
            if (!rest[1]) {
              notify(ctx, "usage: /unlimited pool add <url> [label]", "warning");
              return;
            }
            if (!addRoute(rest[1])) return;
            saveState(state);
            // Never flip pi-bansos's own relay switch as a side effect of
            // editing the pool: preserve whatever it had.
            writeRelayFile(state, state.activeUrl, state.enabled || readRelayFile().enabled);
            notify(ctx, `unlimited: added ${rest[1]}\n${renderPool(state)}`, "info");
            return;
          }
          if (action === "remove") {
            const target = (rest[1] ?? "").replace(/\/$/, "");
            if (!target) {
              notify(ctx, "usage: /unlimited pool remove <url>", "warning");
              return;
            }
            const before = state.pool.length;
            state.pool = state.pool.filter((e) => e.url !== target);
            if (state.activeUrl === target) state.activeUrl = state.pool[0]?.url ?? "";
            saveState(state);
            writeRelayFile(state, state.activeUrl, state.enabled || readRelayFile().enabled);
            notify(
              ctx,
              before === state.pool.length ? `not in the pool: ${target}` : `removed ${target}`,
              "info",
            );
            return;
          }
          if (action === "clear") {
            state.pool = [];
            state.activeUrl = "";
            saveState(state);
            writeRelayFile(state, "", false);
            notify(ctx, "unlimited: pool cleared.", "info");
            return;
          }
          if (action === "test") {
            if (!state.pool.length) {
              notify(ctx, "pool is empty — nothing to test", "warning");
              return;
            }
            const candidates = rankPool(state.pool).slice(0, 10);
            const results: string[] = [];
            for (const entry of candidates) {
              const probe = await probeRoute(entry.url);
              if (probe.ok) {
                entry.lastLatencyMs = probe.latencyMs;
                entry.lastOkAt = Date.now();
                entry.lastError = undefined;
                entry.failures = 0;
                entry.quarantineUntil = 0;
                const slow = probe.latencyMs > SLOW_ROUTE_MS ? " (slow)" : "";
                results.push(`ok   ${probe.latencyMs}ms${slow} — ${entry.url}`);
              } else {
                quarantine(state, entry.url);
                entry.lastError = probe.error;
                results.push(`dead ${probe.error ?? ""} — ${entry.url}`);
              }
            }
            saveState(state);
            setStatus(ctx);
            notify(ctx, [`probed ${candidates.length} route(s):`, ...results].join("\n"), "info");
            return;
          }
          if (action === "next") {
            const current = state.activeUrl || readRelayFile().url;
            const next = pickNext(state, current);
            if (!next) {
              notify(ctx, "unlimited: no other healthy route in the pool", "warning");
              return;
            }
            state.activeUrl = next.url;
            const written = writeRelayFile(state, next.url, true);
            saveState(state);
            if (!written.ok) {
              notify(ctx, `unlimited: relay file write failed: ${written.error}`, "error");
              return;
            }
            notify(ctx, `unlimited: active route → ${labelOf(next)}\nReloading to apply…`, "info");
            await ctx.reload();
            return;
          }
          notify(ctx, "usage: /unlimited pool list|add|remove|test|next|clear", "warning");
          return;
        }

        case "watch": {
          const mode = rest[0];
          if (mode === "on" || mode === "off") {
            state.watch = mode === "on";
            saveState(state);
            setStatus(ctx);
            notify(ctx, `unlimited: watcher ${state.watch ? "ON" : "OFF"}`, "info");
            return;
          }
          notify(ctx, `unlimited: watcher is ${state.watch ? "ON" : "OFF"} (use watch on|off)`, "info");
          return;
        }

        case "apply": {
          if (!state.enabled) {
            state.enabled = true;
            state.watch = true;
          }
          if (!state.activeUrl && state.pool.length) state.activeUrl = rankPool(state.pool)[0].url;
          const written = writeRelayFile(state, state.activeUrl, true);
          saveState(state);
          if (!written.ok) {
            notify(ctx, `unlimited: relay file write failed: ${written.error}`, "error");
            return;
          }
          notify(ctx, `unlimited: applying route ${state.activeUrl || "direct"} — reloading…`, "info");
          await ctx.reload();
          return;
        }

        case "reset": {
          const dry = rest.includes("--dry");
          const probe = await probeEgress();
          const blockBefore = probe?.block ?? state.egress.block;
          const current = state.activeUrl || readRelayFile().url;
          quarantine(state, current);
          const next = pickNext(state, current);
          const lines = [
            `reset${dry ? " (dry run)" : ""}`,
            `egress now: ${probe ? `${probe.ip} (${probe.block})` : "unreachable"}`,
            `route: ${current || "direct"} → ${next ? labelOf(next) : "unchanged (no healthy alternative)"}`,
          ];
          if (blockBefore) {
            const entry = state.ledger[blockBefore];
            if (entry && entry.day === utcDay()) {
              lines.push(`cleared ledger for ${blockBefore} (${entry.hits} hit(s) today)`);
              if (!dry) delete state.ledger[blockBefore];
            } else {
              lines.push(`ledger for ${blockBefore}: already clean today`);
            }
          }
          if (dry) {
            notify(ctx, lines.join("\n"), "info");
            return;
          }
          if (next) state.activeUrl = next.url;
          state.rotations.push(Date.now());
          saveState(state);
          const written = writeRelayFile(state, state.activeUrl, true);
          if (!written.ok) {
            notify(ctx, `unlimited: relay file write failed: ${written.error}`, "error");
            return;
          }
          notify(ctx, `${lines.join("\n")}\nReloading to apply…`, "info");
          await ctx.reload();
          return;
        }

        case "doctor": {
          const checks: string[] = [];
          const node = process.version;
          checks.push(`node ${node}`);
          try {
            fs.accessSync(AGENT_DIR, fs.constants.W_OK);
            checks.push(`agent dir writable: ${AGENT_DIR}`);
          } catch {
            checks.push(`agent dir NOT writable: ${AGENT_DIR}`);
          }
          const commands = pi.getCommands();
          checks.push(
            commands.some((c) => c.name === "bansos")
              ? "pi-bansos loaded (/bansos present)"
              : "pi-bansos NOT loaded — install npm:pi-bansos",
          );
          checks.push(
            fs.existsSync(BANSOS_RELAY_FILE)
              ? `relay file: ${BANSOS_RELAY_FILE}`
              : `relay file missing (created on first write): ${BANSOS_RELAY_FILE}`,
          );
          checks.push(`state file: ${STATE_FILE}`);
          const probe = await probeEgress();
          checks.push(probe ? `egress probe ok: ${probe.ip}` : "egress probe FAILED");
          checks.push(`pool: ${state.pool.length} route(s), ${rankPool(state.pool).filter((e) => e.quarantineUntil <= Date.now()).length} healthy`);
          notify(ctx, ["pi-unlimited doctor:", ...checks.map((c) => `- ${c}`)].join("\n"), "info");
          return;
        }

        default: {
          notify(
            ctx,
            "usage: /unlimited status|on|off|usage|block|pool|watch|apply|reset|doctor",
            "warning",
          );
          return;
        }
      }
    },
  });
}
