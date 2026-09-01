# Noctalia-coloured GTK theme package.
#
# Rationale: Chromium (151+) renders its native browser chrome through GTK4
# and does NOT load the per-user overlay ~/.config/gtk-4.0/gtk.css. When a GTK
# app is launched through some paths (e.g. Noctalia's launcher) the user-level
# CSS is ignored and the active theme's own CSS is used. The base
# adw-gtk3-dark theme bakes the adwaita accent (#3584e4 / @blue_3) and window
# colours into its bundled CSS (gtk-4.0/libadwaita-tweaks.css+libadwaita.css,
# gtk-3.0/gtk.css line 46), so Chromium shows those blue/teal defaults instead
# of Noctalia's green.
#
# Fix: bake the Noctalia palette straight into a copy of the theme. GTK
# resolves the last @define-color of a name, so appending the Noctalia
# definitions to the end of each theme CSS file makes every GTK app
# (Chromium included) pick them up at theme priority, independent of the user
# overlay or the launch path.
{ lib, pkgs }:
let
  overrideCss = ''
    @define-color accent_color #9ad4a1;
    @define-color accent_bg_color #9ad4a1;
    @define-color accent_fg_color #003916;

    @define-color destructive_bg_color #ffb4ab;
    @define-color destructive_fg_color #690005;

    @define-color error_bg_color #ffb4ab;
    @define-color error_fg_color #690005;

    @define-color window_bg_color #101510;
    @define-color window_fg_color #dfe4dc;

    @define-color view_bg_color #101510;
    @define-color view_fg_color #dfe4dc;

    @define-color headerbar_bg_color #101510;
    @define-color headerbar_fg_color #dfe4dc;
    @define-color headerbar_backdrop_color @window_bg_color;
    @define-color headerbar_shade_color rgba(0, 0, 0, 0.36);
    @define-color headerbar_darker_shade_color rgba(0, 0, 0, 0.55);

    @define-color popover_bg_color #101510;
    @define-color popover_fg_color #dfe4dc;

    @define-color card_bg_color #101510;
    @define-color card_fg_color #dfe4dc;
    @define-color card_shade_color rgba(0, 0, 0, 0.36);

    @define-color dialog_bg_color #101510;
    @define-color dialog_fg_color #dfe4dc;

    @define-color overview_bg_color #101510;
    @define-color overview_fg_color #dfe4dc;

    @define-color sidebar_bg_color #101510;
    @define-color sidebar_fg_color #dfe4dc;
    @define-color sidebar_backdrop_color @window_bg_color;
    @define-color sidebar_border_color @window_bg_color;

    @define-color secondary_sidebar_bg_color #101510;
    @define-color secondary_sidebar_fg_color #dfe4dc;

    @define-color thumbnail_bg_color #101510;
    @define-color thumbnail_fg_color #dfe4dc;

    @define-color shade_color rgba(0, 0, 0, 0.36);
    @define-color scrollbar_outline_color rgba(0, 0, 0, 0.55);

    /* Selection states */
    @define-color theme_selected_bg_color @accent_bg_color;
    @define-color theme_selected_fg_color @accent_fg_color;
    @define-color theme_unfocused_bg_color @window_bg_color;
    @define-color theme_unfocused_base_color @window_bg_color;
    @define-color theme_unfocused_selected_bg_color @accent_bg_color;
    @define-color theme_unfocused_selected_fg_color @accent_fg_color;
  '';

  base = pkgs.adw-gtk3;
in
pkgs.stdenv.mkDerivation {
  pname = "noctalia-gtk";
  version = "1.0.0";
  dontUnpack = true;
  buildInputs = [ base ];

  buildPhase = ''
    runHook preBuild
    mkdir -p $out/share/themes/noctalia/
    cp -r ${base}/share/themes/adw-gtk3-dark/. $out/share/themes/noctalia/
    chmod u+w $out/share/themes/noctalia/gtk-3.0/gtk.css $out/share/themes/noctalia/gtk-4.0/gtk.css $out/share/themes/noctalia/index.theme
    cat >> $out/share/themes/noctalia/gtk-3.0/gtk.css <<'OVERRIDE'
${overrideCss}
OVERRIDE
    cat >> $out/share/themes/noctalia/gtk-4.0/gtk.css <<'OVERRIDE'
${overrideCss}
OVERRIDE
    sed -i 's/Name=Adwaita-dark/Name=Noctalia/' $out/share/themes/noctalia/index.theme
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    runHook postInstall
  '';

  meta = {
    description = "adw-gtk3-dark re-themed with the Noctalia palette (colors baked into theme CSS so GTK4/Chromium honor them)";
    platforms = lib.platforms.linux;
  };
}
