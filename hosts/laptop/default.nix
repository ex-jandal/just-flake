# Phase 2 — NixOS system config for the laptop host.
#
# ACTIVE ONLY AFTER MIGRATING TO NIXOS.
# Currently this file is a stub; home-manager (home/default.nix) is the
# active, testable part right now (run: `home-manager build --flake .#laptop`).
#
# Steps to activate on NixOS:
#   1. Run `nixos-generate-config --root /` on the real machine and copy
#      the generated `hardware-configuration.nix` over hosts/laptop/hardware.nix.
#   2. Confirm GPU drivers + bootloader/filesystems (from hardware.nix).
#   3. Enable `nixosConfigurations.laptop` in flake.nix.
#   4. `sudo nixos-rebuild switch --flake .#laptop`

{
  pkgs,
  inputs,
  lib,
  config,
  ...
}:
{
  # Hardware (filesystems, boot.initrd, GPU) — auto-generated. See hardware.nix.
  imports = [
    ./hardware.nix
    inputs.noctalia.nixosModules.default
    inputs.noctalia-greeter.nixosModules.default
  ];

  # --- GPU/driver placeholder — confirm the laptop GPU ---
  # The original Arch box used open-source AMD (amdgpu/vulkan-radeon).
  # On NixOS, amdgpu needs no extra packages (mesa ships it). For NVIDIA set
  # hardware.nvidia.* + services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  # --- Networking (Noctalia needs NetworkManager) ---
  networking = {
    hostName = "laptop";
    networkmanager.enable = true;
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
    package = inputs.noctalia-greeter.packages.${pkgs.system}.default;
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
