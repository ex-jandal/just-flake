{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  # Path to encrypted secrets file (relative to flake root)
  secretsFile = ./../../../.secrets/secrets.yaml.enc;
in
{
  sops = {
    # Default sops file (can be overridden per secret)
    defaultSopsFile = secretsFile;

    # KEY STRATEGY: SSH Host Key Derivation (RECOMMENDED - no key deployment)
    # Derives age key from /etc/ssh/ssh_host_ed25519_key
    # Works automatically on any machine with SSH host key
    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      # sops-nix will auto-generate key from these
    };

    # Alternative: Static Age Key File (uncomment if not using SSH derivation)
    # age.keyFile = "/var/lib/sops-nix/key.txt";
  };

  # INDIVIDUAL KEY MAPPING: each creates /run/secrets/<secret-name>
  sops.secrets.anthropic_api_key = {
    key = "ANTHROPIC_API_KEY";
    owner = "abu_jandal";
    group = "users";
    mode = "0400";
  };

  sops.secrets.openai_api_key = {
    key = "OPENAI_API_KEY";
    owner = "abu_jandal";
    group = "users";
    mode = "0400";
  };

  sops.secrets.github_token = {
    key = "GITHUB_TOKEN";
    owner = "abu_jandal";
    group = "users";
    mode = "0400";
  };

  # Add more secret mappings here as needed:
  # sops.secrets.database_url = {
  #   key = "DATABASE_URL";
  #   owner = "abu_jandal";
  #   group = "users";
  #   mode = "0400";
  # };

  # Full dotenv file at /run/secrets/dotenv (sourced by apps).
  sops.templates.dotenv = {
    path = "/run/secrets/dotenv";
    owner = "root";
    group = "root";
    mode = "0400";
    content = ''
      ANTHROPIC_API_KEY=${config.sops.placeholder.anthropic_api_key}
      OPENAI_API_KEY=${config.sops.placeholder.openai_api_key}
      GITHUB_TOKEN=${config.sops.placeholder.github_token}
    '';
  };

  # Harden sops-nix service
  systemd.services.sops-nix = {
    serviceConfig = {
      # Drop privileges after key derivation
      User = "root";
      Group = "root";
      # Private tmp, no new privileges
      PrivateTmp = true;
      NoNewPrivileges = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      # Only allow reading SSH host key and writing /run/secrets
      ReadOnlyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      ReadWritePaths = [
        "/run/secrets"
        "/var/lib/sops-nix"
      ];
    };
  };
}
