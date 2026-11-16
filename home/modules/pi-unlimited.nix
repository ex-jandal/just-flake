{
  pkgs,
  lib,
  config,
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
#   identities do land on different /32s. Measured 2026-11-16, three identities
#   -> two distinct addresses, four -> three. A distinct address is the unit of
#   budget, so an extra identity is worth it only if it adds an address.
#
#   What more egress does NOT buy: measured the same day, five tunnels spanning
#   five distinct exit addresses (three WARP, Tor, Privoxy-over-Tor) all came
#   back with the same daily-limit refusal and the same ~16h reset. Once the
#   bucket is spent, extra proxies add latency and nothing else. They only help
#   while some addresses still have morning budget, because WARP and Tor exits
#   are shared with strangers.
#
#   Why the gateway de-duplicates: the pool repeats addresses, and two tunnels
#   behind one /32 are one budget. The gateway learns each exit's public address
#   and collapses duplicates before spending a request.
#
#   Registration is rate-limited by Cloudflare (HTTP 429 after a handful of
#   rapid `wgcf register` calls), so units register lazily, retry on their own
#   schedule, and never block the gateway: a tunnel that is not up yet is simply
#   quarantined and `direct` keeps serving.
let
  # - how many WARP identities to run. Each costs one more tunnel and yields a
  #   distinct block only if WARP happens to hand out a new address; the gateway
  #   reports the real distinct count, so raise this only if that number grows.
  # - two identities, because more did not buy more: measured 2026-11-16, four
  #   identities landed on two addresses (201.80 and 233.73), so the extra pair
  #   was duplicate budget and duplicate rows. `/unlimited rotate N` is the tool
  #   when the two collide on one address.
  warpCount = 2;
  warpPortBase = 25344;

  # - Any extra SOCKS5 or HTTP-CONNECT proxy you trust, tried after the WARP
  #   tunnels and before `direct`. Left empty on purpose: measured 2026-11-16,
  #   Tor (socks5://127.0.0.1:9050) and Privoxy over Tor (http://127.0.0.1:8118)
  #   both reached OpenCode from a fresh address and both were refused, while
  #   costing 5-8s per attempt instead of ~1s. Add them if you want the extra
  #   lottery ticket; expect latency.
  extraEgress = [
    # "socks5://127.0.0.1:9050"   # Tor
    # "http://127.0.0.1:8118"     # Privoxy (Tor)
  ];

  # - WireGuard exports you own, one `pi-unlimited-vpn-<n>` unit each, in
  #   `novpn.slice` so they are not nested inside the system VPN. Each file needs
  #   a PrivateKey in [Interface] and an Endpoint in [Peer]; a [Socks5] section is
  #   appended automatically, so do not add one. `~/` is expanded here rather
  #   than left to systemd, whose ExecStartPre args never see a shell.
  #
  #   Kept enabled by operator decision. Know the cost, because it is invisible
  #   from inside the pool: all seven exports belong to the same Proton account as
  #   the NetworkManager connection `us-proton`, and a free Proton account allows
  #   one connection, so every extra peer competes with the tunnel the machine is
  #   actually using. They also share Address 10.2.0.2/32 and DNS 10.2.0.1, and
  #   wg-quick leaves that resolver in /etc/resolv.conf where it is only reachable
  #   through the tunnel — so a dropped main tunnel takes DNS down with it.
  #   If the main VPN starts dropping, cut this list down before blaming the
  #   gateway; `/unlimited doctor` reports the resolver and the pool size.
  vpnConfigs = [
    "~/.config/pi-unlimited/vpn/nl-proton.conf"
    "~/.config/pi-unlimited/vpn/ca-21-proton.conf"
    "~/.config/pi-unlimited/vpn/je-23-proton.conf"
    "~/.config/pi-unlimited/vpn/mx-17-proton.conf"
    "~/.config/pi-unlimited/vpn/us-33-proton.conf"
    "~/.config/pi-unlimited/vpn/us-127-proton.conf"
    "~/.config/pi-unlimited/vpn/nl-111-proton.conf"
  ];
  vpnConfigsResolved = map (
    entry:
    if lib.hasPrefix "~/" entry then
      "${config.home.homeDirectory}/${lib.removePrefix "~/" entry}"
    else
      entry
  ) vpnConfigs;
  vpnPortBase = 25360;

  gatewayHost = "127.0.0.1";
  # - one gateway per routing class. They run in different slices, so their
  #   `direct` egress leaves through different addresses: the VPN one exits via
  #   the tunnel, the novpn one via the physical interface (the `novpn` command's
  #   nftables marks apply per cgroup, so *any* process in novpn.slice bypasses).
  #   Two addresses is two budgets, and it means a novpn shell gets what it
  #   asked for instead of being quietly relayed through the VPN.
  gatewayPort = 18790;
  gatewayPortNovpn = 18791;
  warpSocksPort = index: warpPortBase + index;

  # - egress pool, highest priority first. The gateway appends `direct` itself
  #   as a final fallback, but listing it keeps the intent visible.
  vpnSocksPort = index: vpnPortBase + index;
  # - the `#name` suffix is carried verbatim into the gateway and shown by
  #   `/unlimited proxies`. Without it every socks5 entry renders as "warp",
  #   because the port alone says nothing about what is behind it.
  vpnLabel = index: lib.removeSuffix ".conf" (baseNameOf (builtins.elemAt vpnConfigsResolved index));
  vpnEgress = map (index: "socks5://127.0.0.1:${toString (vpnSocksPort index)}#${vpnLabel index}") (
    lib.range 0 (builtins.length vpnConfigsResolved - 1)
  );
  warpEgress = map (
    index: "socks5://127.0.0.1:${toString (warpSocksPort index)}#warp-${toString index}"
  ) (lib.range 0 (warpCount - 1));
  egressBase = vpnEgress ++ warpEgress ++ extraEgress ++ [ "direct" ];
  egressSpaces = builtins.filter (entry: builtins.match ".*[[:space:]].*" entry != null) egressBase;
  egress =
    if egressSpaces == [ ] then
      egressBase
    else
      throw "pi-unlimited: these egress entries contain whitespace, which systemd's Environment= splits, silently truncating the pool: ${builtins.toJSON egressSpaces}";
  egressCount = builtins.length egress;
  # A space anywhere in an entry silently truncates the whole pool: home-manager
  # writes Environment=KEY=a,b,c unquoted, systemd splits it on whitespace, and
  # everything after the space becomes a stray assignment nobody reads. That is
  # how `#warp 0` cost this pool its second tunnel. Fail the build instead.
  egressHasSpace = builtins.filter (entry: builtins.match ".*[[:space:]].*" entry != null) egress;

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

  # - Turn one of your own WireGuard configs into a wireproxy SOCKS5. The source
  #   file is never modified: wireproxy needs a [Socks5] section that wg-quick
  #   would reject, so a private copy is written to the state dir (mode 600) with
  #   any [Socks5] block stripped and ours appended. Refuses loudly on a config
  #   that would only fail later, at tunnel start.
  vpnPrepare = pkgs.writeShellScript "pi-unlimited-vpn-prepare" ''
    set -eu
    index="''${1:?vpn tunnel index required}"
    src="''${2:?wireguard config required}"
    case "$src" in
      "~/"*) src="$HOME/''${src#\~/}" ;;
    esac
    dir="''${XDG_STATE_HOME:-$HOME/.local/state}/pi-unlimited/vpn/$index"
    port="$(( ${toString vpnPortBase} + index ))"

    if [ ! -e "$src" ]; then
      echo "pi-unlimited: no such WireGuard config: $src" >&2
      exit 1
    fi
    # /etc/wireguard is root-only by design (0700), and a user service cannot
    # even stat inside it, so this is the failure people actually hit.
    if [ ! -r "$src" ]; then
      # /etc/wireguard is 0700 root, so a user service cannot stat inside it.
      # Keep this block free of nested quoting: escaping it wrong turns the
      # whole unit into an "unexpected EOF" at build time.
      echo "pi-unlimited: $src exists but is not readable by $(id -un)." >&2
      echo "  /etc/wireguard is root-only, so copy the export out once:" >&2
      echo "    mkdir -p ~/.config/pi-unlimited/vpn" >&2
      echo "    sudo install -m 600 -o $(id -un) -g $(id -gn) $src ~/.config/pi-unlimited/vpn/" >&2
      echo "  then point vpnConfigs at the copy." >&2
      exit 1
    fi
    grep -q '^\[Interface\]' "$src" || { echo "pi-unlimited: $src has no [Interface]" >&2; exit 1; }
    grep -q '^\[Peer\]' "$src" || { echo "pi-unlimited: $src has no [Peer]" >&2; exit 1; }
    grep -qi '^PrivateKey' "$src" || { echo "pi-unlimited: $src has no PrivateKey" >&2; exit 1; }
    grep -qi '^Endpoint' "$src" || { echo "pi-unlimited: $src has no Endpoint" >&2; exit 1; }

    mkdir -p "$dir"
    # Copy the config verbatim and change exactly one thing: drop any [Socks5]
    # block, because ours is appended below. Everything else stays, including
    # Address and DNS. Stripping those was wrong: wireproxy resolves SOCKS
    # hostnames through the tunnel's DNS, so without it every request fails with
    # "SOCKS reply 4" (host unreachable). wg-quick-only keys (Table, PostUp,
    # SaveConfig) are ignored by wireproxy, so there is nothing to clean up.
    ${lib.getExe pkgs.gawk} '
      /^\[/ { skip = ($0 ~ /^\[Socks5\]/) }
      skip { next }
      { print }
    ' "$src" > "$dir/profile.conf"
    printf '\n[Socks5]\nBindAddress = 127.0.0.1:%s\n' "$port" >> "$dir/profile.conf"
    chmod 600 "$dir/profile.conf"
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
            # - Cloudflare 429s bulk registration. Retry patiently but not
            #   forever: 10 attempts an hour, then stay failed until an explicit
            #   `systemctl --user reset-failed` instead of hammering the API.
            StartLimitIntervalSec = 3600;
            StartLimitBurst = 10;
          };
          Service = {
            ExecStartPre = "${warpPrepare} ${toString index}";
            ExecStart = "${lib.getExe pkgs.wireproxy} -c %h/.local/state/pi-unlimited/warp/${toString index}/wgcf-profile.conf";
            # - a registration 429 is transient: back off two minutes so the
            #   restart itself never trips the start limit above.
            Restart = "on-failure";
            RestartSec = 120;
          };
          Install.WantedBy = [ "default.target" ];
        };
      }) (lib.range 0 (warpCount - 1))
    )
    # - merged with the line below in one attribute set: Nix rejects the same
    #   attribute path twice in one attrset.
    // lib.listToAttrs (
      map (
        index:
        let
          src = builtins.elemAt vpnConfigsResolved index;
        in
        {
          name = "pi-unlimited-vpn-${toString index}";
          value = {
            Unit = {
              Description = "WireGuard egress ${toString index} as userspace SOCKS5 (pi-unlimited)";
              After = [ "network-online.target" ];
              # - a wrong or unreadable config will not fix itself; stop the
              #   restart loop after a handful of tries instead of every 30s.
              StartLimitIntervalSec = 3600;
              StartLimitBurst = 10;
            };
            Service = {
              ExecStartPre = "${vpnPrepare} ${toString index} ${src}";
              ExecStart = "${lib.getExe pkgs.wireproxy} -c %h/.local/state/pi-unlimited/vpn/${toString index}/profile.conf";
              # - novpn.slice so your own tunnel is not nested inside whichever
              #   VPN the machine is already on. Loopback stays reachable from
              #   the gateways in app.slice, so both can still use it.
              Slice = "novpn.slice";
              Restart = "on-failure";
              RestartSec = 30;
            };
            Install.WantedBy = [ "default.target" ];
          };
        }
      ) (lib.range 0 (builtins.length vpnConfigsResolved - 1))
    )
    // lib.listToAttrs (
      map
        (
          spec:
          let
            sliceAttrs = if spec.slice == null then { } else { Slice = spec.slice; };
          in
          {
            name = spec.name;
            value = {
              Unit = {
                Description = "pi-unlimited relay (${spec.label} egress) for pi-bansos";
                # - soft ordering only: the gateway handles absent tunnels by
                #   quarantining them and using the next block.
                After = map (index: "pi-unlimited-warp-${toString index}.service") (lib.range 0 (warpCount - 1));
              };
              Service = {
                ExecStart = "${lib.getExe pkgs.nodejs} ${../../assets/aiAgent/gateway/pi-unlimited-gateway.mjs}";
                Environment = [
                  "PI_UNLIMITED_HOST=${gatewayHost}"
                  "PI_UNLIMITED_PORT=${toString spec.port}"
                  "PI_UNLIMITED_EGRESS=${lib.concatStringsSep "," egress}"
                  # - one lap per configured egress. The gateway skips tunnels that
                  #   share an exit address, so this is an upper bound, not a
                  #   request budget.
                  "PI_UNLIMITED_MAX_EYEBALLS=${toString egressCount}"
                  # - hard per-attempt deadline, far below any caller timeout. A
                  #   request still in flight when pi gives up makes pi-bansos 0.8.1
                  #   fall back to opencodeDirectFetch with an already-aborted
                  #   signal, where it calls req.destroy() before attaching its
                  #   'error' listener — an unhandled error that exits pi.
                  "PI_UNLIMITED_ATTEMPT_TIMEOUT_MS=30000"
                  "PI_UNLIMITED_TOTAL_BUDGET_MS=25000"
                ]
                # - a file name, not a path: systemd does not expand %h or $HOME
                #   inside Environment= (verified 2026-11-16), so the gateway
                #   appends a profile to its own default state path instead. The
                #   VPN gateway keeps the unprofiled name it already wrote.
                ++ lib.optional (spec.profile != null) "PI_UNLIMITED_PROFILE=${spec.profile}";
                Restart = "on-failure";
                RestartSec = 3;
              }
              // sliceAttrs;
              Install.WantedBy = [ "default.target" ];
            };
          }
        )
        [
          {
            name = "pi-unlimited-gateway";
            label = "VPN";
            port = gatewayPort;
            slice = null;
            profile = null;
          }
          {
            name = "pi-unlimited-gateway-novpn";
            label = "novpn";
            port = gatewayPortNovpn;
            slice = "novpn.slice";
            profile = "novpn";
          }
        ]
    );
}
