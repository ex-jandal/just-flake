{ pkgs, lib, ... }:
{
  systemd.user.services.agentmemory = {
    Unit = {
      Description = "AgentMemory persistent memory server";
      After = [ "network.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.nodejs}/bin/npx --yes @agentmemory/agentmemory@latest";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [ "HOME=%h" ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  home.packages = [
    pkgs.nodejs
    (pkgs.writeShellScriptBin "agentmemory" ''
      exec ${pkgs.nodejs}/bin/npx --yes @agentmemory/agentmemory@latest "$@"
    '')
  ];
}
