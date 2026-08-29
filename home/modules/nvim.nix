{
  pkgs,
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
  home.file.".config/nvim/lazy-lock.json".source = ../../assets/nvim/lazy-lock.json;
  home.file.".config/nvim/lua".source = ../../assets/nvim/lua;

  # Set nvim as default editor system-wide in home-manager.
  home.sessionVariables.EDITOR = "nvim";

  programs.neovim.enable = false;
}
