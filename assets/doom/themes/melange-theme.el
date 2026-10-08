;;; melange-theme.el --- Melange theme for Emacs -*- lexical-binding: t; -*-

;; A Doom Emacs port of the dark Melange palette by savq.
;; Original project:
;; https://github.com/savq/melange-nvim
;;
;; Design principle from the original:
;;   control flow -> warm colors
;;   data         -> cool colors
;;
;; This file intentionally has no package dependencies.

(deftheme melange
  "Warm, earthy dark theme inspired by savq/melange-nvim.")

(let* ((class '((class color) (min-colors 89)))

       ;; -------------------------------------------------------------------
       ;; Melange palette -- taken from the upstream melange_dark palette.
       ;; -------------------------------------------------------------------
       (bg            "#292522")
       (bg-alt        "#34302C")
       (bg-dim        "#403A36")
       (bg-deep       "#233524")

       (fg            "#ECE1D7")
       (fg-alt        "#C1A78E")
       (fg-dim        "#867462")

       ;; Warm / control-flow colors
       (red           "#BD8183")
       (red-bright    "#D47766")
       (red-dark      "#7D2A2F")
       (yellow        "#E49B5D")
       (yellow-bright "#EBC06D")
       (yellow-dark   "#8B7449")
       (green         "#78997A")
       (green-bright  "#85B695")

       ;; Cool / data colors
       (blue           "#7F91B2")
       (blue-bright    "#A3A9CE")
       (blue-dark      "#273142")
       (cyan           "#7B9695")
       (cyan-bright    "#89B3B6")
       (cyan-dark      "#253333")
       (magenta        "#B380B0")
       (magenta-bright "#CF9BC2")
       (magenta-dark   "#422741")

       ;; UI
       (selection      "#403A36")
       (inactive       "#34302C")
       (line           "#403A36")
       (comment        "#867462")
       (error          "#D47766")
       (warning        "#EBC06D")
       (success        "#85B695")
       (info           "#89B3B6"))

  (custom-theme-set-faces
   'melange

   ;; -----------------------------------------------------------------------
   ;; Core Emacs
   ;; -----------------------------------------------------------------------
   `(default
     ((,class (:background ,bg :foreground ,fg))))
   `(cursor
     ((,class (:background ,yellow-bright))))
   `(fringe
     ((,class (:background ,bg :foreground ,fg-dim))))
   `(vertical-border
     ((,class (:foreground ,line))))
   `(shadow
     ((,class (:foreground ,comment))))
   `(link
     ((,class (:foreground ,blue-bright :underline t))))
   `(link-visited
     ((,class (:foreground ,magenta-bright :underline t))))
   `(highlight
     ((,class (:background ,selection))))
   `(region
     ((,class (:background ,selection))))
   `(secondary-selection
     ((,class (:background ,bg-dim))))
   `(match
     ((,class (:background ,yellow-dark :foreground ,fg))))
   `(isearch
     ((,class (:background ,yellow :foreground ,bg :weight bold))))
   `(lazy-highlight
     ((,class (:background ,selection :foreground ,yellow-bright))))
   `(isearch-fail
     ((,class (:background ,red-dark :foreground ,fg))))
   `(escape-glyph
     ((,class (:foreground ,yellow-bright))))
   `(trailing-whitespace
     ((,class (:background ,red-dark))))
   `(minibuffer-prompt
     ((,class (:foreground ,cyan-bright :weight bold))))
   `(error
     ((,class (:foreground ,error :weight bold))))
   `(warning
     ((,class (:foreground ,warning :weight bold))))
   `(success
     ((,class (:foreground ,success :weight bold))))
   `(tooltip
     ((,class (:background ,bg-alt :foreground ,fg))))

   ;; -----------------------------------------------------------------------
   ;; Font lock / syntax
   ;;
   ;; Melange's original philosophy is preserved here:
   ;; warm colors for control flow and cool colors for data.
   ;; -----------------------------------------------------------------------
   `(font-lock-builtin-face
     ((,class (:foreground ,cyan))))
   `(font-lock-comment-face
     ((,class (:foreground ,comment :slant italic))))
   `(font-lock-comment-delimiter-face
     ((,class (:foreground ,comment :slant italic))))
   `(font-lock-constant-face
     ((,class (:foreground ,blue))))
   `(font-lock-doc-face
     ((,class (:foreground ,fg-alt :slant italic))))
   `(font-lock-function-name-face
     ((,class (:foreground ,blue-bright))))
   `(font-lock-keyword-face
     ((,class (:foreground ,red-bright :weight bold))))
   `(font-lock-negation-char-face
     ((,class (:foreground ,red-bright :weight bold))))
   `(font-lock-preprocessor-face
     ((,class (:foreground ,yellow))))
   `(font-lock-regexp-grouping-backslash
     ((,class (:foreground ,magenta-bright))))
   `(font-lock-regexp-grouping-construct
     ((,class (:foreground ,magenta-bright))))
   `(font-lock-string-face
     ((,class (:foreground ,green-bright))))
   `(font-lock-type-face
     ((,class (:foreground ,cyan-bright))))
   `(font-lock-variable-name-face
     ((,class (:foreground ,cyan))))
   `(font-lock-warning-face
     ((,class (:foreground ,warning :weight bold))))

   ;; -----------------------------------------------------------------------
   ;; Mode line
   ;; -----------------------------------------------------------------------
   `(mode-line
     ((,class
       (:background ,bg-alt :foreground ,fg
        :box (:line-width 1 :color ,line)
        :weight normal))))
   `(mode-line-inactive
     ((,class
       (:background ,bg :foreground ,comment
        :box (:line-width 1 :color ,bg)))))
   `(mode-line-buffer-id
     ((,class (:foreground ,yellow-bright :weight bold))))
   `(mode-line-emphasis
     ((,class (:foreground ,cyan-bright :weight bold))))
   `(header-line
     ((,class (:background ,bg :foreground ,fg-alt))))

   ;; -----------------------------------------------------------------------
   ;; Line numbers / hl-line
   ;; -----------------------------------------------------------------------
   `(line-number
     ((,class (:background ,bg :foreground ,comment))))
   `(line-number-current-line
     ((,class (:background ,bg-alt :foreground ,yellow-bright :weight bold))))
   `(hl-line
     ((,class (:background ,bg-alt))))

   ;; -----------------------------------------------------------------------
   ;; Search / completion
   ;; -----------------------------------------------------------------------
   `(completions-common-part
     ((,class (:foreground ,cyan-bright))))
   `(completions-first-difference
     ((,class (:foreground ,yellow-bright :weight bold))))
   `(completions-highlight
     ((,class (:background ,selection :foreground ,fg))))
   `(completion-preview
     ((,class (:foreground ,comment))))
   `(icomplete-first-match
     ((,class (:foreground ,yellow-bright :weight bold))))

   ;; Corfu
   `(corfu-default
     ((,class (:background ,bg-alt :foreground ,fg))))
   `(corfu-current
     ((,class (:background ,selection :foreground ,yellow-bright :weight bold))))
   `(corfu-bar
     ((,class (:background ,yellow-bright))))
   `(corfu-border
     ((,class (:background ,bg-dim))))
   `(corfu-annotations
     ((,class (:foreground ,comment :slant italic))))

   ;; Vertico
   `(vertico-current
     ((,class (:background ,selection :foreground ,yellow-bright :weight bold))))
   `(vertico-group-title
     ((,class (:foreground ,cyan-bright :weight bold))))
   `(vertico-multiline
     ((,class (:foreground ,fg-alt))))

   ;; Orderless
   `(orderless-match-face-0
     ((,class (:foreground ,yellow-bright :weight bold))))
   `(orderless-match-face-1
     ((,class (:foreground ,cyan-bright :weight bold))))
   `(orderless-match-face-2
     ((,class (:foreground ,magenta-bright :weight bold))))
   `(orderless-match-face-3
     ((,class (:foreground ,green-bright :weight bold))))

   ;; -----------------------------------------------------------------------
   ;; Org
   ;; -----------------------------------------------------------------------
   `(org-document-title
     ((,class (:foreground ,yellow-bright :weight bold :height 1.35))))
   `(org-level-1
     ((,class (:foreground ,yellow-bright :weight bold :height 1.20))))
   `(org-level-2
     ((,class (:foreground ,cyan-bright :weight bold :height 1.12))))
   `(org-level-3
     ((,class (:foreground ,magenta-bright :weight bold))))
   `(org-level-4
     ((,class (:foreground ,green-bright :weight bold))))
   `(org-level-5
     ((,class (:foreground ,blue-bright))))
   `(org-level-6
     ((,class (:foreground ,red-bright))))
   `(org-level-7
     ((,class (:foreground ,yellow))))
   `(org-level-8
     ((,class (:foreground ,cyan))))
   `(org-link
     ((,class (:foreground ,blue-bright :underline t))))
   `(org-code
     ((,class (:foreground ,cyan :background ,bg-alt))))
   `(org-verbatim
     ((,class (:foreground ,green-bright :background ,bg-alt))))
   `(org-block
     ((,class (:background ,bg-alt :extend t))))
   `(org-block-begin-line
     ((,class (:foreground ,comment :background ,bg-alt :slant italic))))
   `(org-block-end-line
     ((,class (:foreground ,comment :background ,bg-alt :slant italic))))
   `(org-quote
     ((,class (:foreground ,fg-alt :slant italic))))
   `(org-todo
     ((,class (:foreground ,red-bright :weight bold))))
   `(org-done
     ((,class (:foreground ,green-bright :weight bold))))
   `(org-warning
     ((,class (:foreground ,warning :weight bold))))
   `(org-date
     ((,class (:foreground ,cyan))))
   `(org-agenda-date
     ((,class (:foreground ,cyan-bright :weight bold))))
   `(org-agenda-date-today
     ((,class (:foreground ,yellow-bright :weight bold :height 1.1))))
   `(org-scheduled
     ((,class (:foreground ,green-bright))))
   `(org-scheduled-previously
     ((,class (:foreground ,red))))
   `(org-checkbox
     ((,class (:foreground ,cyan-bright :weight bold))))

   ;; -----------------------------------------------------------------------
   ;; Magit
   ;; -----------------------------------------------------------------------
   `(magit-section-heading
     ((,class (:foreground ,yellow-bright :weight bold))))
   `(magit-section-highlight
     ((,class (:background ,bg-alt))))
   `(magit-branch-local
     ((,class (:foreground ,cyan-bright))))
   `(magit-branch-remote
     ((,class (:foreground ,green-bright))))
   `(magit-branch-current
     ((,class (:foreground ,yellow-bright :weight bold))))
   `(magit-hash
     ((,class (:foreground ,comment))))
   `(magit-diff-added
     ((,class (:foreground ,green-bright :background ,bg-deep))))
   `(magit-diff-removed
     ((,class (:foreground ,red-bright :background ,red-dark))))
   `(magit-diff-context
     ((,class (:foreground ,fg-dim :background ,bg))))
   `(magit-diff-context-highlight
     ((,class (:foreground ,fg-alt :background ,bg-alt))))
   `(magit-diff-hunk-heading
     ((,class (:foreground ,cyan-bright :background ,cyan-dark))))
   `(magit-diff-hunk-heading-highlight
     ((,class (:foreground ,cyan-bright :background ,bg-dim))))
   `(magit-diff-file-heading
     ((,class (:foreground ,yellow-bright :weight bold))))
   `(magit-process-ok
     ((,class (:foreground ,success :weight bold))))
   `(magit-process-ng
     ((,class (:foreground ,error :weight bold))))
   `(magit-signature-good
     ((,class (:foreground ,green-bright))))
   `(magit-signature-bad
     ((,class (:foreground ,red-bright))))

   ;; -----------------------------------------------------------------------
   ;; Which-key
   ;; -----------------------------------------------------------------------
   `(which-key-key
     ((,class (:foreground ,yellow-bright :weight bold))))
   `(which-key-command-description-face
     ((,class (:foreground ,fg))))
   `(which-key-group-description-face
     ((,class (:foreground ,cyan-bright))))
   `(which-key-local-map-description-face
     ((,class (:foreground ,magenta-bright))))

   ;; -----------------------------------------------------------------------
   ;; Dired / file managers
   ;; -----------------------------------------------------------------------
   ;; Dired: deliberately restrained. Keep the filesystem view quiet.
   `(dired-directory
     ((,class (:foreground ,cyan-bright :weight bold))))
   `(dired-header
     ((,class (:foreground ,fg-alt :weight bold))))
   `(dired-flagged
     ((,class (:foreground ,red-bright :weight bold))))
   `(dired-marked
     ((,class (:foreground ,yellow-bright :weight bold))))
   `(dired-mark
     ((,class (:foreground ,yellow-bright :weight bold))))
   `(dired-symlink
     ((,class (:foreground ,magenta-bright))))
   `(dired-broken-symlink
     ((,class (:foreground ,red-bright :weight bold))))
   `(dired-ignored
     ((,class (:foreground ,comment))))
   `(dired-perm-write
     ((,class (:foreground ,fg-alt))))
   `(dired-perm-read
     ((,class (:foreground ,comment))))
   `(dired-perm-exec
     ((,class (:foreground ,green))))
   `(dired-set-id
     ((,class (:foreground ,yellow))))
   `(dired-warning
     ((,class (:foreground ,yellow))))
   `(dired-special
     ((,class (:foreground ,magenta))))
   `(dired-date
     ((,class (:foreground ,comment))))
   `(dired-filename
     ((,class (:foreground ,fg))))

   ;; diredfl (enabled by Doom in some configurations) overrides many of
   ;; Dired's normal faces. Theme those faces explicitly so the Dired view
   ;; remains Melange instead of falling back to diredfl's palette.
   `(diredfl-dir-name
     ((,class (:foreground ,cyan-bright :weight bold))))
   `(diredfl-dir-priv
     ((,class (:foreground ,comment))))
   `(diredfl-dir-heading
     ((,class (:foreground ,fg-alt :weight bold))))
   `(diredfl-dir-symlink
     ((,class (:foreground ,magenta-bright))))
   `(diredfl-file-name
     ((,class (:foreground ,fg))))
   `(diredfl-file-suffix
     ((,class (:foreground ,fg-alt))))
   `(diredfl-file-suffix-simple
     ((,class (:foreground ,fg))))
   `(diredfl-read-priv
     ((,class (:foreground ,comment))))
   `(diredfl-write-priv
     ((,class (:foreground ,fg-alt))))
   `(diredfl-exec-priv
     ((,class (:foreground ,green))))
   `(diredfl-no-priv
     ((,class (:foreground ,comment))))
   `(diredfl-number
     ((,class (:foreground ,fg-alt))))
   `(diredfl-date
     ((,class (:foreground ,comment))))
   `(diredfl-dir-name
     ((,class (:foreground ,cyan-bright :weight bold))))

   ;; Nerd Icons Dired: keep icons subordinate to the filename.
   `(nerd-icons-dired-dir-face
     ((,class (:foreground ,cyan-bright))))
   `(nerd-icons-dired-file-face
     ((,class (:foreground ,fg))))

   ;; -----------------------------------------------------------------------
   ;; Messages / compilation / diagnostics
   ;; -----------------------------------------------------------------------
   `(message-header-name
     ((,class (:foreground ,cyan-bright))))
   `(message-header-subject
     ((,class (:foreground ,yellow-bright :weight bold))))
   `(message-header-to
     ((,class (:foreground ,green-bright))))
   `(message-header-cc
     ((,class (:foreground ,blue-bright))))
   `(message-separator
     ((,class (:foreground ,comment))))
   `(compilation-error
     ((,class (:foreground ,red-bright :weight bold))))
   `(compilation-warning
     ((,class (:foreground ,yellow-bright :weight bold))))
   `(compilation-info
     ((,class (:foreground ,green-bright))))
   `(flycheck-error
     ((,class (:underline (:style wave :color ,red-bright)))))
   `(flycheck-warning
     ((,class (:underline (:style wave :color ,yellow-bright)))))
   `(flycheck-info
     ((,class (:underline (:style wave :color ,cyan-bright)))))

   ;; -----------------------------------------------------------------------
   ;; LSP
   ;; -----------------------------------------------------------------------
   `(lsp-face-highlight-textual
     ((,class (:background ,selection))))
   `(lsp-face-highlight-read
     ((,class (:background ,blue-dark :foreground ,blue-bright))))
   `(lsp-face-highlight-write
     ((,class (:background ,cyan-dark :foreground ,cyan-bright))))
   `(lsp-ui-doc-background
     ((,class (:background ,bg-alt))))
   `(lsp-ui-sideline-code-action
     ((,class (:foreground ,yellow-bright))))
   `(lsp-ui-sideline-current-symbol
     ((,class (:foreground ,yellow-bright :weight bold))))

   ;; -----------------------------------------------------------------------
   ;; Tree-sitter / treesit faces
   ;; -----------------------------------------------------------------------
   `(tree-sitter-hl-face:comment
     ((,class (:inherit font-lock-comment-face))))
   `(tree-sitter-hl-face:keyword
     ((,class (:inherit font-lock-keyword-face))))
   `(tree-sitter-hl-face:string
     ((,class (:inherit font-lock-string-face))))
   `(tree-sitter-hl-face:function
     ((,class (:foreground ,blue-bright))))
   `(tree-sitter-hl-face:function.call
     ((,class (:foreground ,blue))))
   `(tree-sitter-hl-face:type
     ((,class (:foreground ,cyan-bright))))
   `(tree-sitter-hl-face:constant
     ((,class (:foreground ,blue))))
   `(tree-sitter-hl-face:number
     ((,class (:foreground ,yellow))))
   `(tree-sitter-hl-face:property
     ((,class (:foreground ,cyan))))
   `(tree-sitter-hl-face:variable
     ((,class (:foreground ,fg))))
   `(tree-sitter-hl-face:operator
     ((,class (:foreground ,red-bright))))

   ;; -----------------------------------------------------------------------
   ;; Ediff
   ;; -----------------------------------------------------------------------
   `(ediff-current-diff-A
     ((,class (:background ,red-dark :foreground ,fg))))
   `(ediff-current-diff-B
     ((,class (:background ,green :foreground ,bg))))
   `(ediff-current-diff-C
     ((,class (:background ,blue-dark :foreground ,fg))))
   `(ediff-fine-diff-A
     ((,class (:background ,red-bright :foreground ,bg :weight bold))))
   `(ediff-fine-diff-B
     ((,class (:background ,green-bright :foreground ,bg :weight bold))))
   `(ediff-fine-diff-C
     ((,class (:background ,blue-bright :foreground ,bg :weight bold))))

   ;; -----------------------------------------------------------------------
   ;; Term / ANSI colors
   ;; -----------------------------------------------------------------------
   `(ansi-color-black
     ((,class (:foreground ,bg-alt :background ,bg-alt))))
   `(ansi-color-red
     ((,class (:foreground ,red :background ,red))))
   `(ansi-color-green
     ((,class (:foreground ,green :background ,green))))
   `(ansi-color-yellow
     ((,class (:foreground ,yellow :background ,yellow))))
   `(ansi-color-blue
     ((,class (:foreground ,blue :background ,blue))))
   `(ansi-color-magenta
     ((,class (:foreground ,magenta :background ,magenta))))
   `(ansi-color-cyan
     ((,class (:foreground ,cyan :background ,cyan))))
   `(ansi-color-white
     ((,class (:foreground ,fg-alt :background ,fg-alt))))

   ;; -----------------------------------------------------------------------
   ;; Tabs / tab-bar
   ;; -----------------------------------------------------------------------
   `(tab-bar
     ((,class (:background ,bg :foreground ,comment))))
   `(tab-bar-tab
     ((,class (:background ,bg-alt :foreground ,yellow-bright :weight bold))))
   `(tab-bar-tab-inactive
     ((,class (:background ,bg :foreground ,comment))))
   `(tab-line
     ((,class (:background ,bg :foreground ,comment))))
   `(tab-line-tab-current
     ((,class (:background ,bg-alt :foreground ,yellow-bright :weight bold))))
   `(tab-line-tab-inactive
     ((,class (:background ,bg :foreground ,comment))))

   ;; -----------------------------------------------------------------------
   ;; Help / Info / manuals
   ;; -----------------------------------------------------------------------
   `(help-key-binding
     ((,class (:background ,bg-alt :foreground ,yellow-bright :weight bold))))
   `(Info-title-1
     ((,class (:foreground ,yellow-bright :weight bold :height 1.3))))
   `(Info-title-2
     ((,class (:foreground ,cyan-bright :weight bold :height 1.2))))
   `(Info-title-3
     ((,class (:foreground ,magenta-bright :weight bold))))
   `(Info-title-4
     ((,class (:foreground ,green-bright :weight bold))))

   ;; -----------------------------------------------------------------------
   ;; Rainbow delimiters
   ;; -----------------------------------------------------------------------
   `(rainbow-delimiters-depth-1-face ((,class (:foreground ,cyan-bright))))
   `(rainbow-delimiters-depth-2-face ((,class (:foreground ,yellow-bright))))
   `(rainbow-delimiters-depth-3-face ((,class (:foreground ,magenta-bright))))
   `(rainbow-delimiters-depth-4-face ((,class (:foreground ,green-bright))))
   `(rainbow-delimiters-depth-5-face ((,class (:foreground ,blue-bright))))
   `(rainbow-delimiters-depth-6-face ((,class (:foreground ,red-bright))))
   `(rainbow-delimiters-depth-7-face ((,class (:foreground ,cyan))))
   `(rainbow-delimiters-depth-8-face ((,class (:foreground ,yellow))))
   `(rainbow-delimiters-depth-9-face ((,class (:foreground ,magenta))))

   ;; -----------------------------------------------------------------------
   ;; Solaire
   ;; -----------------------------------------------------------------------
   `(solaire-default-face
     ((,class (:background ,bg-alt :foreground ,fg))))

   ;; -----------------------------------------------------------------------
   ;; Doom-specific common faces
   ;; -----------------------------------------------------------------------
   `(doom-modeline-bar
     ((,class (:background ,yellow-bright))))
   `(doom-modeline-buffer-file
     ((,class (:foreground ,fg :weight bold))))
   `(doom-modeline-buffer-modified
     ((,class (:foreground ,red-bright :weight bold))))
   `(doom-modeline-buffer-major-mode
     ((,class (:foreground ,cyan-bright))))
   `(doom-modeline-project-dir
     ((,class (:foreground ,yellow-bright :weight bold))))
   `(doom-modeline-info
     ((,class (:foreground ,cyan-bright))))
   `(doom-modeline-warning
     ((,class (:foreground ,yellow-bright))))
   `(doom-modeline-urgent
     ((,class (:foreground ,red-bright :weight bold))))

   ;; Doom popup
   `(doom-popup-menu
     ((,class (:background ,bg-alt :foreground ,fg))))
   `(doom-popup-menu-mapper
     ((,class (:background ,bg-alt :foreground ,cyan-bright))))
   `(doom-popup-menu-box
     ((,class (:background ,bg-alt :foreground ,line))))

   ;; -----------------------------------------------------------------------
   ;; Custom theme variables
   ;; -----------------------------------------------------------------------
   )

  ;; -------------------------------------------------------------------------
  ;; Palette variables exposed through the theme.
  ;; Useful for Doom modules/config.el customizations.
  ;; -------------------------------------------------------------------------
  (custom-theme-set-variables
   'melange
   '(ansi-color-names-vector
     ["#34302C" "#BD8183" "#78997A" "#E49B5D"
      "#7F91B2" "#B380B0" "#7B9695" "#C1A78E"])
   '(ansi-color-faces-vector
     [default ansi-color-red ansi-color-green ansi-color-yellow
              ansi-color-blue ansi-color-magenta ansi-color-cyan ansi-color-white]))

  ;; Make the palette accessible to package code that wants to inspect it.
  (custom-theme-set-variables
   'melange
   `(melange-palette
     '((bg . ,bg)
       (bg-alt . ,bg-alt)
       (bg-dim . ,bg-dim)
       (fg . ,fg)
       (fg-alt . ,fg-alt)
       (comment . ,comment)
       (red . ,red)
       (red-bright . ,red-bright)
       (yellow . ,yellow)
       (yellow-bright . ,yellow-bright)
       (green . ,green)
       (green-bright . ,green-bright)
       (blue . ,blue)
       (blue-bright . ,blue-bright)
       (cyan . ,cyan)
       (cyan-bright . ,cyan-bright)
       (magenta . ,magenta)
       (magenta-bright . ,magenta-bright)))))

;;;###autoload
(when load-file-name
  (add-to-list 'custom-theme-load-path
               (file-name-directory load-file-name)))

(provide-theme 'melange)

;;; melange-theme.el ends here
