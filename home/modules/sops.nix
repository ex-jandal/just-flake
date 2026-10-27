{
  config,
  ...
}:
{
  sops = {
    # User-level decryption key. Copy it once with:
    #   install -d -m 700 ~/.config/sops/age
    #   install -m 600 .secrets/age.key ~/.config/sops/age/keys.txt
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    # Single in-place encrypted file: `sops .secrets/secrets.yaml`.
    defaultSopsFile = ../../.secrets/secrets.yaml;

    keepGenerations = 2;

    # Add new secrets here: <attr> = { key = "<YAML_KEY>"; };
    # Each lands at ~/.config/sops-nix/secrets/<attr>.
    secrets = {
      anthropic_api_key = {
        key = "ANTHROPIC_API_KEY";
      };
      openai_api_key = {
        key = "OPENAI_API_KEY";
      };
      github_token = {
        key = "GITHUB_TOKEN";
      };
    };

    # Dotenv for tools that take an env file:
    # ~/.config/sops-nix/secrets/rendered/secrets.env
    templates."secrets.env".content = ''
      ANTHROPIC_API_KEY=${config.sops.placeholder.anthropic_api_key}
      OPENAI_API_KEY=${config.sops.placeholder.openai_api_key}
      GITHUB_TOKEN=${config.sops.placeholder.github_token}
    '';

    # Fish exports, auto-sourced below:
    # ~/.config/sops-nix/secrets/rendered/secrets.fish
    # templates."secrets.fish".content = ''
    #   set -gx ANTHROPIC_API_KEY '${config.sops.placeholder.anthropic_api_key}'
    #   set -gx OPENAI_API_KEY '${config.sops.placeholder.openai_api_key}'
    #   set -gx GITHUB_TOKEN '${config.sops.placeholder.github_token}'
    # '';
  };

  # Export the secrets into every interactive fish shell.
  # programs.fish.interactiveShellInit = ''
  #   if test -f ${config.sops.templates."secrets.fish".path}
  #     source ${config.sops.templates."secrets.fish".path}
  #   end
  # '';
}
