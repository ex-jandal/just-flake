{ pkgs, inputs, ... }:
{
  imports = [
    inputs.rusbmux.nixosModules.default
  ];

  # - daemons below are installed but DISABLED at boot, to keep VM idle memory
  #   low. Start with `systemctl start <unit>`, or `--now` to persist.
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
  # - mpd installed but disabled by default
  services.mpd.enable = false;
  # - MariaDB/MySQL in nixpkgs lives under services.mysql
  services.mysql = {
    enable = false;
    package = pkgs.mariadb;
  };
  services.postgresql.enable = false;
  # - ollama has no NixOS module in this snapshot — provide a (disabled)
  #   systemd unit so `systemctl start ollama` works
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
  # - avahi-daemon (Arch had this enabled, mDNS/DNS-SD). Kept enabled; revisit
  #   once systemd-resolved (Avahi) integration is decided.
  services.avahi.enable = true;

  # - gamemode: user-level gamemoded service + gamemode.ini. The CLI lands in
  #   environment.systemPackages, so it does not need to be in home.packages.
  programs.gamemode.enable = true;

  services.rusbmux.enable = true;
}
