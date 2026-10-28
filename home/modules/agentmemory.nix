{ pkgs, lib, ... }:
let
  # - pinned npm version + node runtime, shared with pi's MCP entry (see
  #   home/packages/agentmemory.nix).
  agentmemory = import ../packages/agentmemory.nix { inherit pkgs; };
in
{
  systemd.user.services.agentmemory = {
    Unit = {
      Description = "AgentMemory persistent memory server";
      After = [ "network.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${agentmemory.cli}/bin/agentmemory";
      Restart = "on-failure";
      RestartSec = 5;
      Environment = [ "HOME=%h" ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  home.packages = agentmemory.packages;
}
