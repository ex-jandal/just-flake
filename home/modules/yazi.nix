{
  pkgs,
  ...
}:
{
  # yazi — terminal file manager (git + full-border plugins).
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
  };

  home.file.".config/yazi/yazi.toml".source = ../../assets/yazi/yazi.toml;
  home.file.".config/yazi/init.lua".source = ../../assets/yazi/init.lua;
  home.file.".config/yazi/keymap.toml".source = ../../assets/yazi/keymap.toml;
  home.file.".config/yazi/theme.toml".source = ../../assets/yazi/theme.toml;
  home.file.".config/yazi/package.toml".source = ../../assets/yazi/package.toml;

  home.packages = with pkgs; [
    ueberzugpp
    ffmpegthumbnailer
    poppler-utils
  ];
}
