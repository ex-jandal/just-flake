;;; packages.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Almost everything here is unnecessary: Doom's own packages.el files already
;; declare every package its enabled modules need, and nix-doom-emacs-unstraightened
;; (home/modules/doom-emacs.nix) resolves those pins out of nixpkgs +
;; emacs-overlay at build time. So this file only needs entries for things Doom
;; does NOT ship a module for.
;;
;; Rules for adding an entry here:
;;   * must be resolvable from nixpkgs `emacsPackages`, OR
;;   * need a `:recipe` AND a `:pin`, or the Nix build fails with
;;     "unable to derive repository URL".
;;   * `:pin` is a full 40-char git commit. Look it up with:
;;       git ls-remote https://github.com/OWNER/REPO HEAD

;; - :lang vala does not exist upstream, so Doom never declares vala-mode.
;;   Dropped: `vala-mode` is in nixpkgs emacsPackages, but vala-ls (the LSP)
;;   is not, so this only buys syntax highlighting with no completion.
;;   Uncomment if you want it.
;; (package! vala-mode)

;; Prefer Doom's own tree-sitter grammars; the nixpkgs set is provided via
;; `extraPackages` (with-all-grammars) so that grammar .so files are compiled
;; ahead of time rather than at first launch.
