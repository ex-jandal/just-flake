{
  pkgs,
  lib,
  ...
}:
{
  # NeoVim — NvChad-based (lazy.nvim). Config copied verbatim; plugins fetch
  # at runtime via lazy.nvim (approved: runtime network fetch, not nix-pinned).
  home.packages = with pkgs; [
    neovim
    # lazy.nvim plugin system deps + formatters often invoked from within nvim
    git
    curl
    unzip
    ripgrep
    fd
    gcc
    nodejs
    python3
    lazygit
    marksman
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

  programs.neovim.enable = false;
}
