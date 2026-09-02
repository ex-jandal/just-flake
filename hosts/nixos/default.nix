# Phase 2 — NixOS system config for the nixos host.
#
# ACTIVE ONLY AFTER MIGRATING TO NIXOS.
# Currently this file is a stub; home-manager (home/default.nix) is the
# active, testable part right now (run: `home-manager build --flake .#nixos`).
#
# Steps to activate on NixOS:
#   1. Run `nixos-generate-config --root /` on the real machine and copy
#      the generated `hardware-configuration.nix` over hosts/nixos/hardware.nix.
#   2. Confirm GPU drivers + bootloader/filesystems (from hardware.nix).
#   3. Enable `nixosConfigurations.nixos` in flake.nix.
#   4. `sudo nixos-rebuild switch --flake .#nixos`

{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
{
  # Target platform for this host. Declared here (not passed as the deprecated
  # `system` arg to nixosSystem) per current nixpkgs guidance.
  nixpkgs.hostPlatform = "x86_64-linux";

  # Link Wayland session .desktop files into /run/current-system/sw/share so
  # the Noctalia greeter's session picker can enumerate them. system.path's
  # default pathsToLink omits /share/wayland-sessions, so without this no
  # session (incl. niri above) is ever visible to the greeter.
  environment.pathsToLink = [ "/share/wayland-sessions" ];

  # Hardware (filesystems, boot.initrd, GPU) — auto-generated. See hardware.nix.
  imports = [
    ./hardware.nix
    inputs.noctalia.nixosModules.default
    inputs.noctalia-greeter.nixosModules.default
  ];

  # --- Boot loader: GRUB on UEFI (matches Arch) ---
  boot.loader = {
    efi.canTouchEfiVariables = true;
    grub = {
      enable = true;
      device = "nodev"; # EFI-only install, no legacy MBR
      efiSupport = true;
    };
  };

  # --- Initramfs: use the modern systemd initrd (NixOS's fast, minimal
  #     equivalent of Arch's booster) in place of the legacy stage-1 initrd. ---
  boot.initrd.systemd.enable = true;

  # --- Boot splash (matches Arch plymouth) ---
  boot.plymouth.enable = true;

  # --- GPU/driver placeholder — confirm the laptop GPU ---
  # The original Arch box used open-source AMD (amdgpu/vulkan-radeon).
  # On NixOS, amdgpu needs no extra packages (mesa ships it). For NVIDIA set
  # hardware.nvidia.* + services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  # --- Kernel: linux-zen (matches Arch linux-zen + linux-zen-headers) ---
  # Zen = mainline + desktop-latency/CPU-scheduler tweaks. 7.1.10 is the
  # newest Zen in this nixpkgs snapshot; NixOS otherwise defaults to the LTS
  # stable kernel.
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # --- Networking (Noctalia needs NetworkManager) ---
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    # The dnscrypt-proxy module sets networking.nameservers = 127.0.0.1 when
    # enabled, which would route ALL system DNS through the proxy. Neutralize
    # with mkForce: dnscrypt-proxy runs in the background on 127.0.0.1:53 only,
    # and system DNS keeps using DHCP (192.168.122.1) until the Noctalia
    # dns-switcher plugin points it at the proxy on demand.
    nameservers = lib.mkForce [ ];
  };
  # Use iwd as the Wi-Fi backend for NetworkManager (matches Arch).
  networking.networkmanager.wifi.backend = "iwd";

  # --- DNSCrypt proxy (config ported from Arch /etc/dnscrypt-proxy/*) ---
  services.dnscrypt-proxy = {
    enable = true;
    settings = {
      server_names = [ "apple" "adnull" "quad9alpha" "envs" "v0dka" "shecan" ];
      listen_addresses = [ "127.0.0.1:53" ];
      max_clients = 250;
      ipv4_servers = true;
      ipv6_servers = false;
      require_dnssec = true;
      require_nolog = true;
      require_nofilter = true;
      force_tcp = false;
      timeout = 5000;
      keepalive = 30;
      bootstrap_resolvers = [ "9.9.9.11:53" "8.8.8.8:53" ];
      ignore_system_dns = true;
      block_ipv6 = false;
      block_unqualified = true;
      block_undelegated = true;
      cache = true;
      cache_size = 4096;
      cache_min_ttl = 2400;
      cache_max_ttl = 86400;
      cache_neg_min_ttl = 60;
      cache_neg_max_ttl = 600;
      # Ad/tracker blocklist + safesearch cloaking from Arch.
      # blocked_names/blocked_ips are TOML tables (keyed by *_file);
      # cloaking_rules/forwarding_rules are TOML strings (a single file path).
      # Nesting the later two as tables makes dnscrypt-proxy abort at startup
      # ("...value has type map[string]any; destination has type string"),
      # which kills all DNS (resolv.conf -> dead 127.0.0.1 stub).
      blocked_names = {
        blocked_names_file = ../../assets/dnscrypt/blocked-names.txt;
      };
      blocked_ips = {
        blocked_ips_file = ../../assets/dnscrypt/blocked-ips.txt;
      };
      cloaking_rules = ../../assets/dnscrypt/cloaking-rules.txt;
      forwarding_rules = ../../assets/dnscrypt/forwarding-rules.txt;
    };
  };

  # --- Noctalia recommended services: NetworkManager + Bluetooth +
  #     UPower + power-profiles-daemon ---
  programs.noctalia = {
    enable = true;
    recommendedServices.enable = true;
  };

  # --- Display manager: greetd + Noctalia Greeter ---
  # The greeter user is required by the noctalia-greeter module (it reads
  # services.greetd default_session.user).
  users.users.greeter = {
    isSystemUser = true;
    group = "greeter";
    description = "Noctalia Greeter account";
  };
  users.groups.greeter = { };

  programs.noctalia-greeter = {
    enable = true;
    package = inputs.noctalia-greeter.packages.${pkgs.stdenv.hostPlatform.system}.default;
    settings = {
      session.default = "niri";
      # Reduce greeter rendering overhead (VM has no GPU — software renderer).
      appearance.corner_radius_scale = 0;
      appearance.hide_logo = true;
    };
  };
  services.greetd.enable = true;
  # Ensure greetd does not auto-select the console session over the greeter.
  services.greetd.settings.default_session.user = "greeter";

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
  ];

  # --- Fonts (moved here from home/packages.nix) ---
  # System-level registration: NixOS writes each font package into the
  # fontconfig config by its explicit store path, so fontconfig's cache
  # invalidates properly on every rebuild. Fonts installed via Home Manager
  # instead land in ~/.nix-profile/share/fonts, whose store dirs keep the
  # frozen 1970 mtime — fontconfig then never rescans, and fonts added in a
  # later rebuild (Rubik) stay invisible.
  fonts = {
    fontconfig.enable = true;
    # Rubik is the system sans-serif across the platform stack (Qt via qt6ct,
    # Chromium, GTK). Set here (not in ~/.config/fontconfig/fonts.conf) —
    # that HM-shipped file is a read-only store symlink with a frozen mtime,
    # so fontconfig's config cache never re-reads it after a change.
    fontconfig.defaultFonts.sansSerif = [ "Rubik" ];
    packages = with pkgs; [
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
      # Arabic (Arch: ttf-amiri, ttf-scheherazade-new).
      amiri
      scheherazade-new
      # CJK (Arch: noto-fonts-cjk). Large (~200MB) — bundled here per request.
      noto-fonts-cjk-sans
      # Arch: ttf-opensans
      open-sans
      # Arch: ttf-roboto-flex (variable-width Roboto family).
      roboto-flex
      # Arch: ttf-droid — Droid Sans Mono via the nerd-fonts set.
      nerd-fonts.droid-sans-mono
      # Arch: powerline-fonts (Powerline glyph set for prompt integrations).
      powerline-fonts
      # Arch: woff2-font-awesome — OTF Font Awesome icon set (waybar/rofi glyphs).
      font-awesome
      # Extra: Inter (clean UI sans, nice complement to Rubik).
      inter
      # Unavailable in this nixpkgs snapshot: ttf-bitstream-vera, ttf-cairo
      # (no font pkg), ttf-droid-sans (non-mono), ttf-gabarito, ttf-sil-lateef,
      # ttf-gnu-free-fonts, otf-space-grotesk, separate rubik-vf.
    ];
  };

  # --- Bluetooth ---
  hardware.bluetooth.enable = true;

  # --- Optional services (installed, but DISABLED at boot) ---
  # Docker/DBs/libvirt/ollama ship with their daemons present so the tools
  # "just work" once the user starts them; they're not auto-started to keep the
  # VM idle-memory low. Start manually with:
  #   systemctl start docker redis mariadb postgresql libvirtd ollama mpd
  # or `sudo systemctl enable --now <unit>` to persist across reboots.
  virtualisation.docker.enable = false;
  virtualisation.libvirtd = { enable = false; qemu.enable = false; };
  services.redis.servers."".enable = false;
  # Music player daemon (mpd installed) — disabled by default.
  services.mpd.enable = false;
  # MariaDB/MySQL in nixpkgs lives under services.mysql.
  services.mysql = {
    enable = false;
    package = pkgs.mariadb;
  };
  services.postgresql.enable = false;
  # ollama has no NixOS module in this snapshot — provide a (disabled) systemd
  # unit so `systemctl start ollama` works.
  systemd.services.ollama = {
    description = "Ollama local LLM server";
    wantedBy = [ ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.ollama}/bin/ollama serve";
      Restart = "on-failure";
    };
  };

  # --- Tor (ENABLED) — anonymous SOCKS proxy + HTTP via Privoxy ---
  # services.tor.enable alone exposes a "slow" SOCKS proxy on 127.0.0.1:9050
  # (new circuit per destination). client.enable keeps that 9050 listener.
  # Privoxy (enableTor) adds an 8118 HTTP proxy that forwards to Tor's "fast"
  # SOCKS on 9063 (new circuit every 10 min) — see the NixOS wiki. No relay /
  # exit / bridge: client only. proxychains' ProxyList (home/modules/
  # proxychains.nix) and torsocks use the same 9050/9063/8118 ports.
  services.tor = {
    enable = true;
    client.enable = true;
  };
  # Privoxy HTTP proxy -> Tor fast SOCKS. enableTor wires forward-socks5 to
  # 127.0.0.1:9063 and extends tor SOCKSPort accordingly.
  services.privoxy = {
    enable = true;
    enableTor = true;
  };

  # --- Audio: PipeWire ---
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # --- Power management: TLP (settings ported from Arch /etc/tlp.conf) ---
  # Noctalia's recommendedServices enables power-profiles-daemon; we force it
  # off because TLP and PPD fight over the same /sys power knobs.
  services.power-profiles-daemon.enable = lib.mkForce false;
  services.tlp = {
    enable = true;
    # Radio Device Wizard (tlp-rdw) — pulled in when NetworkManager is enabled.
    package = pkgs.tlp.override {
      enableRDW = config.networking.networkmanager.enable;
    };
    settings = {
      TLP_PROFILE_BAT = "SAV";
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_SCALING_GOVERNOR_ON_SAV = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "balance_performance";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_SAV = "power";
      CPU_BOOST_ON_AC = 1;
      CPU_BOOST_ON_BAT = 0;
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";
      PLATFORM_PROFILE_ON_SAV = "low-power";
      RADEON_DPM_PERF_LEVEL_ON_AC = "high";
      RADEON_DPM_PERF_LEVEL_ON_BAT = "low";
      USB_AUTOSUSPEND = 1;
    };
  };
  # tlp-pd (powered devices daemon), matches Arch tlp-pd.
  services.tlp.pd.enable = true;

  # --- Users ---
  users.users.abu_jandal = {
    isNormalUser = true;
    shell = pkgs.fish;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "docker"
      "libvirt"
    ];
  };

  services.openssh.enable = true;

  # Register dconf's D-Bus activation file so the user session bus can start
  # the dconf-service. Without it, Home Manager's dconfSettings activation
  # fails with "ca.desrt.dconf: The name is not activatable".
  services.dbus.packages = [ pkgs.dconf ];

  # fish is the user's login shell — enable it at the NixOS level so it lands
  # in /etc/shells and gets the nix dirs in PATH. Content is home-manager managed.
  programs.fish.enable = true;

  # --- Misc system settings ---
  # Allow unfree system packages (matches the home-manager predicate; needed
  # for the NixOS closure to build unrar, obs, etc).
  nixpkgs.config.allowUnfreePredicate = _: true;
  # JoyPixels emoji font separate license gate (same as home/default.nix).
  nixpkgs.config.joypixels.acceptLicense = true;

  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      # Noctalia binary cache (kept separate from the flake's nixConfig).
      extra-substituters = [ "https://noctalia.cachix.org" ];
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
  };

  system.stateVersion = "25.05";
}
