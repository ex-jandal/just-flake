{ pkgs, ... }:
{
  boot = {
    # --- Boot loader: GRUB on UEFI (matches Arch) ---
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev"; # EFI-only install, no legacy MBR
        efiSupport = true;
      };
    };

    # --- Boot splash (matches Arch plymouth) ---
    plymouth.enable = true;

    # --- Initramfs: use the modern systemd initrd (NixOS's fast, minimal
    #     equivalent of Arch's booster) in place of the legacy stage-1 initrd. ---
    initrd.systemd.enable = true;

    # Enable silent boot to hide text spam behind the splash
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "rd.udev.log_level=3"
      "sysv.enabled=0"
    ];

    # --- Kernel: linux-zen (matches Arch linux-zen + linux-zen-headers) ---
    # Zen = mainline + desktop-latency/CPU-scheduler tweaks. 7.1.10 is the
    # newest Zen in this nixpkgs snapshot; NixOS otherwise defaults to the LTS
    # stable kernel.
    kernelPackages = pkgs.linuxPackages_zen;
    kernelModules = [
      "vhci-hcd"
      "usbip-core"
      "usbip-host"
    ];
  };
}
