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

  qt = {
    enable = true;
    platformTheme.name = "gtk3";
  };

  home.pointerCursor = {
    enable = true;
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 48;
  };

  # Silence stateVersion deprecation: keep legacy gtk3 theme also on gtk4.
  gtk.gtk4.theme = null;
}
