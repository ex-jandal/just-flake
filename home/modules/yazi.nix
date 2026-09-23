{
  pkgs,
  ...
}:
let
  yaziPlugins = pkgs.yaziPlugins;
  enablePlugins =
    names:
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value = {
          package = yaziPlugins.${name};
        };
      }) names
    );
in
{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    plugins = enablePlugins [
      "git"
      "lsar"
      "full-border"
      "mount"
      "smart-enter"
      "smart-filter"
      "toggle-pane"
      "vcs-files"
      "chmod"
      "mime-ext"
    ];
  };

  home.file.".config/yazi/yazi.toml".source = ../../assets/yazi/yazi.toml;
  home.file.".config/yazi/init.lua".source = ../../assets/yazi/init.lua;
  home.file.".config/yazi/keymap.toml".source = ../../assets/yazi/keymap.toml;
  home.file.".config/yazi/theme.toml".source = ../../assets/yazi/theme.toml;

  home.packages = with pkgs; [
    ueberzugpp
    ffmpegthumbnailer
    poppler-utils
  ];
}
