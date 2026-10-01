{
  config,
  inputs,
  pkgs,
  ...
}:
{
  # - Doom's own build system pulls its elisp deps from nixpkgs + emacs-overlay
  #   rather than straight.el, so there is no `:doom sync` and no runtime
  #   compilation. The config in `assets/doom` is baked into the store, so
  #   changing it requires a `home-manager switch` (not `doom sync`).
  imports = [ inputs.doom-emacs.homeModule ];

  programs.doom-emacs = {
    enable = true;

    # - must be a git-tracked path: flake inputs do not see untracked files.
    doomDir = ../../assets/doom;
    # - must be an ABSOLUTE path: this option is `types.path`, which rejects a
    #   leading `~` at type-check time, before the module's own `~` expansion
    #   ever runs (its upstream `example` is misleading on this point).
    doomLocalDir = "${config.xdg.dataHome}/doom";

    # - language servers. Doom/lsp-mode exec these by bare name, so they have
    #   to be real binaries on $PATH — nvim's mason dir (~/.local/share/nvim/
    #   mason/bin) is deliberately NOT used, so the setup stays declarative.
    #   Missing by design: qmlls, vala-ls, slint-ls (not in nixpkgs).
    extraBinPackages = with pkgs; [
      # Nix
      nil
      nixd
      # Shell / data / markup
      bash-language-server
      fish-lsp
      shellcheck
      mesonlsp
      marksman
      taplo
      yaml-language-server
      texlab
      # Systems
      basedpyright
      clang-tools
      # - dape resolves its Rust/C/OCaml debuggers by bare command name
      #   (`lldb-dap', `lldb-vscode') with only `dape-ensure-command', which is
      #   just an executable-find check — so lldb on $PATH is all it needs, and
      #   nothing gets downloaded into the read-only dape-adapter-dir.
      #   clang-tools does NOT ship lldb-dap; only lldb does.
      lldb
      ccls
      csharp-ls
      gopls
      lua-language-server
      nim
      omnisharp-roslyn
      rust-analyzer
      zls
      # JVM
      jdt-language-server
      kotlin-language-server
      # Web
      # - both of these install BOTH spellings (vscode-css-language-server and
      #   vscode-css-languageserver, likewise for json), which is what lsp-mode
      #   looks for. `meta.mainProgram` reports only the plural one, so do not
      #   conclude from mainProgram alone that the singular name is missing.
      vscode-css-languageserver
      vscode-json-languageserver
      typescript-language-server
      vue-language-server
      svelte-language-server
      tailwindcss-language-server
      intelephense
      svgo
      # Infra
      docker-language-server
      docker-compose-language-service
      terraform-ls
      sqls
      vale
      typos
    ];

    # - tree-sitter grammars for the :lang modules below. Doom installs
    #   grammars into the *profile* data dir, so they must be pre-compiled and
    #   have their paths registered, or highlighting silently falls back to
    #   regex. Natives (tree-sitter-grammars) are built from source per grammar.
    #
    # - Color themes. Only gruvbox-dark is enabled in assets/doom/config.el;
    #   the rest are here so `M-x doom/load-theme` can switch at runtime with no
    #   rebuild. Note the nixpkgs attribute name does not always match the elisp
    #   theme symbol it provides: tokyo-night provides tokyonight-*,
    #   foggy-night-theme provides foggy-night, nord-theme provides nord-*.
    extraPackages = epkgs: [
      epkgs.treesit-grammars.with-all-grammars

      epkgs.gruvbox-theme
      epkgs.catppuccin-theme
      epkgs.tokyo-night
      epkgs.dracula-theme
      epkgs.nordic-night-theme
      epkgs.nord-theme
      epkgs.zenburn-theme
      epkgs.material-theme
      epkgs.foggy-night-theme
      epkgs.base16-theme
    ];
  };

  # - all-the-icons glyph set. Doom's icons come from here, and the Nerd Fonts
  #   themselves are already installed system-wide (hosts/nixos/modules/fonts.nix).
  home.packages = [
    pkgs.emacs-all-the-icons-fonts
    pkgs.hunspell
    pkgs.hunspellDicts.en_US
  ];

  # - Noctalia's emacs template writes its generated theme to the FIRST of
  #   ~/.config/doom, ~/.config/emacs, ~/.emacs.d that exists (see its
  #   assets/templates/emacs/output-path.sh). DOOMDIR is a read-only store path,
  #   so none of those exist by default and the template would silently emit
  #   nothing. Create ~/.config/doom/themes so it has somewhere to land.
  home.file.".config/doom/themes/.keep".text = "";
}
