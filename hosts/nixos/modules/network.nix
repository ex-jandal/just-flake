{ lib, pkgs, ... }:
{
  # --- Bluetooth ---
  hardware.bluetooth.enable = true;

  # --- Networking (Noctalia needs NetworkManager) ---
  networking = {
    hostName = "nixos";
    networkmanager = {
      enable = true;
      plugins = with pkgs; [
        networkmanager-l2tp
        # networkmanager-fortisslvpn
        # networkmanager-iodine
        # networkmanager-openconnect
        # networkmanager-openvpn
        # networkmanager-sstp
        # networkmanager-strongswan
        # networkmanager-vpnc
      ];
    };
    # The dnscrypt-proxy module sets networking.nameservers = 127.0.0.1 when
    # enabled, which would route ALL system DNS through the proxy. Neutralize
    # with mkForce: dnscrypt-proxy runs in the background on 127.0.0.1:53 only,
    # and system DNS keeps using DHCP (192.168.122.1) until the Noctalia
    # dns-switcher plugin points it at the proxy on demand.
    nameservers = lib.mkForce [ ];
  };
  # Use iwd as the Wi-Fi backend for NetworkManager (matches Arch).
  networking.networkmanager.wifi.backend = "iwd";

  # --- DNSCrypt proxy (config ported from Arch /etc/dnscrypt-proxy/*) ---
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      server_names = [
        "quad9-dnscrypt-ip4-nofilter-pri"
        "quad9-dnscrypt-ip4-nofilter-ecs-pri"
        "cloudflare"
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
      # When the bootstrap resolvers are unreachable (e.g. UDP/53 is
      # firewalled on this network), fall back to the system/DHCP resolver
      # to fetch the server list. Only the list hostname is exposed, never
      # real queries.
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
      # Ad/tracker blocklist + safesearch cloaking from Arch.
      # blocked_names/blocked_ips are TOML tables (keyed by *_file);
      # cloaking_rules/forwarding_rules are TOML strings (a single file path).
      # Nesting the later two as tables makes dnscrypt-proxy abort at startup
      # ("...value has type map[string]any; destination has type string"),
      # which kills all DNS (resolv.conf -> dead 127.0.0.1 stub).
      blocked_names = {
        blocked_names_file = ../../../assets/dnscrypt/blocked-names.txt;
      };
      blocked_ips = {
        blocked_ips_file = ../../../assets/dnscrypt/blocked-ips.txt;
      };
      cloaking_rules = ../../../assets/dnscrypt/cloaking-rules.txt;
      forwarding_rules = ../../../assets/dnscrypt/forwarding-rules.txt;
    };
  };
}
