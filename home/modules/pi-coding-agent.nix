{ inputs, pkgs, ... }:

let
  # - shared npm pin + node runtime; see home/packages/agentmemory.nix for why
  #   this is not a hardcoded /nix/store path or an ~/.npm/_npx cache path.
  agentmemory = import ../packages/agentmemory.nix { inherit pkgs; };
in

{
  imports = [ inputs.pi-agent.homeManagerModules.default ];

  programs.pi-coding-agent = {
    enable = true;

    agentFiles = {
      settings = {
        value = {
          defaultModel = "big-pickle";
          defaultProvider = "bansos";

          retry = {
            enabled = true;
            maxRetries = 5;
            baseDelayMs = 1000;
            maxAgentDelayMs = 120000;
            provider = {
              timeoutMs = 300000;
              maxRetries = 2;
              maxRetryDelayMs = 120000;
            };
          };

          httpIdleTimeoutMs = 600000;

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

            "/home/abu_jandal/.agents/agentmemory"
          ];

          extensions = [
            "-builtin:mcp"
          ];
        };
      };

      mcp = {
        value = {
          mcpServers = {
            context7 = {
              command = "npx";
              args = [
                "-y"
                "@upstash/context7-mcp"
              ];
              description = "Fetch up-to-date library documentation and code examples";
              exposure = "direct";
            };

            sequential-thinking = {
              command = "npx";
              args = [
                "-y"
                "@modelcontextprotocol/server-sequential-thinking"
              ];
              description = "Structured reasoning and problem decomposition";
              exposure = "direct";
            };

            agentmemory = {
              command = "${agentmemory.mcp}/bin/agentmemory-mcp";
              env = {
                AGENTMEMORY_TOOLS = "all";
                AGENTMEMORY_FORCE_PROXY = "1";
              };
              exposure = "direct";
            };
          };
        };
      };
    };
  };

  home.file.".agents/skills/brainstorm/SKILL.md".source =
    ../../assets/aiAgent/skills/brainstorm/SKILL.md;
  home.file.".agents/skills/visualize/SKILL.md".source =
    ../../assets/aiAgent/skills/visualize/SKILL.md;
  home.file.".agents/skills/teach/SKILL.md".source = ../../assets/aiAgent/skills/teach/SKILL.md;

  home.file.".pi/agent/extensions/md-log.ts".source = ../../assets/aiAgent/extensions/md-log.ts;
  home.file.".pi/agent/extensions/quiz.ts".source = ../../assets/aiAgent/extensions/quiz.ts;
  home.file.".pi/agent/extensions/ask-user-question-for-teach.ts".source =
    ../../assets/aiAgent/extensions/ask-user-question-for-teach.ts;
  home.file.".pi/agent/extensions/visual-tools" = {
    source = ../../assets/aiAgent/extensions/visual-tools;
    recursive = true;
  };

  home.file.".pi/agent/agents/researcher.md".source = ../../assets/aiAgent/agents/researcher.md;
  home.file.".pi/agent/agents/mermaid-maker.md".source = ../../assets/aiAgent/agents/mermaid-maker.md;
  home.file.".pi/agent/agents/svg-maker.md".source = ../../assets/aiAgent/agents/svg-maker.md;
}
