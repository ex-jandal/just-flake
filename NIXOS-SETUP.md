# NixOS Setup Guide — just-flake

How to build and apply this flake on your new **NixOS** install (Niri + Noctalia
desktop). This is the Phase 2 activation guide. For the project overview and
Arch-side notes see [`README.md`](./README.md) and [`PLAN.md`](./PLAN.md).

> **Do NOT run any `switch` on your Arch box** — it will overwrite your real
> dotfiles. Everything here targets the NixOS machine.

---

## TL;DR — first-time quick start

1. **Generate hardware config** on the NixOS machine, copy it in:
   ```sh
   nixos-generate-config --root /
   cp /etc/nixos/hardware-configuration.nix <repo>/hosts/nixos/hardware.nix
   ```
2. **Review `hosts/nixos/default.nix`** — confirm `networking.hostName`, GPU
   drivers, bootloader, and filesystems.
3. **Switch:**
   ```sh
   cd <repo>
   sudo nixos-rebuild switch --flake .#nixos --accept-flake-config
   ```

That's it. Details and safety below.

---

## 1. Before you start (one-time base NixOS config)

Edit `/etc/nixos/configuration.nix` on the NixOS install so these are enabled:

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

## 2. First-time activation

1. **Generate the real hardware config** and replace the placeholder
   `hosts/nixos/hardware.nix`:
   ```sh
   nixos-generate-config --root /
   cp /etc/nixos/hardware-configuration.nix <repo>/hosts/nixos/hardware.nix
   ```

2. **Review `hosts/nixos/default.nix`** — it is a fresh default. Confirm:
   - `networking.hostName`
   - GPU drivers (`hardware.graphics`; the Arch box was AMD — confirm the laptop GPU)
   - bootloader and filesystems come from `hardware.nix`

3. **Switch:**
   ```sh
   cd <repo>
   sudo nixos-rebuild switch --flake .#nixos --accept-flake-config
   ```
   `--accept-flake-config` trusts the `noctalia.cachix.org` substituter declared
   in `flake.nix`. It is safe (just a binary cache), but Nix asks before using a
   flake-provided cache setting.

---

## 3. Day-to-day

```sh
# Full system + home-manager in one switch (user config comes from home/default.nix)
sudo nixos-rebuild switch --flake .#nixos --accept-flake-config

# Update all inputs (nixpkgs, home-manager, noctalia), then rebuild
nix flake update
sudo nixos-rebuild switch --flake .#nixos --accept-flake-config
```

> **One command covers everything.** `nixosConfigurations.nixos` bundles
> home-manager via `home-manager.nixosModules.home-manager`, so this single
> switch applies **both the system and your user environment** — one command,
> one rollback point.

---

## 4. Home-manager (optional on NixOS)

On NixOS you usually **don't need** this — the `nixos-rebuild` in §3 already
applies your home config. The standalone command is useful when you:

- want to **test on Arch** (`build` only — never `switch` there), or
- want to apply just home changes **without** a full system rebuild.

```sh
# Install the home-manager CLI once (or use `nix develop`)
nix profile install nixpkgs#home-manager

# Apply home only
home-manager switch --flake .#nixos

# Build without applying (dry-run to a ./result symlink)
home-manager build --flake .#nixos
```

---

## 5. Rollback / safety

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

## 6. Post-migration fixes (Arch → NixOS breakers)

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

## 7. Binary cache (noctalia)

The cache is declared in `flake.nix`:

```nix
nixConfig = {
  extra-substituters = [ "https://noctalia.cachix.org" ];
  extra-trusted-public-keys = [
    "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
  ];
};
```

- Works automatically once `abu_jandal` is a **trusted user** (§1) and you pass
  `--accept-flake-config`.
- If not a trusted user, it is ignored and noctalia (+ its nixpkgs) builds from
  source, which is slow. Fix via `nix.settings.trusted-users`.

---

## Cheat sheet

| Action | Command |
|---|---|
| Validate flake (no download if inputs cached) | `nix flake check --offline` |
| Lock inputs | `nix flake lock` |
| Build NixOS system | `sudo nixos-rebuild build --flake .#nixos` |
| Apply NixOS system + home | `sudo nixos-rebuild switch --flake .#nixos --accept-flake-config` |
| Apply home only (optional) | `home-manager switch --flake .#nixos` |
| Build home (no apply) | `home-manager build --flake .#nixos` |
| Boot this generation once | `sudo nixos-rebuild boot` |
| Rollback | `sudo nixos-rebuild switch --rollback` |
