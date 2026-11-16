# pi-unlimited

A rotating-egress gateway for pi's `bansos` provider
([pi-bansos](https://www.npmjs.com/package/pi-bansos)), plus an honest ledger of
what OpenCode's free tier actually did.

It is the [opencode-unlimited-proxy](https://github.com/ebouther/opencode-unlimited-proxy)
idea rebuilt for pi without Docker: Cloudflare WARP runs as **userspace** WireGuard
(`wireproxy` — no TUN, no `CAP_NET_ADMIN`, no root), one tunnel per identity,
each exposing its own SOCKS5 port, and a small Node relay in front of pi-bansos
rotates egress across those blocks and `direct` on every `429`/`403`.

```
pi (provider "bansos")
  └─ pi-bansos local proxy
       └─ relay ──► pi-unlimited-gateway :18790
                      ├─ egress pool: WARP :25344, :25345, :25346 → direct
                      ├─ de-duplicates exits that share one public address
                      ├─ rotates on 429/403, quarantine + backoff
                      └─ TLS shape (JA4 cipher list + ALPN)
```

pi-bansos keeps building the request — UA, project/session headers, the exact
`read`+`shell` tools, the `<env>` prompt block. Re-implementing that fingerprint
in a gateway would rot the moment upstream moves a gate, so the gateway is
inserted only at the seam pi-bansos leaves open: its relay protocol
(`x-relay-target` / `x-relay-path`). It reproduces only the TLS shape the
OpenCode edge keys on (cipher-list order + ALPN).

## Components

| Piece | Where |
|---|---|
| Gateway (relay + egress pool) | `assets/aiAgent/gateway/pi-unlimited-gateway.mjs` |
| Extension (ledger, wiring, failover model) | `assets/aiAgent/extensions/pi-unlimited/index.ts` |
| WARP + gateway systemd user services | `home/modules/pi-unlimited.nix` |

## Commands

| Command | What it does |
|---|---|
| `/unlimited` | One line: `wrapped`/`direct`, distinct blocks, and either `DAILY LIMIT <wait>` or `backoff <wait>` or `ok` |
| `/unlimited status full` | The long form: per-egress buckets, last refusal, today's counts |
| `/unlimited test` | Fires **one real request per distinct block** and reports, live, which blocks still have budget and when the spent ones reset |
| `/unlimited usage` | Today's refusals grouped by status/kind/model |
| `/unlimited egress` | Per-egress health from the gateway: ready / parked, latency, errors |
| `/unlimited apply` | Point pi-bansos at the gateway, then reload |
| `/unlimited off` | Remove the gateway relay, then reload |
| `/unlimited reload` | Reload to drop pi-bansos's in-memory 429 backoff |
| `/unlimited watch on\|off` | Notifications only (recording is always on) |
| `/unlimited clear` | Clear local history only |
| `/unlimited doctor` | Wiring checks |

## `/unlimited test` — what "how much is left" can honestly mean

The free tier publishes **no remaining-usage counter**. There is no number to
read, no API that returns "you have N messages left". So the only truthful
answer is a yes/no per block plus the reset clock, and that is exactly what the
test reports:

```
egress test · deepseek-v4.1-flash-free · 2 request(s) in 3s
  25344   104.28.201.80    SPENT · resets 00:00Z in 16h 45m
  direct  89.189.83.90     SPENT · resets 00:00Z in 16h 45m
0/2 block(s) have budget · remaining usage not published by upstream
```

```
egress test · deepseek-v4.1-flash-free · 2 request(s) in 3s
  25344   104.28.201.80    ok  2s
  direct  89.189.83.90     SPENT · resets 00:00Z in 16h 43m
1/2 block(s) have budget · remaining usage not published by upstream
```

Both lines above are real output from 2026-11-16. `ok` means the block answered
a real completion, so it had budget **at that moment**; `SPENT` carries the
provider's own `Retry-After`, which is the reset time `/unlimited status` quotes
as `DAILY LIMIT`.

Two things to know before running it:

- **It spends budget.** One real completion per distinct block. On a nearly
  exhausted block, the test itself can be the request that hits the limit — the
  first `ok` above became `SPENT` on the very next run for that reason.
- **It costs a turn's worth of latency**, up to ~2s per block, capped at 2
  minutes total. It is sequential and de-duplicated by exit address, so a
  duplicate tunnel is never charged twice.

If the fingerprint ever drifts, the test degrades to `gate · fingerprint
rejected — cannot judge quota` instead of falsely reporting a spent block. That
is the whole reason the probe carries the client shape: OpenCode answers a
mis-shaped request with the *same* `429` as a real quota refusal, and reporting
that as "spent" would be a lie.

## Multiple tunnels, and why they are de-duplicated

WARP draws exits from a shared pool, so extra identities are worth it but not
linear. Measured 2026-11-16:

| Identity | SOCKS5 | Exit address |
|---|---|---|
| 0 | `:25344` | `104.28.201.80` |
| 1 | `:25345` | `104.28.241.89` |
| 2 | `:25346` | `104.28.241.89` ← duplicate block |

Three tunnels, two distinct blocks. So the gateway probes `api.ipify.org` through
each egress every 10 minutes, records the public address, and collapses tunnels
that share one *before* spending a request on them. `/unlimited egress` shows
the addresses, and the health endpoint reports `distinctBlocks`.

The practical upside is real: with identity 0 spent, identity 1 answered `200`
and completed a pi turn. The upside is bounded by how many distinct addresses
WARP will hand you.

`wgcf register` is rate-limited by Cloudflare (`429 Too Many Requests` after a
handful of rapid calls), so the units register lazily, retry every 2 minutes,
and stop after 10 attempts in an hour. A tunnel that is not up yet is simply
quarantined; `direct` keeps serving in the meantime. If a unit gave up:

```bash
systemctl --user reset-failed pi-unlimited-warp-1
systemctl --user start pi-unlimited-warp-1
```

## Verified behaviour (2026-11-15)

Live, on this machine, through `pi -p`:

| Route | Result |
|---|---|
| `direct` (`46.35.92.131`) | `429 FreeUsageLimitError` |
| WARP (`104.28.241.89`) | `200`, 10247 ms, answer returned |

The gateway sent the request out via WARP, got `200`, and pi printed the answer
— while `direct` was in cooldown for a `429`. Rotation is not cosmetic.

It is also not magic. In an earlier run the *same* two egresses both returned
`429` with an identical `Retry-After` (~00:00 UTC), and so did two different
free models: the spent bucket was global, not per-IP and not per-model. When
that happens the gateway reports `poolWide: true` and `/unlimited` says so
instead of inviting another lap around the pool.

## Why every attempt has a hard deadline

pi-bansos 0.8.1 has a latent crash that a slow relay can reach. In
`opencodeDirectFetch`:

```ts
if (opts.signal?.aborted) {
  req.destroy(opts.signal.reason ?? new Error("Aborted"));
  return;                     // ← before req.on("error", reject) below
}
req.on("error", reject);
```

When the caller's `AbortSignal.timeout(...)` has already fired and every relay
failed, `relayFetch` falls back to that function. It destroys the
`ClientRequest` while it still has **no `error` listener**, Node re-raises the
`DOMException [TimeoutError]` as an uncaught exception, and pi exits with
`ERR_UNHANDLED_ERROR … at destroyRequestOnSocketNT`.

Any relay can trigger this; the local gateway did because it could hold a
request past the caller's timeout (WARP stalls, and the old upstream timeout was
600 s). Two defences here:

1. `PI_UNLIMITED_ATTEMPT_TIMEOUT_MS` bounds each attempt (30 s default) and the
   total budget is `attempts × that`, far under pi's 300 s provider timeout.
2. A client disconnect aborts the in-flight egress immediately instead of
   running to its deadline.

The underlying bug is upstream and worth reporting: the `aborted` branch must
attach the error handler before `req.destroy()`.

## The "retry in 8m / 15m" trap

When a free model is spent, pi-bansos records its own reactive backoff, not the
provider's wait. In `extensions/upstream-health.ts`:

```ts
const QUOTA_BASE_MS = 90_000;
const QUOTA_CAP_MS = 15 * 60_000;
```

and in `extensions/index.ts` any OpenCode `Retry-After` longer than 300s is
discarded:

```ts
const hint = upstream === "opencode" && parsed != null && parsed > 300 ? null : parsed;
```

So a bucket that actually refills at midnight UTC surfaces as
`Retry in 8m 22s`, then `14m 59s` (the cap) on each manual retry. That number is
pi-bansos's own ladder — 90s → 180s → 360s → 720s → 900s — and it short-circuits
**before** the relay, so the gateway never gets a chance to rotate while it is
active.

What follows from that:

- The gateway records the provider's real hint (`bucket.spentUntil`, typically
  `00:00Z`), and `/unlimited status` prints it, labelled separately from the
  15-minute local backoff.
- `/unlimited reload` is the only way to drop the in-memory backoff without
  switching models, because it lives in pi-bansos module state.
- Rotating egress cannot lift the cooldown while it is active — pi-bansos does
  not call out at all. `/unlimited reload` first, then the gateway retries.

## Honest limits

- **No budget is created.** Egress rotation multiplies a budget that is metered
  per egress block. If upstream meters globally, rotation does nothing.
- **WARP IPv4 is one shared NAT pool.** Other users exhaust it routinely; an
  exit that answers today may refuse tomorrow. IPv6 with a routed `/64` would
  give each exit its own block — this host has no routed `/64`.
- **Tor does not work here.** Measured: every Tor exit returned `429`. Rolling
  through a dozen exhausted exits costs requests and buys nothing.
- **The reset is wall-clock.** `00:00 UTC`, every day. No local state changes it.
- **Fingerprint gate is pi-bansos's job.** If it fires (`403 FreeTierError`), the
  gateway surfaces it immediately instead of rotating — it is identical on every
  egress.
- **Terms of service.** Routing around per-network limits may breach OpenCode's
  terms and Cloudflare's WARP terms. That decision is yours.

## Nix

`home/modules/pi-unlimited.nix` declares both services and seeds pi-bansos's
relay state on activation (only when no relay is configured yet, so a
hand-picked relay is never clobbered):

```nix
systemd.user.services."pi-unlimited-warp-0".Service.ExecStart =
  "${lib.getExe pkgs.wireproxy} -c %h/.local/state/pi-unlimited/warp/0/wgcf-profile.conf";

systemd.user.services.pi-unlimited-gateway.Service = {
  ExecStart = "${lib.getExe pkgs.nodejs} ${../../assets/aiAgent/gateway/pi-unlimited-gateway.mjs}";
  Environment = [
    "PI_UNLIMITED_EGRESS=socks5://127.0.0.1:25344,socks5://127.0.0.1:25345,socks5://127.0.0.1:25346,direct"
    "PI_UNLIMITED_MAX_EYEBALLS=4"
  ];
};
```

Each WARP identity is minted per machine on first start into
`~/.local/state/pi-unlimited/warp/<n>/wgcf-account.toml` (mode 600) — a device
private key, so it lives in `$HOME`, never in the Nix store. Identity 0 adopts
an existing `~/.config/warp` profile instead of re-registering.

```bash
systemctl --user status 'pi-unlimited-warp-*' pi-unlimited-gateway
node assets/aiAgent/gateway/pi-unlimited-gateway.mjs --probe
curl -s http://127.0.0.1:18790/__unlimited/health | jq
```

## Gateway configuration

| Env | Default | Meaning |
|---|---|---|
| `PI_UNLIMITED_HOST` | `127.0.0.1` | bind address |
| `PI_UNLIMITED_PORT` | `18790` | bind port |
| `PI_UNLIMITED_EGRESS` | `direct` | comma list, priority order: `direct`, `socks5://h:p`, `http://h:p` |
| `PI_UNLIMITED_MAX_EYEBALLS` | `3` | egresses to try per request |
| `PI_UNLIMITED_STATE` | `<agent-dir>/pi-unlimited-gateway.json` | ledger |
| `PI_UNLIMITED_AUTH` | unset | optional `x-relay-auth` secret |
| `PI_UNLIMITED_ATTEMPT_TIMEOUT_MS` | `30000` | hard per-attempt deadline; keep far below the caller timeout |
| `PI_UNLIMITED_DEBUG` | unset | `1` logs routing decisions |

Only `opencode.ai` and `api.kilo.ai` are relayable, so the listener is never an
open proxy.

## CLI

```bash
pi-unlimited-gateway                 # serve
pi-unlimited-gateway --probe         # probe every egress, print a table
pi-unlimited-gateway --print-config  # resolved pool
```
