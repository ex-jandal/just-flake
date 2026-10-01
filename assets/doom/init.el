;;; init.el -*- lexical-binding: t; -*-

;; This file is loaded by Doom's :user module (DOOMDIR points here, in the Nix
;; store). Everything private goes in config.el instead.

(doom! :completion
       vertico
       corfu

       :ui
       doom
       dashboard
       modeline
       nav-flash
       ophints
       (popup +defaults)
       window-select
       neotree

       :editor
       (evil +everywhere)
       file-templates
       fold
       snippets
       word-wrap

       :emacs
       dired
       undo
       vc

       :term
       eshell
       vterm

       :os
       (:if (featurep :system 'macos) macos)
       (tty +osc)

       :lang
       (cc +lsp +tree-sitter)
       (csharp +lsp +tree-sitter)
       ;; - no :lang vala module exists upstream; XML/CSV come from :lang data.
       data
       (go +lsp +tree-sitter)
       (java +lsp +tree-sitter)
       (json +lsp +tree-sitter)
       (javascript +lsp +tree-sitter)
       (kotlin +lsp +tree-sitter)
       (latex +lsp)
       (markdown +lsp +tree-sitter)
       ;; - :lang nim has no +lsp flag upstream (zls works anyway; see config.el)
       nim
       (nix +lsp +tree-sitter)
       ;; - deliberately no +present: it pulls `revealjs`, the only package in
       ;;   this config absent from nixpkgs AND emacs-overlay. Unstraightened
       ;;   then fetches hakimel/reveal.js itself with `shallow = false;
       ;;   allRefs = true` — a full git clone on every rebuild. Costs a 35MB
       ;;   JS/CSS library to get org-present slides nobody has asked for.
       ;;   Re-add the flag + one fetchTree setting if presentations matter.
       (org +journal +roam +pretty)
       (php +lsp +tree-sitter)
       (python +lsp +tree-sitter)
       (qt +lsp +tree-sitter)
       (rest +jq)
       (rust +lsp +tree-sitter)
       (sh +lsp +tree-sitter)
       (yaml +lsp +tree-sitter)
       (zig +lsp +tree-sitter)

       :tools
       debugger
       direnv
       editorconfig
       (lsp +lsp)
       magit
       pdf
       tree-sitter

       :checkers
       (syntax +flymake)
       (spell +hunspell)

       :config
       (default +bindings))
