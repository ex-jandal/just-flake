{
  pkgs,
  ...
}: {
  # Qutebrowser (QtWebEngine browser, vim-inspired). Config ported verbatim
  # from the Arch ~/.config/qutebrowser/ (a self-contained git repo): gruvbox
  # theme, uBlock/StevenBlack adblock, container userscripts, custom bindings.
  #
  # Notes on verbatim port:
  #  - config.py sets NODE_PATH=/home/deve/... (stale username) — harmless, kept.
  #  - keepassxc / bitwarden / add-nextcloud-bookmarks / dark-toogle userscript
  #    bindings reference scripts not present on Arch either (dead bindings).
  #  - container userscripts use `rofi -dmenu` for the container picker.
  home.packages = with pkgs; [
    qutebrowser
  ];

  home.file.".config/qutebrowser/config.py".source = ../../assets/qutebrowser/config.py;
  home.file.".config/qutebrowser/gruvbox.py".source = ../../assets/qutebrowser/gruvbox.py;
  home.file.".config/qutebrowser/theme.py".source = ../../assets/qutebrowser/theme.py;
  home.file.".config/qutebrowser/styles".source = ../../assets/qutebrowser/styles;
  home.file.".config/qutebrowser/userscripts.sh".source = ../../assets/qutebrowser/userscripts.sh;
  home.file.".config/qutebrowser/userscript_urls.txt".source = ../../assets/qutebrowser/userscript_urls.txt;
  home.file.".config/qutebrowser/userscripts".source = ../../assets/qutebrowser/userscripts;

  # containers_config sources this file at runtime for the container list;
  # must exist (empty) on first run.
  home.file.".config/qutebrowser/containers".text = "";
}
