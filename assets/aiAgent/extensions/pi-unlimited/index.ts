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
 * The extension also reports the provider's *real* reset time. pi-bansos
 * deliberately discards OpenCode `Retry-After` hints longer than 300s and
 * substitutes its own 90s→15min reactive backoff, so a bucket that refills at
 * midnight UTC reaches the TUI looking like "retry in 8m". The gateway keeps
 * the hint; this extension surfaces it and labels the short one for what it is.
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
 *   /unlimited reload         clear pi-bansos's in-memory 429 backoff
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
/**
 * Two gateways, because an egress belongs to the *process*, not to pi: a service
 * in app.slice leaves through the VPN tunnel, one in novpn.slice leaves through
 * the physical interface. `novpn` marks packets per cgroup in nftables, so
 * membership in that slice is the whole bypass — and it is what we detect here,
 * from our own cgroup, since that is inherited by every child we spawn.
 *
 * Keep in sync with gatewayPort / gatewayPortNovpn in modules/pi-unlimited.nix.
 */
const GATEWAY_URL_VPN = "http://127.0.0.1:18790";
const GATEWAY_URL_NOVPN = "http://127.0.0.1:18791";
const GATEWAY_UNITS: Record<"vpn" | "novpn", string> = {
  vpn: "pi-unlimited-gateway",
  novpn: "pi-unlimited-gateway-novpn",
};

function detectNovpn(): boolean {
  if (process.platform !== "linux") return false;
  try {
    return fs.readFileSync("/proc/self/cgroup", "utf8").includes("/novpn.slice/");
  } catch {
    // No procfs, or an unreadable cgroup: assume the VPN path, which is what a
    // systemd service and an ordinary login shell both use.
    return false;
  }
}

/** True when *this* pi process was started under `novpn`. */
const IN_NOVPN = detectNovpn();
const EGRESS_CLASS: "vpn" | "novpn" = IN_NOVPN ? "novpn" : "vpn";
const GATEWAY_URL =
  process.env.PI_UNLIMITED_URL?.trim() || (IN_NOVPN ? GATEWAY_URL_NOVPN : GATEWAY_URL_VPN);
const GATEWAY_UNIT = GATEWAY_UNITS[EGRESS_CLASS];
const GATEWAY_STATE_FILE = path.join(
  AGENT_DIR,
  IN_NOVPN ? "pi-unlimited-gateway-novpn.json" : "pi-unlimited-gateway.json",
);
const RELAY_LABEL = "pi-unlimited gateway";
/**
 * pi-bansos never forwards an OpenCode hint longer than 300s; it substitutes its
 * own backoff, which caps at 15 minutes. So any `retry-after` up to 900s is
 * pi-bansos talking about itself, and anything much larger is the provider.
 */
const LOCAL_BACKOFF_MAX_SECONDS = 900;
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
  id?: string;
  healthy: boolean;
  requests: number;
  failures: number;
  lastOkAt: number;
  lastLatencyMs: number;
  lastError: string;
  quarantineUntil: number;
  /** Public address this exit actually leaves from; duplicates share one budget. */
  exitIp?: string;
};

type GatewayState = {
  bind?: string;
  startedAt?: number;
  savedAt?: number;
  egress?: GatewayEgress[] | Record<string, Omit<GatewayEgress, "id" | "healthy">>;
  requests?: { total: number; byDay: Record<string, number> };
  /** The provider's real "spent until", per egress; pi-bansos's 15m cap hides it. */
  buckets?: Record<string, { spentUntil: number; retryAfterSeconds: number; at: number }>;
  /** How many distinct exit addresses the pool actually reaches. */
  distinctBlocks?: number;
  events?: { at: number; egress: string; status: number; kind: RefusalKind; retryAfterSeconds?: number }[];
};

