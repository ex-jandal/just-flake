{
  inputs,
  pkgs,
  system,
  ...
}:
{
  # - Noctalia v5, official module. Uses the flake input (cachix branch,
  #   pre-built binary) so no quickshell is needed.
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    # - use the flake-provided package (pinned, cached) rather than nixpkgs'
    #   copy.
    package = inputs.noctalia.packages.${system}.default;
    # - settings: attrset, TOML string, or path to a .toml file.
    settings = ../../assets/noctalia/settings.toml;
  };

  # - the Noctalia service wires into home-manager's wayland systemd target,
  #   which is part of home-manager core (no extra option needed here).

  # - supporting tools for Noctalia's features (bars, media, udisks, wallpaper).
  #   wl-clipboard/playerctl/udiskie are already in home/packages.nix.
  #   - polkit-gnome deliberately NOT installed: its XDG autostart .desktop
  #     registers first and forces Noctalia's own (themed) agent off
  #     (shell.polkit_agent in assets/noctalia/settings.toml).
  home.packages = with pkgs; [
    bluez
    upower
    # - dconf CLI: Noctalia's gtk template persists gtk-theme + prefer-dark
    #   through it. Without it Chromium's portal Settings.Read reports light.
    dconf
  ];
}
