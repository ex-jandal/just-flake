{ inputs, ... }:

{
  imports = [ inputs.pi-agent.homeManagerModules.default ];

  programs.pi-coding-agent = {
    enable = true;

    agentFiles = {
      settings = {
        value = {
          defaultModel = "nvidia/nemotron-3-ultra-550b-a55b:free";
          defaultProvider = "openrouter";

          packages = [
            "npm:@termdraw/pi"
            # "npm:pi-mcp-adapter"
            "npm:pi-permission-system"
            "npm:@danchamorro/pi-agent-modes"
            "npm:pi-undo-redo"
            "npm:@0xkahi/pi-vim-keys"
            "npm:@xynogen/pix-pretty"
            "npm:@juicesharp/rpiv-pi"
            "npm:@danchamorro/pi-prompt-enhancer"
            "git:github.com/DietrichGebert/ponytail"
            "npm:@tintinweb/pi-subagents"
          ];
        };
      };
    };
  };
}
