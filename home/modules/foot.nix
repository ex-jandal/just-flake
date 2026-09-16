{
  pkgs,
  ...
}:
{
  # - foot: config copied verbatim (includes noctalia theme + fish shell).
  #   Noctalia theme file is owned/rendered by Noctalia (seeded if-absent).
  home.packages = [ pkgs.foot ];

  xdg.configFile."foot/foot.ini".source = ../../assets/foot/foot.ini;
}
