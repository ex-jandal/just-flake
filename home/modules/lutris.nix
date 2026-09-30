{ pkgs, ... }:
{
  # - Windows game launcher. home-manager wraps it in an FHS env that ships no
  #   wine of its own, so the wine build is wired in two places: winePackages
  #   creates the runner symlink lutris discovers, and extraPackages puts the
  #   binary on the FHS PATH for winetricks.
  #   wine + the overlay libs also go in home/packages.nix so they work in a
  #   normal shell against the same ~/.wine prefix.
  programs.lutris = {
    enable = true;
    winePackages = [ pkgs.wineWow64Packages.stagingFull ];
    # - pins lutris's default version to the store build, otherwise it downloads
    #   its own wine into ~/.cache/lutris and ignores the one above.
    defaultWinePackage = pkgs.wineWow64Packages.stagingFull;
    # - run *inside* the FHS sandbox, not on the user's PATH. gamemode is the
    #   client CLI; the gamemoded daemon is programs.gamemode in hosts/nixos.
    extraPackages = with pkgs; [
      pkgs.wineWow64Packages.stagingFull
      winetricks
      mangohud
      vkbasalt
      gamescope
      gamemode
    ];
  };
}
