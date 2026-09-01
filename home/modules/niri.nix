{
  pkgs,
  ...
}:
{
  # Niri window manager — faithful copy of config.kdl + mirroring script.
  # noctalia.kdl / monitor.kdl are NOT shipped as store symlinks (Noctalia
  # must be able to overwrite them); they are seeded as real writable files
  # (seed-if-absent) so niri's includes never dangle on a fresh install while
  # Noctalia's re-rendered themes survive rebuilds.
  home.packages = [ pkgs.niri ];

  xdg.configFile."niri/config.kdl".source = ../../assets/niri/config.kdl;
  xdg.configFile."niri/monitor-mirroring.sh".source = ../../assets/niri/monitor-mirroring.sh;

  home.file.".local/bin/monitor-mirroring.sh" = {
    source = ../../assets/niri/monitor-mirroring.sh;
    executable = true;
  };

  home.activation.seedNoctaliaThemeFiles = ''
    # install -m 0644 (not cp) — cp preserves the read-only perms of store
    # sources, which would block Noctalia from overwriting the seeded file.
    seed_file() {
      local dst="$1" src="$2"
      if [ ! -e "$dst" ]; then
        mkdir -p "$(dirname "$dst")"
        install -m 0644 "$src" "$dst"
      fi
    }

    seed_file "$HOME/.config/niri/noctalia.kdl"      ${../../assets/niri/noctalia.kdl}
    seed_file "$HOME/.config/niri/monitor.kdl"       ${../../assets/niri/monitor.kdl}
    seed_file "$HOME/.config/kitty/themes/noctalia.conf" ${../../assets/kitty/themes/noctalia.conf}
    seed_file "$HOME/.config/foot/themes/noctalia"   ${../../assets/foot/themes/noctalia}
    seed_file "$HOME/.config/ghostty/themes/noctalia" ${../../assets/ghostty/themes/noctalia}
  '';
}