{
  pkgs,
  ...
}: {
  # Terminal multiplexer (zellij) + AMD GPU monitor (amdgpu_top — nvtop absent
  # from this nixpkgs snapshot). Config.kdl ported verbatim from Arch.
  home.packages = with pkgs; [
    zellij
    amdgpu_top
  ];

  home.file.".config/zellij/config.kdl".source = ../../assets/zellij/config.kdl;
}