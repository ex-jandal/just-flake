{
  inputs,
  pkgs,
  system,
  ...
}:
{
  # Noctalia v5 — official home-manager module.
  # Uses the flake input (cachix branch, pre-built binary) so no quickshell needed.
  imports = [ inputs.noctalia.homeModules.default ];

  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    # Use the flake-provided package (pinned, cached) rather than nixpkgs' copy.
    package = inputs.noctalia.packages.${system}.default;
    # settings: attrset, TOML string, or path to a .toml file.
    settings = ../../assets/noctalia/settings.toml;
  };

  ## The Noctalia service wires into home-manager's wayland systemd target,
  ## which is part of home-manager core (no extra option needed here).

  # Supporting tools used by Noctalia features/services (bars, clipboard,
  # media, udisks, wallpaper). Plain home packages — NOT module options.
  home.packages = with pkgs; [
    wl-clipboard
    playerctl
    udiskie
    polkit_gnome
    bluez
    upower
    # dconf CLI — lets Noctalia's gtk template persist gtk-theme +
    # color-scheme="prefer-dark" into the dconf DB (its sync_system_appearance
    # silently skips when neither gsettings nor dconf is available). Without it
    # Chromium's portal Settings.Read reports light.
    dconf
  ];
}
