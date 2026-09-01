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

  # gtk writes its settings through DConf; enable the user dconf.service unit
  # so the session bus can activate ca.desrt.dconf (its .service file declares
  # SystemdService=dconf.service). Without this, Home Manager's dconfSettings
  # activation fails with "Could not activate remote peer 'ca.desrt.dconf'".
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
