{
  pkgs,
  ...
}:
{
  # kitty — copy config verbatim (uses noctalia theme include + kittens).
  home.packages = [ pkgs.kitty ];

  xdg.configFile."kitty/kitty.conf".source = ../../assets/kitty/kitty.conf;
  xdg.configFile."kitty/themes".source = ../../assets/kitty/themes;
  xdg.configFile."kitty/scroll_mark.py".source = ../../assets/kitty/scroll_mark.py;
  xdg.configFile."kitty/search.py".source = ../../assets/kitty/search.py;

  # Noctalia generates the theme file; provide a default match until then.
  xdg.configFile."kitty/current-theme.conf".text = ''
    include themes/noctalia.conf
  '';
}
