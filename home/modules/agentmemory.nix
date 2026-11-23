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
    # - The CLI boots the iii engine + a detached Worker Compose daemon, prints
    #   the port banner, then exits 0. The daemon is meant to outlive the CLI
    #   (that is what engine-state.json + `agentmemory stop` are for).
    # - Type=simple was the bug: when the CLI exits, systemd tears down the whole
    #   cgroup, killing the compose daemon, the workers and the REST (3111) /
    #   viewer (3113) / engine (49134) listeners. Nothing was ever reachable.
    # - oneshot + RemainAfterExit keeps the unit "active (exited)" while the
    #   detached daemon lives; ExecStop tears it down through the CLI so the
    #   engine state is cleaned up properly. Restart= is rejected by systemd for
    #   oneshot units, so it is intentionally absent.
    # - Prompt start/stop timeouts: first boot downloads + links the workers.
    Service = {
      Type = "oneshot";
      ExecStart = "${agentmemory.cli}/bin/agentmemory";
      ExecStop = "${agentmemory.cli}/bin/agentmemory stop";
      RemainAfterExit = true;
      KillMode = "mixed";
      TimeoutStartSec = 180;
      TimeoutStopSec = 60;
      Environment = [ "HOME=%h" ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };

  home.packages = agentmemory.packages;
}
