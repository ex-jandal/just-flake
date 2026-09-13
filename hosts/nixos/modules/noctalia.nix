{ inputs, pkgs, ... }:
{
  imports = [
    inputs.noctalia.nixosModules.default
    inputs.noctalia-greeter.nixosModules.default
  ];

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
}
