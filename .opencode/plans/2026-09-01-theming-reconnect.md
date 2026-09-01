# Re-wire Noctalia theming to Qt/KDE apps + GTK/chromium

## Problem (verified)
- Noctalia generates `~/.config/qt6ct/colors/noctalia.conf` (valid palette: dark
  #101510, accent #308c3b), `~/.config/gtk-3.0|4.0/noctalia.css` (+ gtk.css import),
  `~/.local/share/color-schemes/noctalia.colors`, and dconf prefer-dark — but apps
  don't consume them:
  - qt6ct.conf has no `color_scheme_path`/`custom_palette` (removed in de-customize
    pass) -> dolphin + KDE apps render default palette ("unstyled").
  - settings.ini has NO `gtk-theme-name` -> GTK3/4 + chromium native chrome use
    default Adwaita (light-ish) despite portal dark + noctalia.css overlay.
  - `adw-gtk3` theme already installed in profile (home/packages.nix theme block).

## User decisions
- Qt: palette + explicit `style=Fusion` (Noctalia-colored flat look).
- GTK: base theme `adw-gtk3-dark` (+ noctalia.css overlay).

## Edits — `home/modules/gtk-qt.nix`
1. `gtk.theme = { name = "adw-gtk3-dark"; package = pkgs.adw-gtk3; };`
2. qt6ct.conf [Appearance] -> add:
   ```
   color_scheme_path=/home/abu_jandal/.config/qt6ct/colors/noctalia.conf
   style=Fusion
   custom_palette=true
   ```
   (keep icon_theme/cursor_theme/cursor_size/standard_dialogs).
3. Refresh the two stale "no palette override" comments.

## Deploy + verify (VM)
- rsync -> git add -A + commit wip -> `sudo nixos-rebuild switch --flake .#nixos`.
- `grep gtk-theme-name ~/.config/gtk-3.0/settings.ini` -> adw-gtk3-dark.
- `grep color_scheme_path ~/.config/qt6ct/qt6ct.conf`.
- `ls ~/.config/qt6ct/colors/noctalia.conf` still present (re-verify).
- Visual: relaunch dolphin + chromium in VM display.

## Local commit (normal message) when user asks.