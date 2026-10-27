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
            "npm:pi-mcp-adapter"
            "npm:pi-permission-system"
            "npm:@danchamorro/pi-agent-modes"
            "npm:pi-undo-redo"
            "npm:pi-vimmode"
            "npm:@xynogen/pix-pretty"
            "npm:@juicesharp/rpiv-pi"
            "npm:@danchamorro/pi-prompt-enhancer"
            "git:github.com/DietrichGebert/ponytail"
            "git:github.com/anthropics/skills"
            "npm:@tintinweb/pi-subagents"
            "npm:pi-opencode-free"

            "npm:@juicesharp/rpiv-ask-user-question"
            "npm:@juicesharp/rpiv-todo"
            "npm:@juicesharp/rpiv-i18n"
            "npm:@juicesharp/rpiv-web-tools"
            "npm:@juicesharp/rpiv-args"
            "npm:@juicesharp/rpiv-workflow"
          ];
        };
      };
    };
  };

  home.file.".agents/skills/brainstorm/SKILL.md".source = ../../assets/skills/brainstorm/SKILL.md;
}
