#!/usr/bin/env node
/**
 * pi-unlimited-gateway — a local, dependency-free relay that fronts pi-bansos
 * with a pool of rotating egress addresses.
 *
 * This is the pi-native equivalent of opencode-unlimited-proxy's engine
 * (ghcr.io/jasonxu114514/opencode2api) reduced to the one job that matters
 * here: take a pi-bansos relay request, forward it upstream through a chosen
 * egress, and retry on a *different* egress when the free tier refuses it.
 *
 * Why it speaks pi-bansos's relay protocol
 * ----------------------------------------
 * pi-bansos already owns the OpenCode client fingerprint (UA, project id,
 * session headers, `read`+`shell` tool payload, `<env>` prompt block) and the
 * JA4 TLS cipher order. Re-implementing that in a gateway would rot the moment
 * upstream changes a gate. Instead this process is inserted at the one seam
 * pi-bansos leaves open: its relay state file. pi-bansos POSTs to us with
 *
 *     x-relay-target: https://opencode.ai
 *     x-relay-path:   /inference/v1/chat/completions
 *
 * and we answer by proxying that request out through the selected egress,
 * reproducing only the TLS shape (cipher list + ALPN) the OpenCode edge keys
 * on. Prompt/body handling stays entirely pi-bansos's business.
 *
 * Honest limits
 * -------------
 * Egress rotation multiplies a budget that is metered *per egress block*. It
 * cannot create budget. Measured on 2026-11-15: OpenCode answered direct
 * (46.35.92.131), Cloudflare WARP (104.28.241.89) and Tor exits with the same
 * `429 FreeUsageLimitError` and the same `Retry-After` (~00:00 UTC), i.e. the
 * bucket being spent was global, not per block. The gateway records that
 * observation instead of pretending the rotation fixed it: when every egress
 * returns the same refusal, `/unlimited status` says so.
 *
 * Usage
 * -----
 *   pi-unlimited-gateway                     # serve
 *   pi-unlimited-gateway --probe             # probe every egress, print a table
 *   pi-unlimited-gateway --print-config      # show the resolved egress pool
 *
 * Configuration (env)
 * -------------------
 *   PI_UNLIMITED_HOST     bind address            (default 127.0.0.1)
 *   PI_UNLIMITED_PORT     bind port               (default 18790)
 *   PI_UNLIMITED_EGRESS   comma list, in priority order. Each entry is
 *                         `direct` or `<scheme>://<host>:<port>` where scheme
 *                         is http (CONNECT) or socks5. Default: direct.
 *   PI_UNLIMITED_STATE    state file   (default <agent-dir>/pi-unlimited-gateway.json)
 *   PI_UNLIMITED_AUTH     optional x-relay-auth secret to require
 *   PI_UNLIMITED_MAX_EYEBALLS  egresses to try per request (default 3)
 *   PI_UNLIMITED_ATTEMPT_TIMEOUT_MS  hard per-attempt deadline (default 30000)
 *                         Keep this far below the caller's own timeout: a
 *                         request still in flight when the caller aborts makes
 *                         pi-bansos 0.8.1 crash on its direct fallback.
 *   PI_UNLIMITED_DEBUG=1  log routing decisions to stderr
 */

import * as fs from "node:fs";
import * as http from "node:http";
import * as net from "node:net";
import * as os from "node:os";
import * as path from "node:path";
import * as tls from "node:tls";

// ── Upstreams we are willing to relay to ───────────────────────────────────
// An open relay would let anything on the box spend the free tier and would
// forward to arbitrary hosts; pin it to the two pi-bansos knows about.
const ALLOWED_HOSTS = new Set(["opencode.ai", "api.kilo.ai"]);

/**
 * OpenCode's edge keys its TLS ClientHello on the JA4 cipher-list hash
 * (BoringSSL/Bun order, `5b57614c22b0`). Node's default OpenSSL list is refused
 * with `429 FreeUsageLimitError` even from a clean IP, which is indistinguishable
 * from a real quota hit. Keep this list byte-identical to pi-bansos's
 * OPENCODE_CIPHER_LIST, and always send ALPN — JA4 includes it.
 */
