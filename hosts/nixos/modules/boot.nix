{ pkgs, ... }:
{
  boot = {
    # - boot loader: GRUB on UEFI (matches Arch); EFI-only, no legacy MBR
    loader = {
      efi.canTouchEfiVariables = true;
      grub = {
        enable = true;
        device = "nodev";
        efiSupport = true;
      };
    };

    # - plymouth boot splash (matches Arch plymouth)
    plymouth.enable = true;

    # - systemd initrd — NixOS's fast, minimal equivalent of Arch's booster,
    #   in place of the legacy stage-1 initrd
    initrd.systemd.enable = true;

    # - silent boot: hide text spam behind the splash
    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "splash"
      "rd.udev.log_level=3"
      "sysv.enabled=0"
    ];

    # - linux-zen kernel (matches Arch linux-zen + linux-zen-headers) —
    #   mainline + desktop-latency/CPU-scheduler tweaks; NixOS otherwise
    #   defaults to the LTS stable kernel
    kernelPackages = pkgs.linuxPackages_zen;
    kernelModules = [
      "vhci-hcd"
      "usbip-core"
      "usbip-host"
    ];
  };
}