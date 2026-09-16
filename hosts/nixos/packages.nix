{ pkgs, inputs, ... }:
{
  imports = [
    inputs.helium-flake.nixosModules.default
  ];

  # - Provide a Wayland session entry so the greeter can offer Niri (pkgs.niri
  #   ships its own niri.desktop; adding it to environment.systemPackages links
  #   it into /run/current-system/sw/share).
  environment.systemPackages = with pkgs; [
    git
    curl
    vim
    fish
    niri

    # - pkexec apps live in the SYSTEM profile (not home.packages) because
    #   their polkit actions must register with the system polkitd daemon —
    #   only systemProfile/share/polkit-1/actions is searched. Without the
    #   action, pkexec strips DISPLAY and root GUI apps die; the action's
    #   allow_gui annotation forwards DISPLAY/XAUTHORITY. (gparted:
    #   org.gnome.gparted; ettercap: org.pkexec.ettercap; meson:
    #   com.mesonbuild.install.)
    gparted
    ettercap
    meson
    ninja
    gcc
    clang-tools
    clang
    pkg-config

    # - MTP kioslave + kmtpd so Dolphin can open phones via Solid (the worker
    #   ships in kio-extras; it must be a profile entry so plugins land on
    #   QT_PLUGIN_PATH/XDG).
    kdePackages.kio-extras
    # - admin:/ worker — browse/edit root-owned files from Dolphin with a
    #   polkit prompt.
    kdePackages.kio-admin

    # - System-wide theme stack so root pkexec GTK apps (gparted, ettercap)
    #   resolve the same look: adw-gtk3-dark + Papirus-Dark + ComixCursors.
    #   User profiles are outside root's XDG_DATA_DIRS; these land in
    #   /run/current-system/sw/share, which every user (incl. root) searches.
    adw-gtk3
    papirus-icon-theme
    comixcursors.Black

    # - gns3-server: system-level daemon (the GUI lives in home/packages.nix
    #   and spawns the server locally).
    gns3-server

    networkmanagerapplet

    linuxPackages.usbip
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # - add any missing dynamic libraries for unpackaged programs here,
    #   NOT in environment.systemPackages
    lua
    lua-language-server
    marksman
  ];

  programs.helium.enable = true;
  programs.kdeconnect.enable = true;
}