const OPENCODE_CIPHERS = [
  "TLS_AES_128_GCM_SHA256",
  "TLS_AES_256_GCM_SHA384",
  "TLS_CHACHA20_POLY1305_SHA256",
  "ECDHE-ECDSA-AES128-GCM-SHA256",
  "ECDHE-RSA-AES128-GCM-SHA256",
  "ECDHE-ECDSA-AES256-GCM-SHA384",
  "ECDHE-RSA-AES256-GCM-SHA384",
  "ECDHE-ECDSA-CHACHA20-POLY1305",
  "ECDHE-RSA-CHACHA20-POLY1305",
  "ECDHE-ECDSA-AES128-SHA",
  "ECDHE-RSA-AES128-SHA",
  "ECDHE-ECDSA-AES256-SHA",
  "ECDHE-RSA-AES256-SHA",
  "AES128-GCM-SHA256",
  "AES256-GCM-SHA384",
  "AES128-SHA",
  "AES256-SHA",
].join(":");

const HOP_BY_HOP = new Set([
  "connection",
  "keep-alive",
  "proxy-authenticate",
  "proxy-authorization",
  "te",
  "trailer",
  "transfer-encoding",
  "upgrade",
  "host",
  "content-length",
]);

const MAX_BODY_BYTES = 64 * 1024 * 1024;
/**
 * Hard per-attempt deadline. Deliberately far below any caller timeout: a
 * client that gives up mid-request makes pi-bansos fall back to
 * `opencodeDirectFetch` with an ALREADY-ABORTED AbortSignal, and pi-bansos
 * 0.8.1 destroys the ClientRequest *before* attaching its 'error' listener
 * (`req.destroy(...); return;` above `req.on("error", reject)`), which throws
 * ERR_UNHANDLED_ERROR and kills pi. Answering fast keeps that path unreachable.
 */
const ATTEMPT_TIMEOUT_MS = Number(process.env.PI_UNLIMITED_ATTEMPT_TIMEOUT_MS) || 30_000;
const QUARANTINE_BASE_MS = 90_000;
const QUARANTINE_MAX_MS = 6 * 3600_000;
const MAX_EVENTS = 300;

const DEBUG = process.env.PI_UNLIMITED_DEBUG === "1";
const log = (...args) => {
  if (DEBUG) process.stderr.write(`[pi-unlimited] ${args.join(" ")}\n`);
};

// ── Config ────────────────────────────────────────────────────────────────

function agentDir() {
  return process.env.PI_CODING_AGENT_DIR?.trim() || path.join(os.homedir(), ".pi", "agent");
}

function parseEgress(raw) {
  const spec = String(raw).trim();
  if (!spec || spec === "direct") return { id: "direct", kind: "direct", url: "direct" };
  let u;
  try {
    u = new URL(spec);
  } catch {
    throw new Error(`invalid egress entry: ${spec}`);
  }
  if (u.protocol !== "socks5:" && u.protocol !== "http:" && u.protocol !== "https:") {
    throw new Error(`unsupported egress scheme in ${spec} (use socks5:// or http://)`);
  }
  const kind = u.protocol === "socks5:" ? "socks5" : "http";
  const port = Number(u.port) || (kind === "socks5" ? 1080 : 8080);
  return { id: spec, kind, host: u.hostname, port, url: spec };
}

function loadConfig() {
  const raw = process.env.PI_UNLIMITED_EGRESS?.trim() || "direct";
  const entries = raw
    .split(",")
    .map((s) => s.trim())
    .filter(Boolean)
    .map(parseEgress);
  // `direct` is always the final fallback: a dead proxy pool must not make the
  // provider unusable, it must merely stop helping.
  if (!entries.some((e) => e.kind === "direct")) {
    entries.push({ id: "direct", kind: "direct", url: "direct" });
  }
  return {
    host: process.env.PI_UNLIMITED_HOST?.trim() || "127.0.0.1",
    port: Number(process.env.PI_UNLIMITED_PORT) || 18790,
    stateFile:
      process.env.PI_UNLIMITED_STATE?.trim() ||
      path.join(agentDir(), "pi-unlimited-gateway.json"),
    auth: process.env.PI_UNLIMITED_AUTH?.trim() || "",
    maxEyeballs: Math.max(1, Math.min(5, Number(process.env.PI_UNLIMITED_MAX_EYEBALLS) || 3)),
    egress: entries,
  };
}

