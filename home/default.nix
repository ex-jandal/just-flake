{
  inputs,
  pkgs,
  lib,
  ...
}:
{
  home = {
    username = "abu_jandal";
    homeDirectory = "/home/abu_jandal";
    stateVersion = "25.05";
  };

  # Curated daily-use package list.
  imports = [
    ./packages.nix
    ./modules/niri.nix
    ./modules/noctalia.nix
    ./modules/fish.nix
    ./modules/starship.nix
    ./modules/nvim.nix
    ./modules/git.nix
    ./modules/tmux.nix
    ./modules/kitty.nix
    ./modules/foot.nix
    ./modules/ghostty.nix
    ./modules/alacritty.nix
    ./modules/rofi.nix
    ./modules/yazi.nix
    ./modules/fastfetch.nix
    ./modules/gtk-qt.nix
    ./modules/fontconfig.nix
  ];

  programs.home-manager.enable = true;
}
