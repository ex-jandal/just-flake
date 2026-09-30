{
  pkgs,
  inputs,
  ...
}:
# - mapped from `pacman -Qqe`/`-Qqm` + config refs. Unfree allowed via
#   nixpkgs.config.allowUnfreePredicate in home/default.nix. AUR-only apps are
#   not in nixpkgs; see README. Zen browser is enabled as a module above.
{
  imports = [
    inputs.zen-browser.homeModules.default
  ];

  programs.zen-browser.enable = true;

  home.packages =
    let
      cli = with pkgs; [
        eza
        zoxide
        fzf
        fd
        ripgrep
        bat
        btop
        htop
        tree
        jq
        yq
        glow
        onefetch
        starship
        tealdeer
        unzip
        unrar
        p7zip
        zip
        uutils-coreutils
        trash-cli
        lorem
        imgcat
        chafa
        clolcat
        fortune
        pokego
        wget
        curl
        rusbmux
        file
        nix-your-shell
        ghostscript
        tesseract
        pdfminer
      ];

      utils = with pkgs; [
        # - dolphin: KDE file manager (Mod+E bind spawns it)
        kdePackages.dolphin
        # - dolphin thumbnails (videos via ffmpegthumbs, images via
        #   kimageformats)
        kdePackages.ffmpegthumbs
        kdePackages.kimageformats
        kdePackages.ark
        kdePackages.systemsettings
        # - ranger: file selector for qutebrowser fileselect.*
        #   (choosefile/choosedir)
        ranger
        nautilus
        eog
        # - qt6ct: Qt platform theme — applies Noctalia palette to Qt/KDE
        #   apps (dolphin etc.). Selected via QT_QPA_PLATFORMTHEME=qt6ct.
        qt6Packages.qt6ct
        # - darkly: modern QStyle (fork of Lightly); qt6ct style=Darkly
        #   (lib/qt-6/plugins/styles/darkly6.so + kdecoration3 plugin)
        darkly
        libreoffice
        pdftk
        qpdf
        atool
        aria2
        libimobiledevice
      ];

      editors = with pkgs; [
        neovim
        vim
        # - codelldb (debugger): install via NvChad/mason at runtime instead
        shellcheck
        tree-sitter
        nixd
        fish-lsp
        mesonlsp
        # - lspmux: shares one language-server instance across editors
        lspmux
        nixfmt
      ];

      wayland = with pkgs; [
        niri
        kanshi
        nwg-displays
        flameshot
        slurp
        grim
        wl-clipboard
        # - fuse3: required by xdg-desktop-portal to mount /run/user/<uid>/doc
        #   (portal FileChooser handles) — without fusermount3 pickers error/blank
        fuse3
        # - xwayland-satellite: niri creates X11 sockets + spawns it on demand
        #   when an X11 client connects — needed by xdg-desktop-portal-gtk
        #   (GTK3) for the FileChooser dialog
        xwayland-satellite
        wl-mirror
        wtype
        wmenu
        uwsm
        cliphist
        playerctl
        xdg-desktop-portal
        xdg-desktop-portal-wlr
        # - gnome portal: provides portal.Settings so Chromium/etc read
        #   prefers-color-scheme (niri uses this, not the wlroots portal)
        xdg-desktop-portal-gnome

        wlsunset
        ydotool
        gnome-calculator
        gnome-disk-utility
        gnome-text-editor
        gnome-font-viewer
        udiskie
        usbutils
        testdisk
        gpart
        cifs-utils
        ntfs3g
      ];

      git = with pkgs; [
        # - git binary comes via the programs.git module (not pkgs.git)
        gh
        lazygit
        lazydocker
        just
        gitui
      ];

      media = with pkgs; [
        ffmpeg
        yt-dlp
        imagemagick
        kdePackages.kdenlive
        inkscape
        audacity
        easyeffects
        pavucontrol
        gpu-screen-recorder
        ffmpegthumbnailer
        imv
        gifski
        resvg
        scrcpy
      ];

      browsers = with pkgs; [
        chromium
        w3m
      ];

      social = with pkgs; [
        telegram-desktop
        # - signal-desktop: override forces the gnome-libsecret keyring
        #   (Electron password store) so it unlocks on non-GNOME desktops
        #   instead of always asking for a nonexistent master password.
        signal-desktop
        legcord
        zapzap
      ];

      extras = with pkgs; [
        # - apps from the Arch inventory delta (see ARCH-INVENTORY.md §8)
        obsidian
        waybar
        swaylock
        fuzzel
        mpd
        localsend
        sioyek
        super-productivity
        anki
        freerdp
      ];

      lab = with pkgs; [
        # - unfree, newer than nixpkgs's cisco-packet-tracer_9 (9.0.0). Build
        #   needs the deb registered once: nix-store --add-fixed sha256
        #   ~/Downloads/CiscoPacketTracer_901_Ubuntu_64bit.deb
        (pkgs.callPackage ./packages/packet-tracer-901.nix { })
        # - gns3-gui: spawns gns3-server locally
        gns3-gui
        dynamips
        vpcs
        ubridge
        inetutils
        # - qemu_full: QEMU for GNS3/VMs (dev block uses qemu_full too)
        wireshark
        tcpdump
        traceroute
        netcat-openbsd
        nethogs
        haguichi
        bmon
        cpufetch
      ];

      network = with pkgs; [
        virt-viewer
        dnsmasq
        hostapd
        iw
        haveged
      ];

      game = with pkgs; [
        # - on PATH for a normal shell, sharing ~/.wine with lutris. The
        #   lutris package itself comes from programs.lutris (modules/lutris.nix),
        #   which puts the same wine build inside its FHS sandbox.
        wineWow64Packages.stagingFull
        winetricks
        mangohud
        vkbasalt
        gamescope
      ];

      dev = with pkgs; [
        devenv
        nodejs
        bun
        pnpm
        go
        rustup
        dioxus-cli
        jdk
        gradle
        python3
        uv
        # - qemu_full listed in the lab block (QEMU for GNS3/VMs)
        gdb
        nasm
        neovide
        calc
        zigPackages."0.16"
      ];

      security = with pkgs; [
        proxychains-ng
        # - r2ghidra not in this snapshot — re-add if available
        burpsuite
        yersinia
        # - anonymous overlay network + tooling (Tor config in hosts/nixos)
        torsocks
        tor-browser
      ];

      theme = with pkgs; [
        matugen
        # - adw-gtk3 is in environment.systemPackages (hosts/nixos) so root
        #   pkexec apps resolve it via system XDG_DATA_DIRS. comixcursors: use
        #   the .Black output, its base `out` is empty and that is what niri
        #   references (xcursor-theme "ComixCursors-Black").
        comixcursors.Black
      ];

      # - fonts moved to NixOS fonts.packages (hosts/nixos/default.nix) —
      #   system registration fixes fontconfig rescanning of store dirs.
    in
    cli
    ++ utils
    ++ editors
    ++ wayland
    ++ git
    ++ media
    ++ social
    ++ browsers
    ++ dev
    ++ security
    ++ lab
    ++ network
    ++ game
    ++ theme
    ++ extras;
}