// ── State ─────────────────────────────────────────────────────────────────

function freshState(config) {
  return {
    version: 1,
    startedAt: Date.now(),
    pid: process.pid,
    bind: `${config.host}:${config.port}`,
    egress: Object.fromEntries(
      config.egress.map((e) => [
        e.id,
        { requests: 0, failures: 0, lastOkAt: 0, lastError: "", quarantineUntil: 0, lastLatencyMs: 0 },
      ]),
    ),
    requests: { total: 0, byDay: {} },
    /**
     * The provider's own view of the free budget, as last reported. pi-bansos
     * deliberately discards OpenCode Retry-After hints longer than 300s and
     * substitutes its own 90s→15min reactive backoff, so this is the only
     * place the real "spent until" is still visible.
     */
    bucket: { spentUntil: 0, retryAfterSeconds: 0, at: 0, egress: "" },
    events: [],
  };
}

function loadState(config) {
  const base = freshState(config);
  try {
    const raw = JSON.parse(fs.readFileSync(config.stateFile, "utf8"));
    return {
      ...base,
      ...raw,
      // Runtime identity always belongs to this process, never to the file:
      // uptime and pid must not be inherited from a previous gateway.
      startedAt: base.startedAt,
      pid: base.pid,
      bind: base.bind,
      // Keep egress records for every configured entry, even new ones, and drop
      // records for entries that are no longer configured.
      egress: Object.fromEntries(
        config.egress.map((e) => [e.id, { ...base.egress[e.id], ...(raw.egress?.[e.id] ?? {}) }]),
      ),
      requests: {
        total: Number(raw.requests?.total) || 0,
        byDay: raw.requests?.byDay ?? {},
      },
      events: Array.isArray(raw.events) ? raw.events.slice(-MAX_EVENTS) : [],
    };
  } catch {
    return base;
  }
}

function saveState(config, state) {
  const tmp = `${config.stateFile}.${process.pid}.tmp`;
  try {
    fs.mkdirSync(path.dirname(config.stateFile), { recursive: true });
    fs.writeFileSync(tmp, JSON.stringify({ ...state, savedAt: Date.now() }));
    fs.renameSync(tmp, config.stateFile);
  } catch (error) {
    try {
      fs.rmSync(tmp, { force: true });
    } catch {
      /* the gateway must never take the provider down over bookkeeping */
    }
    log(`state write failed: ${error}`);
  }
}

function utcDay(now = Date.now()) {
  return new Date(now).toISOString().slice(0, 10);
}

// ── Egress health ─────────────────────────────────────────────────────────

function healthy(config, state, id) {
  const record = state.egress[id];
  if (!record) return true;
  return !record.quarantineUntil || record.quarantineUntil <= Date.now();
}

/** Direct first if healthy, then configured order; quarantined entries last. */
function egressOrder(config, state) {
  const ready = config.egress.filter((e) => healthy(config, state, e.id));
  const parked = config.egress.filter((e) => !healthy(config, state, e.id));
  const direct = ready.filter((e) => e.kind === "direct");
  const rest = ready.filter((e) => e.kind !== "direct");
  // Prefer a real exit while it is healthy — that is the whole point of the
  // pool — but never let `direct` disappear from the tail.
  return [...rest, ...direct, ...parked];
}

function noteSuccess(state, id, latencyMs) {
  const record = state.egress[id];
  if (!record) return;
  record.requests += 1;
  record.failures = 0;
  record.quarantineUntil = 0;
  record.lastError = "";
  record.lastOkAt = Date.now();
  record.lastLatencyMs = latencyMs;
}

