{
  pkgs,
  ...
}:
{
  # Starship prompt — copied verbatim from the existing config.
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = builtins.fromTOML (builtins.readFile ../../assets/starship.toml);
  };
}
