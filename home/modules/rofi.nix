{
  pkgs,
  ...
}:
{
  # rofi — adi1090x launcher/powermenu collection used by niri keybinds.
  # Copies the whole config tree so `rofi/launchers/type-2/launcher.sh` etc work.
  home.packages = [ pkgs.rofi ];

  xdg.configFile."rofi".source = ../../assets/rofi;
}
