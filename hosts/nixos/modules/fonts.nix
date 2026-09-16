{ pkgs, ... }:
{
  # - fonts moved here from home/packages.nix:
  #   - system-level registration: NixOS writes each font package into the
  #     fontconfig config by explicit store path, so its cache invalidates on
  #     every rebuild. Home Manager fonts land in ~/.nix-profile/share/fonts,
  #     whose store dirs keep a frozen 1970 mtime — fontconfig never rescans,
  #     and fonts added in a later rebuild stay invisible.
  #   - Rubik (the system sans-serif across Qt/Chromium/GTK) must be set here,
  #     not in ~/.config/fontconfig/fonts.conf — that HM-shipped file is a
  #     read-only store symlink with a frozen mtime, so the config cache never
  #     re-reads it after a change.
  fonts = {
    fontconfig.enable = true;
    fontconfig.defaultFonts.sansSerif = [ "Rubik" ];
    packages = with pkgs; [
      # - Nerd fonts (Arch: ttf-cascadia-code-nerd, ttf-cascadia-mono-nerd,
      #   ttf-jetbrains-mono-nerd, ttf-firacode-nerd, ttf-nerd-fonts-symbols)
      nerd-fonts.jetbrains-mono
      nerd-fonts.caskaydia-cove
      nerd-fonts.caskaydia-mono
      nerd-fonts.fira-code
      nerd-fonts.symbols-only
      # - Noto (Arch: noto-fonts + extra + emoji — extra variants bundled in
      #   this snapshot; cjk not separate here)
      noto-fonts
      noto-fonts-color-emoji
      # - Arch: ttf-joypixels
      joypixels
      # - Arch: ttf-material-design-icons-extended / material-icons-git /
      #   symbols-variable
      material-design-icons
      # - Arch: ttf-dejavu
      dejavu_fonts
      # - Arch: ttf-liberation
      liberation_ttf
      # - Arch: terminus-font
      terminus_font
      # - Arch: ttf-hack
      hack-font
      # - Arch: ttf-ubuntu-font-family
      ubuntu-classic
      # - Arch: ttf-roboto
      roboto
      # - Arch: ttf-twemoji
      twemoji-color-font
      # - Arch: ttf-weather-icons
      weather-icons
      # - Arch: adwaita-fonts
      adwaita-fonts
      # - Google Rubik font (5 weight Roman + Italic)
      rubik
      # - Arabic (Arch: ttf-amiri, ttf-scheherazade-new)
      amiri
      scheherazade-new
      # - CJK (Arch: noto-fonts-cjk) — large (~200MB), bundled per request
      noto-fonts-cjk-sans
      # - Arch: ttf-opensans
      open-sans
      # - Arch: ttf-roboto-flex (variable-width Roboto family)
      roboto-flex
      # - Arch: ttf-droid — Droid Sans Mono via the nerd-fonts set
      nerd-fonts.droid-sans-mono
      # - Arch: powerline-fonts (Powerline glyph set for prompt integrations)
      powerline-fonts
      # - Arch: woff2-font-awesome — OTF Font Awesome icon set (waybar/rofi
      #   glyphs)
      font-awesome
      # - Inter (clean UI sans, nice complement to Rubik)
      inter
      # - Unavailable in this snapshot: ttf-bitstream-vera, ttf-cairo, ttf-droid-
      #   sans (non-mono), ttf-gabarito, ttf-sil-lateef, ttf-gnu-free-fonts,
      #   otf-space-grotesk, separate rubik-vf
    ];
  };
}