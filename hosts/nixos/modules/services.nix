{ pkgs, inputs, ... }:
{
  imports = [
    inputs.rusbmux.nixosModules.default
  ];

  # --- Optional services (installed, but DISABLED at boot) ---
  # Docker/DBs/libvirt/ollama ship with their daemons present so the tools
  # "just work" once the user starts them; they're not auto-started to keep the
  # VM idle-memory low. Start manually with:
  #   systemctl start docker redis mariadb postgresql libvirtd ollama mpd avahi
  # or `sudo systemctl enable --now <unit>` to persist across reboots.
  virtualisation.docker.enable = false;

  programs.virt-manager.enable = true;
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_full;
    };
  };
  virtualisation.spiceUSBRedirection.enable = true;
  users.groups.libvirtd.members = [ "abu_jandal" ];

  services.tailscale.enable = true;

  programs.wireshark.enable = true;
  users.groups.wireshark.members = [ "abu_jandal" ];

  services.gns3-server = {
    enable = false;
    dynamips.enable = true;
    ubridge.enable = true;
    vpcs.enable = true;
  };

  programs.java.enable = true;

  services.redis.servers."".enable = false;
  # Music player daemon (mpd installed) — disabled by default.
  services.mpd.enable = false;
  # MariaDB/MySQL in nixpkgs lives under services.mysql.
  services.mysql = {
    enable = false;
    package = pkgs.mariadb;
  };
  services.postgresql.enable = false;
  # ollama has no NixOS module in this snapshot — provide a (disabled) systemd
  # unit so `systemctl start ollama` works.
  systemd.services.ollama = {
    description = "Ollama local LLM server";
    wantedBy = [ ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.ollama}/bin/ollama serve";
      Restart = "on-failure";
    };
  };
  # avahi-daemon — Arch had this enabled (mDNS/DNS-SD). Disabled for now;
  # enable once systemd-resolved (Avahi) integration is decided.
  services.avahi.enable = true;

  services.rusbmux.enable = true;

  # --- Tor (ENABLED) — anonymous SOCKS proxy + HTTP via Privoxy ---
  # services.tor.enable alone exposes a "slow" SOCKS proxy on 127.0.0.1:9050
  # (new circuit per destination). client.enable keeps that 9050 listener.
  # Privoxy (enableTor) adds an 8118 HTTP proxy that forwards to Tor's "fast"
  # SOCKS on 9063 (new circuit every 10 min) — see the NixOS wiki. No relay /
  # exit / bridge: client only. proxychains' ProxyList (home/modules/
  # proxychains.nix) and torsocks use the same 9050/9063/8118 ports.
  services.tor = {
    enable = true;
    client.enable = true;
  };
  # Privoxy HTTP proxy -> Tor fast SOCKS. enableTor wires forward-socks5 to
  # 127.0.0.1:9063 and extends tor SOCKSPort accordingly.
  services.privoxy = {
    enable = true;
    enableTor = true;
  };
}
