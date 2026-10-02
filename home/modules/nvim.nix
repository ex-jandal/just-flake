{
  pkgs,
  lib,
  ...
}:
{
  # - the rest of the toolchain (curl, unzip, ripgrep, fd, nodejs, python3,
  #   lazygit) is in home/packages.nix; `git` comes from programs.git.
  home.packages = with pkgs; [
    gcc
    basedpyright
    # - mandatory for opencode.nvim: it finds the server port via
    #   `lsof -Fpn -iTCP -sTCP:LISTEN`, and :checkhealth opencode errors without it
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
    # - `cp` inherits the store's 0444 mode, which blocks lazy.nvim from writing
    #   new pins. Restore owner-write unconditionally so broken lockfiles that
    #   already exist get repaired too.
    chmod u+w "$HOME/.config/nvim/lazy-lock.json"
  '';

  # - nvim as default editor (system-wide in home-manager).
  home.sessionVariables.EDITOR = "nvim";
}
