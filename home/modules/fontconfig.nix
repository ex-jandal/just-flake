{
  ...
}:
{
  # - fontconfig: copies the user's fonts.conf (rgba off, hinting,
  #   hintstyle hintslight, antialias on, + user font dir).
  xdg.configFile."fontconfig/fonts.conf".source = ../../assets/fontconfig/fonts.conf;

  # - config references ~/.local/share/fonts; make sure the dir exists so
  #   fontconfig's <dir> doesn't warn.
  home.file.".local/share/fonts/.keep".text = "";
}
