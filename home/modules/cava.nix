{
  pkgs,
  ...
}: {
  # Audio visualizer. Colors match the Noctalia green/teal palette.
  home.packages = with pkgs; [
    cava
  ];

  home.file.".config/cava/config".text = ''
    [general]
    framerate = 60
    bars = 40
    sensitivity = 4
    autosens = 1

    [output]
    method = ncurses
    channels = stereo

    [color]
    gradient = 1
    gradient_count = 4
    gradient_color_1 = "#9ad4a1"
    gradient_color_2 = "#7fc2b0"
    gradient_color_3 = "#4f8a8b"
    gradient_color_4 = "#1d404b"
    background = "#101510"
    foreground = "#1d404b"
  '';
}