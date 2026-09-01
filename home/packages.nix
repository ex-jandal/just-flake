{
  pkgs,
  lib,
  ...
}:
let
  # Noctalia-baked GTK theme (colors compiled into the theme CSS so GTK4/
  # Chromium honor them regardless of the user gtk.css overlay).
  noctaliaGtkTheme = import ./modules/noctalia-gtk-theme.nix { inherit pkgs lib; };
in
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
      ];

      # --- Terminals ---
      terminals = with pkgs; [
        # kitty
        foot
        ghostty
        # alacritty
      ];

      utils = with pkgs; [
        # KDE file manager (Mod+E bind spawns dolphin).
        kdePackages.dolphin
        kdePackages.ark
        eog
        zathura
        mpv
        # Qt platform theme backend — applies Noctalia color scheme to Qt/KDE
        # apps (dolphin etc.). Selected via QT_QPA_PLATFORMTHEME=qt6ct.
        qt6Packages.qt6ct
        # Modern QStyle (fork of Lightly); selected as qt6ct style=Darkly.
        # Ships lib/qt-6/plugins/styles/darkly6.so + kdecoration3 plugin.
        darkly
      ];

      # --- Editors / language tooling ---
      editors = with pkgs; [
        neovim
        vim
        # codelldb (debugger) — install via NvChad/mason at runtime instead
        shellcheck
        tree-sitter
        nixd
      ];

        # --- WM / DE / Wayland tools ---
        wayland = with pkgs; [
          niri
          rofi
        kanshi
        nwg-displays
        # swaylock
        # swaybg
        slurp
        grim
        wl-clipboard
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
        polkit
        wlsunset
        ydotool
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
        mpv
        ffmpeg
        yt-dlp
        imagemagick
        obs-studio
        # kdenlive missing from this nixpkgs snapshot — re-add if available
        blender
        inkscape
        audacity
        easyeffects
        pavucontrol
        gpu-screen-recorder
        ffmpegthumbnailer
        # vlc
        imv
      ];

      # --- Browsers ---
      browsers = with pkgs; [
        # zen-browser not in this nixpkgs snapshot — re-add if available
        chromium
        # firefox
        # qutebrowser
        # w3m
      ];

      # --- Apps from the Arch inventory delta (see ARCH-INVENTORY.md §8) ---
      extras = with pkgs; [
        obsidian
        telegram-desktop
        signal-desktop
        qbittorrent
        # waybar
        # mako
        # swaylock
        # fuzzel
      ];

      # --- Dev toolchains / runtimes ---
      dev = with pkgs; [
        nodejs
        bun
        pnpm
        go
        rustup
        dotnet-sdk
        jdk
        maven
        gradle
        kotlin
        php
        python3
        uv
        zig
        odin
        docker
        docker-compose
        qemu
        mitmproxy
        nmap
        wireshark
        mariadb
        postgresql
        redis
        sqlite
        sqls
        sqlfluff
        glab
      ];

      # --- Security / CTF ---
      security = with pkgs; [
        aircrack-ng
        bettercap
        hashcat
        john
        proxychains
        radare2
        ghidra
        # r2ghidra not in this nixpkgs snapshot — re-add if available
        nmap
      ];

      # --- Noctalia ecosystem (theme plugin templates) ---
      theme = with pkgs; [
        matugen
        adw-gtk3
        noctaliaGtkTheme
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
    ++ browsers
    # ++ dev
    # ++ security
    ++ theme
    ++ extras;
}
