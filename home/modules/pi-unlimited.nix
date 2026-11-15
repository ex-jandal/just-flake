{
  pkgs,
  lib,
  ...
}:
# - pi-unlimited: a local, rotating-egress gateway in front of pi-bansos.
#
#   This is the declarative half of the opencode-unlimited-proxy idea, without
#   Docker: Cloudflare WARP is brought up as a *userspace* WireGuard tunnel
#   (wireproxy — no TUN, no CAP_NET_ADMIN, no root) that exposes a local SOCKS5
#   port, and a tiny Node relay in front of pi-bansos rotates egress across
#   that port and `direct` on every 429/403.
#
#   Measured on 2026-11-15, in both directions: one run had direct and WARP
#   return the same `429 FreeUsageLimitError` with the same Retry-After
#   (pool-wide, rotation cannot help), and a later run had `direct` answer 429
#   while WARP answered 200 and completed the turn. So rotation is a real
#   lever, not a guarantee — the gateway reports which case it hit rather than
#   claiming an unlock.
let
  # - egress pool, highest priority first. `direct` is always appended by the
  #   gateway as a final fallback, so a dead WARP tunnel degrades to the old
  #   behaviour instead of taking the provider offline.
  egress = [
    "socks5://127.0.0.1:25344" # Cloudflare WARP via wireproxy
    "direct"
  ];

  gatewayHost = "127.0.0.1";
  gatewayPort = 18790;
  warpSocksPort = 25344;

  # - wgcf mints a per-machine WARP identity on first start. The account file
  #   holds a device private key, so it lives in $HOME (mode 600), never in the
  #   Nix store. Registration is idempotent: existing files are reused.
  warpPrepare = pkgs.writeShellScript "pi-unlimited-warp-prepare" ''
    set -eu
    dir="''${PI_UNLIMITED_WARP_DIR:-$HOME/.config/warp}"
    mkdir -p "$dir"
    cd "$dir"

    if [ ! -f wgcf-account.toml ]; then
      ${lib.getExe pkgs.wgcf} register --accept-tos
    fi
    if [ ! -f wgcf-profile.conf ]; then
      ${lib.getExe pkgs.wgcf} generate
    fi

    # wireproxy needs a [Socks5] section; append it exactly once, so repeated
    # service restarts do not stack duplicate sections.
    if ! grep -q '^\[Socks5\]' wgcf-profile.conf; then
      printf '\n[Socks5]\nBindAddress = 127.0.0.1:${toString warpSocksPort}\n' >> wgcf-profile.conf
      chmod 600 wgcf-profile.conf
    fi
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

  systemd.user.services.pi-unlimited-warp = {
    Unit = {
      Description = "Cloudflare WARP egress as a userspace SOCKS5 (pi-unlimited)";
      # - WARP needs outbound UDP 2408; if the ISP blocks it the tunnel simply
      #   never handshakes and the gateway falls back to direct.
      After = [ "network-online.target" ];
    };
    Service = {
      ExecStartPre = "${warpPrepare}";
      ExecStart = "${lib.getExe pkgs.wireproxy} -c %h/.config/warp/wgcf-profile.conf";
      Restart = "on-failure";
      RestartSec = 5;
      # wireproxy is chatty at DEBUG level; keep the journal bounded.
      StandardOutput = "journal";
      StandardError = "journal";
    };
    Install.WantedBy = [ "default.target" ];
  };

  systemd.user.services.pi-unlimited-gateway = {
    Unit = {
      Description = "pi-unlimited rotating-egress relay for pi-bansos";
      # - soft ordering only: the gateway handles an absent WARP endpoint by
      #   quarantining it and using `direct`.
      After = [ "pi-unlimited-warp.service" ];
    };
    Service = {
      ExecStart = "${lib.getExe pkgs.nodejs} ${../../assets/aiAgent/gateway/pi-unlimited-gateway.mjs}";
      Environment = [
        "PI_UNLIMITED_HOST=${gatewayHost}"
        "PI_UNLIMITED_PORT=${toString gatewayPort}"
        "PI_UNLIMITED_EGRESS=${lib.concatStringsSep "," egress}"
        # - one lap around the pool per request. More than that only burns the
        #   same refusal again, and a pool-wide refusal is reported anyway.
        "PI_UNLIMITED_MAX_EYEBALLS=2"
      ];
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
