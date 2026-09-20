{ lib, pkgs, ... }:
{
  # - Bluetooth
  hardware.bluetooth.enable = true;

  networking = {
    hostName = "nixos";
    networkmanager = {
      enable = true;
      plugins = with pkgs; [
        networkmanager-l2tp
        networkmanager-strongswan
        # - networkmanager-fortisslvpn
        # - networkmanager-iodine
        # - networkmanager-openconnect
        networkmanager-openvpn
        # - networkmanager-sstp
        # - networkmanager-vpnc
      ];
      # - the L2TP "VPN connection 1" (UUID 65acbc5e-...) is intentionally NOT in
      #   ensureProfiles: it writes a minimal profile to
      #   /run/NetworkManager/system-connections that would shadow the full
      #   gateway/user/password/psk profile in /etc. The /etc profile persists
      #   across rebuilds (NixOS never wipes NetworkManager/system-connections)
      #   and already carries ipsec-interface=virbr2 + ipv4.never-default.
    };
    # - dnscrypt-proxy sets networking.nameservers = 127.0.0.1 when enabled,
    #   routing ALL DNS through the proxy. Neutralize with mkForce:
    #   dnscrypt-proxy runs in the background on 127.0.0.1:53 only, and system
    #   DNS keeps using DHCP (192.168.122.1) until the Noctalia dns-switcher
    #   plugin points it at the proxy on demand.
    nameservers = lib.mkForce [ ];
  };
  # - iwd as the Wi-Fi backend for NetworkManager (matches Arch)
  networking.networkmanager.wifi.backend = "iwd";

  services.xl2tpd.enable = false;
  # - do NOT enable services.strongswan here: nm-l2tp-service spawns its own
  #   per-connection charon from the strongswan bundled in its package closure
  #   (networkmanager-l2tp -> strongswan-6.0.7). A system-wide charon binds
  #   ports 500/4500, conflicts, and has to be SIGINT-killed on every connect
  #   ("Stopping strongSwan IPsec failed").

  # - Create /etc/strongswan.conf:
  #   - do NOT use a manual `load = ...` line — plugins are compiled into the
  #     binary (monolithic build); a manual list overrides the compile-time one
  #     and breaks everything.
  #   - disable the integrity self-test (it fails on Nix store paths).
  environment.etc."strongswan.conf".text = ''
    libstrongswan {
      integrity_test = no
    }
  '';

  # - ensure /etc/ipsec.d/ exists and is writable — nm-l2tp-service writes
  #   ipsec.nm-l2tp.secrets here at runtime
  systemd.tmpfiles.rules = [
    "d /etc/ipsec.d 0755 root root -"
  ];

  # - include the secrets file so strongswan finds the PSK at runtime
  environment.etc."ipsec.secrets".text = ''
    include ipsec.d/ipsec.nm-l2tp.secrets
  '';

  # - dnscrypt-proxy (config ported from Arch /etc/dnscrypt-proxy/*)
  services.dnscrypt-proxy = {
    enable = true;
settings = {
      static = {
        quad9alpha = {
          stamp = "sdns://AgcAAAAAAAAAAAATYWxwaGEtZG5zLnF1YWQ5Lm5ldAovZG5zLXF1ZXJ5";
        };
        adnull = {
          stamp = "sdns://AgcAAAAAAAAAAAAOZG5zLmFkbnVsbC5jb20KL2Rucy1xdWVyeQ";
        };
        envs = {
          stamp = "sdns://AgcAAAAAAAAAAAAMZG5zLmVudnMubmV0Ci9kbnMtcXVlcnk";
        };
        apple = {
          stamp = "sdns://AgcAAAAAAAAAAAARZG9oLmRucy5hcHBsZS5jb20KL2Rucy1xdWVyeQ";
        };
        shecan = {
          stamp = "sdns://AgcAAAAAAAAAAAANcHJvLnNoZWNhbi5pcgovZG5zLXF1ZXJ5";
        };
        v0dka = {
          stamp = "sdns://AgcAAAAAAAAAAAAIdjBka2EucnUKL2Rucy1xdWVyeQ";
        };
      };
      server_names = [
        "quad9-dnscrypt-ip4-nofilter-pri"
        "quad9-dnscrypt-ip4-nofilter-ecs-pri"
        "cloudflare"
        "quad9alpha"
        "adnull"
        "envs"
        "apple"
        "shecan"
        "v0dka"
      ];
      listen_addresses = [ "127.0.0.1:53" ];
      max_clients = 250;
      ipv4_servers = true;
      ipv6_servers = false;
      require_dnssec = true;
      require_nolog = true;
      require_nofilter = true;
      force_tcp = false;
      timeout = 5000;
      keepalive = 30;
      bootstrap_resolvers = [
        "9.9.9.11:53"
        "8.8.8.8:53"
      ];
      # - when the bootstrap resolvers are unreachable (e.g. UDP/53 firewalled
      #   on this network), fall back to the system/DHCP resolver to fetch the
      #   server list — only the list hostname is exposed, never real queries.
      ignore_system_dns = false;
      block_ipv6 = false;
      block_unqualified = true;
      block_undelegated = true;
      cache = true;
      cache_size = 4096;
      cache_min_ttl = 2400;
      cache_max_ttl = 86400;
      cache_neg_min_ttl = 60;
      cache_neg_max_ttl = 600;
      # - ad/tracker blocklist + safesearch cloaking from Arch.
      #   blocked_names/blocked_ips are TOML tables (keyed by *_file);
      #   cloaking_rules/forwarding_rules are TOML strings (single file path).
      #   Nesting the latter as tables makes dnscrypt-proxy abort at startup,
      #   killing all DNS (resolv.conf -> dead 127.0.0.1 stub).
      # blocked_names = {
      #   blocked_names_file = ../../../assets/dnscrypt/blocked-names.txt;
      # };
      # blocked_ips = {
      #   blocked_ips_file = ../../../assets/dnscrypt/blocked-ips.txt;
      # };
      cloaking_rules = ../../../assets/dnscrypt/cloaking-rules.txt;
      forwarding_rules = ../../../assets/dnscrypt/forwarding-rules.txt;
    };
  };

  # - Tor: anonymous SOCKS proxy + HTTP via Privoxy. services.tor.enable alone
  #   exposes a "slow" SOCKS proxy on 127.0.0.1:9050 (new circuit per
  #   destination); client.enable keeps that 9050 listener. Privoxy (enableTor)
  #   adds an 8118 HTTP proxy forwarding to Tor's "fast" SOCKS on 9063 (new
  #   circuit every 10 min). No relay/exit/bridge: client only. proxychains
  #   (home/modules/proxychains.nix) and torsocks use 9050/9063/8118.
  services.tor = {
    enable = true;
    client.enable = true;
  };
  # - Privoxy HTTP proxy -> Tor fast SOCKS. enableTor wires forward-socks5 to
  #   127.0.0.1:9063 and extends tor SOCKSPort accordingly.
  services.privoxy = {
    enable = true;
    enableTor = true;
  };
}
