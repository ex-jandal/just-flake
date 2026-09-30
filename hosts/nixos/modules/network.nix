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
        networkmanager-openvpn
      ];
      # - the L2TP "VPN connection 1" (UUID 65acbc5e-...) is intentionally NOT
      #   in ensureProfiles: it writes a minimal /run profile that shadows the
      #   full gateway/user/password/psk one in /etc, which persists across
      #   rebuilds and already carries ipsec-interface=virbr2 + never-default.
    };
    # - dnscrypt-proxy forces nameservers = 127.0.0.1; mkForce [] keeps system
    #   DNS on DHCP until the Noctalia dns-switcher plugin points it at the
    #   proxy on demand.
    nameservers = lib.mkForce [ ];
  };
  # - iwd as the Wi-Fi backend for NetworkManager (matches Arch)
  networking.networkmanager.wifi.backend = "iwd";

  services.xl2tpd.enable = false;
  # - do NOT enable services.strongswan: nm-l2tp-service spawns its own charon
  #   from its package closure, and a second system-wide one binds 500/4500,
  #   conflicts, and must be SIGINT-killed on every connect.

  # - integrity_test = no: the self-test fails on Nix store paths. No manual
  #   `load = ...` — plugins are compiled in, and overriding breaks everything.
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
      # - ad/tracker blocklist + safesearch cloaking. blocked_names/blocked_ips
      #   are TOML tables (keyed by *_file); cloaking_rules/forwarding_rules
      #   are TOML strings (a bare file path). Nesting the latter as tables
      #   makes dnscrypt-proxy abort at startup, killing ALL DNS via a dead
      #   127.0.0.1 stub in resolv.conf.
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

  # - client-only Tor (no relay/exit/bridge): 9050 is the slow SOCKS (new
  #   circuit per destination), which proxychains and torsocks use. Privoxy
  #   adds 8118 (HTTP) forwarding to the fast SOCKS on 9063.
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
