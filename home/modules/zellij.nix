{
  pkgs,
  ...
}: {
  # Terminal multiplexer (zellij) + AMD GPU monitor (amdgpu_top — nvtop absent
  # from this nixpkgs snapshot).
  home.packages = with pkgs; [
    zellij
    amdgpu_top
  ];

  # Minimal theme preset on top of zellij defaults; Noctalia-adjacent dark.
  home.file.".config/zellij/config.kdl".text = ''
    theme "nord"
    default_shell "fish"
    scroll_buffer_size "10000"
    pane_frames false
    copy_on_select true
    mouse_mode false
    simplified_ui true
    show_startup_screen false
  '';
}