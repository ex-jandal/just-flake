{
  pkgs,
  ...
}:
{
  # GTK + Qt appearance. Noctalia owns the GTK theme + dconf color-scheme
  # (its gtk template sets adw-gtk3-dark and gsettings/dconf color-scheme
  # itself); here we only set the base icon/cursor themes and font override.
  gtk = {
    enable = true;
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
    # qt6ct is the Qt platform theme; it supplies icon/cursor fonts and the
    # default font via fontconfig (Rubik). No Noctalia palette override —
    # Qt/KDE apps (dolphin) use the stock Qt look.
    platformTheme.name = "qt6ct";
  };

  # qt6ct is the platform theme for Qt/KDE apps: it supplies the icon/cursor
  # themes and the default font (resolved via fontconfig → Rubik). No custom
  # palette/style is pinned here — older hand-overrides (color_scheme_path,
  # custom_palette, style=Fusion) made dolphin render off; it now uses the
  # stock Qt look while keeping the icon/cursor set.
  home.file.".config/qt6ct/qt6ct.conf".text = ''
    [Appearance]
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
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gnome ];
    config = {
      common = {
        default = [ "gnome" ];
      };
      niri = {
        default = [ "gnome" ];
      };
    };
    configPackages = [ pkgs.xdg-desktop-portal-gnome ];
  };

  home.pointerCursor = {
    enable = true;
    name = "ComixCursors-Black";
    package = pkgs.comixcursors.Black;
    size = 48;
  };
}
