# - AgentMemory (rohitg00/agentmemory) is distributed only through npm, so the
#   one thing we can pin is the version. Both consumers import this file and
#   share it: the user service + `agentmemory` CLI (home/modules/agentmemory.nix)
#   and pi's MCP entry (home/modules/pi-coding-agent.nix).
# - Never `@latest`: it re-fetches from the registry on every start, silently
#   changes the MCP tool surface, and (because npx caches by content hash) makes
#   any hardcoded script path rot on the next update.
# - `node` comes from nixpkgs via ${pkgs.nodejs}/bin/npx, never a hardcoded
#   /nix/store path, so a `flake update` or `nix-collect-garbage` cannot break it.
{
  pkgs,
  version ? "0.9.31",
}:
let
  # - `agentmemory` is the CLI (`agentmemory` with no args starts the engine,
  #   `agentmemory status`, `stop`, `doctor`, ...).
  cli = pkgs.writeShellScriptBin "agentmemory" ''
    exec ${pkgs.nodejs}/bin/npx --yes "@agentmemory/agentmemory@${version}" "$@"
  '';

  # - `agentmemory mcp` is the documented standalone MCP shim (it runs
  #   dist/standalone.mjs) — the stdio surface MCP-only clients such as pi use.
  mcp = pkgs.writeShellScriptBin "agentmemory-mcp" ''
    exec ${cli}/bin/agentmemory mcp "$@"
  '';
in
{
  inherit cli mcp version;

  # - home.packages entry: the wrapper plus the node runtime it shells out to.
  packages = [
    pkgs.nodejs
    cli
  ];
}
