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
    # - opencode.nvim discovers a running server's port via
    #   `pgrep -f 'opencode.*--port'` + `lsof -Fpn -iTCP -sTCP:LISTEN`.
    #   `lsof` is mandatory there and `:checkhealth opencode` errors without it.
    lsof
  ];

  home.file.".config/nvim/init.lua".source = ../../assets/nvim/init.lua;
  home.file.".config/nvim/lua".source = ../../assets/nvim/lua;

  # - Seed lazy-lock.json as a writable copy (NOT a read-only nix-store symlink)
  #   so lazy.nvim can update plugin versions during :Lazy install/update/sync.
  home.activation.seedNvimLock = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/nvim"
    if [[ ! -f "$HOME/.config/nvim/lazy-lock.json" ]]; then
      cp -f "${../../assets/nvim/lazy-lock.json}" "$HOME/.config/nvim/lazy-lock.json"
    fi
    # - `cp` inherits the source's 0444 mode from the read-only nix store, which
    #   stops lazy.nvim from writing new pins. Restore owner-write unconditionally
    #   so pre-existing broken lockfiles get repaired too.
    chmod u+w "$HOME/.config/nvim/lazy-lock.json"
  '';

  # - nvim as default editor (system-wide in home-manager).
  home.sessionVariables.EDITOR = "nvim";
}
