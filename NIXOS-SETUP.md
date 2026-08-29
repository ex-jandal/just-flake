# NixOS Setup Guide — just-flake

How to build and apply this flake on your new **NixOS** install (Niri + Noctalia
laptop). This is the Phase 2 activation guide. For the project overview, plan
and Arch-side notes see [`README.md`](./README.md) and [`PLAN.md`](./PLAN.md).

> **Do NOT run any `switch` on your Arch box** — it will overwrite your real
> dotfiles. Everything here targets the NixOS machine.

---

## 1. Before you start (on the NixOS install)

After the base NixOS install, edit `/etc/nixos/configuration.nix` (regenerate
with `nixos-generate-config --root /`) so these are enabled:

```nix
{
  # Flakes + nix-command (needed for `--flake`)
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Allow your user to use the flake's binary cache (noctalia.cachix.org).
  # Without this the cache is IGNORED and everything builds from source (slow).
  nix.settings.trusted-users = [ "root" "abu_jandal" ];

  # Get git so `--flake .#` can fetch inputs.
  environment.systemPackages = with pkgs; [ git ];
}
```

Rebuild the base system once:

```sh
sudo nixos-rebuild switch
```

---

## 2. Activate the system config (first time)

The system config is currently a **commented stub** (`flake.nix` →
`nixosConfigurations.nixos`). Do this once:

1. **Generate hardware config** on the NixOS machine and copy it into the repo:
   ```sh
   nixos-generate-config --root /
   # copy /etc/nixos/hardware-configuration.nix to:
   #   <repo>/hosts/nixos/hardware.nix
   ```
   Replace the placeholder `hosts/nixos/hardware.nix`.

2. **Review `hosts/nixos/default.nix`** — it is a fresh default. Confirm:
   - `networking.hostName`
   - GPU / `hardware.opengl` drivers (the Arch box was AMD; confirm the laptop GPU)
   - bootloader, filesystems come from `hardware.nix`

3. **Uncomment `nixosConfigurations.nixos`** in `flake.nix` (it is already
   wired to import `hosts/nixos/default.nix` + home-manager).

4. **Switch:**
   ```sh
   cd <repo>
   sudo nixos-rebuild switch --flake .#nixos --accept-flake-config
   ```
   `--accept-flake-config` trusts the `noctalia.cachix.org` substituter declared
   in `flake.nix`. It is safe (just a binary cache) but Nix asks before using a
   flake-provided cache setting.

---

## 3. Applying changes day-to-day

```sh
# Full system + home-manager (user config comes from home/default.nix)
sudo nixos-rebuild switch --flake .#nixos --accept-flake-config

# Update all inputs (nixpkgs, home-manager, noctalia) then rebuild
nix flake update
sudo nixos-rebuild switch --flake .#nixos --accept-flake-config
```

### Home-manager only (without full system rebuild)

If you only changed `home/`, you can apply just home-manager:

```sh
# Install the home-manager CLI once (or use `nix develop`)
nix profile install nixpkgs#home-manager

# Apply
home-manager switch --flake .#nixos

# Build without applying (dry-run to a ./result symlink)
home-manager build --flake .#nixos
```

---

## 4. Rollback / safety

```sh
# Revert system to previous generation
sudo nixos-rebuild switch --rollback

# Boot the previous generation once (then reboot)
sudo nixos-rebuild boot

# Inspect generations
nixos-rebuild list-generations
home-manager generations
```

---

## 5. Post-migration fixes (Arch → NixOS breakers)

These configs reference **Arch-specific paths** that do NOT exist on NixOS. Fix
before or right after migrating (all under `home/`):

| Place | Arch path | What to do on NixOS |
|---|---|---|
| `home/default.nix` / `fish` | `JAVA_HOME=/usr/lib/jvm/java-26-openjdk` | point to a nixpkgs jdk, e.g. `/nix/store/...` or set via `programs.java.enable` |
| `fish` sessionVariables | `ANDROID_HOME=~/Android/Sdk`, `$ANDROID_*` | reinstall SDK or drop these vars |
| `fish` shellInit | `~/.config/composer/vendor/bin`, `~/repos/nipe`, surrealdb `file://...` | parametrize or remove |
| `noctalia` settings | absolute wallpaper `~/Pictures/Wallpapers/tree-in-green-field.webp` | make sure the file exists or update `assets/noctalia/settings.toml` |

**AUR-only apps** (packet-tracer, superproductivity, legcord,
illogical-impulse-*, cht.sh, wooz, ...) are not in nixpkgs — add them via
overlays if needed. See README.

**Noctalia runs natively under Niri** (spawned from `assets/niri/config.kdl`) —
it is a Wayland shell, no quickshell/GTK needed. Its theme templates generate
foot/kitty/ghostty/gtk/niri themes from the palette.

---

## 6. Binary cache (noctalia)

The cache is declared in `flake.nix`:

```nix
nixConfig = {
  extra-substituters = [ "https://noctalia.cachix.org" ];
  extra-trusted-public-keys = [
    "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
  ];
};
```

- Works automatically once `abu_jandal` is a **trusted user** (step 1) — pass
  `--accept-flake-config` to use it.
- If not a trusted user, it is ignored and noctalia (+ its nixpkgs) builds from
  source, which is slow. Fix via `nix.settings.trusted-users`.

---

## Cheat sheet

| Action | Command |
|---|---|
| Validate flake (no download if inputs cached) | `nix flake check --offline` |
| Lock inputs | `nix flake lock` |
| Test-evaluate home config | `nix eval --raw .#homeConfigurations.nixos.activationPackage` |
| Build home-manager (no apply) | `home-manager build --flake .#nixos` |
| Apply home-manager | `home-manager switch --flake .#nixos` |
| Build NixOS system | `sudo nixos-rebuild build --flake .#nixos` |
| Apply NixOS system | `sudo nixos-rebuild switch --flake .#nixos --accept-flake-config` |
| Boot this generation once | `sudo nixos-rebuild boot` |
| Rollback | `sudo nixos-rebuild switch --rollback` |
