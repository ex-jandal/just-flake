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
       └─ relay ──► pi-unlimited-gateway :18790  (vpn) / :18791 (novpn)
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
| `/unlimited` | One line: session class, `wrapped`/`direct`, distinct blocks, and the address that answered last |
| `/unlimited proxies` | **One row per exit address** across both gateways: state, ok/refused counts, which gateway reaches it, which one is in use |
| `/unlimited rotate [n]` | Mint a fresh WARP identity on unit `n` (default: a spent one), wait for it, re-probe both gateways |
| `/unlimited status full` | The long form: per-egress buckets, last refusal, today's counts, plus the proxy table |
| `/unlimited test` | Fires **one real request per distinct block** and reports, live, which blocks still have budget and when the spent ones reset |
| `/unlimited usage` | Today's refusals grouped by status/kind/model |
| `/unlimited egress` | Per-egress health from the gateway: ready / parked, latency, errors |
| `/unlimited apply` | Point pi-bansos at the gateway, then reload |
| `/unlimited off` | Remove the gateway relay, then reload |
| `/unlimited reload` | Reload to drop pi-bansos's in-memory 429 backoff |
| `/unlimited watch on\|off` | Notifications only (recording is always on) |
| `/unlimited clear` | Clear local history only |
| `/unlimited doctor` | Wiring checks |

## Two gateways, because an egress belongs to a process

An address is a property of the process, not of pi. `novpn` works by marking
packets per cgroup in nftables, so anything running inside `novpn.slice` leaves
through the physical interface while everything else leaves through the Proton
tunnel. A systemd service cannot join you in that slice, which is why a single
gateway in `app.slice` relayed *all* model traffic through the VPN even from a
`novpn` shell — the extension was printing the VPN address because that really
was the address on the wire.

So there are two, same code, different slice:

| Service | Port | Slice | `direct` exit (measured) |
|---|---|---|---|
| `pi-unlimited-gateway` | `:18790` | `app.slice` | `149.22.84.140` (Proton VPN) |
| `pi-unlimited-gateway-novpn` | `:18791` | `novpn.slice` | `89.189.83.90` (ISP) |

The extension decides by reading its own `/proc/self/cgroup` — inherited by every
child, so it is a reliable "am I inside novpn". It then re-points
`pi-bansos-relay-state.json` at the matching gateway while the file is already
tracking one of ours, and leaves it alone if you pointed it elsewhere or ran
`/unlimited off`. That rewrite happens during extension load, not in a handler:
pi-bansos re-reads the file in its own `session_start`, which runs after every
extension has been imported, so the switch lands without `/unlimited reload`.

Verified both directions:

```
# inside novpn.slice
relay before  : http://127.0.0.1:18790
relay after   : http://127.0.0.1:18791
status        : unlimited: novpn · wrapped · ok

# inside app.slice
relay before  : http://127.0.0.1:18791
relay after   : http://127.0.0.1:18790
status        : unlimited: wrapped · 3 blocks · DAILY LIMIT 14h 28m
```

Two side effects worth knowing:

- **Two ledgers.** Each gateway keeps its own state file
  (`pi-unlimited-gateway.json`, `pi-unlimited-gateway-novpn.json`), so bucket
  counts are per egress class — which is accurate, they are different addresses.
- **`novpn --clean` stops the slice**, and the novpn gateway with it. It comes
  back on next login (`WantedBy=default.target`) or with
  `systemctl --user start pi-unlimited-gateway-novpn`.

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

### Why the probe replays instead of inventing

OpenCode meters the free tier per **client identity** and answers a client it
does not recognise with the *same* `FreeUsageLimitError` as a genuinely spent
bucket. An invented request therefore cannot tell the two apart, and an earlier
version of this test reported `spent` for a block that was answering `pi` at
that moment — measured, interleaved, three times in a row:

| Request | Result |
|---|---|
| real `pi` turn | `200` (×11, one after another) |
| gateway replay with captured body + headers | `429 quota` |
| probe with **invented** `x-opencode-project` / `x-session-id` | `429 quota` |
| probe with those headers **captured from real traffic** | `200` (×3) |

The gateway sits on the wire and sees every real request, so it stores the last
one's upstream headers, tool schemas, system prompt and body
(`GET /__unlimited/shape` shows what it has) and the probe replays that client
identity. Until a real request has passed through since the gateway started, the
probe has only its built-in shape, and then it *says so*:

```
egress test · deepseek-v4.1-flash-free · 1 request(s) in 2s
  direct  89.189.83.90  SPENT · resets 00:00Z in 13h 26m
0/1 block(s) have budget · remaining usage not published by upstream
  shape: builtin — no real request captured yet, so a refusal may be the client
  gate, not quota
```

