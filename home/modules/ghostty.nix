{
  pkgs,
  ...
}:
{
  # ghostty — copy config verbatim (uses custom shaders + noctalia theme).
  home.packages = [ pkgs.ghostty ];

  xdg.configFile."ghostty/config".source = ../../assets/ghostty/config;
  xdg.configFile."ghostty/shaders".source = ../../assets/ghostty/shaders;
  xdg.configFile."ghostty/cursor-shaders".source = ../../assets/ghostty/cursor-shaders;
  xdg.configFile."ghostty/themes".source = ../../assets/ghostty/themes;
}
