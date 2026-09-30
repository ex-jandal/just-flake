{
  pkgs,
  lib,
  ...
}:
{
  # - GTK + Qt appearance. Noctalia owns the GTK colors and the dconf
  #   color-scheme; here we only pick the base dark theme, icons, cursor and
  #   font. Qt/KDE apps get the palette via the KColorScheme template qt6ct
  #   reads below.
  gtk = {
    enable = true;
    # - name only, no package: pkgs.adw-gtk3 is in home/packages, and setting
    #   package here makes HM claim gtk-4.0/gtk.css, which Noctalia owns.
    theme = {
      # - Noctalia renders the palette into ~/.config/gtk-{3,4}.0/noctalia.css
      #   and imports it from gtk.css, so apps honoring the overlay follow it.
      name = "adw-gtk3-dark";
    };
    # - explicit null: adw-gtk3-dark is GTK3-only, and GTK4 apps take
    #   Noctalia's gtk-4.0/gtk.css overlay + dconf prefer-dark instead.
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

  # - dconf.enable alone does not install the unit in this HM version, and
  #   without it dconfSettings fails with "unknown unit ca.desrt.dconf".
  #   Declared here because dconf's shipped D-Bus file points SystemdService
  #   at it, so the session bus activates it via the user systemd manager.
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
    # - qt6ct is the Qt platform theme; applies the Noctalia palette (see
    #   qt6ct.conf), icons, cursor and default font via fontconfig (Rubik).
    platformTheme.name = "qt6ct";
  };

  # - color_scheme_path is the palette Noctalia's qt template writes, in qt6ct's
  #   own [ColorScheme] format; custom_palette=true makes Qt honor it.
  #   - DO NOT point it at the KColorScheme .colors file: qt6ct cannot parse the
  #     KDE [Colors:*] format and silently falls back to the default palette
  #     (wrong text colors). KDE apps still get KColorScheme via kdeglobals.
  #   - style=Darkly is the darkly QStyle (fork of Lightly).
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

  # - gnome backend so Chromium picks up prefers-color-scheme via the Settings
  #   portal. FileChooser is forced to gtk: gnome >= 47 delegates file dialogs
  #   to Nautilus, which isn't installed, so pickers would never render.
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
  };

  home.pointerCursor = {
    enable = true;
    name = "ComixCursors-Black";
    package = pkgs.comixcursors.Black;
    size = 48;
  };

  # - KDE apps read their icon theme from kdeglobals [Icons] Theme, not from
  #   qt6ct, and fall back to hicolor without it. Noctalia owns and rewrites
  #   that file, so append at activation rather than symlinking (which would
  #   read-lock it): idempotent, respects a manual override, survives rewrites.
  home.activation.ensureKdeIconTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -e "$HOME/.config/kdeglobals" ] && ! grep -Eq '^\s*Theme=[^\s]*$' "$HOME/.config/kdeglobals"; then
      printf '\n[Icons]\nTheme=Papirus-Dark\n' >> "$HOME/.config/kdeglobals"
    fi
  '';
}
