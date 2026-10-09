{ pkgs, inputs, ... }:
{
  imports = [
    inputs.helium-flake.nixosModules.default
    inputs.artcraft.nixosModules.default
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

    # - pkexec apps must be in the SYSTEM profile, not home.packages: only
    #   systemProfile/share/polkit-1/actions is searched, and without the
    #   action pkexec strips DISPLAY so root GUI apps die. (gparted:
    #   org.gnome.gparted, ettercap: org.pkexec.ettercap, meson:
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

    # - same theme stack as the user profile, so root pkexec apps match. User
    #   profiles sit outside root's XDG_DATA_DIRS; these land in
    #   /run/current-system/sw/share, which every user searches.
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

  programs.artcraft = {
  enable = true;
  apps = [
    "photocraft"
    "vectorcraft"
    "filmcraft"
    "effectcraft"
  ];  # default: every app, newest version
  linkFonts = true;
  };

  programs.helium.enable = true;
  programs.kdeconnect.enable = true;

  programs.ghidra = {
    enable = true;
    package = pkgs.ghidra;
    gdb = true;
  };
}
