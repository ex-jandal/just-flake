{
  pkgs,
  ...
}:
{
  # foot — copy config verbatim (includes noctalia theme + fish shell).
  home.packages = [ pkgs.foot ];

  xdg.configFile."foot/foot.ini".source = ../../assets/foot/foot.ini;
  xdg.configFile."foot/themes".source = ../../assets/foot/themes;
}
