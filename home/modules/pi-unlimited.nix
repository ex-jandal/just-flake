{
  pkgs,
  lib,
  ...
}:
# - pi-unlimited: a local, rotating-egress gateway in front of pi-bansos.
#
#   The declarative half of the opencode-unlimited-proxy idea, without Docker.
#   Cloudflare WARP runs as *userspace* WireGuard (wireproxy — no TUN, no
#   CAP_NET_ADMIN, no root), one tunnel per identity, each exposing its own
#   SOCKS5 port; the gateway rotates across them and `direct` on every 429/403.
#
#   Why several identities: WARP draws exits from a shared pool, but different
#   identities do land on different /32s (measured 2026-11-16: three identities
#   -> two distinct addresses, and one of them still answered 200 while another
#   was spent). A distinct block is a distinct budget.
#
#   Why the gateway de-duplicates: the pool repeats addresses, and two tunnels
#   behind one /32 are one budget. The gateway learns each exit's public address
#   and collapses duplicates before spending a request, which is why adding
#   identities is worth it but not linear.
#
#   Registration is rate-limited by Cloudflare (HTTP 429 after a handful of
#   rapid `wgcf register` calls), so units register lazily, retry on their own
#   schedule, and never block the gateway: a tunnel that is not up yet is simply
#   quarantined and `direct` keeps serving.
let
  # - how many WARP identities to run. Each costs one more tunnel and yields a
  #   distinct block only if WARP happens to hand out a new address; the gateway
  #   reports the real distinct count, so raise this only if that number grows.
  warpCount = 3;
  warpPortBase = 25344;

  gatewayHost = "127.0.0.1";
  gatewayPort = 18790;
  warpSocksPort = index: warpPortBase + index;

  # - egress pool, highest priority first. The gateway appends `direct` itself
  #   as a final fallback, but listing it keeps the intent visible.
  egress =
    map (index: "socks5://127.0.0.1:${toString (warpSocksPort index)}") (lib.range 0 (warpCount - 1))
    ++ [ "direct" ];

  # - wgcf mints a per-machine WARP identity. The profile holds a device private
  #   key, so it lives in $XDG_STATE_HOME (mode 600), never in the Nix store.
  #   Registration is idempotent; identity 0 adopts the single-identity config
  #   this module used before, so an existing tunnel is not re-registered.
  warpPrepare = pkgs.writeShellScript "pi-unlimited-warp-prepare" ''
    set -eu
    index="''${1:?warp identity index required}"
    dir="''${XDG_STATE_HOME:-$HOME/.local/state}/pi-unlimited/warp/$index"
    mkdir -p "$dir"
    cd "$dir"

    legacy="$HOME/.config/warp"
    if [ ! -f wgcf-account.toml ] && [ "$index" = "0" ] && [ -f "$legacy/wgcf-account.toml" ]; then
      cp "$legacy/wgcf-account.toml" .
      [ -f "$legacy/wgcf-profile.conf" ] && cp "$legacy/wgcf-profile.conf" . || true
    fi

    if [ ! -f wgcf-account.toml ]; then
      ${lib.getExe pkgs.wgcf} register --accept-tos
    fi
    if [ ! -f wgcf-profile.conf ]; then
      ${lib.getExe pkgs.wgcf} generate
    fi

    # wireproxy needs a [Socks5] section. Append once, and rewrite a stale port
    # so changing warpPortBase does not silently leave a unit on the old port.
    port="''${PI_UNLIMITED_WARP_PORT:-$(( ${toString warpPortBase} + index ))}"
    if grep -q '^\[Socks5\]' wgcf-profile.conf; then
      ${lib.getExe pkgs.gnused} -i -E "s#^BindAddress = .*#BindAddress = 127.0.0.1:$port#" wgcf-profile.conf
    else
      printf '\n[Socks5]\nBindAddress = 127.0.0.1:%s\n' "$port" >> wgcf-profile.conf
    fi
    chmod 600 wgcf-profile.conf
  '';
in
{
  # - Seed pi-bansos's relay state once, so a fresh activation routes through
  #   the gateway without a manual `/unlimited apply`. Only written when there
  #   is no relay configured yet: if the operator pointed pi-bansos somewhere
  #   else (or ran `/unlimited off`), that decision is left alone.
  home.activation.piUnlimitedRelay = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        relay="$HOME/.pi/agent/pi-bansos-relay-state.json"
        current=""
        if [ -f "$relay" ]; then
          current="$(${lib.getExe pkgs.jq} -r '.url // ""' "$relay" 2>/dev/null || echo "")"
        fi
        if [ -z "$current" ]; then
          mkdir -p "$(dirname "$relay")"
          cat > "$relay" <<'JSON'
    {"enabled":true,"url":"http://127.0.0.1:18790","relays":[{"url":"http://127.0.0.1:18790","label":"pi-unlimited gateway"}],"statusBar":"hidden"}
    JSON
        fi
  '';

  systemd.user.services =
    lib.listToAttrs (
      map (index: {
        name = "pi-unlimited-warp-${toString index}";
        value = {
          Unit = {
            Description = "Cloudflare WARP egress ${toString index} as a userspace SOCKS5 (pi-unlimited)";
            After = [ "network-online.target" ];
            # - Cloudflare 429s bulk registration. Three failures in 15 minutes
            #   is enough evidence that the address pool wants a longer pause.
            StartLimitIntervalSec = 900;
            StartLimitBurst = 3;
          };
          Service = {
            ExecStartPre = "${warpPrepare} ${toString index}";
            ExecStart = "${lib.getExe pkgs.wireproxy} -c %h/.local/state/pi-unlimited/warp/${toString index}/wgcf-profile.conf";
            # - a registration 429 is transient: wait a full minute before the
            #   next attempt instead of hammering Cloudflare.
            Restart = "on-failure";
            RestartSec = 60;
          };
          Install.WantedBy = [ "default.target" ];
        };
      }) (lib.range 0 (warpCount - 1))
    )
    # - merged with the line below in one attribute set: Nix rejects the same
    #   attribute path twice in one attrset.
    // {
      pi-unlimited-gateway = {
        Unit = {
          Description = "pi-unlimited rotating-egress relay for pi-bansos";
          # - soft ordering only: the gateway handles absent tunnels by quarantining
          #   them and using the next block.
          After = map (index: "pi-unlimited-warp-${toString index}.service") (lib.range 0 (warpCount - 1));
        };
        Service = {
          ExecStart = "${lib.getExe pkgs.nodejs} ${../../assets/aiAgent/gateway/pi-unlimited-gateway.mjs}";
          Environment = [
            "PI_UNLIMITED_HOST=${gatewayHost}"
            "PI_UNLIMITED_PORT=${toString gatewayPort}"
            "PI_UNLIMITED_EGRESS=${lib.concatStringsSep "," egress}"
            # - one lap per distinct block. The gateway skips tunnels that share an
            #   exit address, so this is an upper bound, not a request budget.
            "PI_UNLIMITED_MAX_EYEBALLS=${toString (warpCount + 1)}"
            # - hard per-attempt deadline, far below any caller timeout. A request
            #   still in flight when pi gives up makes pi-bansos 0.8.1 fall back to
            #   opencodeDirectFetch with an already-aborted signal, where it calls
            #   req.destroy() before attaching its 'error' listener — an unhandled
            #   error that exits pi. Answering fast keeps that path unreachable.
            "PI_UNLIMITED_ATTEMPT_TIMEOUT_MS=30000"
          ];
          Restart = "on-failure";
          RestartSec = 3;
        };
        Install.WantedBy = [ "default.target" ];
      };
    };
}
