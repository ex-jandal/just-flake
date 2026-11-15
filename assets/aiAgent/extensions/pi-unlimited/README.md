# pi-unlimited

A rotating-egress gateway for pi's `bansos` provider
([pi-bansos](https://www.npmjs.com/package/pi-bansos)), plus an honest ledger of
what OpenCode's free tier actually did.

It is the [opencode-unlimited-proxy](https://github.com/ebouther/opencode-unlimited-proxy)
idea rebuilt for pi without Docker: Cloudflare WARP runs as a **userspace**
WireGuard tunnel (`wireproxy` — no TUN, no `CAP_NET_ADMIN`, no root) exposing a
local SOCKS5 port, and a small Node relay in front of pi-bansos rotates egress
across that port and `direct` on every `429`/`403`.

```
pi (provider "bansos")
  └─ pi-bansos local proxy
       └─ relay ──► pi-unlimited-gateway :18790
                      ├─ egress pool: WARP socks5 → direct
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
| `/unlimited` | Route, gateway health, last refusal, retry-after, UTC reset clock |
| `/unlimited usage` | Today's refusals grouped by status/kind/model |
| `/unlimited egress` | Per-egress health from the gateway: ready / parked, latency, errors |
| `/unlimited apply` | Point pi-bansos at the gateway, then reload |
| `/unlimited off` | Remove the gateway relay, then reload |
| `/unlimited auto on\|off` | Select `bansos/auto`, the free-model failover model |
| `/unlimited watch on\|off` | Notifications only (recording is always on) |
| `/unlimited clear` | Clear local history only |
| `/unlimited doctor` | Wiring checks |

## Model failover

`/unlimited auto on` selects `bansos/auto`, a virtual model that routes each
request to a healthy free model. It stays on whatever already answered
(`continuation` keeps the prompt cache), and only leaves the previous model on
a refusal — a `429`/`403` retry moves to the next free model instead of
replaying the same refusal. The ladder is `PREFERRED_FREE_MODELS`, with any
other live `bansos` model appended.

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
systemd.user.services.pi-unlimited-warp.Service.ExecStart =
  "${lib.getExe pkgs.wireproxy} -c %h/.config/warp/wgcf-profile.conf";

systemd.user.services.pi-unlimited-gateway.Service = {
  ExecStart = "${lib.getExe pkgs.nodejs} ${../../assets/aiAgent/gateway/pi-unlimited-gateway.mjs}";
  Environment = [
    "PI_UNLIMITED_EGRESS=socks5://127.0.0.1:25344,direct"
    "PI_UNLIMITED_MAX_EYEBALLS=2"
  ];
};
```

The WARP identity is minted per machine on first start into
`~/.config/warp/wgcf-account.toml` (mode 600) — a device private key, so it
lives in `$HOME`, never in the Nix store.

```bash
systemctl --user status pi-unlimited-warp pi-unlimited-gateway
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
| `PI_UNLIMITED_DEBUG` | unset | `1` logs routing decisions |

Only `opencode.ai` and `api.kilo.ai` are relayable, so the listener is never an
open proxy.

## CLI

```bash
pi-unlimited-gateway                 # serve
pi-unlimited-gateway --probe         # probe every egress, print a table
pi-unlimited-gateway --print-config  # resolved pool
```
