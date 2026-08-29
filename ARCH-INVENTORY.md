# Arch → NixOS Migration Inventory

**Purpose**: point-in-time reference of the current Arch system (snapshot
2026-08-29) so NixOS migration can replicate it faithfully. Read this together
with `NIXOS-SETUP.md` (how to build/apply) and `PLAN.md`.

Raw evidence lives in `arch/*.txt` (regenerate with the commands below).
Package→NixOS mapping: `arch/pkgs-nixos-mapping.md`.

---

## 1. System identity

| Field | Value |
|---|---|
| hostname | `nixos` (Arch was `archlinux`) |
| OS | Arch Linux (x86_64), **not** NixOS yet |
| kernel | `7.1.3-zen1-3-zen` (linux-zen) |
| locale | `en_US.UTF-8` |
| timezone | **Asia/Aden** |
| init | systemd + greetd |
| compositor | Niri (Wayland) + Noctalia shell |
| microcode | amd-ucode |

> **Gap**: libcap — `hosts/nixos/default.nix` sets no `time.timeZone`.
> Add `time.timeZone = "Asia/Aden";` and `i18n.defaultLocale = "en_US.UTF-8";`.

## 2. Hardware

| Component | Detail |
|---|---|
| CPU | AMD **Ryzen 5 5625U** (8 threads) |
| iGPU | AMD **Barcelo** `1002:15e7` (rev c2) — `amdgpu` driver — HP chassis `103c:8a1b` |
| RAM | 19 GiB |
| Swap | `/swapfile` 4 GiB (swap on ZRAM not used) |
| Storage | ext4 `/` + vfat `/boot` (see §3) |
| Audio | AMD Renoir/Cezanne HDMI/DP Discrete Audio |

GPU stack on Arch: `mesa`, `vulkan-radeon`, `lib32-mesa`, `lib32-vulkan-radeon`,
`linux-firmware-amdgpu`, `obs-vaapi`, `libva`. → NixOS: `hardware.graphics.enable`
(+ `enable32Bit = true`). Already scaffolded in `hosts/nixos/default.nix`.

## 3. Boot & filesystems

> **Resolved on NixOS**: `hosts/nixos/default.nix` now uses **GRUB on UEFI**
> (`boot.loader.grub` + `efiSupport`, device `nodev`) with the **systemd initrd**
> (`boot.initrd.systemd.enable`) — matching Arch's GRUB + booster setup.

Evidence: `arch/boot.txt`, `arch/fstab.txt`.