function noteRefusal(state, id, status, detail) {
  const record = state.egress[id];
  if (!record) return;
  record.requests += 1;
  record.failures += 1;
  record.lastError = `${status} ${detail}`.trim().slice(0, 200);
  // Exponential backoff per consecutive refusal, same shape pi-bansos uses for
  // its own relays: 429/403 mean "this exit has no budget / is flagged".
  const base = status === 429 || status === 403 ? QUARANTINE_BASE_MS : 30_000;
  const wait = Math.min(base * 2 ** (record.failures - 1), QUARANTINE_MAX_MS);
  record.quarantineUntil = Date.now() + wait;
}

function noteTransportFailure(state, id, error) {
  const record = state.egress[id];
  if (!record) return;
  record.requests += 1;
  record.failures += 1;
  record.lastError = `transport: ${String(error).slice(0, 180)}`;
  const wait = Math.min(30_000 * 2 ** (record.failures - 1), 15 * 60_000);
  record.quarantineUntil = Date.now() + wait;
}

/** Parse a Retry-After header (seconds or HTTP date) into seconds. */
function retryAfterSeconds(value) {
  if (value == null) return undefined;
  const raw = String(value).trim();
  if (/^\d+$/.test(raw)) return Number(raw);
  const at = Date.parse(raw);
  if (Number.isNaN(at)) return undefined;
  return Math.max(0, Math.ceil((at - Date.now()) / 1000));
}

/**
 * Distinguish the two unrelated axes an upstream refusal can be:
 *  - quota:   the free budget (per block, per model, or global) is spent
 *  - egress:  this exit's IP is flagged ("abusive traffic"); another exit may help
 *  - shape:   the fingerprint was rejected; no egress will help
 * The distinction decides whether rotating is worth another request.
 */
function classifyRefusal(bodyText) {
  const text = String(bodyText || "").toLowerCase();
  if (/abusive traffic|from this ip address|ip address/.test(text)) return "egress";
  if (/freetiererror|can only be used from within opencode|fingerprint/.test(text)) return "shape";
  if (/freeusalimit|free usage limit|rate limit|quota/.test(text)) return "quota";
  return "other";
}

function noteEvent(state, event) {
  state.events.push(event);
  if (state.events.length > MAX_EVENTS) state.events = state.events.slice(-MAX_EVENTS);
  // A long quota hint is the provider telling us when the bucket refills
  // (OpenCode points at 00:00 UTC). Keep the latest one so the operator sees
  // the real wait instead of pi-bansos's capped local backoff.
  if (event.kind === "quota" && (event.retryAfterSeconds ?? 0) > 300) {
    state.bucket = {
      spentUntil: event.at + event.retryAfterSeconds * 1000,
      retryAfterSeconds: event.retryAfterSeconds,
      at: event.at,
      egress: event.egress,
    };
  }
}

// ── Transports ────────────────────────────────────────────────────────────

function tcpConnect(host, port, timeoutMs = 15_000, signal) {
  // The connect must finish before tls.connect wraps it. Wrapping a socket that
  // is still connecting and then handing it to http.request segfaults Node
  // (reproduced on v24.19.0), so this is deliberately two steps.
  return new Promise((resolve, reject) => {
    const socket = net.connect({ port, host });
    linkAbort(socket, signal);
    socket.setTimeout(timeoutMs, () => {
      socket.destroy();
      reject(new Error(`tcp timeout ${host}:${port}`));
    });
    socket.once("connect", () => {
      socket.setTimeout(0);
      socket.removeListener("error", reject);
      resolve(socket);
    });
    socket.once("error", reject);
  });
}

/**
 * Destroy a socket when the caller goes away, so a cancelled turn stops
 * consuming an egress instead of running to its own deadline.
 */
function linkAbort(socket, signal) {
  if (!signal) return;
  if (signal.aborted) {
    socket.destroy();
    return;
  }
  const onAbort = () => socket.destroy(new Error("aborted by client"));
  signal.addEventListener("abort", onAbort, { once: true });
  socket.once("close", () => signal.removeEventListener("abort", onAbort));
}

