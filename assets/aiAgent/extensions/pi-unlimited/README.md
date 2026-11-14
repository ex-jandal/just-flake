# pi-unlimited

An [opencode-unlimited](https://github.com/Tazmyan/OpenCode-Unlimited)-style
route controller for pi's `bansos` provider ([pi-bansos](https://www.npmjs.com/package/pi-bansos)).

pi-bansos gives you free OpenCode Zen / KiloCode models through a local
OpenAI-compatible proxy. When OpenCode's free budget lands, it lands **per
egress block per UTC day** — one IPv4 `/32`, one IPv6 `/64`. It is not per
project, per session, per model or per device id, so rotating an identity string
changes nothing. `pi-unlimited` is the operator surface around the two levers
that do work:

1. **leave through a different address block**, and
2. **move the session onto an upstream that is not billing that block**.

It owns a ranked relay pool with health records and quarantine, an egress-block
ledger, a local usage meter, and the one-shot `reset` that rotates the route and
reloads so pi-bansos actually picks it up.

## Commands

| Command | What it does |
|---|---|
| `/unlimited` | Status: mode, pool health, active route, egress, hits today, reset clock |
| `/unlimited on` | Enable routing + watcher, write the relay file, seed the active route |
| `/unlimited off` | Stop the watcher, disable the relay, return to direct egress |
| `/unlimited usage` | Local meter, last limit hit, UTC reset clock, top models |
| `/unlimited block` | Probe the current egress, classify its `/32` or `/64`, report spent/clean |
| `/unlimited pool list` | Ranked pool: ready / untested / slow / parked, latency, failures |
| `/unlimited pool add <url> [label]` | Add a relay or pass-through endpoint |
| `/unlimited pool remove <url>` | Remove a route |
| `/unlimited pool test` | Probe up to 10 routes, record latency, park the dead |
| `/unlimited pool next` | Switch to the next healthy route and reload |
| `/unlimited pool clear` | Forget the pool |
| `/unlimited watch on\|off` | Auto-queue a route change on a `429`/`403` |
| `/unlimited apply` | Write the active route into pi-bansos and reload |
| `/unlimited reset [--dry]` | Rotate the route, clear today's ledger for the block, reload |
| `/unlimited doctor` | Node, agent dir, pi-bansos presence, relay file, egress probe |

## How it hooks in

- `after_provider_response` — sees the HTTP status before the stream body is
  consumed. `429` is classified as quota, `403` as the egress/fingerprint gate.
  Each hit updates the ledger, the local meter and the status bar; when the
  watcher is on it also queues the next healthy route.
- `session_start` / `session_shutdown` — loads state, renders the status bar,
  persists counters.
- **Shared file**: `pi-bansos-relay-state.json` is pi-bansos's own state. This
  extension merges its pool into that file's `relays` list and sets the active
  `url`. pi-bansos re-reads it on every `session_start`, which is why `apply`,
  `reset` and `pool next` end with `ctx.reload()`.

State lives in `<agent-dir>/pi-unlimited-state.json` (agent dir defaults to
`~/.pi/agent`, overridable with `PI_CODING_AGENT_DIR`).

## Honest limits

- **No invented proxies.** Public proxy lists are mostly dead and a dead exit
  costs a real request. Routes are added explicitly.
- **The quota is server-side.** Nothing here unlocks an entitlement; the window
  is a wall clock that resets at exactly `00:00 UTC`.
- **A route change needs a session restart.** `apply` / `reset` / `pool next`
  do that for you via reload; a file write alone leaves pi-bansos's in-memory
  pool stale.
- **Rotation is capped** at five moves per 30 minutes, so a spent day cannot
  turn into hammering every exit you own.
- **Relay egress is not free IP diversity.** Vercel relays share one NAT pool;
  the value of the pool is failover, not a new `/32` each time. Use real
  egress (VPN, hotspot, router reconnect) when the block itself is spent.

## Nix

Wired declaratively in `home/modules/pi-coding-agent.nix`:

```nix
home.file.".pi/agent/extensions/pi-unlimited" = {
  source = ../../assets/aiAgent/extensions/pi-unlimited;
  recursive = true;
};
```

The directory is auto-discovered (`~/.pi/agent/extensions/*/index.ts`) and
hot-reloadable with `/reload`.
