# just-flake — Migration to NixOS + Home-Manager

A declarative, modular NixOS + Home-Manager configuration for a single
Niri laptop, currently being built on Arch (test only — never applied to the
running Arch system), then migrated to NixOS.

## Goals

- Reproduce the current Arch + Niri + Noctalia desktop in a clean, modular Nix flake.
- Port **core active configs only** (not the ~200 config dirs).
- Get home-manager working and validated on Arch via `home-manager build`
  (NO `switch`, so the running Arch system is never touched).
- Later, become a full `nixosConfigurations` flake for NixOS.

## Confirmed environment facts

- OS: Arch Linux (Wayland), WM: **Niri**, shell: **Noctalia v5** desktop shell.
- Nix already installed: **Lix 2.95**, single-user, `nix-command` + `flakes`.
- Noctalia **v5 = native Wayland shell** (no Qt/GTK/quickshell).
  → quickshell input NOT needed.
- Active Noctalia config lives at `~/.local/state/noctalia/settings.toml`.
  `~/.config/noctalia/*` (JSON) is **legacy** and is NOT ported.
- Noctalia's **theme templates** (Nord / palette `Hexa34C`) generate themes for
  foot, kitty, ghostty, gtk3, gtk4, niri, qt. → rely on templating, don't
  hand-port terminal colors.
- git user: Sultan Majed <sultan.m.alsalahi@gmail.com>, ssh insteadOf github.

## Locked decisions

1. **Curated daily-use** package list (from `pacman -Qqe`/`-Qqm` + config refs).
2. **`allowUnfreePredicate`** enabled (vscode, spotify, steam, burpsuite, ...).
3. **Runtime network fetch** for nvim (lazy.nvim) and tmux (TPM) plugin graphs.
4. **Noctalia bar is primary** — waybar NOT ported, removed from niri spawn.
5. Everything on **`nixos-unstable`**.
6. **Test only on Arch** — `home-manager build`, never `home-manager switch`.

## Flake inputs

| Input        | URL / ref                 | Notes                                              |
|--------------|---------------------------|----------------------------------------------------|
| nixpkgs      | `nixos-unstable`          | single nixpkgs for everything                      |
| home-manager | `nix-community/home-manager` (master) | standalone home-manager                      |
| noctalia     | `github:noctalia-dev/noctalia/cachix` | `cachix` branch → pre-built binaries; official home-manager module |

`nixConfig` in flake.nix adds the noctalia binary cache:
`https://noctalia.cachix.org` / `noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=`

## Directory structure

```
just-flake/
├── flake.nix
├── flake.lock
├── PLAN.md
├── README.md
├── hosts/
│   └── laptop/
│       ├── default.nix          # NixOS module (Phase 2 — stub/commented now)
│       └── hardware.nix         # placeholder; generate on real machine
├── home/
│   ├── default.nix              # home-manager entry: user, imports, unfree
│   ├── packages.nix             # curated home.packages
│   └── modules/
│       ├── niri.nix
│       ├── noctalia.nix
│       ├── fish.nix
│       ├── starship.nix
│       ├── nvim.nix
│       ├── git.nix
│       ├── tmux.nix
│       ├── kitty.nix
│       ├── foot.nix
│       ├── ghostty.nix
│       ├── alacritty.nix
│       ├── rofi.nix
│       ├── yazi.nix
│       ├── fastfetch.nix
│       └── gtk-qt.nix
└── assets/
    ├── noctalia/settings.toml
    ├── niri/config.kdl
    ├── niri/noctalia.kdl
    ├── fish/  (config.fish + completions)
    ├── nvim/  (init.lua, lua/, lazy-lock.json)
    └── tmux/tmux.conf
```

## Module porting notes

### niri
- Copy `config.kdl` verbatim via `xdg.configFile."niri/config.kdl"`.
- Keep `spawn-at-startup "noctalia"`, the `environment { ... }` block,
  keybinds (call `noctalia msg`, `rofi` fallback, `foot`/`ghostty`).
- Remove the `waybar` spawn (waybar not ported) but keep rofi fallback binds.
- Copy `noctalia.kdl` theme file.

### noctalia
- `imports = [ inputs.noctalia.homeModules.default ]`
- `programs.noctalia.enable = true`
- `programs.noctalia.settings = ./assets/noctalia/settings.toml`
- Package auto-installed by module.
- Port enabled plugins: dns-switcher, wl-screen-mirror, mawaqit,
  keybind-cheatsheet, screen-toolkit, udiskie (settings in settings.toml).
- Wallpaper `~/Pictures/Wallpapers/tree-in-green-field.webp` — copy into
  `assets/` and point settings at the flake path (or keep default).

