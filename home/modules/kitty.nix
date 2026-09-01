{
  pkgs,
  ...
}:
{
  # kitty — copy config verbatim (uses noctalia theme include + kittens).
  # The Noctalia theme file is owned/rendered by Noctalia (seeded if-absent).
  home.packages = [ pkgs.kitty ];

  xdg.configFile."kitty/kitty.conf".source = ../../assets/kitty/kitty.conf;
  xdg.configFile."kitty/scroll_mark.py".source = ../../assets/kitty/scroll_mark.py;
  xdg.configFile."kitty/search.py".source = ../../assets/kitty/search.py;
}