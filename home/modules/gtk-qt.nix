{
  pkgs,
  ...
}:
{
  # GTK + Qt appearance. Noctalia owns the GTK theme colors + dconf color-scheme
  # (its gtk template writes noctalia.css + sets adw-gtk3-dark and the dconf
  # color-scheme); here we select the base dark theme, icon/cursor themes and
  # font override. Qt/KDE apps get the Noctalia palette via qt6ct (below).
  gtk = {
    enable = true;
    # Base dark theme for GTK apps + chromium native chrome; Noctalia's
    # gtk3/gtk4 templates overlay noctalia.css on top of it. Name only (no
    # package — pkgs.adw-gtk3 is already in home/packages): setting package
    # here makes HM claim gtk-4.0/gtk.css, which Noctalia owns as a real file.
    # HM then just writes gtk-theme-name into settings.ini.
    theme = {
      name = "adw-gtk3-dark";
    };
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
  # colors/noctalia.conf), so it stays in sync with theme changes; custom_
  # palette=true makes Qt honor it; style=Fusion gives the flat Noctalia look.
  home.file.".config/qt6ct/qt6ct.conf".text = ''
    [Appearance]
    color_scheme_path=/home/abu_jandal/.config/qt6ct/colors/noctalia.conf
    custom_palette=true
    style=Fusion
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
