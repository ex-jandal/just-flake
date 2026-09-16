{
  lib,
  config,
  pkgs,
  ...
}:
{
  # - TLP (settings ported from Arch /etc/tlp.conf). Noctalia's
  #   recommendedServices enables power-profiles-daemon; force it off because
  #   TLP and PPD fight over the same /sys power knobs.
  services.power-profiles-daemon.enable = lib.mkForce false;
  services.tlp = {
    enable = true;
    # - tlp-rdw (Radio Device Wizard) — pulled in when NetworkManager is
    #   enabled
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
  # - tlp-pd (powered devices daemon), matches Arch tlp-pd.
  services.tlp.pd.enable = true;
}