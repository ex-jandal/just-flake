{
  pkgs,
  lib,
  ...
}:
{
  systemd.user.services.lspmux = {
    Unit = {
      Description = "Language server multiplexer";
      After = "graphical-session.target";
    };
    Service = {
      Type = "simple";
      ExecStart = "${lib.getExe pkgs.lspmux} server";
      Restart = "on-failure";
      RestartSec = 3;
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  xdg.configFile."lspmux/config.toml".text = ''
    instance_timeout = 300
    gc_interval = 10
    listen = ["127.0.0.1", 27631]
    connect = ["127.0.0.1", 27631]
    log_filters = "info"
    pass_environment = ["*"]
  '';
}
