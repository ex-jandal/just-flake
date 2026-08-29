# AUR Package → NixOS Mapping

Reference for migrating the 86 AUR-installed packages (snapshot: 2026-08-29)
to NixOS. Each row: how to get the equivalent on NixOS.

Legend
- **nixpkgs** — exists in nixpkgs (exact attr name given; click-name or Cachix cache may differ).
- **unfree** — requires `allowUnfreePredicate`/`allowUnfree` (flake already sets `_ : true`).
- **git/fetch** — not packaged; grab upstream source/script or write a flake-parts/drv.
- **runtime data** — not a binary; copy files instead of installing.
- **skip** — build tool / debug dep / superseded; drop on NixOS.

## AUR-only packages

| AUR pkg | Class | NixOS equivalent / note |
|---|---|---|
| adw-gtk-theme-git | nixpkgs | attr `adw-gtk3` (older) or `libadwaita` themes; GTK `.config/gtk-4.0` covers most |
| archtry | skip | AUR helper for trying packages; obsolete on NixOS |
| artha | nixpkgs | attr `artha` |
| breeze-plus | nixpkgs | `breeze-plus` (KDE) — only if KDE kept |
| carbonyl-bin | NOT in nixpkgs | headless Chromium browser — flatpak or manual drv |
| cht.sh-git | git | shell script — `home.packages` fetch or `fetchFromGitHub` of `chubin/cheat.sh` client |
| codelldb-bin | vscode-ext | `vscode-extensions.vadimcn.vscode-lldb` (Neovim dap adapter) |
| darkly-bin | nixpkgs | attr `darkly` (KDE Kvantum theme) — verified |
| dma | nixpkgs | attr `dma` (DragonFly Mail Agent) — verified |
| docgen | git | upstream `mongodb/docgen` — write drv or skip |
| dynamips | nixpkgs | attr `dynamips` — verified |
| easyeffects-bundy01-presets | runtime data | copy preset files into `~/.config/easyeffects/` (already have easyeffects active) |
| easyeffects-digitalone1-presets-git | runtime data | copy preset XML |
| easyeffects-jtrv-presets-git | runtime data | copy preset XML |
| electron37 | nixpkgs | attr `electron` pinned version; usually avoid — prefer app's bundled electron |
| fpm | nixpkgs | attr `fpm` (Ruby packaging) — note brings ruby stack |
| ftxui | nixpkgs | attr `ftxui` (header-only C++ UI lib) |
| gns3-gui | nixpkgs | attr `gns3-gui` — verified |
| gns3-server | nixpkgs | attr `gns3-server` — verified |
| go-pray-bin | git | upstream; small binary — write drv fetching release |
| golings | NOT in nixpkgs | flatpak or manual — `go-lang-tour` alternative `golings` repo |
| illogical-impulse-audio | nixpkgs | `illogical-impulse` is GTK 5 shell theme suite; `illogical-impulse-audio` = audio preset pack |
| illogical-impulse-backlight | nixpkgs | backlight component of `illogical-impulse` |
| illogical-impulse-basic | nixpkgs | base GTK/CSS of `illogical-impulse` |
| illogical-impulse-bibata-modern-classic-bin | nixpkgs | Bibata cursor (part of theme suite) |
| illogical-impulse-fonts-themes | nixpkgs | fonts/themes sub-pkgs of suite |
| illogical-impulse-kde | nixpkgs | KDE flavor of theme |
| illogical-impulse-microtex-git | nixpkgs | microtex component |
| illogical-impulse-microtex-git-debug | skip | debug build |
| illogical-impulse-python | nixpkgs | Python component of suite |
| illogical-impulse-toolkit | nixpkgs | toolkit component |
| imgcat | nixpkgs | attr `imgcat` (or `chafa` alternative — already installed) |
| java-debug | nixpkgs | VS Code Java debugger (`java-debug` in nixpkgs) |
| java-lombok | nixpkgs | attr `lombok` |
| laravel-ls-git | git | Laravel language server — npm/Composer global or `laravel-ls` |
| lib32-libwebp | nixpkgs | attr `pkgsi686Linux.libwebp` |
| libdeep_filter_ladspa-bin | git | LSP deep filter LADSPA plugin; `linuxstudioplugins` or manual .so into ladspa dir |
| lowfi | nixpkgs | attr `lowfi` (Rust LoFi player) — verified |
| makeheaders | NOT in nixpkgs | tiny C header generator — vendored in repo, trivial C build |
| mars-mips | nixpkgs | attr `mars-mips` (MIPS simulator) — verified |
| matugen-bin | nixpkgs | attr `matugen` — verified `.config/matugen` exists |
| mongoose | nixpkgs | attr `mongoose` — verified |
| noctalia-greeter | nixpkgs | **flake input** `noctalia-greeter` (already wired: `programs.noctalia-greeter`) |
| otf-space-grotesk | nixpkgs | attr `space-grotesk` (font) |
| packettracer | unfree | Cisco Packet Tracer — writes system dirs; needs manual install on NixOS |
| paru-debug | skip | debug build of AUR helper — obsolete on NixOS |
| poop | nixpkgs | attr `poop` (ASCII poop tracker) |
| python-py-cpuinfo | nixpkgs | attr `python3Packages.py-cpuinfo` |
| python-telnetlib3 | nixpkgs | Python 3.9 `telnetlib3` (3.13 removed stdlib) — `python3Packages.telnetlib3` |
| python2-bin | skip | Python 2 — drop unless old scripts need it |
| qemu-block-gluster | nixpkgs | `qemu` pulls gluster support via `glusterfs` dependency (nixpkgs `qemu_kvm`); enable `buildWithGluster` where needed |
| quran-companion | git | desktop Quran app — write drv or use flatpak |
| rockyou | nixpkgs | attr `rockyou` (password wordlist) — verified |
| ruby-arr-pm etc. (fpm deps) | nixpkgs | `fpm` pulls these automatically; don't install individually |
| rusbmux-git | nixpkgs | attr `rusbmux` (used-by `scrcpy` USB) — service enabled |
| spimsuite-svn | nixpkgs | attrs `qtspim` / `xspim` (SPIM MIPS simulator GUI) |
| ttf-amiri | nixpkgs | attr `amiri` (font) — verified |
| ttf-cairo | nixpkgs | nixpkgs attrs `cairo-latex`? — uncertain; fonts mostly set via `fonts.packages` |
| ttf-gabarito-git | NOT in nixpkgs | fetch Google Fonts gabarito — `fonts.packages` custom |
| ttf-joypixels | nixpkgs | attr `joypixels` (flake: `nixpkgs.config.joypixels.acceptLicense`) |
| ttf-roboto-flex | nixpkgs | `roboto` / `roboto-flex` font |
| ttf-rubik-vf | nixpkgs | attr `rubik` (font) |
| ttf-sil-lateef | NOT in nixpkgs | fetch SIL lateef — `fonts.packages` custom |
| ttf-weather-icons | nixpkgs | attr `weather-icons` (font) |
| ubridge | nixpkgs | attr `ubridge` (GNS3 bridge) — verified |
| uefi-run | nixpkgs | attr `uefi-run` — verified |
| vpcs | nixpkgs | attr `vpcs` (GNS3 virtual PC) — verified |
| walrs-git | NOT in nixpkgs | Rust pywal port not packaged — use `pywal` or `wallust` instead |
| whitesur-cursor-theme-git | nixpkgs | attr `whitesur-cursor-theme` |
| whitesur-gtk-theme | nixpkgs | attr `whitesur-gtk-theme` |
| whitesur-icon-theme-git | nixpkgs | attr `whitesur-icon-theme` |
| wlroots0.19 | git | pinned wlroots ABI — matches nothing current; skip unless a pinned compositor needs it |
| wooz-git | git | `wooz` (AI coding CLI) — write drv or skip |
| wordnet-common / dictd / progs | nixpkgs | attr `wordnet` |
| xcursor-pixelfun-all | git | cursor theme — copy `cursors` xcursor dir |
| xmcl-electron-bin | NOT in nixpkgs | flatpak `XMCL` or manual drv (Minecraft launcher) |
| zigdown-bin | NOT in nixpkgs | manual drv or skip |

