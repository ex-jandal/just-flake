{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # - shared npm pin + node runtime; see home/packages/agentmemory.nix
  agentmemory = import ../packages/agentmemory.nix { inherit pkgs; };

  yaml = pkgs.formats.yaml { };

  # Declarative MCP configuration matching pi-coding-agent
  mcpConfig = {
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
          AGENTMEMORY_URL = "http://localhost:3111";
        };
        exposure = "direct";
      };
    };
  };

  # Declarative models configuration matching pi-coding-agent
  modelsConfig = {
    providers = {
      "llama-cpp" = {
        baseUrl = "http://127.0.0.1:8087/v1";
        api = "openai-completions";
        apiKey = "llama";

        compat = {
          supportsDeveloperRole = false;
          supportsReasoningEffort = false;
        };

        models = [
          {
            id = "LFM3-1.7B";
            name = "LFM3 1.7B (local)";
            reasoning = true;
            input = [ "text" ];
            contextWindow = 262144;
          }
        ];
      };
    };
  };

  # Declarative omp settings in config.yml
  ompSettings = {
    modelRoles = {
      default = "bansos/deepseek-v4.1-flash-free:high";
    };

    defaultThinkingLevel = "high";

    retry = {
      enabled = true;
      maxRetries = 5;
      baseDelayMs = 1000;
      maxDelayMs = 120000;
    };

    theme = {
      dark = "titanium";
      light = "light";
    };

    symbolPreset = "nerd";
    composer = {
      shape = "field";
    };
  };

  configFile = yaml.generate "omp-config.yml" ompSettings;

  # Declared npm/git plugins for omp (excluding those omp already has natively like todos, vim, mcp, web_search)
  plugins = [
    "npm:pi-bansos"
    "npm:@termdraw/pi"
    "npm:@danchamorro/pi-agent-modes"
    "npm:@xynogen/pix-pretty"
    "npm:@danchamorro/pi-prompt-enhancer"
    "github:DietrichGebert/ponytail"
    "npm:@juicesharp/rpiv-ask-user-question"
    "npm:@juicesharp/rpiv-i18n"
    "npm:@juicesharp/rpiv-args"
    "npm:@juicesharp/rpiv-workflow"
  ];
in

{
  imports = [ inputs.omp.homeManagerModules.default ];

  programs.omp = {
    enable = true;
  };

  # Declarative configuration files under ~/.omp/agent
  home.file.".omp/agent/mcp.json".text = builtins.toJSON mcpConfig;
  home.file.".omp/agent/models.json".text = builtins.toJSON modelsConfig;

  # Assets: extensions, agents, skills
  home.file.".omp/agent/extensions" = {
    source = ../../assets/aiAgent/extensions;
    recursive = true;
  };
  home.file.".omp/agent/agents/researcher.md".source =
    ../../assets/aiAgent/agents/researcher.md;
  home.file.".omp/agent/agents/mermaid-maker.md".source =
    ../../assets/aiAgent/agents/mermaid-maker.md;
  home.file.".omp/agent/agents/svg-maker.md".source =
    ../../assets/aiAgent/agents/svg-maker.md;

  home.file.".omp/agent/skills/brainstorm/SKILL.md".source =
    ../../assets/aiAgent/skills/brainstorm/SKILL.md;
  home.file.".omp/agent/skills/visualize/SKILL.md".source =
    ../../assets/aiAgent/skills/visualize/SKILL.md;
  home.file.".omp/agent/skills/teach/SKILL.md".source =
    ../../assets/aiAgent/skills/teach/SKILL.md;

  # Writable config.yml with advisory locking support + plugin reconciliation
  home.activation.ompDeclarativeConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p "$HOME/.omp/agent"
    $DRY_RUN_CMD install -m 600 ${configFile} "$HOME/.omp/agent/config.yml"

    # Install declared plugins if omp binary is available and not dry run
    if [ -z "$DRY_RUN_CMD" ] && [ -x "${config.programs.omp.package}/bin/omp" ]; then
      LOCK_FILE="$HOME/.omp/plugins/omp-plugins.lock.json"
      for pkg in ${lib.concatStringsSep " " (map lib.escapeShellArg plugins)}; do
        PKG_SEARCH=$(echo "$pkg" | sed -E 's/^npm://; s/^github:[^/]+\///')
        if [ ! -f "$LOCK_FILE" ] || ! grep -qi "$PKG_SEARCH" "$LOCK_FILE" 2>/dev/null; then
          ${config.programs.omp.package}/bin/omp plugin install "$pkg" 2>&1 || true
        fi
      done
    fi
  '';
}
