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
