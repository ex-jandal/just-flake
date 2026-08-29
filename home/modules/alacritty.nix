{
  pkgs,
  ...
}:
{
  # alacritty — copy config verbatim (noctalia theme applied via theme file).
  home.packages = [ pkgs.alacritty ];

  xdg.configFile."alacritty/alacritty.toml".source = ../../assets/alacritty/alacritty.toml;
}
