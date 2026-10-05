;;; init.el -*- lexical-binding: t; -*-

;; This file is loaded by Doom's :user module (DOOMDIR points here, in the Nix
;; store). Everything private goes in config.el instead.

(doom! :completion
       (vertico +icons)
       (corfu +icons +orderless)

       :ui
       doom
       dashboard
       modeline
       hl-todo
       nav-flash
       ophints
       (popup +defaults)
       window-select
       neotree
       zen

       :editor
       (evil +everywhere)
       file-templates
       ;; - `SPC c f' is bound to +format/region-or-buffer by :config default
       ;;   +bindings regardless of whether this module is on. Doom only generates
       ;;   autoloads for ENABLED modules (lisp/cli/loaddefs.el skips a module's
       ;;   autoloads when `doom-module-active-p' is false), so without this the
       ;;   key points at a function that was never defined and pressing it throws
       ;;   "Wrong type argument: commandp, +format/region-or-buffer".
       ;; - +lsp routes SPC c f through textDocument/formatting. No +onsave: that
       ;;   would reformat every file on save. Formatting stays on demand.
       (format +lsp)
       fold
       snippets
       word-wrap
       multiple-cursors

       :emacs
       (dired +dirvish +icons)
       (ibuffer +icons)
       undo
       vc

       :term
       eshell
       vterm
       ;; (ghostel +everywhere)

       :os
       (:if (featurep :system 'macos) macos)
       (tty +osc)

       :lang
       (cc +lsp +tree-sitter)
       (csharp +lsp +tree-sitter)
       ;; - no :lang vala module exists upstream; XML/CSV come from :lang data.
       data
       emacs-lisp
       (go +lsp +tree-sitter)
       (java +lsp +tree-sitter)
       (json +lsp +tree-sitter)
       (javascript +lsp +tree-sitter)
       (kotlin +lsp +tree-sitter)
       (latex +cdlatex +lsp)
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
       (org +journal +roam +pretty +dragndrop +gnuplot)
       (php +lsp +tree-sitter)
       (python +lsp +tree-sitter)
       (qt +lsp +tree-sitter)
       (rest +jq)
       (rust +lsp +tree-sitter)
       (sh +lsp +tree-sitter)
       ;; - html + css + svelte LSPs. Nothing outside this module hooks lsp-mode
       ;;   into those modes: modules/lang/web/+html.el:169 and +css.el:71 are the
       ;;   only `add-hook ... :append #'lsp!' for web-mode/html-mode/nxml-mode and
       ;;   the css family. Without this line .html fell through to the built-in
       ;;   mhtml-mode and .css to the built-in css-mode — both loaded, neither with
       ;;   a client — and .svelte had no auto-mode-alist entry at all.
       ;; - It also claims `\.svelte\': +html.el does `(use-package! web-mode :mode
       ;;   "\\.svelte\\'")'. config.el requires svelte-mode, which prepends its own
       ;;   entry and so wins that extension.
       (web +lsp +tree-sitter)
       (yaml +lsp +tree-sitter)
       (zig +lsp +tree-sitter)

       :tools
       debugger
       direnv
       editorconfig
       ;; - NOT optional: :config default +bindings binds SPC c d/D/i/t/k to
       ;;   #'+lookup/* unconditionally (+evil-bindings.el), so omitting this
       ;;   module leaves five keys pointing at undefined functions and they
       ;;   throw "Wrong type argument: commandp, +lookup/definition".
       lookup
       (lsp +lsp)
       (magit +forge)
       pdf
       tree-sitter

       :checkers
       (syntax +flymake +icons)
       (spell +hunspell)

       :config
       (default +bindings +smartparens))
