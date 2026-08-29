{
  ...
}:
{
  # fontconfig — copies the user's fontconfig/fonts.conf (rgba off, hinting,
  # hintstyle hintslight, antialias on, + user font dir).
  xdg.configFile."fontconfig/fonts.conf".source = ../../assets/fontconfig/fonts.conf;

  # Additionally the config references ~/.local/share/fonts; make sure the dir
  # exists so fontconfig's <dir> doesn't warn.
  home.file.".local/share/fonts/.keep".text = "";
}
