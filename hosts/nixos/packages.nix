{
  pkgs,
  inputs,
  ...
}:
let
  android-emu-libs = with pkgs; [
    # Audio
    libpulseaudio

    # X11
    libx11
    libxcb
    libxkbcommon
    libxkbfile
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxtst

    # X11 utility libraries
    libxcb-wm
    libxcb-render-util
    libxcb-keysyms
    libxcb-image
    libxcb-cursor
    libsm
    libice

    # Graphics
    libGL
    libdrm
    libpng

    # System/runtime libraries
    glib
    zlib
    expat
    libbsd
    libuuid
    nspr
    nss
    dbus
    alsa-lib

    # C/C++ runtime
    stdenv.cc.cc.lib
    llvmPackages.libcxx

    # Other
    protobuf
    abseil-cpp
    gperftools
  ];

  # - Upstream's flake adds ninja/cmake to nativeBuildInputs, which lets
  #   ninja's setup-hook steal buildPhase/installPhase from the cargo hooks.
  #   It also installs only the bare binary, while winit dlopens libwayland.
  artcraft-launcher =
    inputs.artcraft-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs
      (old: {
        dontUseNinjaBuild = true;
        dontUseNinjaInstall = true;
        nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.makeWrapper ];
        postInstall = ''
          install -Dm644 ${old.src}/packaging/linux/ai.storyteller.artcraft-launcher.desktop \
            $out/share/applications/ai.storyteller.artcraft-launcher.desktop
          mkdir -p $out/share/icons
          cp -r ${old.src}/assets/app-icon/hicolor $out/share/icons/
        '';
        postFixup = ''
          wrapProgram $out/bin/artcraft-launcher \
            --prefix LD_LIBRARY_PATH : ${
              pkgs.lib.makeLibraryPath (
                with pkgs;
                [
                  wayland
                  libxkbcommon
                  libGL
                  mesa
                  vulkan-loader
                  libx11
                  libxcursor
                  libxrandr
                  libxi
                  libxcb
                  fontconfig
                  freetype
                  alsa-lib
                ]
              )
            }
        '';
      });
in
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
    proton-vpn
    wireguard-tools

    linuxPackages.usbip

    artcraft-launcher
  ];

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries =
    with pkgs;
    [
      # - add any missing dynamic libraries for unpackaged programs here,
      #   NOT in environment.systemPackages
      lua
      lua-language-server
      marksman

    ]
    ++ android-emu-libs; # for Android Emulator

  programs.helium.enable = true;
  programs.kdeconnect.enable = true;

  programs.ghidra = {
    enable = true;
    package = pkgs.ghidra;
    gdb = true;
  };
}