function httpConnect(egress, host, port, timeoutMs = 15_000, signal) {
  return new Promise((resolve, reject) => {
    const socket = net.connect({ port: egress.port, host: egress.host });
    linkAbort(socket, signal);
    let buffer = "";
    socket.setTimeout(timeoutMs, () => {
      socket.destroy();
      reject(new Error(`CONNECT timeout via ${egress.id}`));
    });
    socket.once("error", reject);
    socket.once("connect", () => {
      socket.write(`CONNECT ${host}:${port} HTTP/1.1\r\nHost: ${host}:${port}\r\n\r\n`);
    });
    const onData = (chunk) => {
      buffer += chunk.toString("latin1");
      const end = buffer.indexOf("\r\n\r\n");
      if (end === -1) return;
      socket.removeListener("data", onData);
      const line = buffer.split("\r\n")[0];
      const code = Number((/^HTTP\/1\.[01] (\d{3})/.exec(line) || [])[1] || 0);
      if (code !== 200) {
        socket.destroy();
        reject(new Error(`CONNECT ${code} via ${egress.id}: ${line}`));
        return;
      }
      const rest = Buffer.from(buffer.slice(end + 4), "latin1");
      socket.setTimeout(0);
      if (rest.length) socket.unshift(rest);
      resolve(socket);
    };
    socket.on("data", onData);
  });
}

function socks5Connect(egress, host, port, timeoutMs = 15_000, signal) {
  return new Promise((resolve, reject) => {
    const socket = net.connect({ port: egress.port, host: egress.host });
    linkAbort(socket, signal);
    let buffer = Buffer.alloc(0);
    let stage = "greeting";
    socket.setTimeout(timeoutMs, () => {
      socket.destroy();
      reject(new Error(`SOCKS timeout via ${egress.id}`));
    });
    socket.once("error", reject);
    socket.once("connect", () => socket.write(Buffer.from([5, 1, 0])));
    const onData = (chunk) => {
      buffer = Buffer.concat([buffer, chunk]);
      if (stage === "greeting") {
        if (buffer.length < 2) return;
        if (buffer[1] !== 0) {
          socket.destroy();
          reject(new Error(`SOCKS no-auth rejected via ${egress.id}`));
          return;
        }
        stage = "reply";
        buffer = Buffer.alloc(0);
        const hostBytes = Buffer.from(host, "utf8");
        const request = Buffer.alloc(7 + hostBytes.length);
        request[0] = 5; // version
        request[1] = 1; // CONNECT
        request[2] = 0; // reserved
        request[3] = 3; // domain-name address type
        request[4] = hostBytes.length;
        hostBytes.copy(request, 5);
        request.writeUInt16BE(port, 5 + hostBytes.length);
        socket.write(request);
        return;
      }
      if (buffer.length < 5) return;
      if (buffer[1] !== 0) {
        socket.destroy();
        reject(new Error(`SOCKS reply ${buffer[1]} via ${egress.id}`));
        return;
      }
      const atyp = buffer[3];
      const length =
        atyp === 1 ? 10 : atyp === 4 ? 22 : atyp === 3 ? 5 + buffer[4] + 2 : -1;
      if (length < 0) {
        socket.destroy();
        reject(new Error(`SOCKS bad address type ${atyp} via ${egress.id}`));
        return;
      }
      if (buffer.length < length) return;
      socket.removeListener("data", onData);
      const rest = buffer.slice(length);
      socket.setTimeout(0);
      if (rest.length) socket.unshift(rest);
      resolve(socket);
    };
    socket.on("data", onData);
  });
}

async function tunnel(egress, host, port, timeoutMs, signal) {
  const socket =
    egress.kind === "direct"
      ? await tcpConnect(host, port, timeoutMs, signal)
      : egress.kind === "socks5"
        ? await socks5Connect(egress, host, port, timeoutMs, signal)
        : await httpConnect(egress, host, port, timeoutMs, signal);
  // A persistent listener: an unhandled 'error' on a socket this process owns
  // would take the gateway down, and the gateway must never be the reason a
  // provider request fails.
  socket.on("error", (error) => log(`${egress.id} tunnel error: ${error}`));
  return socket;
}

/**
 * One upstream request through one egress. Returns either
 *   { status, headers, stream }   for a response we should pass through, or
 *   { status, headers, bodyText } for a refusal we consumed to classify.
 */