## Key official (non-AUR) packages with non-trivial NixOS mapping
(These are in official Arch repos; on NixOS they map to nixpkgs attrs.)

| Arch pkg | NixOS note |
|---|---|
| niri / uwsm / wlroots | nixpkgs attrs `niri`, `uwsm`; **session entry must be provided** (already in hosts/nixos) |
| noctalia / noctalia-greeter | flake inputs (already wired) |
| linux-zen | `boot.kernelPackages = pkgs.linuxPackages_zen` |
| amd-ucode | `hardware.cpu.amd.updateMicrocode = true` |
| plymouth | `boot.plymouth.enable` |
| grub + efibootmgr | **hosts/nixos currently uses systemd-boot — switch to `boot.loader.grub` to match Arch** |
| mesa / vulkan-radeon / lib32-mesa | `hardware.graphics.enable = true` + `hardware.graphics.enable32Bit` |
| tlp / tlp-rdw / tlp-pd | `services.tlp.enable`, `services.tlp.rdw`, `powerManagement` |
| tor | `services.tor.enable` |
| docker / docker-compose | `virtualisation.docker.enable` |
| libvirt / virt-manager | `virtualisation.libvirtd.enable` |
| mariadb / postgresql | `services.mariadb.enable` / `services.postgresql.enable` |
| dnscrypt-proxy | `services.dnscrypt-proxy2.enable` |
| blueman / bluez | `services.bluetooth.enable` + blueman |
| signal-desktop, telegram-desktop, browsers | nixpkgs attrs of same name |
