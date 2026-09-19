{
  pkgs,
  ...
}:
# - mapped from `pacman -Qqe`/`-Qqm` + config refs
# - unfree allowed via nixpkgs.config.allowUnfreePredicate in home/default.nix
# - some AUR-only apps are NOT in nixpkgs and are documented in README
# - browser/modern apps exposed as options below to keep the list tidy
{
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
        fastfetch
        starship
        yazi
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
      ];

      terminals = with pkgs; [
        # - kitty
        foot
        ghostty
        # - alacritty needed by qutebrowser config (editor + fileselect spawn)
        alacritty
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
        zathura
        # - qt6ct: Qt platform theme — applies Noctalia palette to Qt/KDE
        #   apps (dolphin etc.). Selected via QT_QPA_PLATFORMTHEME=qt6ct.
        qt6Packages.qt6ct
        # - darkly: modern QStyle (fork of Lightly); qt6ct style=Darkly
        #   (lib/qt-6/plugins/styles/darkly6.so + kdecoration3 plugin)
        darkly
        libreoffice
        # - inkscape
        # - evince
        pdftk
        qpdf
        # - kew
        atool
        aria2
        libimobiledevice
        opencode
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
      ];

      wayland = with pkgs; [
        niri
        rofi
        kanshi
        nwg-displays
        flameshot
        # - swaylock
        # - swaybg
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
        # - blender
        # - inkscape
        audacity
        easyeffects
        pavucontrol
        gpu-screen-recorder
        ffmpegthumbnailer
        # - vlc
        imv
        gifski
        resvg
        scrcpy
      ];

      browsers = with pkgs; [
        # - zen-browser not in this snapshot — re-add if available
        chromium
        # - firefox
        # - w3m
      ];

      social = with pkgs; [
        telegram-desktop
        signal-desktop
        legcord
        zapzap
      ];

      extras = with pkgs; [
        # - apps from the Arch inventory delta (see ARCH-INVENTORY.md §8)
        obsidian
        # - qbittorrent
        waybar
        # - mako
        swaylock
        fuzzel
        mpd
        localsend
        sioyek
        # -  super-productivity
        anki
        # - tigervnc
        freerdp
        # - xchm
        # - drawio
      ];

      lab = with pkgs; [
        # - Cisco Packet Tracer 9.0.1 (unfree): built from the official deb;
        #   newer than nixpkgs's cisco-packet-tracer_9 (9.0.0). Register the
        #   deb once: nix-store --add-fixed sha256
        #   ~/Downloads/CiscoPacketTracer_901_Ubuntu_64bit.deb
        (pkgs.callPackage ./packages/packet-tracer-901.nix { })
        # - gns3-gui: spawns gns3-server locally
        gns3-gui
        # - gns3-server
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
        # - ostinato
        haguichi
        bmon
        cpufetch
      ];

      network = with pkgs; [
        # - bind
        # - ipcalc
        # - dnscrypt-proxy
        # - cloudflared
        # - openvpn
        # - tinyproxy
        # - virt-manager
        virt-viewer
        dnsmasq
        hostapd
        iw
        haveged
        # - sniffnet
        # - linux-wifi-hotspot
      ];

      game = with pkgs; [
        # - wine
        # - wine64
        # - winetricks
        # lutris
        # - mangohud
      ];

      dev = with pkgs; [
        devenv
        nodejs
        bun
        pnpm
        go
        rustup
        dioxus-cli
        # - dotnet-sdk
        jdk
        # - maven
        gradle
        # - kotlin
        # - php
        python3
        uv
        # - odin
        # - docker
        # - docker-compose
        # - qemu_full listed in the lab block (QEMU for GNS3/VMs)
        # - mitmproxy
        # - nmap
        # - mariadb
        # - postgresql
        # - redis
        # - sqlite
        # - sqls
        # - sqlfluff
        # - glab
        gdb
        # - valgrind
        nasm
        # - mdbook
        # - c3c
        neovide
        # - ollama
        calc
        zigPackages."0.16"
      ];

      security = with pkgs; [
        # - aircrack-ng
        # - bettercap
        # - hashcat
        # - john
        proxychains-ng
        # - radare2
        # - r2ghidra not in this snapshot — re-add if available
        # - nmap
        burpsuite
        # - ida-free
        yersinia
        # - crunch
        # - rockyou
        # - exiftool
        # - showmethekey
        # - anonymous overlay network + tooling (Tor config in hosts/nixos)
        # - tor
        torsocks
        tor-browser
      ];

      theme = with pkgs; [
        matugen
        # - adw-gtk3 moved to environment.systemPackages (hosts/nixos) so root
        #   pkexec GTK apps resolve the theme via system XDG_DATA_DIRS
        # - comixcursors .Black: multi-output, base `out` is empty — the .Black
        #   output is what niri references (xcursor-theme "ComixCursors-Black")
        comixcursors.Black
      ];

      # - fonts moved to NixOS fonts.packages (hosts/nixos/default.nix) —
      #   system registration fixes fontconfig rescanning of store dirs.
    in
    cli
    ++ terminals
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