async function forward(config, egress, target, { signal, timeoutMs = ATTEMPT_TIMEOUT_MS } = {}) {
  const started = Date.now();
  // Check before creating anything: an already-aborted turn must not open a
  // socket, and Node throws on a destroyed request with no 'error' listener.
  if (signal?.aborted) throw new Error("client aborted before request");
  const raw = await tunnel(egress, target.hostname, Number(target.port) || 443, timeoutMs, signal);
  const isSecure = target.protocol === "https:";
  const socket = isSecure
    ? await new Promise((resolve, reject) => {
        // ALPN is part of JA4; https.request sends it, a bare tls.connect does not.
        const secure = tls.connect(
          {
            socket: raw,
            servername: target.hostname,
            ciphers: OPENCODE_CIPHERS,
            ALPNProtocols: ["http/1.1"],
          },
          () => {
            secure.removeListener("error", reject);
            resolve(secure);
          },
        );
        secure.setTimeout(timeoutMs, () => secure.destroy(new Error("tls handshake timeout")));
        secure.once("error", reject);
      })
    : raw;

  const body = target.body;
  const headers = { ...target.headers };
  headers.host = target.hostname;
  if (body) headers["content-length"] = String(body.length);
  headers.connection = "close";

  return await new Promise((resolve, reject) => {
    const request = http.request(
      {
        method: target.method,
        path: target.path,
        host: target.hostname,
        headers,
        createConnection: () => socket,
      },
      (response) => {
        const status = response.statusCode ?? 502;
        const responseHeaders = {};
        for (const [key, value] of Object.entries(response.headers)) {
          if (value == null) continue;
          if (key === "transfer-encoding" || key === "connection") continue;
          responseHeaders[key] = Array.isArray(value) ? value.join(", ") : value;
        }
        const latency = Date.now() - started;
        if (status === 429 || status === 403) {
          // Refusals are small JSON bodies and we must read them to tell a
          // spent block from a flagged IP.
          const chunks = [];
          response.on("data", (chunk) => chunks.push(chunk));
          response.on("end", () =>
            resolve({
              status,
              headers: responseHeaders,
              bodyText: Buffer.concat(chunks).toString("utf8"),
              latency,
            }),
          );
          response.on("error", reject);
          return;
        }
        resolve({ status, headers: responseHeaders, stream: response, latency });
      },
    );
    request.setTimeout(timeoutMs, () => request.destroy(new Error("upstream timeout")));
    request.on("error", reject);
    // The listener above must exist before any destroy() below, otherwise Node
    // re-raises the error as an uncaught exception.
    if (signal) {
      const onAbort = () => request.destroy(new Error("client aborted"));
      signal.addEventListener("abort", onAbort, { once: true });
      request.on("close", () => signal.removeEventListener("abort", onAbort));
    }
    if (body) request.write(body);
    request.end();
  });
}

// ── Relay handler ─────────────────────────────────────────────────────────

function readBody(request) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let size = 0;
    request.on("data", (chunk) => {
      size += chunk.length;
      if (size > MAX_BODY_BYTES) {
        reject(new Error(`request body exceeds ${MAX_BODY_BYTES} bytes`));
        request.destroy();
        return;
      }
      chunks.push(chunk);
    });
    request.on("end", () => resolve(Buffer.concat(chunks)));
    request.on("error", reject);
  });
}

function sanitize(headers) {
  const out = {};
  for (const [key, value] of Object.entries(headers)) {
    const lower = key.toLowerCase();
    if (HOP_BY_HOP.has(lower)) continue;
    if (lower.startsWith("x-relay-")) continue;
    out[lower] = value;
  }
  return out;
}

function reply(res, status, payload, extraHeaders = {}) {
  const body = JSON.stringify(payload);
  res.writeHead(status, {
    "content-type": "application/json",
    "cache-control": "no-cache",
    ...extraHeaders,
  });
  res.end(body);
}

