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
      name = "CaskaydiaCove Nerd Font";
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
    # qt6ct reads Noctalia's generated color scheme so Qt/KDE apps (dolphin)
    # take the Noctalia theme instead of falling back to GTK adw-gtk3.
    platformTheme.name = "qt6ct";
  };

  # Configure qt6ct to apply the Noctalia color scheme to Qt/KDE apps
  # (dolphin). The palette file is written by Noctalia's qt template at
  # ~/.config/qt6ct/colors/noctalia.conf; this only selects it and the widget
  # style (Fusion is Qt built-in; the custom palette supplies the Noctalia
  # colors). Mirrors the working Arch qt6ct.conf layout.
  home.file.".config/qt6ct/qt6ct.conf".text = ''
    [Appearance]
    color_scheme_path=/home/abu_jandal/.config/qt6ct/colors/noctalia.conf
    custom_palette=true
    icon_theme=Papirus-Dark
    cursor_theme=ComixCursors-Black
    cursor_size=48
    style=Fusion
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