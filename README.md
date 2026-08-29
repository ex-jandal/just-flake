# just-flake

A clean, modular **NixOS + Home-Manager** flake for a **Niri + Noctalia**
laptop, migrated from Arch. Full plan in [`PLAN.md`](./PLAN.md).

## Status

- **Phase 1 (ACTIVE)** — Home-manager flake that builds on Arch without
  touching the running system (`home-manager build`, never `switch`).
- **Phase 2 (in progress)** — Full `nixosConfigurations` system config
  (`hosts/nixos/`) is wired and **evaluates cleanly** (`nix flake check`), but
  only runs after migrating to NixOS.

Migration reference: **[ARCH-INVENTORY.md](./ARCH-INVENTORY.md)** — the Arch
system as-built record (hardware, boot, services, 491 pkgs / 86 AUR, dotfile
delta) with raw snapshots under `arch/`.

## Structure

```
flake.nix            # inputs + homeConfigurations + nixosConfigurations
hosts/nixos/        # NixOS system config (Phase 2 stub)
home/
  default.nix        # entry: user abu_jandal, imports
  packages.nix       # curated home.packages
  modules/           # one file per program
assets/              # copied configs (niri, noctalia, nvim, tmux, terminals, ...)
arch/                # Arch migration snapshots (packages, services, fstab, mapping)
ARC-INVENTORY.md     # as-built Arch reference for migration
```

## Usage

**Test (safe on Arch — does NOT modify your system):**

```sh
cd just-flake
nix flake lock
nix flake check
home-manager build --flake .#nixos   # builds to /nix/store + ./result, no switch
```

**Apply home-manager (only when ready; on Arch would overwrite dotfiles):**

```sh
home-manager switch --flake .#nixos
```

**After migrating to NixOS (Phase 2):**

```sh
sudo nixos-rebuild switch --flake .#nixos
```

## Key facts

- **Noctalia v5** is a native Wayland shell (no Qt/GTK/quickshell). Installed
  via its official home-manager module, using the `cachix` branch for
  pre-built binaries. Binary cache is configured in both `flake.nix`
  (`nixConfig`) and `hosts/nixos/default.nix`.
- Noctalia's **theme templates** generate foot/kitty/ghostty/gtk/niri themes
  from its palette — so no manual porting of terminal colors.
- **nvim** (NvChad + lazy.nvim) and **tmux** (TPM) fetch their plugins at
  runtime (by design), not via nixpkgs pinning.
- **Boot**: GRUB on **UEFI** + **systemd initrd** (`boot.initrd.systemd`), the
  NixOS-native fast initrd (Arch's "booster" equivalent).
- **Power**: **TLP** (+ tlp-pd) with the Arch config ported to
  `services.tlp.settings`; `power-profiles-daemon` is force-disabled so it
  can't fight TLP.
- **DNS**: **dnscrypt-proxy** listening on `127.0.0.1:53`, system routed to it
  (`networking.nameservers`); ad-blocklist + safesearch cloaking ported from
  Arch into `assets/dnscrypt/`.
- **Wi-Fi**: NetworkManager uses the **iwd** backend (`networking.networkmanager.wifi.backend`).

## Caveats / known breakers

- **Fish env vars** reference Arch paths that won't exist on NixOS:
  `JAVA_HOME=/usr/lib/jvm/java-26-openjdk`, `ANDROID_HOME=~/Android/Sdk`,
  `~/.config/composer/vendor/bin`, `~/repos/nipe`, surreal DB paths.
  Parametrize these after migrating.
- **Unfree** packages are allowed via `allowUnfreePredicate` in
  `home/default.nix`.
- **AUR-only apps** not packaged in nixpkgs (packet-tracer, superproductivity,
  legcord, illogical-impulse-*, cht.sh, wooz, ...) are not included; add them
  via overlays if needed.
- Noctalia's `settings.toml` references an absolute wallpaper path
  (`~/Pictures/Wallpapers/tree-in-green-field.webp`) — the file must exist on
  the target machine or be updated in `assets/noctalia/settings.toml`.

## Adding a program

1. Create `home/modules/<name>.nix` (copy the app's existing
   `~/.config/<name>` into `assets/<name>/`).
2. Import it in `home/default.nix`.
3. Add any executables it needs to `home/packages.nix`.
4. Re-run `home-manager build --flake .#nixos`.

## Building / applying on NixOS

See **[NIXOS-SETUP.md](./NIXOS-SETUP.md)** — full guide covering fresh-install
prereqs, activating `nixosConfigurations.nixos`, day-to-day `nixos-rebuild` /
`home-manager` apply, the noctalia binary cache, rollback, and Arch→NixOS
breaker fixes.
