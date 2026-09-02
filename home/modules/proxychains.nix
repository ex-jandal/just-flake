{
  ...
}: {
  # proxychains-ng per-user config. proxychains-ng walks several candidate
  # paths in order ($PROXYCHAINS_CONF_FILE, ~/.proxychains/proxychains.conf,
  # /etc/proxychains4.conf, ...); dropping this file at the per-user location
  # is picked up automatically without touching system config.
  #
  # dynamic_chain -> walk the ProxyList and use the first live proxy; doesn't
  # hard-fail if a later entry (e.g. fast SOCKS 9063 or Privoxy 8118) isn't up.
  # proxy_dns     -> resolve names through the proxy chain (keeps lookups on Tor).
  home.file.".proxychains/proxychains.conf".text = ''
    # dynamic_chain
    #
    # Dynamic - Each connection will go via the proxy of your choosing in a
    # random order. All proxies not in the list are ignored. If no proxy is up,
    # proxychains aborts.
    dynamic_chain

    # proxy_dns - remote dns resolve.
    proxy_dns

    tcp_read_time_out 15000
    tcp_connect_time_out 8000

    [ProxyList]
    # Local Tor SOCKS proxies + Privoxy HTTP, all routing to the Tor network
    # (see the services.tor block in hosts/nixos/default.nix).
    # 9050 = "slow" SOCKS, isolated per-destination circuit (safe default).
    socks4 127.0.0.1 9050
    # 9063 = "fast" SOCKS, new circuit every 10 minutes (browser usage).
    socks5 127.0.0.1 9063
    # 8118 = Privoxy HTTP proxy -> fast SOCKS. Use for HTTP(S) traffic.
    http 127.0.0.1 8118
  '';
}