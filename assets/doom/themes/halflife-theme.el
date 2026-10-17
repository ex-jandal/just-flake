;;; halflife-theme.el --- Half-Life themed Melange for Emacs -*- lexical-binding: t; -*-

;; A Half-Life / Black Mesa flavored port of the Melange theme for Emacs.
;; Built upon the dark Melange palette by savq, infused with Lambda orange and industrial grit.

(deftheme halflife
  "Half-Life / Black Mesa styled variant of the warm, earthy Melange theme.")

(let* ((class '((class color) (min-colors 89)))

       ;; -------------------------------------------------------------------
       ;; Half-Life / Black Mesa Palette (Melange-infused industrial tones)
       ;; -------------------------------------------------------------------
       (bg            "#1c1715") ; Deep bunker obsidian background
       (bg-alt        "#2b2320") ; Industrial panel surface
       (bg-dim        "#382e29") ; Highlighted surfaces / borders
       (bg-deep       "#14100e") ; Deepest void / contrast depth

       (fg            "#f2e6dc") ; Clean terminal foreground text
       (fg-alt        "#c49a66") ; Muted desert/amber metadata
       (fg-dim        "#8c7560") ; Comments and subtle UI elements

       ;; Warm / control-flow colors (Half-Life Lambda Orange focus)
       (red           "#d96b52")
       (red-bright    "#ff6000") ; Iconic Half-Life Lambda Orange
       (red-dark      "#732602") ; Hazard rust / error deep
       (yellow        "#e6a13b") ; Hazard caution amber
       (yellow-bright "#ffb74d") ; Bright warning highlight
       (yellow-dark   "#8b572a") ; Muted amber highlight
       (green         "#78997A")
       (green-bright  "#85B695")

       ;; Cool / data colors (Xen / HEV suit interface blue/cyan accents)
       (blue          "#6f8ac7")
       (blue-bright   "#92b0e8")
       (blue-dark     "#202a3d")
       (cyan          "#5fa8a3") ; HEV interface cyan
       (cyan-bright   "#7fc9c2") ; Bright display cyan
       (cyan-dark     "#1b3331")
       (magenta       "#b380b0")
       (magenta-bright "#cf9bc2")
       (magenta-dark  "#422741")

       ;; UI
       (selection     "#382e29")
       (inactive      "#2b2320")
       (line          "#382e29")
       (comment       "#8c7560")
       (error         "#ff6000")
       (warning       "#e6a13b")
       (success       "#85B695")
       (info          "#7fc9c2"))

  (custom-theme-set-faces
   'halflife

   ;; -----------------------------------------------------------------------
   ;; Core Emacs
   ;; -----------------------------------------------------------------------
   `(default
     ((,class (:background ,bg :foreground ,fg))))
   `(cursor
     ((,class (:background ,red-bright))))
   `(fringe
     ((,class (:background ,bg :foreground ,fg-dim))))
   `(vertical-border
     ((,class (:foreground ,line))))
   `(shadow
     ((,class (:foreground ,comment))))
   `(link
     ((,class (:foreground ,cyan-bright :underline t))))
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
     ((,class (:background ,red-bright :foreground ,bg :weight bold))))
   `(lazy-highlight
     ((,class (:background ,selection :foreground ,yellow-bright))))
   `(isearch-fail
     ((,class (:background ,red-dark :foreground ,fg))))
   `(escape-glyph
     ((,class (:foreground ,yellow-bright))))
   `(trailing-whitespace
     ((,class (:background ,red-dark))))
   `(minibuffer-prompt
     ((,class (:foreground ,red-bright :weight bold))))
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
   ;; -----------------------------------------------------------------------
   `(font-lock-builtin-face
     ((,class (:foreground ,magenta))))
   `(font-lock-comment-face
     ((,class (:foreground ,comment :slant italic))))
   `(font-lock-comment-delimiter-face
     ((,class (:foreground ,comment :slant italic))))
   `(font-lock-constant-face
     ((,class (:foreground ,blue))))
   `(font-lock-doc-face
     ((,class (:foreground ,fg-alt :slant italic))))
   `(font-lock-function-name-face
     ((,class (:foreground ,yellow-bright))))
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
     ((,class (:foreground ,blue-bright))))
   `(font-lock-variable-name-face
     ((,class (:foreground ,fg-alt))))
   `(font-lock-warning-face
     ((,class (:foreground ,warning :weight bold))))

   ;; Emacs 29+/treesit faces. This used to be routed through `tree-sitter-hl-
   ;; face:*' names, which belong to the external `tree-sitter-hl' package.
   ;; This Doom loads built-in `treesit' instead, so those faces never applied;
   ;; theme the faces `treesit' actually uses.
   `(font-lock-function-call-face
     ((,class (:foreground ,yellow-bright))))
   `(font-lock-property-name-face
     ((,class (:foreground ,magenta-bright))))
   `(font-lock-property-use-face
     ((,class (:foreground ,magenta-bright))))
   `(font-lock-variable-use-face
     ((,class (:foreground ,fg-alt))))
   `(font-lock-operator-face
     ((,class (:foreground ,red-bright))))
   `(font-lock-number-face
     ((,class (:foreground ,yellow))))
   `(font-lock-bracket-face
     ((,class (:foreground ,fg-dim))))
   `(font-lock-delimiter-face
     ((,class (:foreground ,fg-dim))))
   `(font-lock-punctuation-face
     ((,class (:foreground ,fg-dim))))
   `(font-lock-escape-face
     ((,class (:foreground ,magenta-bright))))
   `(font-lock-doc-markup-face
     ((,class (:foreground ,blue))))

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
     ((,class (:foreground ,red-bright :weight bold))))
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
     ((,class (:background ,bg-alt :foreground ,red-bright :weight bold))))
   `(hl-line
     ((,class (:background ,bg-alt))))

   ;; -----------------------------------------------------------------------
   ;; Search / completion
   ;; -----------------------------------------------------------------------
   `(completions-common-part
     ((,class (:foreground ,cyan-bright))))
   `(completions-annotations
     ((,class (:foreground ,comment :slant italic))))
   `(completions-first-difference
     ((,class (:foreground ,red-bright :weight bold))))
   `(completions-highlight
     ((,class (:background ,selection :foreground ,fg))))
   `(completion-preview
     ((,class (:foreground ,comment))))
   `(icomplete-first-match
     ((,class (:foreground ,red-bright :weight bold))))

   ;; Corfu
   `(corfu-default
     ((,class (:background ,bg-alt :foreground ,fg))))
   `(corfu-current
     ((,class (:background ,selection :foreground ,red-bright :weight bold))))
   `(corfu-bar
     ((,class (:background ,red-bright))))
   `(corfu-border
     ((,class (:background ,bg-dim))))
   `(corfu-annotations
     ((,class (:foreground ,comment :slant italic))))

   ;; Vertico
   `(vertico-current
     ((,class (:background ,selection :foreground ,red-bright :weight bold))))
   `(vertico-group-title
     ((,class (:foreground ,cyan-bright :weight bold))))
   `(vertico-multiline
     ((,class (:foreground ,fg-alt))))

   ;; Orderless
   `(orderless-match-face-0
     ((,class (:foreground ,red-bright :weight bold))))
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
     ((,class (:foreground ,red-bright :weight bold :height 1.35))))
   `(org-level-1
     ((,class (:foreground ,red-bright :weight bold :height 1.20))))
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
     ((,class (:foreground ,cyan-bright :underline t))))
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
     ((,class (:foreground ,red-bright :weight bold :height 1.1))))
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
     ((,class (:foreground ,red-bright :weight bold))))
   `(magit-section-highlight
     ((,class (:background ,bg-alt))))
   `(magit-branch-local
     ((,class (:foreground ,cyan-bright))))
   `(magit-branch-remote
     ((,class (:foreground ,green-bright))))
   `(magit-branch-current
     ((,class (:foreground ,red-bright :weight bold))))
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
     ((,class (:foreground ,red-bright :weight bold))))
   `(which-key-command-description-face
     ((,class (:foreground ,fg))))
   `(which-key-group-description-face
     ((,class (:foreground ,cyan-bright))))
   `(which-key-local-map-description-face
     ((,class (:foreground ,magenta-bright))))

   ;; -----------------------------------------------------------------------
   ;; Dired / file managers
   ;; -----------------------------------------------------------------------
   ;; Standard Dired. Directories carry the Half-Life hazard amber instead of
   ;; the cyan they shared with Melange, so the filesystem view reads as part
   ;; of this theme rather than a leftover.
   `(dired-directory
     ((,class (:foreground ,yellow-bright :weight bold))))
   `(dired-header
     ((,class (:foreground ,fg-alt :weight bold))))
   `(dired-flagged
     ((,class (:foreground ,red-bright :weight bold))))
   `(dired-marked
     ((,class (:foreground ,red-bright :weight bold))))
   `(dired-mark
     ((,class (:foreground ,red-bright :weight bold))))
   `(dired-symlink
     ((,class (:foreground ,magenta-bright))))
   `(dired-broken-symlink
     ((,class (:foreground ,red-bright :weight bold))))
   `(dired-ignored
     ((,class (:foreground ,comment))))
   `(dired-perm-write
     ((,class (:foreground ,fg-alt :background nil))))
   `(dired-perm-read
     ((,class (:foreground ,comment :background nil))))
   `(dired-perm-exec
     ((,class (:foreground ,green :background nil))))
   `(dired-set-id
     ((,class (:foreground ,yellow :background nil))))
   `(dired-warning
     ((,class (:foreground ,yellow :background nil))))
   `(dired-special
     ((,class (:foreground ,magenta :background nil))))
   `(dired-date
     ((,class (:foreground ,comment))))
   `(dired-filename
     ((,class (:foreground ,fg))))

   ;; diredfl faces - Explicitly clear background blocks to fix Dired layout.
   ;; The faces below the privs are the ones diredfl leaves at its own
   ;; defaults (pure Blue/Red/Green names and odd hex), which is why they used
   ;; to punch straight through the theme.
   `(diredfl-dir-name
     ((,class (:foreground ,yellow-bright :weight bold))))
   `(diredfl-dir-priv
     ((,class (:foreground ,comment :background nil))))
   `(diredfl-dir-heading
     ((,class (:foreground ,fg-alt :weight bold))))
   `(diredfl-dir-symlink
     ((,class (:foreground ,magenta-bright))))
   `(diredfl-symlink
     ((,class (:foreground ,magenta-bright))))
   `(diredfl-file-name
     ((,class (:foreground ,fg))))
   `(diredfl-file-suffix
     ((,class (:foreground ,fg-alt))))
   `(diredfl-file-suffix-simple
     ((,class (:foreground ,fg))))
   `(diredfl-read-priv
     ((,class (:foreground ,comment :background nil))))
   `(diredfl-write-priv
     ((,class (:foreground ,fg-alt :background nil))))
   `(diredfl-exec-priv
     ((,class (:foreground ,green :background nil))))
   `(diredfl-no-priv
     ((,class (:foreground ,comment :background nil))))
   `(diredfl-number
     ((,class (:foreground ,fg-alt))))
   `(diredfl-date
     ((,class (:foreground ,comment))))
   `(diredfl-date-time
     ((,class (:foreground ,comment))))
   `(diredfl-rare-priv
     ((,class (:foreground ,yellow :background nil))))
   `(diredfl-link-priv
     ((,class (:foreground ,magenta-bright :background nil))))
   `(diredfl-other-priv
     ((,class (:foreground ,fg-alt :background nil))))
   `(diredfl-executable-tag
     ((,class (:foreground ,green))))
   `(diredfl-autofile-name
     ((,class (:foreground ,fg-alt))))
   `(diredfl-compressed-file-name
     ((,class (:foreground ,fg-alt))))
   `(diredfl-compressed-file-suffix
     ((,class (:foreground ,fg-alt))))
   `(diredfl-ignored-file-name
     ((,class (:foreground ,comment))))
   `(diredfl-deletion
     ((,class (:foreground ,red-bright :weight bold))))
   `(diredfl-deletion-file-name
     ((,class (:foreground ,red-bright :weight bold))))
   `(diredfl-flag-mark
     ((,class (:foreground ,red-bright :weight bold))))
   `(diredfl-flag-mark-line
     ((,class (:background ,selection))))
   `(diredfl-tagged-autofile-name
     ((,class (:foreground ,yellow-bright))))

   ;; Nerd Icons Dired
   `(nerd-icons-dired-dir-face
     ((,class (:foreground ,yellow-bright))))
   `(nerd-icons-dired-file-face
     ((,class (:foreground ,fg))))

   ;; Dirvish. Doom's dired module runs with +dirvish, and dirvish ships its own
   ;; faces that neither theme touched, so its hardcoded defaults leaked:
   ;; file-time #5699AF, file-modes #a9a1e1, and file-size through the unthemed
   ;; `completions-annotations' it inherits from.
   `(dirvish-file-modes
     ((,class (:foreground ,fg-alt))))
   `(dirvish-file-time
     ((,class (:foreground ,fg-dim))))
   `(dirvish-file-size
     ((,class (:foreground ,fg-dim))))
   `(dirvish-file-user-id
     ((,class (:foreground ,fg-dim))))
   `(dirvish-file-group-id
     ((,class (:foreground ,fg-dim))))
   `(dirvish-file-device-number
     ((,class (:foreground ,fg-dim))))
   `(dirvish-file-inode-number
     ((,class (:foreground ,fg-dim))))
   `(dirvish-file-link-number
     ((,class (:foreground ,fg-dim))))
   `(dirvish-free-space
     ((,class (:foreground ,blue-bright))))
   `(dirvish-subtree-state
     ((,class (:foreground ,fg-dim))))
   `(dirvish-subtree-guide
     ((,class (:foreground ,fg-dim))))
   `(dirvish-hl-line
     ((,class (:background ,bg-alt))))
   `(dirvish-hl-line-inactive
     ((,class (:background ,bg-dim))))
   `(dirvish-inactive
     ((,class (:foreground ,comment))))
   `(dirvish-proc-running
     ((,class (:foreground ,yellow))))
   `(dirvish-proc-finished
     ((,class (:foreground ,green))))
   `(dirvish-proc-failed
     ((,class (:foreground ,red-bright))))
   `(dirvish-media-info-heading
     ((,class (:foreground ,yellow-bright :weight bold))))
   `(dirvish-media-info-property-key
     ((,class (:foreground ,fg-alt))))

   ;; -----------------------------------------------------------------------
   ;; Messages / compilation / diagnostics
   ;; -----------------------------------------------------------------------
   `(message-header-name
     ((,class (:foreground ,cyan-bright))))
   `(message-header-subject
     ((,class (:foreground ,red-bright :weight bold))))
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
     ((,class (:foreground ,red-bright))))
   `(lsp-ui-sideline-current-symbol
     ((,class (:foreground ,red-bright :weight bold))))

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
     ((,class (:background ,bg-alt :foreground ,red-bright :weight bold))))
   `(tab-bar-tab-inactive
     ((,class (:background ,bg :foreground ,comment))))
   `(tab-line
     ((,class (:background ,bg :foreground ,comment))))
   `(tab-line-tab-current
     ((,class (:background ,bg-alt :foreground ,red-bright :weight bold))))
   `(tab-line-tab-inactive
     ((,class (:background ,bg :foreground ,comment))))

   ;; -----------------------------------------------------------------------
   ;; Help / Info / manuals
   ;; -----------------------------------------------------------------------
   `(help-key-binding
     ((,class (:background ,bg-alt :foreground ,red-bright :weight bold))))
   `(Info-title-1
     ((,class (:foreground ,red-bright :weight bold :height 1.3))))
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
   `(rainbow-delimiters-depth-2-face ((,class (:foreground ,red-bright))))
   `(rainbow-delimiters-depth-3-face ((,class (:foreground ,magenta-bright))))
   `(rainbow-delimiters-depth-4-face ((,class (:foreground ,green-bright))))
   `(rainbow-delimiters-depth-5-face ((,class (:foreground ,blue-bright))))
   `(rainbow-delimiters-depth-6-face ((,class (:foreground ,red))))
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
     ((,class (:background ,red-bright))))
   `(doom-modeline-buffer-file
     ((,class (:foreground ,fg :weight bold))))
   `(doom-modeline-buffer-modified
     ((,class (:foreground ,red-bright :weight bold))))
   `(doom-modeline-buffer-major-mode
     ((,class (:foreground ,cyan-bright))))
   `(doom-modeline-project-dir
     ((,class (:foreground ,red-bright :weight bold))))
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
   )

  ;; -------------------------------------------------------------------------
  ;; Palette variables exposed through the theme.
  ;; -------------------------------------------------------------------------
  (custom-theme-set-variables
   'halflife
   '(ansi-color-names-vector
     ["#2b2320" "#d96b52" "#78997A" "#e6a13b"
      "#6f8ac7" "#b380b0" "#5fa8a3" "#c49a66"]))

  (custom-theme-set-variables
   'halflife
   `(halflife-palette
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

(provide-theme 'halflife)

;;; halflife-theme.el ends here
