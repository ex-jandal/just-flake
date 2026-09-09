{ 
  pkgs,
  inputs, 
  ... 
}:
{
  imports = [
    inputs.xmcl.homeModules.xmcl
  ];

  programs.xmcl = {
    enable = true;
    # commandLineArgs = [
    #   "--password-store=\"gnome-libsecret\""
    # ];
    jres = with pkgs; [
      jre25_minimal
      jre
      jre8
      temurin-jre-bin-17
    ];
  }; 
}
