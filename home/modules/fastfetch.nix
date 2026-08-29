{
  pkgs,
  ...
}:
{
  # fastfetch — system info (custom ascii logo).
  home.packages = [ pkgs.fastfetch ];

  xdg.configFile."fastfetch/config.jsonc".source = ../../assets/fastfetch/config.jsonc;
  xdg.configFile."fastfetch/ascii".source = ../../assets/fastfetch/ascii;
}
