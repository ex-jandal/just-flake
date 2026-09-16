{
  pkgs,
  ...
}:
{
  # - cava audio visualizer. Config ported verbatim from Arch ~/.config/cava/config
  #   (64 bars, gradient #ffdc8b→#f0b27a, monstercat smoothing, pulse input).
  home.packages = with pkgs; [
    cava
  ];

  home.file.".config/cava/config".source = ../../assets/cava/config;
}
