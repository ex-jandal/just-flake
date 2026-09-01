{
  pkgs,
  ...
}:
{
  # Niri window manager — faithful copy of config.kdl + noctalia theme file.
  home.packages = [ pkgs.niri ];

  xdg.configFile."niri/config.kdl".source = ../../assets/niri/config.kdl;
  xdg.configFile."niri/noctalia.kdl".source = ../../assets/niri/noctalia.kdl;
  # xdg.configFile."niri/monitor.kdl".source = ../../assets/niri/monitor.kdl;
  xdg.configFile."niri/monitor-mirroring.sh".source = ../../assets/niri/monitor-mirroring.sh;

  home.file.".local/bin/monitor-mirroring.sh" = {
    source = ../../assets/niri/monitor-mirroring.sh;
    executable = true;
  };
}
