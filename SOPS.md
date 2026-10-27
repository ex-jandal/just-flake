# Secrets with sops-nix

Secrets live in one file, `.secrets/secrets.yaml`, which is **encrypted in
place** and committed to git. You edit it with `sops`, which decrypts into your
editor and re-encrypts on save.

Decryption happens in home-manager (`home/modules/sops.nix`). The old
NixOS-level module was removed.

## Files

| Path                            | Purpose                                  | Committed       |
|---------------------------------|------------------------------------------|-----------------|
| `.secrets/secrets.yaml`         | encrypted secrets (edit with `sops`)     | yes             |
| `.secrets/secrets.yaml.example` | plaintext stub for a fresh setup         | yes             |
| `.secrets/age.key`              | age private key                          | no (gitignored) |
| `~/.config/sops/age/keys.txt`   | copy used by home-manager                | no              |
| `.sops.yaml`                    | encryption recipients / creation rule    | yes             |
| `home/modules/sops.nix`         | home-manager secret mappings + templates | yes             |

`age` and `sops` are installed system-wide (`hosts/nixos/packages.nix`).
Outside this host: `nix shell nixpkgs#age nixpkgs#sops`.

## Edit secrets

From the repo root:

```sh
sops .secrets/secrets.yaml
```

That opens the decrypted YAML in `$EDITOR`. Add/change/remove keys, save, and
exit; sops re-encrypts the file automatically. Then commit it:

```sh
git add .secrets/secrets.yaml
```

Do not edit the file with a normal editor: the `ENC[...]` values and the
`sops:` metadata block would break.

## Add a key

1. Add the line to the YAML:

   ```yaml
   ANTHROPIC_API_KEY: sk-ant-...
   OPENAI_API_KEY: sk-...
   GITHUB_TOKEN: ghp_...
   RESTIC_PASSWORD: hunter2
   ```

2. Map it in `home/modules/sops.nix`:

   ```nix
   secrets.restic_password = {
     key = "RESTIC_PASSWORD";
   };
   ```

   This creates `~/.config/sops-nix/secrets/restic_password`.

3. To export it to shells/tools, add it to a template:

   ```nix
   templates."secrets.env".content = ''
     RESTIC_PASSWORD=${config.sops.placeholder.restic_password}
   '';

   templates."secrets.fish".content = ''
     set -gx RESTIC_PASSWORD '${config.sops.placeholder.restic_password}'
   '';
   ```

4. `git add .secrets/secrets.yaml home/modules/sops.nix` and rebuild.

The example file already uses this pattern for the three existing keys.

## Add a recipient (age key)

Do this when a new machine or user must decrypt the file.

### Local age key

```sh
age-keygen -o new-machine.key          # keep this private
age-keygen -y new-machine.key          # age1... public key
```

### NixOS host key

```sh
nix run nixpkgs#ssh-to-age -- -i /etc/ssh/ssh_host_ed25519_key.pub
```

Add the public key(s) to `.sops.yaml`:

```yaml
creation_rules:
  - path_regex: \.secrets/secrets\.yaml$
    age:
      - age1...personal...
      - age1...new-machine...
```

Then sync the existing file to the new recipient list (no plaintext needed):

```sh
sops --config .sops.yaml updatekeys .secrets/secrets.yaml
git add .sops.yaml .secrets/secrets.yaml
```

Removing a recipient works the same way: delete it from `.sops.yaml` and run
`updatekeys` again.

Never commit a private key. `.gitignore` excludes `.secrets/age.key` and
`.secrets/*.key`.

## Use in home-manager

The module is imported in `home/default.nix`:

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

### Available paths

| What              | Path                                               |
|-------------------|----------------------------------------------------|
| individual secret | `~/.config/sops-nix/secrets/<attr>`                |
| dotenv template   | `~/.config/sops-nix/secrets/rendered/secrets.env`  |
| fish template     | `~/.config/sops-nix/secrets/rendered/secrets.fish` |

Current mappings in `home/modules/sops.nix`:

- `anthropic_api_key` → `ANTHROPIC_API_KEY`
- `openai_api_key` → `OPENAI_API_KEY`
- `github_token` → `GITHUB_TOKEN`

The `secrets.fish` template is sourced from every interactive fish shell, so
those variables are exported automatically.

### Consume a secret

In any home-manager module:

```nix
# as a file (e.g. a token file some tool expects)
home.file.".config/foo/token".source =
  config.sops.secrets.github_token.path;

# as an env file for a user service
systemd.user.services.foo.Service.EnvironmentFile =
  config.sops.templates."secrets.env".path;

# inside another template
sops.templates."some-tool.conf".content = ''
  token = ${config.sops.placeholder.github_token}
'';
```

`config.sops.placeholder.<name>` is replaced with the real value when the
templates are rendered. Never interpolate a secret into a plain Nix string: it
would be copied into the world-readable Nix store.

### Rebuild

```sh
sudo nixos-rebuild switch --flake .#nixos
```

## Verify

```sh
sops -d .secrets/secrets.yaml              # decrypt to stdout
ls -l ~/.config/sops-nix/secrets
systemctl --user status sops-nix
```

The user service runs on login/activation and writes a new secrets generation.

## Troubleshooting

| Error                                             | Fix                                                                                   |
|---------------------------------------------------|---------------------------------------------------------------------------------------|
| `sops` shows plaintext in the file                | that file is not encrypted yet; run `sops -e -i .secrets/secrets.yaml`                |
| `no matching creation rules found`                | run from the repo root, or make `.sops.yaml`'s `path_regex` match the path            |
| `no identity matched any of the recipients`       | add your age public key to `.sops.yaml`, then `sops updatekeys .secrets/secrets.yaml` |
| HM activation fails: missing age key              | create `~/.config/sops/age/keys.txt` (mode 600)                                       |
| `sops .secrets/secrets.yaml` opens but save fails | file has no `sops:` metadata; re-encrypt it with `sops -e -i`                         |
| New key cannot decrypt                            | add the recipient and run `updatekeys`                                                |
| Git says the secret file is untracked             | `git add .secrets/secrets.yaml` (it must be committed)                                |