- **Bootloader**: GRUB (`grubx64.efi` at `/boot/EFI/ARCH/`), EFI entry `Boot0000* ARCH`
- **Initramfs**: on NixOS `boot.initrd.systemd.enable = true` (NixOS-native fast
  initrd; the "booster" generator isn't a NixOS option).
- **Plymouth** (Arch only): hooks `base udev plymouth autodetect ...` — not yet ported;
  add `boot.plymouth.enable` if you want the splash.
- **Microcode**: `HOOKS=... microcode ...`, `amd-ucode.img` → `hardware.cpu.amd.updateMicrocode`
- **fstab mounts** (Arch):
  - `/` ext4 `UUID=3492e124-...`
  - `/boot` vfat `UUID=C44E-BC6E`
  - `/swapfile`
  - **bind mounts**: `~/.config/nvim → /root/.config/nvim`, `~/.local/share/nvim → /root/.local/share/nvim`
    (root gets the user's nvim config). On NixOS this is unusual — consider dropping or
    replicating via `home-manager` for root.

## 4. Display / shell

- **Niri** + **Noctalia** (native Wayland shell; `uwsm` session)
- **greetd** + **noctalia-greeter** as display manager (already wired in
  `hosts/nixos/default.nix`)
- Wayland session entry: `niri.desktop` → `Exec=uwsm start niri`
- GTK/Qt theming: `gtk-3.0`, `gtk-4.0`, `gtkrc`, `qt5ct`, `qt6ct`, `Kvantum`, `dconf`
- EasyEffects (audio DSP) + `xcursor` themes (whitesur)

## 5. Enabled services

Evidence: `arch/services.txt` (systemd `--state=enabled`).

- `greetd` (DM), `bluetooth`, `avahi-daemon`, `NetworkManager-dispatcher`
- `tlp`, `tlp-rdw`, `tlp-pd` (power) → NixOS `services.tlp` **+ tlp-pd** (rdw
  has no NixOS module option; dropped). `power-profiles-daemon` force-disabled.
- `docker` (+socket), `libvirtd` (+sockets), `rusbmux`
- `dnscrypt-proxy`, `tor`
- `nix-daemon` (already running for Nix)
- Note: **NetworkManager** is the intended network backend (Noctalia needs it;
  Arch also has `dhcpcd`/`dhclient`/`iwd` installed but NM active). On NixOS:
  NM uses the **iwd** backend, and DNS routes to local dnscrypt (`127.0.0.1:53`).

## 6. Package census

| Category | Count | File |
|---|---|---|
| Explicit (official+pinned) | 491 | `arch/pkgs-explicit.txt` |
| AUR / foreign | 86 | `arch/pkgs-aur.txt` |

The flake's `home/packages.nix` curates only a small daily-driver subset.
Most of the 491 are runtime deps or not yet ported — see mapping doc.

**Only the 86 AUR packages realistically need manual work**; the rest are in
nixpkgs. Map: `arch/pkgs-nixos-mapping.md`.

## 7. AUR → NixOS highlights

- **Already flake-wired**: `noctalia`, `noctalia-greeter`
- **In nixpkgs (verified)**: darkly, dma, dynamips, ftxui, gns3-gui/server,
  lowfi, mars-mips, matugen, mongoose, poop, rockyou, uefi-run, vpcs, ubridge,
  amiri, whitesur themes, and ~30 more.
- **NOT in nixpkgs (manual/flatpak)**: carbonyl, codelldb (via vscode-extension),
  golings, gabarito, lateef, walrs, xmcl, zigdown, makeheaders, packettracer.
- Full list: `arch/pkgs-nixos-mapping.md`.

## 8. Dotfile delta

243 dirs under `~/.config`; **14 are captured** in `assets/` (alacritty,
fastfetch, fish, fontconfig, foot, ghostty, kitty, niri, noctalia, nvim, rofi,
starship, tmux, yazi). The `assets/dnscrypt/` dir captures DNSCrypt list files
(not under `~/.config`).

Full uncovered list: `arch/dotfiles-uncovered.txt` (227 entries).

**Notable uncovered, worth porting** (curated by class):
- **Dev/editor**: `helix`, `avante.nvim`, `lazyvim`, `nvim-bak`, `sqls`, `opencode`,
  `codesnap`, `github-copilot`, `uv`, `composer`, `intelephense`, `psysh`
- **WM/display**: `waybar`, `fuzzel`, `mako`, `swaylock`, `wlogout`, `nwg-displays`,
  `walker`, `pavucontrol-qt`, `fcitx5` (input method), `kanshi`
- **Theming**: `gtk-3.0`, `gtk-4.0`, `gtkrc`, `QtProject`, `qt5ct`, `qt6ct`, `Kvantum`,
  `dconf`, `matugen`, `easyeffects`, `illogical-impulse`
- **Term/CLI**: `btop`, `cava`, `nvtop`, `yazi`(covered), `zellij`, `kew`, `termusic`,
  `nnn`, `mpv`, `superfile`
- **Apps/widgets**: `obsidian`, `aurora/obs-studio`, `qBittorrent`, `telegram-desktop`,
  `signal-desktop`, `Spicetify`, `KDEConnect`, `Legcord`, `superProductivity`
- **KDE/polyglot residue** (likely can drop): `kwinrc`, `kdeglobals`, `plasma-*`,
  `dolphin*`, `konqueror*`, `baloo*`, `kde-material-you-colors`
- **Per-app state/noise** (skip): `.cache`-like, `Electron`, `Godot`, `dolphin-emu`,
  `retroarch`, `Minecraft`, per-browser state dirs, `mimeapps.list-bak`

> Decide later which to add to `assets/` + `home/modules`. This doc only records.

## 9. Env / session variables (Arch)

Already in home-manager `fish.nix` (`home.sessionVariables`):
`EDITOR=nvim`, `PAGER=bat`, `MANPAGER=nvim -c +Man!`,
`JAVA_HOME=/usr/lib/jvm/java-26-openjdk`, `ANDROID_*`, `PNPM_HOME`, `fish_lsp_server_path`.

**Confirm on migration**: Java version (Arch has jre25 + jre21 + jdk; pick one),
Android SDK path, pnpm dir — these are Arch-paths and must be reparametrized
(they are JSON/git-ignored for now).

---

## Regeneration commands

```bash
cd just-flake
pacman -Qeq > arch/pkgs-explicit.txt
pacman -Qmq > arch/pkgs-aur.txt
systemctl list-unit-files --state=enabled > arch/services.txt
cat /etc/fstab > arch/fstab.txt
# gpu/boot: see arch/gpu.txt, arch/boot.txt headers (dump via lspci/uname/etc.)
```