async function handleRelay(config, state, request, res) {
  const rawTarget = request.headers["x-relay-target"];
  const relayPath = request.headers["x-relay-path"];
  if (!rawTarget || !relayPath) {
    reply(res, 400, {
      error: { type: "relay_misconfigured", message: "missing x-relay-target / x-relay-path" },
    });
    return;
  }
  if (config.auth && request.headers["x-relay-auth"] !== config.auth) {
    reply(res, 401, { error: { type: "relay_unauthorized", message: "bad x-relay-auth" } });
    return;
  }

  let target;
  try {
    target = new URL(String(rawTarget));
  } catch {
    reply(res, 400, { error: { type: "relay_misconfigured", message: `bad x-relay-target` } });
    return;
  }
  if (!ALLOWED_HOSTS.has(target.hostname)) {
    reply(res, 403, {
      error: { type: "relay_forbidden", message: `host not allowed: ${target.hostname}` },
    });
    return;
  }

  let body;
  try {
    body = await readBody(request);
  } catch (error) {
    reply(res, 413, { error: { type: "relay_body", message: String(error) } });
    return;
  }

  const upstream = {
    method: request.method || "POST",
    hostname: target.hostname,
    port: target.port || (target.protocol === "https:" ? 443 : 80),
    protocol: target.protocol,
    path: String(relayPath),
    headers: sanitize(request.headers),
    body,
  };

  state.requests.total += 1;
  const day = utcDay();
  state.requests.byDay[day] = (state.requests.byDay[day] ?? 0) + 1;

  const order = egressOrder(config, state);
  const attempts = order.slice(0, config.maxEyeballs);
  const tried = [];
  let last = null;

  // Cancelling the turn must cancel the work: otherwise the gateway keeps an
  // egress busy until its deadline, and pi-bansos is left holding a request
  // past the caller's abort.
  const controller = new AbortController();
  let finished = false;
  res.on("close", () => {
    if (!finished) controller.abort();
  });
  const deadline = Date.now() + ATTEMPT_TIMEOUT_MS * attempts.length;

  for (const egress of attempts) {
    if (controller.signal.aborted) break;
    const remaining = deadline - Date.now();
    if (remaining <= 0) break;
    try {
      const result = await forward(config, egress, upstream, {
        signal: controller.signal,
        timeoutMs: Math.min(ATTEMPT_TIMEOUT_MS, remaining),
      });
      if (result.stream) {
        finished = true;
        noteSuccess(state, egress.id, result.latency);
        saveState(config, state);
        res.writeHead(result.status, result.headers);
        result.stream.pipe(res);
        result.stream.on("error", () => res.destroy());
        res.on("close", () => result.stream.destroy());
        log(`${egress.id} ${result.status} ${upstream.path} ${result.latency}ms`);
        return;
      }

      const kind = classifyRefusal(result.bodyText);
      noteRefusal(state, egress.id, result.status, kind);
      noteEvent(state, {
        at: Date.now(),
        egress: egress.id,
        host: upstream.hostname,
        status: result.status,
        kind,
        retryAfterSeconds: retryAfterSeconds(result.headers["retry-after"]),
      });
      tried.push({ id: egress.id, status: result.status, kind });
      last = result;
      log(`${egress.id} ${result.status} ${kind} — rotating`);

      // A fingerprint rejection is identical on every egress; rotating only
      // burns requests. Surface it immediately.
      if (kind === "shape") break;
    } catch (error) {
      noteTransportFailure(state, egress.id, error);
      tried.push({ id: egress.id, status: 0, kind: "transport" });
      last = { status: 502, headers: {}, bodyText: JSON.stringify({ error: { message: String(error) } }) };
      log(`${egress.id} transport failure: ${error}`);
    }
  }

  saveState(config, state);

  // The caller hung up and we are out of budget/attempts. Writing to a closed
  // response is pointless and, worse, this is the exact moment pi-bansos is
  // about to fall back to direct with an aborted signal.
  if (controller.signal.aborted) {
    if (!res.writableEnded) res.destroy();
    return;
  }

  if (!last) {
    reply(res, 502, { error: { type: "relay_no_egress", message: "no egress available" } });
    return;
  }

  // Report whether the refusal was pool-wide. This is the signal that tells an
  // operator "rotation cannot help, wait for the reset" instead of inviting
  // another lap around the pool.
  const kinds = new Set(tried.map((t) => t.kind));
  const poolWide = tried.length > 1 && kinds.size === 1 && (kinds.has("quota") || kinds.has("shape"));
  const headers = { ...last.headers };
  reply(res, last.status, {
    error: {
      type: "relay_upstream_refusal",
      message: "upstream refused every egress",
      status: last.status,
      kind: tried.at(-1)?.kind ?? "other",
      poolWide,
      tried,
      upstreamBody: String(last.bodyText ?? "").slice(0, 2000),
    },
  }, headers["retry-after"] ? { "retry-after": headers["retry-after"] } : {});
}

