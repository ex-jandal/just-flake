{ inputs, ... }:

{
  imports = [ inputs.pi-agent.homeManagerModules.default ];

  programs.pi-coding-agent = {
    enable = true;

    agentFiles = {
      settings = {
        value = {
          defaultModel = "big-pickle";
          defaultProvider = "bansos";

          packages = [
            "npm:@termdraw/pi"
            "npm:pi-mcp-adapter"
            "npm:pi-web-access"
            "npm:pi-permission-system"
            "npm:@danchamorro/pi-agent-modes"
            "npm:pi-undo-redo"
            "npm:pi-vimmode"

            "npm:@xynogen/pix-pretty"
            "npm:@heyhuynhgiabuu/pi-diff"

            "npm:@danchamorro/pi-prompt-enhancer"
            "git:github.com/DietrichGebert/ponytail"

            {
              source = "git:github.com/anthropics/skills";
              skills = [
                "!skills/frontend-design/**"
                "!skills/claude-api/**"
              ];
            }
            "npm:@tintinweb/pi-subagents"
            "npm:pi-free"
            "npm:pi-bansos"
            "npm:pi-antigravity"

            # "npm:@juicesharp/rpiv-pi"
            "npm:@juicesharp/rpiv-ask-user-question"
            "npm:@juicesharp/rpiv-todo"
            "npm:@juicesharp/rpiv-i18n"
            # "npm:@juicesharp/rpiv-web-tools"
            "npm:@juicesharp/rpiv-args"
            "npm:@juicesharp/rpiv-workflow"
          ];
          extensions = [
            "-builtin:mcp"
          ];
        };
      };
    };
  };

  home.file.".agents/skills/brainstorm/SKILL.md".source =
    ../../assets/aiAgent/skills/brainstorm/SKILL.md;

  home.file.".agents/skills/visualize/SKILL.md".source =
    ../../assets/aiAgent/skills/visualize/SKILL.md;

  home.file.".agents/skills/teach/SKILL.md".source = ../../assets/aiAgent/skills/teach/SKILL.md;
}