/** Reply of `/__unlimited/test`: one real request per distinct block. */
type EgressTest = {
  model: string;
  at: number;
  elapsedMs: number;
  tested: number;
  available: number;
  remaining: string;
  rows: {
    id: string;
    exitIp: string;
    status: number;
    verdict: "ok" | "spent" | "gate" | "flagged" | "error" | "skipped";
    note?: string;
    kind?: RefusalKind;
    retryAfterSeconds?: number;
    latencyMs?: number;
  }[];
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

/**
 * pi-bansos discards OpenCode `Retry-After` hints longer than 300s and applies
 * its own 90s→15min reactive backoff instead, so a spent bucket reaches the TUI
 * as "retry in 8m". The gateway keeps the provider's real hint; prefer it.
 */
function spentBuckets(): { egress: string; spentUntil: number }[] {
  const buckets = loadGatewayState()?.buckets;
  if (!buckets) return [];
  const now = Date.now();
  return Object.entries(buckets)
    .filter(([, bucket]) => typeof bucket.spentUntil === "number" && bucket.spentUntil > now)
    .map(([egress, bucket]) => ({ egress, spentUntil: bucket.spentUntil }))
    .sort((a, b) => a.spentUntil - b.spentUntil);
}

/** "3 of 4 egress spent · next recovers 14:32 UTC" — the pool-wide view. */
function bucketSummary(buckets: { egress: string; spentUntil: number }[]): string | undefined {
  if (!buckets.length) return undefined;
  const next = new Date(buckets[0].spentUntil).toISOString().slice(11, 16);
  const wait = humanDuration((buckets[0].spentUntil - Date.now()) / 1000);
  return `${buckets.length} egress spent · next recovers ~${next} UTC (in ${wait})`;
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

// A live test answers one real, metered request per distinct block, so it is
// allowed to take minutes — hence the separate, generous budget.
async function gatewayTest(model: string): Promise<EgressTest | string> {
  try {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 180_000);
    const url = `${GATEWAY_URL}/__unlimited/test?model=${encodeURIComponent(model)}`;
    const response = await fetch(url, { signal: controller.signal });
    clearTimeout(timer);
    if (!response.ok) return `test failed: HTTP ${response.status}`;
    return (await response.json()) as EgressTest;
  } catch (error) {
    return `test failed: gateway unreachable (${String(error).slice(0, 80)})`;
  }
}

/** `socks5://127.0.0.1:25344` → `25344`, so rows stay narrow. */
function shortEgress(id: string): string {
  if (id === "direct") return "direct";
  try {
    const url = new URL(id);
    return url.port || url.hostname;
  } catch {
    return id;
  }
}

function formatTest(result: EgressTest): string {
  const width = Math.max(...result.rows.map((row) => shortEgress(row.id).length), 4);
  const rows = result.rows.map((row) => {
    const name = shortEgress(row.id).padEnd(width);
    const ip = (row.exitIp || "—").padEnd(15);
    if (row.verdict === "ok") {
      return `  ${name}  ${ip}  ok  ${humanDuration((row.latencyMs ?? 0) / 1000)}`;
    }
    if (row.verdict === "spent") {
      if (row.retryAfterSeconds == null) return `  ${name}  ${ip}  SPENT · no reset given`;
      const reset = new Date(Date.now() + row.retryAfterSeconds * 1000).toISOString().slice(11, 16);
      return `  ${name}  ${ip}  SPENT · resets ${reset}Z in ${humanDuration(row.retryAfterSeconds)}`;
    }
    return `  ${name}  ${ip}  ${row.verdict}${row.note ? ` · ${row.note}` : ""}`;
  });
  return [
    `egress test · ${result.model} · ${result.tested} request(s) in ${humanDuration(result.elapsedMs / 1000)}`,
    ...rows,
    `${result.available}/${result.tested} block(s) have budget · remaining usage ${result.remaining}`,
  ].join("\n");
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

/** Either of this module's gateways — the relay file is shared between shells. */
function isOurGateway(url: string): boolean {
  return url === GATEWAY_URL_VPN || url === GATEWAY_URL_NOVPN;
}

/** Point pi-bansos at the gateway, preserving relays the operator added itself. */
function applyRelay(state: State): { ok: boolean; message: string } {
  const relay = loadRelayFile();
  const others = relay.relays.filter((entry) => !isOurGateway(entry.url));
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
  const others = relay.relays.filter((entry) => !isOurGateway(entry.url));
  const wasActive = isOurGateway(relay.url);
  const next: RelayFile = {
    enabled: wasActive && others.length > 0 ? relay.enabled : wasActive ? false : relay.enabled,
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
  // "managed" = the file points at one of ours (possibly the other shell's).
  // "active" = it points at the gateway that matches this shell's egress class.
  return {
    active: relay.enabled && relay.url === GATEWAY_URL,
    url: relay.url,
    managed: isOurGateway(relay.url),
  };
}

/**
 * The relay file is global but the right gateway is per-shell, so re-point it
 * whenever it already tracks one of ours. Done at load rather than in a handler:
 * pi-bansos re-reads the file in its own `session_start`, which runs after every
 * extension has been imported, so writing here takes effect without a reload.
 */
function alignRelayToShell(): void {
  try {
    const relay = loadRelayFile();
    if (!relay.enabled || !isOurGateway(relay.url) || relay.url === GATEWAY_URL) return;
    writeJsonAtomic(RELAY_FILE, {
      ...relay,
      url: GATEWAY_URL,
      relays: [
        { url: GATEWAY_URL, label: RELAY_LABEL, addedAt: new Date().toISOString() },
        ...relay.relays.filter((entry) => !isOurGateway(entry.url)),
      ],
    });
  } catch {
    // Never let a routing convenience break session start.
  }
}

// ── Reports ────────────────────────────────────────────────────────────────

/**
 * One line, by design. "wrapped" = the relay hop is live; the suffix answers the
 * only two questions that matter: is the daily bucket spent, or is this just
 * pi-bansos's own short backoff.
 */
function statusText(state: State, gateway?: GatewayState): string {
  const bits: string[] = [];
  // The session class is worth one word: it is the difference between the ISP
  // address and the VPN address, and two novpn shells make it obvious.
  if (IN_NOVPN) bits.push("novpn");
  bits.push(relayStatus().active ? "wrapped" : "direct");
  const blocks = gateway?.distinctBlocks;
  if (typeof blocks === "number" && blocks > 0) {
    bits.push(`${blocks} block${blocks === 1 ? "" : "s"}`);
  }
  bits.push(limitState(state));
  return `unlimited: ${bits.join(" · ")}`;
}

/** "daily limit 8h 12m" | "backoff 4m" | "ok" — never both, never a paragraph. */
function limitState(state: State): string {
  const now = Date.now();
  const buckets = spentBuckets();
  if (buckets.length) {
    // The provider's own hint, which pi-bansos hides behind its 15m cap.
    return `DAILY LIMIT ${humanDuration((buckets[0].spentUntil - now) / 1000)}`;
  }
  const latest = state.events[state.events.length - 1];
  const until =
    latest?.retryAfterSeconds != null && latest.retryAfterSeconds <= LOCAL_BACKOFF_MAX_SECONDS
      ? latest.at + latest.retryAfterSeconds * 1000
      : 0;
  if (until > now) return `backoff ${humanDuration((until - now) / 1000)}`;
  return "ok";
}

/** `/unlimited status` — one line. `/unlimited status full` for the detail. */
function statusReport(state: State, gateway?: GatewayState): string {
  const line = statusText(state, gateway);
  if (!relayStatus().active) {
    const relay = relayStatus();
    const hint = relay.managed
      ? `/unlimited reload` // points at the other shell's gateway
      : `/unlimited apply`;
    return `${line}\n  relay not applied · ${hint}`;
  }
  return line;
}

/** The long form, kept for troubleshooting. */
function statusDetail(state: State, gateway?: GatewayState): string {
  const now = Date.now();
  const latest = state.events[state.events.length - 1];
  const today = eventsToday(state);
  const relay = relayStatus();
  const lines = [
    `unlimited: ${relay.active ? `wrapped → ${GATEWAY_URL}` : `direct (relay: ${relay.url || "none"})`}`,
    `session egress: ${IN_NOVPN ? "novpn — physical interface, VPN bypassed" : "vpn — Proton tunnel"}`,
    `gateway: ${gateway ? `up on ${gateway.bind ?? GATEWAY_URL}` : "not reachable"}`,
    `blocks: ${gateway?.distinctBlocks ?? "?"} distinct · ${gateway?.egress ? (Array.isArray(gateway.egress) ? gateway.egress.length : Object.keys(gateway.egress).length) : "?"} configured`,
    latest
      ? `last refusal: HTTP ${latest.status} (${latest.kind}) at ${new Date(latest.at).toISOString().slice(11, 19)} UTC${latest.model ? ` · ${latest.model}` : ""}`
      : "last refusal: none recorded",
    `refusals today: ${today.length} · notifications ${state.watch ? "ON" : "OFF"}`,
    `UTC midnight (free-tier reset) in ${humanDuration(Math.ceil((nextUtcMidnight(now) - now) / 1000))}`,
  ];
  const buckets = spentBuckets();
  const summary = bucketSummary(buckets);
  if (summary) {
    lines.push(`provider buckets: ${summary}`);
    lines.push(`  spent: ${buckets.map((bucket) => bucket.egress).join(", ")}`);
  }
  if (latest?.poolWide) lines.push("note: every egress got the same refusal — the bucket is not per-IP.");
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
  const entries: [string, GatewayEgress][] = Array.isArray(gateway.egress)
    ? gateway.egress.map((record) => [record.id ?? "?", record])
    : Object.entries(gateway.egress).map(([id, record]) => [id, { id, healthy: true, ...record }]);
  const rows = entries.map(([id, record]) => {
    const parked =
      record.quarantineUntil && record.quarantineUntil > now
        ? `parked ${humanDuration((record.quarantineUntil - now) / 1000)}`
        : "ready";
    const latency = record.lastLatencyMs ? `${record.lastLatencyMs}ms` : "—";
    return `- ${id.padEnd(28)} ${parked.padEnd(16)} ok=${record.requests} fail=${record.failures} last=${latency} ${record.exitIp ?? "?"}${
      record.lastError ? ` · ${record.lastError}` : ""
    }`;
  });
  const total = gateway.requests?.total ?? 0;
  const distinct =
    gateway.distinctBlocks ??
    new Set(entries.map(([, record]) => record.exitIp).filter(Boolean)).size;
  return [
    `Gateway egress (${total} request(s) relayed, ${distinct} distinct block(s)):`,
    ...rows,
  ].join("\n");
}

// ── Free-model failover ladder ─────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  // Runs during extension load, i.e. before pi-bansos's own session_start
  // re-reads the relay file — so `novpn pi` lands on the novpn gateway with no
  // manual `/unlimited apply`.
  alignRelayToShell();
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

  const setStatus = (
    ctx: { ui?: { setStatus?: (key: string, text: string) => void } },
    gateway?: GatewayState,
  ) => {
    try {
      ctx.ui?.setStatus?.("unlimited", statusText(state, gateway));
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
    if (!appendEvent(state, event)) return;
    setStatus(ctx);
    if (!state.watch) return;
    const retry = event.retryAfterSeconds != null ? ` Retry in ${humanDuration(event.retryAfterSeconds)}.` : "";
    const wide = event.poolWide ? " Every egress was refused, so rotating cannot help." : "";
    // A short hint is pi-bansos's own backoff (90s→15min cap), not the
    // provider's. Say which, so nobody waits 15 minutes for a bucket that
    // refills at midnight UTC.
    const shortHint =
      event.retryAfterSeconds != null && event.retryAfterSeconds <= LOCAL_BACKOFF_MAX_SECONDS;
    const buckets = spentBuckets();
    const summary = bucketSummary(buckets);
    const bucketNote = summary ? ` Provider buckets: ${summary}.` : "";
    notify(
      ctx,
      `OpenCode ${event.status} ${event.kind}.${retry}${wide}${shortHint ? bucketNote : ""}`,
      event.kind === "quota" ? "warning" : "error",
    );
  };

  pi.on("session_start", async (_event, ctx) => {
    state = loadState();
    // One short probe so the status bar can say how many distinct blocks the
    // pool really reaches; a down gateway must not delay session start.
    const gateway = await gatewayHealth(800);
    setStatus(ctx, gateway);
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

  pi.registerCommand("unlimited", {
    description: "OpenCode free tier: status [full] | test | usage | egress | apply | off | reload | watch | clear | doctor",
    getArgumentCompletions: (prefix) =>
      [
        "status",
        "status full",
        "usage",
        "egress",
        "test",
        "apply",
        "off",
        "reload",
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
          notify(ctx, option === "full" ? statusDetail(state, gateway) : statusReport(state, gateway));
          return;
        }
        case "usage":
          notify(ctx, usageReport(state));
          return;
        case "test": {
          const model = ctx.model?.id ?? "";
          notify(ctx, `testing egress — one real request per block (${model || "default model"})…`);
          const result = await gatewayTest(model);
          notify(ctx, typeof result === "string" ? result : formatTest(result));
          return;
        }
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
              `Gateway not reachable at ${GATEWAY_URL}. Start it: systemctl --user start ${GATEWAY_UNIT}`,
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
        case "reload": {
          // pi-bansos keeps its 429 cooldowns in module state, so a reload is
          // the only way to drop a stale one (e.g. recorded just before the
          // bucket refilled at 00:00 UTC). It does not touch the provider.
          const summary = bucketSummary(spentBuckets());
          const note = summary ? ` Provider ${summary}.` : "";
          notify(
            ctx,
            `Reloading to clear pi-bansos's in-memory 429 backoff.${note}`,
            summary ? "warning" : "info",
          );
          await ctx.reload();
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
            `- distinct egress blocks: ${gateway?.distinctBlocks ?? "unknown"}`,
            `- provider buckets: ${bucketSummary(spentBuckets()) ?? "none spent"}`,
            `- recorded refusals: ${state.events.length}`,
            `- agent directory writable: ${canWrite(AGENT_DIR) ? "yes" : "no"}`,
          ];
          notify(ctx, lines.join("\n"));
          return;
        }
        default:
          notify(ctx, "usage: /unlimited status [full]|test|usage|egress|apply|off|reload|watch on|off|clear|doctor", "warning");
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
