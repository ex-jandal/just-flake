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
      nixd
      # Shell / data / markup
      # - pandoc is not a language server. It is what `markdown-preview' (SPC m p)
      #   shells out to: markdown-mode renders markdown by calling into Doom's
      #   +markdown-compile-functions (modules/lang/markdown/config.el), which
      #   tries marked, pandoc, markdown and multimarkdown in order, stopping at
      #   the first to return non-nil. Each one is gated on executable-find, so
      #   with no binary on $PATH they all return nil and the run ends in
      #   "No markdown program could be found. Install marked, pandoc, markdown
      #   or multimarkdown."
      # - No module flag is needed: that list is already Doom's default, so
      #   `:lang (markdown +lsp +tree-sitter)' is enough once this exists.
      #   `marked' is not in nixpkgs at all (only marked-man, which is unrelated),
      #   and nixpkgs' multimarkdown may install its binary as `mmd', which would
      #   fail executable-find silently. pandoc's name is unambiguous
      #   (meta.mainProgram = "pandoc"), so it works first try.
      # - Doom invokes it as `pandoc -f markdown -t html --mathjax', so LaTeX
      #   math and HTML output both work. The closure is large; swap for
      #   multimarkdown if that matters more than certainty.
      pandoc
      bash-language-server
      fish-lsp
      shellcheck
      mesonlsp
      marksman
      taplo
      yaml-language-server
      texlab
      # basedpyright and jdt-language-server have no lsp-mode client, so they are
      # registered by hand in assets/doom/config.el.
      basedpyright
      # Systems
      clang-tools
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
      vscode-css-languageserver
      vscode-langservers-extracted
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

      # - org-view-mode hides Org markup (leading stars, #+keyword lines, tags,
      #   properties) so a document reads as prose instead of source. Used by
      #   my-markdown-view in assets/doom/config.el to preview Markdown inside
      #   Emacs. Already in nixpkgs emacsPackages, so it needs no :pin/:recipe —
      #   assets/doom/packages.el demands a 40-char commit for anything Doom
      #   does not ship, and `git ls-remote' cannot authenticate here.
      epkgs.org-view-mode

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
