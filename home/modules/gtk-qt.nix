{
  pkgs,
  ...
}:
{
  # GTK + Qt appearance. Noctalia's gtk3/gtk4/qt templates generate themes;
  # here we set the base icon/cursor themes and font overrides.
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
      size = 48;
    };
    font = {
      name = "CaskaydiaCove Nerd Font";
      size = 11;
    };
    theme = {
      name = "adw-gtk3-dark";
      package = pkgs.adw-gtk3;
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

  # Force dark color-scheme so apps that read prefers-color-scheme (e.g.
  # Chromium's own toolbar/tabs) render dark. GTK theme+CSS alone don't flip
  # the gsettings color-scheme that Chromium respects.
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
  };

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

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


  # Chromium on niri/Wayland must use the ozone Wayland frontend so it queries
  # the XDG portal for prefers-color-scheme (dark), otherwise it stays light.
  home.file.".config/chromium-flags.conf".text = ''
    --enable-features=UseOzonePlatform
    --ozone-platform-hint=auto
    --enable-features=WaylandWindowDecorations
    --gtk-version=4
  '';

  # Dolphin (Qt/KDE) reads the KDE icon theme from [Icons] in kdeglobals, not
  # GTK's iconTheme. Noctalia generates kdeglobals, so append the Icons section
  # idempotently instead of owning/clobbering the whole file.
  home.activation.setKdeIconTheme = ''
    kdeglobals="$HOME/.config/kdeglobals"
    if [ -f "$kdeglobals" ] && ! grep -q '^\[Icons\]' "$kdeglobals"; then
      printf '\n[Icons]\nTheme=Papirus-Dark\n' >> "$kdeglobals"
    fi
  '';


  home.pointerCursor = {
    enable = true;
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 48;
  };

  # Silence stateVersion deprecation: keep legacy gtk3 theme also on gtk4.
  gtk.gtk4.theme = null;
}
