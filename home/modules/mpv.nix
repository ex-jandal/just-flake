{
  pkgs,
  ...
}: {
  # Media player. Config, scripts, script-opts and font ported verbatim from the
  # Arch ~/.config/mpv/ (mpv.conf: keep-open=yes/osc=no + memo/modernz/thumbfast
  # scripts). Removed the old from-scratch Noctalia/VA-API config — this
  # matches the user's real setup exactly.
  home.packages = with pkgs; [
    mpv
  ];

  # --- verbatim port of ~/.config/mpv/ ---
  home.file.".config/mpv/mpv.conf".source = ../../assets/mpv/mpv.conf;
  home.file.".config/mpv/script-opts".source = ../../assets/mpv/script-opts;
  home.file.".config/mpv/scripts".source = ../../assets/mpv/scripts;
  home.file.".config/mpv/fonts".source = ../../assets/mpv/fonts;

  # memo.conf writes its history log to ~/.config/mpv/memo-history.log.
  home.file.".config/mpv/memo-history.log".text = "";
}