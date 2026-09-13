{
  pkgs,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    git
    curl
    unzip
    ripgrep
    fd
    gcc
    nodejs
    python3
    lazygit
    nil
    basedpyright
  ];

  home.file.".config/nvim/init.lua".source = ../../assets/nvim/init.lua;
  home.file.".config/nvim/lua".source = ../../assets/nvim/lua;

  # Seed lazy-lock.json as a writable copy (NOT a read-only nix-store symlink),
  # so lazy.nvim can update plugin versions in the lock file during
  # :Lazy install/update/sync.
  home.activation.seedNvimLock = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [[ ! -f "$HOME/.config/nvim/lazy-lock.json" ]]; then
      mkdir -p "$HOME/.config/nvim"
      cp -f "${../../assets/nvim/lazy-lock.json}" "$HOME/.config/nvim/lazy-lock.json"
    fi
  '';

  # Set nvim as default editor system-wide in home-manager.
  home.sessionVariables.EDITOR = "nvim";
}
