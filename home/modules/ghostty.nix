{
  pkgs,
  ...
}:
{
  # - custom shaders + the Noctalia theme, which Noctalia owns and renders.
  home.packages = [ pkgs.ghostty ];

  xdg.configFile."ghostty/config".source = ../../assets/ghostty/config;
  xdg.configFile."ghostty/shaders".source = ../../assets/ghostty/shaders;
  xdg.configFile."ghostty/cursor-shaders".source = ../../assets/ghostty/cursor-shaders;
}
