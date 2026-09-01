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
      ];

      # --- Terminals ---
      terminals = with pkgs; [
        # kitty
        foot
        ghostty
        # alacritty
      ];

      # --- Editors / language tooling ---
      editors = with pkgs; [
        neovim
        vim
        # codelldb (debugger) — install via NvChad/mason at runtime instead
        shellcheck
        tree-sitter
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
        # KDE file manager (Mod+E bind spawns dolphin).
        pkgs.kdePackages.dolphin
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
        # Cursor theme referenced by niri (xcursor-theme "ComixCursors-Black").
        # comixcursors is multi-output; use the .Black output (the base
        # `out` output is empty) so the cursor theme lands in the profile.
        comixcursors.Black
      ];

      # --- Fonts (mirror of the Arch font installs, mapped to nixpkgs) ---
      fonts = with pkgs; [
        # Nerd fonts (Arch: ttf-cascadia-code-nerd, ttf-cascadia-mono-nerd,
        # ttf-jetbrains-mono-nerd, ttf-firacode-nerd, ttf-nerd-fonts-symbols)
        nerd-fonts.jetbrains-mono
        nerd-fonts.caskaydia-cove
        nerd-fonts.caskaydia-mono
        nerd-fonts.fira-code
        nerd-fonts.symbols-only
        # Noto (Arch: noto-fonts, extra, emoji — noto-fonts bundles the
        # "extra" variants in this nixpkgs snapshot; cjk not separate here)
        noto-fonts
        noto-fonts-color-emoji
        # Arch: ttf-joypixels
        joypixels
        # Arch: ttf-material-design-icons-extended / material-icons-git / symbols-variable
        material-design-icons
        # Arch: ttf-dejavu
        dejavu_fonts
        # Arch: ttf-liberation
        liberation_ttf
        # Arch: terminus-font
        terminus_font
        # Arch: ttf-hack
        hack-font
        # Arch: ttf-ubuntu-font-family
        ubuntu-classic
        # Arch: ttf-roboto
        roboto
        # Arch: ttf-twemoji
        twemoji-color-font
        # Arch: ttf-weather-icons
        weather-icons
        # Arch: adwaita-fonts
        adwaita-fonts
        # Google Rubik font (5 weight Roman + Italic).
        rubik
        # NOTE: ttf-amiri, ttf-scheherazade-new, ttf-bitstream-vera,
        # ttf-cairo, ttf-droid, ttf-cjk not available in this nixpkgs snapshot.
      ];
    in
    cli
    ++ terminals
    ++ editors
    ++ wayland
    ++ git
    # ++ media
    ++ browsers
    # ++ dev
    # ++ security
    ++ theme
    ++ fonts;
}