// ── Server ────────────────────────────────────────────────────────────────

function startServer(config, state) {
  const server = http.createServer((request, res) => {
    if (request.url === "/__unlimited/health") {
      reply(res, 200, {
        ok: true,
        bind: `${config.host}:${config.port}`,
        uptimeSeconds: Math.round((Date.now() - state.startedAt) / 1000),
        egress: config.egress.map((e) => ({
          id: e.id,
          healthy: healthy(config, state, e.id),
          ...state.egress[e.id],
        })),
        requests: state.requests,
        bucket: state.bucket?.spentUntil > Date.now() ? state.bucket : null,
      });
      return;
    }
    handleRelay(config, state, request, res).catch((error) => {
      log(`relay error: ${error?.stack ?? error}`);
      if (!res.headersSent) {
        reply(res, 502, { error: { type: "relay_failure", message: String(error) } });
      } else {
        res.destroy();
      }
    });
  });

  server.on("clientError", (_error, socket) => {
    if (socket.writable) socket.end("HTTP/1.1 400 Bad Request\r\n\r\n");
  });

  server.listen(config.port, config.host, () => {
    process.stderr.write(
      `[pi-unlimited] gateway listening on http://${config.host}:${config.port} ` +
        `(egress: ${config.egress.map((e) => e.id).join(" → ")})\n`,
    );
    saveState(config, state);
  });

  const shutdown = () => {
    saveState(config, state);
    server.close(() => process.exit(0));
    setTimeout(() => process.exit(0), 2000).unref();
  };
  process.on("SIGTERM", shutdown);
  process.on("SIGINT", shutdown);
  process.on("unhandledRejection", (error) => log(`unhandled: ${error}`));
  return server;
}

// ── Probe mode ────────────────────────────────────────────────────────────

async function probe(config) {
  const target = {
    method: "GET",
    hostname: "opencode.ai",
    port: 443,
    protocol: "https:",
    path: "/zen/v1/models",
    headers: { "user-agent": "pi-unlimited-probe", accept: "application/json" },
    body: null,
  };
  const rows = [];
  for (const egress of config.egress) {
    const started = Date.now();
    try {
      const result = await forward(config, egress, target);
      if (result.stream) {
        let bytes = 0;
        await new Promise((resolve) => {
          result.stream.on("data", (chunk) => (bytes += chunk.length));
          result.stream.on("end", resolve);
          result.stream.on("error", resolve);
        });
        rows.push({ egress: egress.id, status: result.status, ms: Date.now() - started, note: `${bytes}B` });
      } else {
        rows.push({
          egress: egress.id,
          status: result.status,
          ms: Date.now() - started,
          note: classifyRefusal(result.bodyText),
        });
      }
    } catch (error) {
      rows.push({ egress: egress.id, status: 0, ms: Date.now() - started, note: String(error) });
    }
  }
  const width = Math.max(...rows.map((r) => r.egress.length), 6);
  process.stdout.write(`${"egress".padEnd(width)}  status  ms     note\n`);
  for (const row of rows) {
    process.stdout.write(
      `${row.egress.padEnd(width)}  ${String(row.status).padEnd(6)}  ${String(row.ms).padEnd(5)}  ${row.note}\n`,
    );
  }
  return rows;
}

// ── Entry ─────────────────────────────────────────────────────────────────

const config = loadConfig();

if (process.argv.includes("--print-config")) {
  process.stdout.write(JSON.stringify({ ...config, auth: config.auth ? "<set>" : "" }, null, 2) + "\n");
} else if (process.argv.includes("--probe")) {
  await probe(config);
} else {
  startServer(config, loadState(config));
}
