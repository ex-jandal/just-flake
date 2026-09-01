{
  pkgs,
  ...
}:
{
  # ghostty — copy config verbatim (uses custom shaders + noctalia theme).
  # Noctalia owns/renders its theme file (seeded if-absent). stardust theme
  # was never referenced by the config ("theme = noctalia") so it is dropped.
  home.packages = [ pkgs.ghostty ];

  xdg.configFile."ghostty/config".source = ../../assets/ghostty/config;
  xdg.configFile."ghostty/shaders".source = ../../assets/ghostty/shaders;
  xdg.configFile."ghostty/cursor-shaders".source = ../../assets/ghostty/cursor-shaders;
}