{
  pkgs,
  ...
}:
{
  nix.optimise.automatic = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # - system.path omits /share/wayland-sessions, so without this the Noctalia
  #   greeter's session picker shows no sessions at all.
  environment.pathsToLink = [ "/share/wayland-sessions" ];

  # - sudo's env_reset drops DISPLAY/XAUTHORITY/XDG_RUNTIME_DIR, so root GUI
  #   apps under niri die with "cannot open display" without this.
  security.sudo.extraConfig = "Defaults env_keep += \"DISPLAY XAUTHORITY XDG_RUNTIME_DIR\"";

  # - Hardware (filesystems, boot.initrd, GPU) — auto-generated. See hardware.nix.
  imports = [
    ./hardware.nix
    ./modules/boot.nix
    ./modules/network.nix
    ./modules/noctalia.nix
    ./modules/services.nix
    ./modules/power-management.nix
    ./modules/fonts.nix
    ./modules/audio.nix
    ./packages.nix
  ];

  # - GPU/driver placeholder — the original Arch box used open-source AMD
  #   (amdgpu/vulkan-radeon). On NixOS amdgpu needs no extra packages (mesa
  #   ships it); for NVIDIA set hardware.nvidia.* + videoDrivers = ["nvidia"].
  hardware.graphics.enable = true;

  # - Enable the Core GVfs Service (includes MTP and network backends by default)
  services.gvfs.enable = true;
  services.udisks2.enable = true; # - handles disk mounting

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

  services.gnome.gnome-keyring.enable = true;

  services.openssh.enable = true;

  # - Register dconf's D-Bus activation file so the user session bus can start
  #   the dconf-service. Without it, Home Manager's dconfSettings activation
  #   fails with "ca.desrt.dconf: The name is not activatable".
  services.dbus.packages = [ pkgs.dconf ];

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 8 * 1024;
    }
  ];

  # - fish is the user's login shell — enable it at the NixOS level so it lands
  #   in /etc/shells and gets the nix dirs in PATH. Content is home-manager managed.
  programs.fish.enable = true;

  # - Allow unfree system packages (matches the home-manager predicate; needed
  #   for the NixOS closure to build unrar, obs, etc).
  nixpkgs.config.allowUnfreePredicate = _: true;
  # - JoyPixels emoji font separate license gate (same as home/default.nix).
  nixpkgs.config.joypixels.acceptLicense = true;

  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      # - Noctalia binary cache (kept separate from the flake's nixConfig).
      extra-substituters = [ "https://noctalia.cachix.org" ];
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };
  };

  system.stateVersion = "25.05";
}