A `builtin` verdict never writes to the ledger, so an untrustworthy probe can no
longer poison `/unlimited proxies`.

## Multiple tunnels, and why they are de-duplicated

WARP draws exits from a shared pool, so extra identities are worth it but not
linear. Measured 2026-11-16:

| Identities | SOCKS5 ports | Distinct exit addresses |
|---|---|---|
| 3 | `:25344`–`:25346` | 2 |
| 4 | `:25344`–`:25347` | 3 |
| 5 | `:25344`–`:25348` | 3 |

So the gateway probes `api.ipify.org` through each egress every 10 minutes,
records the public address, and collapses tunnels that share one *before*
spending a request on them. `/unlimited egress` shows the addresses and the
health endpoint reports `distinctBlocks`. Raise `warpCount` only while that
number grows.

An exit address is also **not stable per identity**: `:25344` moved from
`104.28.201.80` to `104.28.233.73` within the hour, which is exactly why the
probe repeats on a timer instead of trusting a one-off reading.

## When everything is spent: `/unlimited rotate`

A spent address cannot be cleared — the budget belongs to the address, and WARP
and Tor addresses are shared with strangers. The only lever is to stop using that
address. `/unlimited rotate [n]` mints a **new WARP identity** on unit `n`
(deleting that unit's `wgcf` account, letting its `ExecStartPre` re-register),
waits for the tunnel to answer, then forces both gateways to re-probe so the table
shows the new address immediately.

With no argument it picks a tunnel whose address the gateway already knows is
spent.

Measured, exactly as it behaves — and why it is a gamble, not a fix:

```
rotating warp 3 — new identity, then waiting for it to come up…
warp 3 (:25347) 104.28.201.73 → 104.28.233.73
```

A new address, yes — but one the pool was already handing out to another unit,
so it carried the same spent budget. `wgcf register` is also rate-limited by
Cloudflare (HTTP 429 after a handful of rapid calls), which is why this rotates a
single unit and tells you to wait rather than looping.

What actually adds usable capacity is an address nobody else is hammering, which
in practice means one you control: put your own VPN servers in `extraEgress`
(borrow the `wgcf`/`wireproxy` pattern — one WireGuard config per server, each on
its own SOCKS port). WARP and Tor will keep landing on shared, spent addresses.

## Adding more proxies — and the honest limit of it

`home/modules/pi-unlimited.nix` has `extraEgress`, a list of any
`socks5://` or `http://` (CONNECT) proxy you trust, tried after the WARP
tunnels and before `direct`:

```nix
extraEgress = [
  "socks5://127.0.0.1:9050"   # Tor
  "http://127.0.0.1:8118"     # Privoxy (Tor)
];
```

It ships empty. That is a measurement, not an oversight. On 2026-11-16, five
egress with **five distinct exit addresses** were all refused:

| Egress | Exit address | Result | Latency |
|---|---|---|---|
| WARP `:25347` | `104.28.241.89` | `429 quota`, reset ~16.4h | 1.1s |
| Tor `:9050` | `45.66.35.21` | `429 quota`, reset ~16.4h | 4.8s |
| Privoxy `:8118` | `193.189.100.204` | `429 quota`, reset ~16.7h | 8.1s |
| WARP `:25344` | `104.28.233.73` | `429 quota`, reset ~16.4h | 9.7s |
| `direct` | `89.189.83.90` | `429 quota`, reset ~16.4h | 11.7s |

Five addresses, five refusals, one shared reset. The budget is per address, but
WARP and Tor addresses are shared with strangers, so a fresh address is a
lottery ticket, not a new allowance — and once the bucket is spent, extra proxies
buy latency and nothing else. The upside is real but narrow: `:25344` answered
`200` in 2.2s while `direct` was mid-cooldown, twenty minutes before the table
above.

Practical guidance: keep `warpCount` at 4, leave Tor out of the default pool
(5–8s per attempt against ~1s), and check `/unlimited test` before adding
anything — it tells you in one command whether the new egress has budget at all.

`wgcf register` is rate-limited by Cloudflare (`429 Too Many Requests` after a
handful of rapid calls), so the units register lazily, retry every 2 minutes,
and stop after 10 attempts in an hour. A tunnel that is not up yet is simply
quarantined; `direct` keeps serving in the meantime. If a unit gave up:

```bash
systemctl --user reset-failed pi-unlimited-warp-3
systemctl --user start pi-unlimited-warp-3
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
