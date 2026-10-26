{ pkgs, ... }:

{
  programs.pi-coding-agent = {
    enable = true;
    package = pkgs.pi-coding-agent;
    settings = {
      packages = [
        "npm:@termdraw/pi"
        "npm:pi-mcp-adapter"
      ];
    };
  };
}