### fish
- `programs.fish`: `shellAliases`, `interactiveShellInit` (starship,
  zoxide, fzf, completions), `sessionVariables`.
- **Arch-specific env vars** (`JAVA_HOME=/usr/lib/jvm/java-26`,
  `ANDROID_HOME=~/Android/Sdk`, `PNPM_HOME`, NI NI paths, surreal paths) are
  hardcoded and WILL break on NixOS → keep now, flag for parametrization.

### nvim
- `programs.neovim` + `home.file` copies of `init.lua`, `lua/`, `lazy-lock.json`.
- lazy.nvim fetches plugins at runtime (approved). Needs git, curl, unzip.

### tmux
- Copy `tmux.conf`; TPM fetches plugins at runtime (approved).

### terminals (kitty / foot / ghostty / alacritty)
- Base configs via `programs.*`; colors come from Noctalia templates.
- Keep any existing theme import lines.

### git
- `programs.git`: user Sultan Majed, email, `insteadOf` github→git@, core.editor nvim.

### rofi / yazi / fastfetch / starship / gtk-qt
- `programs.*` faithful; GTK/Qt themes from Noctalia; fonts via home.packages.

## Curated package list (draft)

Groups → nixpkgs names (Arch names differ; final mapping in `home/packages.nix`):

- **Shell/CLI**: eza, zoxide, fzf, fd, ripgrep, bat, btop, htop, tree, jq, yq,
  glow, onefetch, fastfetch, starship, superfile, yazi, tealdeer, unzip, unrar,
  p7zip, uutils-coreutils, trash-cli
- **Terminals**: kitty, foot, ghostty, alacritty
- **Editors**: neovim, vim, codelldb, shellcheck, texlab
- **WM/DE**: niri, rofi, kanshi, nwg-displays, swaylock, swaybg, slurp, grim,
  wl-clipboard, wtype, wmenu, uwsm, cliphist, playerctl, xdg-desktop-portal, polkit
- **Git/tools**: git, gh, lazygit, lazydocker, just
- **Media**: mpv, ffmpeg, yt-dlp, imagemagick, obs-studio, kdenlive, blender,
  inkscape, audacity, easyeffects, gpu-screen-recorder, pavucontrol
- **Browsers**: zen-browser, chromium, firefox, qutebrowser, tor-browser, w3m
- **Dev**: nodejs, bun, pnpm, go, rustup, dotnet-sdk, jdk, maven, gradle, kotlin,
  php, python, uv, zig, odin, docker, docker-compose, qemu, mitmproxy, nmap,
  wireshark, mariadb, postgresql, redis, sqlite
- **Security/CTF**: aircrack-ng, bettercap, hashcat, john, proxychains-ng,
  scapy, radare2, ghidra, r2ghidra
- **Fonts**: nerd-fonts (jetbrains-mono, cascadia-code, fira-code), joypixels,
  noto-fonts, ttf-amiri/scheherazade, material-design-icons
- **Unfree/AUR/overlay**: noctalia (flake), zen-browser, matugen, legcord,
  superproductivity, packet-tracer, showmethekey, spotify, vscode, obsidian,
  signal-desktop, telegram
- AUR-only not in nixpkgs (packettracer, superproductivity, legcord,
  illogical-impulse-*, cht.sh, wooz, ...) → overlay or documented skip.

## Build / test on Arch (system-safe)

```
cd just-flake
nix flake lock                      # lock inputs
nix flake check                     # validate
home-manager build --flake .#laptop   # build drv, NO switch, NO system change
```

`home-manager build` only writes to `/nix/store` + a `result` symlink; it
never touches `~/.config` or the running system.

## Phase 2 (later, on NixOS)

- Run `nixos-generate-config` on the real machine → `hosts/laptop/hardware.nix`.
- Add `nixosConfigurations.laptop` to flake.nix.
- Wire home-manager as a NixOS module (`useGlobalPkgs`).
- `programs.noctalia.recommendedServices.enable` → NetworkManager + Bluetooth +
  UPower + power-profile service.
- Boot loader, GPU drivers (hardware unknown — fill in later).
- Rebuild: `sudo nixos-rebuild switch --flake .#laptop`.

## Risks / known breakers

- Fish env vars reference Arch paths (`/opt/android-studio`, `/usr/lib/jvm/...`,
  `~/repos/nipe`, surreal db paths) — must be parametrized before NixOS.
- Noctalia wallpaper absolute path — copy into assets.
- Noctalia plugins (state dir) may not ship from the flake/module — document.
- First build downloads nixpkgs-unstable + noctalia cache (large).
