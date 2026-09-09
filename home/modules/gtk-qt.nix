{
  pkgs,
  lib,
  ...
}:
{
  # GTK + Qt appearance. Noctalia owns the GTK theme colors + dconf color-scheme
  # (its gtk template writes noctalia.css + overlays it via gtk-{3,4}.0/gtk.css,
  # and syncs adw-gtk3(-dark) + the dconf color-scheme); here we select the base
  # dark theme, icon/cursor themes and font override. Qt/KDE apps get the
  # Noctalia palette via the KColorScheme template picked up by qt6ct (below).
  gtk = {
    enable = true;
    # Base dark theme for GTK apps + chromium native chrome; Noctalia's
    # gtk3/gtk4 templates overlay noctalia.css on top of it. Name only (no
    # package — pkgs.adw-gtk3 is already in home/packages): setting package
    # here makes HM claim gtk-4.0/gtk.css, which Noctalia owns as a real file.
    # HM then just writes gtk-theme-name into settings.ini.
    theme = {
      # Plain adw-gtk3-dark base. Noctalia's gtk template (builtin_ids =
      # ["gtk3" "gtk4"]) renders the active palette into
      # ~/.config/gtk-{3,4}.0/noctalia.css and imports it from gtk.css, so
      # GTK apps that honor the overlay take on the Noctalia palette over the
      # adwaita base.
      name = "adw-gtk3-dark";
    };
    # gtk4.theme (26.05 default is null; pre-26.05 it silently fell back to
    # config.gtk.theme). adw-gtk3-dark is a GTK3-only theme, and GTK4 apps are
    # colored by Noctalia's gtk-4.0/gtk.css overlay + dconf prefer-dark anyway,
    # so there's no base theme to write for GTK4 — keep the explicit null.
    gtk4.theme = null;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "ComixCursors-Black";
      package = pkgs.comixcursors.Black;
      size = 48;
    };
    font = {
      name = "Rubik";
      size = 11;
    };
  };

  # gtk writes its settings through DConf. The ca.desrt.dconf.service file
  # shipped by dconf declares SystemdService=dconf.service, so the user session
  # bus activates dconf through the systemd user manager. Provide that unit
  # explicitly (dconf.enable alone doesn't install it in this HM version);
  # without it Home Manager's dconfSettings activation fails with
  # "Could not activate remote peer 'ca.desrt.dconf': unknown unit".
  systemd.user.services.dconf = {
    Unit = {
      Description = "User preferences database";
      Documentation = "man:dconf-service(1)";
    };
    Service = {
      ExecStart = "${pkgs.dconf.lib}/libexec/dconf-service";
      Type = "dbus";
      BusName = "ca.desrt.dconf";
      Restart = "on-failure";
    };
  };
  dconf.enable = true;

  qt = {
    enable = true;
    # qt6ct is the Qt platform theme; it applies the Noctalia palette (see
    # qt6ct.conf below), icons, cursor and the default font via fontconfig
    # (Rubik).
    platformTheme.name = "qt6ct";
  };

  # qt6ct is the platform theme for Qt/KDE apps: icon/cursor themes, default
  # font (fontconfig → Rubik), and the Noctalia color scheme. color_scheme_path
  # points at the palette Noctalia's qt template generates (~/.config/qt6ct/
  # colors/noctalia.conf) — qt6ct 0.11's loadColorScheme only parses its own
  # native format ([ColorScheme] group with active/inactive/disabled_colors),
  # which is exactly what that template writes; custom_palette=true makes Qt
  # honor it. Do NOT point it at the KColorScheme .colors file (~/.local/share/
  # color-schemes/noctalia.colors): qt6ct can't parse that (KDE [Colors:*])
  # format and silently falls back to the default system palette → wrong text
  # colors. KDE apps (Dolphin/Ark) still get the KColorScheme natively via
  # ~/.config/kdeglobals, which Noctalia's kcolorscheme template also writes.
  # style=Darkly paints widgets with the modern darkly QStyle (fork of Lightly)
  # on top of that palette.
  home.file.".config/qt6ct/qt6ct.conf".text = ''
    [Appearance]
    color_scheme_path=/home/abu_jandal/.config/qt6ct/colors/noctalia.conf
    custom_palette=true
    style=Darkly
    icon_theme=Papirus-Dark
    cursor_theme=ComixCursors-Black
    cursor_size=48
    standard_dialogs=default
    [Fonts]
    [Interface]
    standard_dialogs=default
    [IconTheme]
    [Settings]
  '';

  # Route XDG Desktop Portal through the GNOME backend so apps spawned in the
  # niri session can read the portal settings (org.freedesktop.impl.portal.
  # Settings), which is how Chromium/etc. honor prefers-color-scheme=dark.
  # Without a running portal, Chromium stays light despite dconf=prefer-dark.
  #
  # FileChooser is explicitly routed to the GTK portal: since xdg-desktop
  # -portal-gnome >= 47 the GNOME backend delegates file dialogs to Nautilus,
  # which isn't installed — so file pickers (zenity, Chromium upload/save,
  # VS Code open) would silently never render. The GTK portal draws the themed
  # GTK file dialog (matches the noctalia theme) and keeps the gnome backend
  # for ScreenCast/Screenshot/Settings, which niri relies on.
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "gnome" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
      niri = {
        default = [ "gnome" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };
    configPackages = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  home.pointerCursor = {
    enable = true;
    name = "ComixCursors-Black";
    package = pkgs.comixcursors.Black;
    size = 48;
  };

  # KDE apps (Dolphin/Ark) resolve their icon theme from KConfig, NOT from
  # qt6ct's platform theme: kiconthemes reads it from kdeglobals under
  # [Icons] Theme. Without it they fall back to a minimal theme (hicolor)
  # → most icons missing even though qt6ct.conf sets icon_theme=Papirus-Dark
  # (that only affects non-KDE Qt apps). kdeglobals is a real file Noctalia
  # owns and merges into on every theme run (it preserves unrelated groups
  # like [PreviewSettings]), so instead of symlinking over it (which would
  # read-lock the file) we append the [Icons] group at activation if no
  # Theme= choice is present yet — idempotent, respects a manual override,
  # and survives Noctalia's rewrites.
  home.activation.ensureKdeIconTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -e "$HOME/.config/kdeglobals" ] && ! grep -Eq '^\s*Theme=[^\s]*$' "$HOME/.config/kdeglobals"; then
      printf '\n[Icons]\nTheme=Papirus-Dark\n' >> "$HOME/.config/kdeglobals"
    fi
  '';
}
