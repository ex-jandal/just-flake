# just-flake

NixOS + Home-Manager configuration for a **Niri + Noctalia** system.

## Key facts

- **Desktop**: Niri (Wayland compositor) + Noctalia (native Wayland shell), greetd + Noctalia greeter
- **Kernel**: linux-zen; boot via GRUB on UEFI, systemd initrd, plymouth
- **Shell**: Fish + Starship prompt
- **Editor**: Neovim (NvChad + lazy.nvim) with multiplexed LSPs (lspmux);
  Doom Emacs 30.2 (prebuilt by `nix-doom-emacs-unstraightened`, no straight.el)
  — manual at `~/project/doom-emacs-manual/`
- **Multiplexer**: tmux (TPM) / zellij
- **Terminals**: foot, ghostty, alacritty, kitty
- **Apps**: rofi, yazi, mpv, zathura, fastfetch, cava
- **Theming**: Noctalia generates foot/kitty/ghostty/gtk/niri themes from its palette
- **Power**: TLP (`power-profiles-daemon` disabled)
- **DNS**: dnscrypt-proxy with ad-blocklist on 127.0.0.1:53
- **Network**: NetworkManager (iwd backend), Tor + Privoxy, Tailscale
- **Virtualization/lab**: libvirt + QEMU, Docker (manual start), GNS3, Wireshark
- **Dev**: Node.js, Bun, Go, Rust, Python, Zig + devShells (`nix develop .#cc` / `.#py`)
- **Security**: Burp Suite, proxychains, torsocks

## Usage

```sh
# Rebuild the full system
sudo nixos-rebuild switch --flake .#nixos

# Home only (faster; what you want after editing assets/*)
home-manager switch

# Dev shells
nix develop .#cc
nix develop .#py
nix develop .#tex
nix develop .#term-browser
```

## Structure

```
flake.nix            # inputs + home/nixos configs + devShells + formatter
hosts/nixos/        # NixOS system config (default.nix, hardware.nix, fonts.nix)
home/
  default.nix        # entry: user abu_jandal + module imports
  packages.nix       # curated home.packages
  modules/           # one file per program (28 modules, doom-emacs.nix among them)
  packages/          # custom packages (packet-tracer-901)
assets/
  doom/              # Doom config: init.el, config.el, packages.el
  nvim/              # NvChad config: init.lua, lua/
  ...                # per-program configs (niri, noctalia, tmux, yazi, ...)
shells/              # devShells (cc.nix, python.nix, latex.nix, term-browser.nix)
```

## Doom Emacs

Launched as `doom-emacs` (or `emacs`). `EDITOR` is still `nvim`.
**Manual:** `~/project/doom-emacs-manual/` — beginner guide written for someone
coming from Neovim.

- **Config**: `assets/doom/{init,config,packages}.el`, baked into the store by
  `home/modules/doom-emacs.nix`. No `~/.doom.d`, no `doom sync` — elisp deps come
  from nixpkgs + emacs-overlay at build time.
- **Edit it, then `home-manager switch`.** The store copy is what runs.
- **Keep those files git-tracked** — flake inputs ignore untracked paths, so the
  switch fails with "not tracked by Git" otherwise.
- **Theme**: `noctalia`, generated at runtime by Noctalia's emacs template into
  `~/.config/doom/themes/`. Reload with `M-x doom/reload-theme`; automatic only
  when Emacs runs as a daemon. Nine other themes are also preinstalled.
- **LSP**: 36 servers injected onto `$PATH` declaratively — deliberately *not*
  nvim's `~/.local/share/nvim/mason/bin`. QML, Vala and Slint have no server in
  nixpkgs and get tree-sitter highlighting only.
- **First build** uses the `doom-emacs-unstraightened` Cachix
  (`hosts/nixos/default.nix`); without it expect a ~1000-derivation compile.

Run `M-x doom-doctor` after the first launch — it reports missing packages and
per-language LSP status.
