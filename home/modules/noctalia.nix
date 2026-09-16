{
  inputs,
  pkgs,
  system,
  ...
}:
{
  # - Noctalia v5 — official home-manager module.
  #   Uses the flake input (cachix branch, pre-built binary) so no quickshell
  #   is needed.
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

  # - supporting tools used by Noctalia features/services (bars, clipboard,
  #   media, udisks, wallpaper) — plain home packages, NOT module options.
  #   - polkit-gnome deliberately NOT installed: it ships an XDG autostart
  #     .desktop whose GTK agent registers first and forces Noctalia's own
  #     (themed) agent to disable itself (shell.polkit_agent = true in
  #     assets/noctalia/settings.toml). Noctalia's built-in agent handles auth.
  home.packages = with pkgs; [
    wl-clipboard
    playerctl
    udiskie
    bluez
    upower
    # - dconf CLI — lets Noctalia's gtk template persist gtk-theme +
    #   color-scheme="prefer-dark" into the dconf DB (its sync_system_appearance
    #   silently skips when neither gsettings nor dconf is available). Without it
    #   Chromium's portal Settings.Read reports light.
    dconf
  ];
}