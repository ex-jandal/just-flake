# Secrets with sops-nix

This flake decrypts secrets at activation time with
[sops](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age)
via [sops-nix](https://github.com/Mic92/sops-nix).

## Files

| Path | Purpose | Committed |
|---|---|---|
| `.secrets/secrets.yaml.enc` | encrypted secrets | yes |
| `.secrets/secrets.yaml` | plaintext working copy | no (gitignored) |
| `.secrets/secrets.yaml.example` | stub to start from | yes |
| `.secrets/age.key` | age private key | no (gitignored) |
| `.sops.yaml` | encryption recipients | yes |
| `hosts/nixos/modules/secrets.nix` | NixOS secret mappings | yes |
| `home/modules/sops.nix` | home-manager secret mappings | yes |

`age` and `sops` are installed system-wide (`hosts/nixos/packages.nix`).
Outside this host: `nix shell nixpkgs#age nixpkgs#sops`.

## How it works

- The encrypted file is a normal YAML document with `ENC[...]` values plus a
  `sops:` metadata block.
- Anyone listed under `age:` in `.sops.yaml` can decrypt it.
- NixOS decrypts with the SSH host key (`/etc/ssh/ssh_host_ed25519_key`) and
  writes values to `/run/secrets/`.
- home-manager decrypts as your user with `~/.config/sops/age/keys.txt` and
  writes values to `~/.config/sops-nix/secrets/`.
- The SSH host key and your personal age key are both recipients of the current
  file, so either side can decrypt.

## Add a secret key

Two workflows; pick one.

### A. Edit the plaintext and re-encrypt

```sh
# decrypt once if the plaintext is missing
sops --input-type yaml --output-type yaml -d .secrets/secrets.yaml.enc > .secrets/secrets.yaml

$EDITOR .secrets/secrets.yaml        # add a line, e.g. RESTIC_PASSWORD: hunter2

sops --config .sops.yaml -e .secrets/secrets.yaml > .secrets/secrets.yaml.enc

git add .secrets/secrets.yaml.enc    # Nix only sees files tracked by git
```

### B. Edit the encrypted file directly

```sh
sops --config .sops.yaml --input-type yaml .secrets/secrets.yaml.enc
```

`--input-type yaml` is required because the `.enc` suffix does not tell sops
the format. Save and exit, then `git add` the file.

After changing the YAML, map the new key where it is needed:

- NixOS: add `sops.secrets.<name> = { key = "<YAML_KEY>"; ... };` in
  `hosts/nixos/modules/secrets.nix`.
- home-manager: add it to `sops.secrets` in `home/modules/sops.nix`.

## Add a recipient (age key)

Do this when adding a machine or user that must decrypt the file.

### Local age key

```sh
age-keygen -o new-machine.key          # keep this private
age-keygen -y new-machine.key          # age1... public key
```

### NixOS host key (no key to deploy)

```sh
nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub
```

Add the public key(s) to `.sops.yaml`:

```yaml
creation_rules:
  - path_regex: secrets\.yaml(\.enc)?$
    age:
      - age1...personal...
      - age1...new-machine...
```

Then rekey the existing file (no plaintext needed):

```sh
sops --config .sops.yaml updatekeys --input-type yaml .secrets/secrets.yaml.enc
# if that complains about the format:
sops --config .sops.yaml -e .secrets/secrets.yaml > .secrets/secrets.yaml.enc
```

Never commit a private key. `.gitignore` already excludes `.secrets/*.key`,
`.secrets/age.key`, `.secrets/secrets.yaml` and `.secrets/secrets.env`.

## Use in NixOS

1. Add the mapping in `hosts/nixos/modules/secrets.nix`:

```nix
sops.secrets.restic_password = {
  key = "RESTIC_PASSWORD";
  owner = "root";
  group = "root";
  mode = "0400";
};
```

2. Use the path (`/run/secrets/restic_password`):

```nix
services.restic.backups.daily.passwordFile =
  config.sops.secrets.restic_password.path;
```

Paths are also accepted by anything that wants a file: `passwordFile`,
`credentialFiles`, `EnvironmentFile`, ssh identity files, etc.

3. For environment variables, render a template instead of pasting the value
   into Nix:

```nix
sops.templates."myservice.env".content = ''
  RESTIC_PASSWORD=${config.sops.placeholder.restic_password}
'';

systemd.services.myservice.serviceConfig.EnvironmentFile =
  config.sops.templates."myservice.env".path;
```

`config.sops.placeholder.<name>` is replaced by the real value at activation.
Never interpolate the secret into a plain Nix string: it would be copied into
the world-readable Nix store.

The existing `dotenv` template in `secrets.nix` does exactly this to produce
`/run/secrets/dotenv`.

## Use in home-manager

The module is already imported in `home/default.nix`:

```nix
imports = [
  inputs.sops-nix.homeManagerModules.sops
  ./modules/sops.nix
];
```

One-time prerequisite: the user service needs the age key.

```sh
install -d -m 700 ~/.config/sops/age
install -m 600 .secrets/age.key ~/.config/sops/age/keys.txt
```

Example config in `home/modules/sops.nix`:

```nix
{ config, ... }:
{
  sops = {
    age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = ../../.secrets/secrets.yaml.enc;

    secrets.github_token = {
      key = "GITHUB_TOKEN";
    };

    templates."github.env".content = ''
      GITHUB_TOKEN=${config.sops.placeholder.github_token}
    '';
  };
}
```

Consume it:

```nix
# as a file (decrypted at ~/.config/sops-nix/secrets/github_token)
home.file.".config/foo/token".source =
  config.sops.secrets.github_token.path;

# as an env file (rendered at ~/.config/sops-nix/secrets/rendered/github.env)
programs.fish.shellInit = ''
  source ${config.sops.templates."github.env".path}
'';

# or in a systemd user service
systemd.user.services.foo.Service.EnvironmentFile =
  config.sops.templates."github.env".path;
```

Notes:

- Standalone use: `home-manager switch --flake .#nixos`.
- Embedded use (this flake's `nixosConfigurations`): the same home module is
  used, so both the system and the user decrypt their own copies.
- Home-manager secrets live under `~/.config/sops-nix/secrets/`; rendered
  templates under `~/.config/sops-nix/secrets/rendered/`.
- To use only the system-decrypted files from home-manager instead, reference
  the fixed path `/run/secrets/<name>` (or `osConfig.sops.secrets.<name>.path`)
  and skip the user-level secret.

## Rebuild and verify

```sh
sudo nixos-rebuild switch --flake .#nixos
home-manager switch --flake .#nixos   # only if you use the standalone config

ls -l /run/secrets /run/secrets/rendered
ls -l ~/.config/sops-nix/secrets
systemctl status sops-nix
systemctl --user status sops-nix
```

The system service runs at boot; the user service runs on login/activation.

## Troubleshooting

| Error | Fix |
|---|---|
| `Path '.secrets/secrets.yaml.enc' is not tracked by Git` | `git add .secrets/secrets.yaml.enc` |
| `no matching creation rules found` | `.sops.yaml` `path_regex` does not match the filename |
| `did not find expected <document start>` | wrong `format`; the file is YAML, use `format = "yaml"` (the default) |
| `Could not unmarshal input data` when decrypting `.enc` | pass `--input-type yaml --output-type yaml` |
| HM activation fails: missing age key | create `~/.config/sops/age/keys.txt` (mode 600) |
| `sops-nix.service` fails on NixOS | host key missing, or host public key not in `.sops.yaml` |
| New key cannot decrypt | add the recipient to `.sops.yaml` and run `sops updatekeys` |
