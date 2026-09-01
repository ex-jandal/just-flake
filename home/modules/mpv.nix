{
  pkgs,
  ...
}: {
  # Media player. Config favors the AMD VA-API hwdec path on the Ryzen/Barcelo
  # iGPU, keeps the window open after EOF, and mirrors the Noctalia look in the
  # OSD/controls. Subtitles/youtube handled by mpv defaults + yt-dlp.
  home.packages = with pkgs; [
    mpv
  ];

  home.file.".config/mpv/mpv.conf".text = ''
    # --- video ---
    hwdec=vaapi
    vo=gpu-next
    gpu-api=vulkan
    scale=ewa_lanczossharp
    video-sync=display-resample

    # --- playback ---
    keep-open=yes
    save-position-on-quit=yes
    cache=yes
    force-window=yes

    # --- youtube ---
    ytdl-format=bestvideo[height<=?1080]+bestaudio/best

    # --- audio ---
    audio-channels=stereo
    volume-max=150

    # --- Noctalia OSD colors ---
    osd-color="#e8ece4"
    osd-border-color="#101510"
    osd-font="Rubik"
    osd-font-size=28
    sub-color="#e8ece4"
    sub-border-color="#101510"
    sub-blur=0
    sub-font="Rubik"
  '';

  # Minimal extra keybindings on top of mpv defaults.
  home.file.".config/mpv/input.conf".text = ''
    KP1 add volume -5
    KP7 add volume 5
  '';
}