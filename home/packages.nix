{
  pkgs,
  ...
}:
# Curated daily-use package list (mapped from `pacman -Qqe`/`-Qqm` + config refs).
#
# NOTE:
#  - Unfree allowed via nixpkgs.config.allowUnfreePredicate in home/default.nix
#  - Some AUR-only apps are NOT in nixpkgs and are documented in README
#  - Browser/modern apps exposed as options below to keep the list tidy
{
  home.packages =
    let
      # --- CLI / shell tooling ---
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
      ];

      # --- Terminals ---
      terminals = with pkgs; [
        # kitty
        foot
        ghostty
        # Needed by qutebrowser config (editor + file-select spawn alacritty).
        alacritty
      ];

      utils = with pkgs; [
        # KDE file manager (Mod+E bind spawns dolphin).
        kdePackages.dolphin
        kdePackages.ark
        # File selector for qutebrowser fileselect.* (choosefile/choosedir).
        ranger
        nautilus
        eog
        zathura
        # Qt platform theme backend — applies Noctalia color scheme to Qt/KDE
        # apps (dolphin etc.). Selected via QT_QPA_PLATFORMTHEME=qt6ct.
        qt6Packages.qt6ct
        # Modern QStyle (fork of Lightly); selected as qt6ct style=Darkly.
        # Ships lib/qt-6/plugins/styles/darkly6.so + kdecoration3 plugin.
        darkly
        # Office / documents / archive / transfer
        # libreoffice
        # inkscape
        # evince
        pdftk
        qpdf
        # kew
        atool
        aria2
        libimobiledevice
        opencode
      ];

      # --- Editors / language tooling ---
      editors = with pkgs; [
        neovim
        vim
        # codelldb (debugger) — install via NvChad/mason at runtime instead
        shellcheck
        tree-sitter
        nixd
        fish-lsp
      ];

      # --- WM / DE / Wayland tools ---
      wayland = with pkgs; [
        niri
        rofi
        kanshi
        nwg-displays
        flameshot
        # swaylock
        # swaybg
        slurp
        grim
        wl-clipboard
        # FUSE 3 userspace — required by xdg-document-portal to mount the
        # /run/user/<uid>/doc fuse fs that backs portal FileChooser handles.
        # Without fusermount3 on PATH, portal file pickers error out/blank.
        fuse3
        # XWayland server for niri (auto-integrated since 25.08): niri creates
        # the X11 sockets, exports $DISPLAY and spawns xwayland-satellite on
        # demand when an X11 client connects. Required by xdg-desktop-portal-gtk
        # (GTK3), which draws the FileChooser dialog over X11/XWayland — without
        # it the dialog never renders.
        xwayland-satellite
        wl-mirror
        wtype
        wmenu
        uwsm
        cliphist
        playerctl
        xdg-desktop-portal
        xdg-desktop-portal-wlr
        # gnome portal provides org.freedesktop.impl.portal.Settings so Chromium
        # / others read prefers-color-scheme from the portal (niri uses this,
        # not wlroots-only.xdg portal).
        xdg-desktop-portal-gnome

        wlsunset
        ydotool
        # Gnome helper apps
        gnome-calculator
        gnome-disk-utility
        gnome-font-viewer
        # Disk / USB / filesystem tools
        udiskie
        usbutils
        testdisk
        gpart
        cifs-utils
        ntfs3g
      ];

      # --- Git / tools ---
      git = with pkgs; [
        # (git provided via programs.git module — pkgs.git is a list here)
        gh
        lazygit
        lazydocker
        just
        gitui
      ];

      # --- Media / graphical ---
      media = with pkgs; [
        ffmpeg
        yt-dlp
        imagemagick
        # obs-studio
        # kdenlive missing from this nixpkgs snapshot — re-add if available
        # blender
        # inkscape
        # audacity
        easyeffects
        pavucontrol
        gpu-screen-recorder
        ffmpegthumbnailer
        # vlc
        imv
        gifski
        resvg
        scrcpy
      ];

      # --- Browsers ---
      browsers = with pkgs; [
        # zen-browser not in this nixpkgs snapshot — re-add if available
        chromium
        # firefox
        # w3m
      ];

      social = with pkgs; [
        telegram-desktop
        signal-desktop
        legcord
      ];

      # --- Apps from the Arch inventory delta (see ARCH-INVENTORY.md §8) ---
      extras = with pkgs; [
        # obsidian
        # qbittorrent
        waybar
        mako
        swaylock
        fuzzel
        mpd
        localsend
        sioyek
        # super-productivity
        # flameshot
        # tigervnc
        # freerdp
        # xchm
        # drawio
      ];

      # --- Network / lab (Cisco + GNS3 + capture/monitor) ---
      lab = with pkgs; [
        # Cisco Packet Tracer 9.0.1 (unfree) — built from the official deb in
        # ~/Downloads; newer than nixpkgs's cisco-packet-tracer_9 (9.0.0).
        # Requires the deb registered once: nix-store --add-fixed sha256
        # ~/Downloads/CiscoPacketTracer_901_Ubuntu_64bit.deb
        (pkgs.callPackage ./packages/packet-tracer-901.nix { })
        # GNS3 stack — shown from GUI, it spawns gns3-server locally.
        gns3-gui
        # gns3-server
        dynamips
        vpcs
        ubridge
        inetutils
        # QEMU full — GNS3/QEMU VMs (dev block uses qemu_full too).
        # qemu_full
        # Capture / monitor / infra
        wireshark
        tcpdump
        traceroute
        netcat-openbsd
        nethogs
        # ostinato
        haguichi
        bmon
        cpufetch
      ];

      # --- Network / infra (DNS, VPN, proxy, VM browsers) ---
      network = with pkgs; [
        # bind
        # whois
        # ipcalc
        # dnscrypt-proxy
        # cloudflared
        # openvpn
        # tinyproxy
        # virt-manager
        virt-viewer
        dnsmasq
        hostapd
        iw
        haveged
        # sniffnet
        # linux-wifi-hotspot
      ];

      # --- Games / Windows compat ---
      game = with pkgs; [
        # wine
        # wine64
        # winetricks
        # lutris
        # mangohud
      ];

      # --- Dev toolchains / runtimes ---
      dev = with pkgs; [
        nodejs
        bun
        pnpm
        go
        rustup
        # dotnet-sdk
        jdk
        # maven
        gradle
        # kotlin
        # php
        python3
        uv
        # odin
        # docker
        # docker-compose
        # qemu_full listed in the lab block (QEMU for GNS3/VMs)
        # mitmproxy
        # nmap
        # mariadb
        # postgresql
        # redis
        # sqlite
        # sqls
        # sqlfluff
        # glab
        gdb
        # valgrind
        nasm
        # mdbook
        # c3c
        neovide
        # ollama
        calc
        zigPackages."0.16"
      ];

      # --- Security / CTF ---
      security = with pkgs; [
        # aircrack-ng
        # bettercap
        # hashcat
        # john
        proxychains-ng
        # radare2
        # ghidra
        # r2ghidra not in this nixpkgs snapshot — re-add if available
        # nmap
        burpsuite
        # ida-free
        yersinia
        # crunch
        # rockyou
        # exiftool
        # showmethekey
        # polkit GUI auth agent — pkexec as root needs a running agent to show
        # an auth dialog outside a terminal (e.g. from the Noctalia launcher);
        # spawned in assets/niri/config.kdl.
        polkit_gnome
        # Anonymous overlay network + tooling (Tor config in hosts/nixos).
        # tor
        torsocks
        # tor-browser
      ];

      # --- Noctalia ecosystem (theme plugin templates) ---
      theme = with pkgs; [
        matugen
        # adw-gtk3 moved to environment.systemPackages (hosts/nixos) so root
        # pkexec GTK apps can resolve the theme via the system XDG_DATA_DIRS.
        # Cursor theme referenced by niri (xcursor-theme "ComixCursors-Black").
        # comixcursors is multi-output; use the .Black output (the base
        # `out` output is empty) so the cursor theme lands in the profile.
        comixcursors.Black
      ];

      # --- Fonts moved to NixOS fonts.packages (hosts/nixos/default.nix):
      #     system registration fixes fontconfig rescanning of store dirs. ---
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
