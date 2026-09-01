{
  pkgs,
  ...
}:
{
  # foot — copy config verbatim (includes noctalia theme + fish shell).
  # The Noctalia theme file is owned/rendered by Noctalia (seeded if-absent).
  home.packages = [ pkgs.foot ];

  xdg.configFile."foot/foot.ini".source = ../../assets/foot/foot.ini;
}