{ ... }:
{
  # - Audio: PipeWire
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  services.pipewire = {
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.quantum" = 1536;
        "default.clock.min-quantum" = 1024;
        "default.clock.max-quantum" = 2046;
      };
    };
  };

  services.pipewire.wireplumber.extraConfig = {
    "51-disable-suspension" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            { "node.name" = "~alsa_input.*"; }
          ];
          actions = {
            update-props = {
              "session.suspend-timeout-seconds" = 0;
            };
          };
        }
      ];
    };
  };
}
