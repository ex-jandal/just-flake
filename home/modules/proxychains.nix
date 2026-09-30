{
  ...
}:
{
  # - per-user drop-in: proxychains-ng walks $PROXYCHAINS_CONF_FILE,
  #   ~/.proxychains/proxychains.conf, /etc/proxychains4.conf, ... in order, so
  #   this is picked up without touching system config. dynamic_chain uses the
  #   first live proxy instead of hard-failing; proxy_dns keeps lookups on Tor.
  home.file.".proxychains/proxychains.conf".text = ''
    dynamic_chain

    # proxy_dns - remote dns resolve.
    proxy_dns

    tcp_read_time_out 15000
    tcp_connect_time_out 8000

    [ProxyList]
    # Local Tor SOCKS + Privoxy, all routing to Tor (services.tor in
    # hosts/nixos/modules/network.nix). 9050 = slow SOCKS, per-destination
    # circuit; 9063 = fast SOCKS; 8118 = Privoxy HTTP -> 9063.
    socks4 127.0.0.1 9050
    socks5 127.0.0.1 9063
    http 127.0.0.1 8118
  '';
}
