{
  pkgs,
  ...
}:
{
  # Target platform for this host. Declared here (not passed as the deprecated
  # `system` arg to nixosSystem) per current nixpkgs guidance.
  nixpkgs.hostPlatform = "x86_64-linux";

  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Link Wayland session .desktop files into /run/current-system/sw/share so
  # the Noctalia greeter's session picker can enumerate them. system.path's
  # default pathsToLink omits /share/wayland-sessions, so without this no
  # session (incl. niri above) is ever visible to the greeter.
  environment.pathsToLink = [ "/share/wayland-sessions" ];

  # Keep the X session + Wayland dir through sudo so root GUI apps (gparted,
  # etc.) can open a display under niri. sudo's default env_reset keeps only a
  # minimal env; without DISPLAY/XAUTHORITY/XDG_RUNTIME_DIR a root GUI app
  # dies with "cannot open display".
  security.sudo.extraConfig = "Defaults env_keep += \"DISPLAY XAUTHORITY XDG_RUNTIME_DIR\"";

  # Hardware (filesystems, boot.initrd, GPU) — auto-generated. See hardware.nix.
  imports = [
    ./hardware.nix
    ./modules/boot.nix
    ./modules/network.nix
    ./modules/noctalia.nix
    ./modules/services.nix
    ./modules/power-management.nix
    ./modules/fonts.nix
    ./packages.nix
  ];

  # --- GPU/driver placeholder — confirm the laptop GPU ---
  # The original Arch box used open-source AMD (amdgpu/vulkan-radeon).
  # On NixOS, amdgpu needs no extra packages (mesa ships it). For NVIDIA set
  # hardware.nvidia.* + services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  # --- Audio: PipeWire ---
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # 1. Enable the Core GVfs Service (Includes MTP and network backends by default)
  services.gvfs.enable = true;
  services.udisks2.enable = true; # Handles disk mounting

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

  security.polkit = {
    enable = true;
    enablePkexecWrapper = true;
  };

  services.openssh.enable = true;

  # Register dconf's D-Bus activation file so the user session bus can start
  # the dconf-service. Without it, Home Manager's dconfSettings activation
  # fails with "ca.desrt.dconf: The name is not activatable".
  services.dbus.packages = [ pkgs.dconf ];

  # Swap file in nixos
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024; # 8 GiB
    }
  ];

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
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # Noctalia binary cache (kept separate from the flake's nixConfig).
      extra-substituters = [ "https://noctalia.cachix.org" ];
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
  };

  system.stateVersion = "25.05";
}
