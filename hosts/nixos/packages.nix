{ pkgs, inputs, ... }:
{
  imports = [
    inputs.helium-flake.nixosModules.default
  ];

  # Provide a Wayland session entry so the greeter can offer Niri.
  # pkgs.niri ships its own share/wayland-sessions/niri.desktop; adding it to
  # environment.systemPackages links it into /run/current-system/sw/share so the
  # greeter's session picker can list it.
  environment.systemPackages = with pkgs; [
    # --- Base tooling ---
    git
    curl
    vim
    fish
    niri

    # Apps that self-elevate via pkexec live in the SYSTEM profile (not
    # home.packages) because their polkit actions must register with the system
    # polkitd daemon — only systemProfile/share/polkit-1/actions is searched.
    # Without the action, pkexec falls back to the default action, strips
    # DISPLAY, and root GUI apps die with "cannot open display". The matched
    # action's allow_gui annotation then lets pkexec forward DISPLAY/XAUTHORITY.
    # (gparted: org.gnome.gparted; ettercap: org.pkexec.ettercap; meson:
    # com.mesonbuild.install.)
    gparted
    ettercap
    meson
    # related to meson
    ninja
    gcc
    clang-tools
    clang
    pkg-config

    # MTP kioslave + kmtpd so Dolphin can open phones via Solid (the worker
    # ships in kio-extras, which dolphin only pulls into its closure — it
    # must be a profile entry so the plugins land on QT_PLUGIN_PATH/XDG).
    kdePackages.kio-extras
    # admin:/ worker — browse/edit root-owned files from Dolphin with a
    # polkit prompt.
    kdePackages.kio-admin

    # System-wide copies of the theme stack so root pkexec GTK apps (gparted,
    # ettercap) resolve the same look: adw-gtk3-dark base + Papirus-Dark icons
    # + ComixCursors cursor. User-profile installs (~/.nix-profile) are outside
    # root's XDG_DATA_DIRS; these land in /run/current-system/sw/share, which
    # every user (incl. root) searches. See system-level gtk settings below.
    adw-gtk3
    papirus-icon-theme
    comixcursors.Black

    # GNS3 server — system-level (installed here for gns3-server daemon; the
    # GUI lives in home/packages.nix and spawns the server locally).
    gns3-server

    networkmanagerapplet

    linuxPackages.usbip
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # Add any missing dynamic libraries for unpackaged programs
    # here, NOT in environment.systemPackages
    lua
    lua-language-server
    marksman
  ];

  programs.helium.enable = true;
  programs.kdeconnect.enable = true;
}
