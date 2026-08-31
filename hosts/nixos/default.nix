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

  # --- Networking (Noctalia needs NetworkManager) ---
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
  };
  # Use iwd as the Wi-Fi backend for NetworkManager (matches Arch).
  networking.networkmanager.wifi.backend = "iwd";
  # Route the whole system's DNS through the local dnscrypt-proxy stub.
  networking.nameservers = [ "127.0.0.1" ];

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
      blocked_names = {
        blocked_names_file = ../../assets/dnscrypt/blocked-names.txt;
      };
      blocked_ips = {
        blocked_ips_file = ../../assets/dnscrypt/blocked-ips.txt;
      };
      cloaking_rules = {
        cloaking_rules_file = ../../assets/dnscrypt/cloaking-rules.txt;
      };
      forwarding_rules = {
        forwarding_rules_file = ../../assets/dnscrypt/forwarding-rules.txt;
      };
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
    # Remember the last session; default to Niri (name shown by the picker).
    settings = {
      session.default = "niri";
    };
  };
  services.greetd.enable = true;
  # Ensure greetd does not auto-select the console session over the greeter.
  services.greetd.settings.default_session.user = "greeter";

  # Provide a Wayland session entry so the greeter can offer Niri.
  # Uses uwsm so Niri runs under a proper systemd user session (needed for the
  # noctalia systemd user service wired through home-manager).
  environment.systemPackages = with pkgs; [
    # --- Base tooling ---
    git
    curl
    vim
    fish

    # --- Niri Wayland session entry (picked up by the greeter) ---
    (pkgs.writeTextDir "share/wayland-sessions/niri.desktop" ''
      [Desktop Entry]
      Type=Application
      Name=niri
      Comment=Niri Wayland compositor
      Exec=uwsm start niri
      X-Session-Type=wayland
      DesktopNames=niri
    '')
  ];

  # --- Bluetooth ---
  hardware.bluetooth.enable = true;

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
