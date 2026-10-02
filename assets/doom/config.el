;;; config.el -*- lexical-binding: t; -*-

;;
;;; Startup
;;
;; - Doom only calls package-initialize from (with-eval-after-load 'straight ...)
;;   (core lisp/doom-emacs.el:328-330), and unstraightened bypasses straight.el
;;   entirely, so it never runs. Without it no package autoloads are read — and
;;   third-party themes register themselves with custom-theme-load-path *from
;;   their autoloads* (core lisp/doom-emacs.el:276 says so). Result: M-x
;;   load-theme listed nothing but the noctalia directory added below, even
;;   though all 11 theme packages were installed.
;; - This has to run before the theme loads. Doom reads $DOOMDIR/config.el after
;;   every module's config.el but before after-init-hook, and doom-init-theme-h
;;   — which does (load-theme doom-theme t) — is on after-init-hook at -90
;;   (core lisp/doom-emacs.el:1308-1312).
(package-initialize)

;; - Doom sets custom-file to $DOOMDIR/custom.el (core lisp/doom-emacs.el:284),
;;   which is a read-only store path. Emacs stores a non-built-in theme's SHA-256
;;   in custom-safe-themes and saves it there the first time you confirm the
;;   theme is safe, so that save can never succeed. Redirect it beside the
;;   noctalia theme output, which is already writable.
(setq custom-file
      (expand-file-name "doom/custom.el"
                        (or (getenv "XDG_CONFIG_HOME")
                            (concat (getenv "HOME") "/.config"))))


;;
;;; Fonts
;;
;; - Doom ships Fira Code at 12pt; both changed here because 12 was small.
;; - CaskaydiaCove Nerd Font is already installed system-wide
;;   (nerd-fonts.caskaydia-cove in hosts/nixos/modules/fonts.nix), so no font
;;   work needed — and the Nerd glyphs keep dashboard/neotree icons rendering.
;; - `doom-big-font-size` is a *ratio*, not a point size (1.33 => 1.33x base).
;;   `doom-small-font-size` is relative to the default face height, so 11 stays
;;   below the 20pt base and remains readable.
(setq doom-font (font-spec :family "CaskaydiaCove Nerd Font" :size 20)
      doom-variable-pitch-font (font-spec :family "Rubik" :size 21)
      doom-big-font-size 1.33
      doom-big-font-line-height 1.1
      doom-small-font-size 11)


;;
;;; Theme
;;
;; - doom-gruvbox, NOT the standalone `gruvbox' from greduan/gruvbox-theme. The
;;   doom-* variants come from doom-themes and carry Doom's own face work —
;;   mode line, neotree, magit, which-key, org, evil, flycheck, dired — so the
;;   whole UI matches instead of looking half-patched over a foreign palette.
;;   doom-themes ships 77 of them; `M-x load-theme' lists every one.
;; - Its defcustoms: doom-gruvbox-dark-variant ("hard" or "soft"; default is
;;   medium) and doom-gruvbox-brighter-comments. There is also doom-gruvbox-light.
;;
;; - Setting `doom-theme' rather than calling `load-theme' keeps Doom's own hooks
;;   (org-modern integration, solaire-mode in popups).
(setq doom-theme 'doom-gruvbox)

;; - Noctalia is still generated and still selectable, just no longer the default.
;;   Its emacs template (assets/noctalia/settings.toml -> [theme.templates]
;;   builtin_ids = ["emacs"]) keeps writing ~/.config/doom/themes/noctalia-theme.el
;;   whenever your Noctalia palette changes.
;; - `custom-theme-load-path' must include that directory, otherwise `load-theme'
;;   cannot find the file: load-theme searches for `<name>-theme.el'.
;;
;; - The old logic picked noctalia when its file existed and fell back to gruvbox
;;   otherwise. That fallback never ran, because Noctalia writes the file on every
;;   palette change, so `doom-theme' would silently revert to noctalia and there
;;   was no way to pick a theme permanently. Hence the unconditional setq above.
(defconst +noctalia-themes-dir
  (expand-file-name "doom/themes"
                    (or (getenv "XDG_CONFIG_HOME")
                        (concat (getenv "HOME") "/.config"))))

(add-to-list 'custom-theme-load-path +noctalia-themes-dir)

;; - Switch back to it after a Noctalia palette change:
;;     M-x my-reload-noctalia-theme
;;   Noctalia's own post_hook does this automatically, but only when Emacs runs
;;   as a daemon (`emacs --daemon`), because it calls `emacsclient -e'.
(defun my-reload-noctalia-theme ()
  "Reload the Noctalia theme, if its file has appeared."
  (interactive)
  (let ((file (expand-file-name "noctalia-theme.el" +noctalia-themes-dir)))
    (if (file-exists-p file)
        (progn (load file nil t) (load-theme 'noctalia t) "Noctalia theme reloaded")
      (message "Noctalia theme not generated yet: %s" file))))

;; - After changing `doom-theme' above: `M-x doom/reload-theme'.
;; - Available with no rebuild (all preinstalled by home/modules/doom-emacs.nix):
;;   doom-gruvbox, doom-gruvbox-light, doom-one, doom-city-lights, doom-1337,
;;   doom-ayu-dark, doom-dracula, doom-zenburn, doom-tokyonight-*, and ~70 more,
;;   plus the non-doom ones: catppuccin-*, tokyonight-*, nord, nordic, material,
;;   foggy-night, zenburn, gruvbox and its variants, base16-<scheme>.



;;
;;; LSP
;;
;; - lsp-mode execs servers by bare name, so most are found automatically from
;;   the PATH packages that home/modules/doom-emacs.nix injects. These are the
;;   ones nixpkgs names differently, or that need a JVM/SDK flag to work.

(setq lsp-command-line-functions
      (list
       ;; nixpkgs ships the launcher capitalised; lsp-mode guesses lowercase.
       '(csharp-mode . ("OmniSharp" "--zero-based-indices" "false"))
       ;; jdtls needs the JDK on PATH (JAVA_HOME, home/modules/fish.nix) and a
       ;; writable workspace dir outside the read-only store.
       '(java-mode . ("jdtls" "-data" "/home/abu_jandal/.cache/jdtls"))
       ;; - :lang nim has no +lsp flag upstream, so register zls by hand.
       '(nim-mode . ("zls"))
       ;; These spell out the nixpkgs binary names lsp-mode can't guess.
       '(typescript-mode . ("typescript-language-server" "--stdio"))
       '(typescript-tsx-mode . ("typescript-language-server" "--stdio"))
       '(js-jsx-mode . ("typescript-language-server" "--stdio"))
       '(svelte-mode . ("svelteserver" "--stdio"))
       '(css-mode . ("vscode-css-languageserver" "--stdio"))
       '(less-css-mode . ("vscode-css-languageserver" "--stdio"))
       '(scss-mode . ("vscode-css-languageserver" "--stdio"))
       '(html-mode . ("vscode-html-languageserver" "--stdio"))
       '(sml-mode . ("vscode-html-languageserver" "--stdio"))
       '(xml-mode . ("vscode-html-languageserver" "--stdio"))
       '(vue-mode . ("vue-language-server" "--stdio"))
       '(yaml-mode . ("yaml-language-server" "--stdio"))
       '(toml-mode . ("taplo"))
       '(go-ts-mode . ("gopls"))
       '(dockerfile-mode . ("docker-language-server" "--stdio"))
       '(docker-compose-mode . ("docker-compose-langserver" "--stdio"))
       '(sql-mode . ("sqls"))
       '(terraform-mode . ("terraform-ls"))
       ;; - qmlls, vala-ls and slint-ls are not in nixpkgs, so QML and Vala get
       ;;   tree-sitter highlighting but no completion. See the README note.
       ))

;; - Doom already sets +lsp-optimization-mode on lsp buffers, but this is the
;;   upstream recommendation for lsp-mode's own I/O.
(setq lsp-idle-delay 0.2
      lsp-log-io nil
      lsp-ensure-ignored-invisibles t
      ;; - never let lsp-mode shell out to npm; every server comes from nix.
      lsp-auto-install-servers t
      lsp-server-install-dir (concat (or (getenv "XDG_DATA_HOME")
                                          (concat (getenv "HOME") "/.local/share"))
                                      "/lsp"))

;; - Heavy per-session allocation. Doom's gcmh handles the GC strategy, so
;;   leave read-process-output-max where the lsp module put it.

;; Hover. Doom's `+lsp` module already hooks up lsp-ui (so lsp-ui-doc is
;; installed and active), but `SPC c k` calls `lsp-describe-thing-at-point`,
;; which prints to the echo area instead of showing the popup. Rebind both the
;; leader key and `M-.` (the Emacs convention for "describe what's at point").
;; Doom tunes the popup to at-point, 72 cols, 8 rows; only the delay is ours.
(setq lsp-ui-doc-show-with-cursor t
      lsp-ui-doc-position 'at-point
      lsp-ui-doc-max-width 90
      lsp-ui-doc-delay 0.2)

(with-eval-after-load 'lsp-ui
  (add-hook 'lsp-managed-mode-hook
            (lambda ()
              (local-set-key (kbd "M-.") #'lsp-ui-doc-show))))

;; `SPC c k` is rebound in +evil-bindings.el for -eglot/lsp; override it after
;; that file has loaded so the popup wins.
(with-eval-after-load 'doom-key-bindings
  (map! :n "SPC c k" #'lsp-ui-doc-show))

(defun my-doom-config ()
  "Set up the Nix-managed Doom profile."
  (setq-default tab-width 2
                indent-tabs-mode nil)
  ;; - evil-auto-indent fights Doom's own indentation logic; leave it off.
  (setq-default evil-auto-indent nil))

;; - Doom's lsp module enables flymake (`SPC c x` for the diagnostic list, and
;;   nav-flash flashes the line on failure). Only the filtering knobs here:
;;   show everything, and let flymake report while logging (so a long compile
;;   doesn't blank out the panel you're reading).
(setq flymake-suppress-diagnostics-when-logging nil
      flymake-diagnostic-explanation-filter-predicates
      '(severity)
      flymake-indicate-diagnostics-faces nil)


(setq-default cursor-type 'box)


;;
;;; Open in external app
;;
;; - Doom already binds `SPC o b` to `browse-url-of-file`, and xdg-open plus
;;   xdg-desktop-portal are both live on this system, so a file at point
;;   already opens in its desktop app (PDF -> zathura, image -> eog, ...).
;;   These add file-at-point and URL-at-point without the lookup machinery.
(global-set-key (kbd "C-c C-o") #'browse-url-file-url)
(global-set-key (kbd "C-c C-r") #'browse-url-at-point)

(defun my-browse-region ()
  "Open the region under point as a URL, or the whole buffer if unmarked."
  (interactive)
  (browse-url (if (use-region-p)
                  (buffer-substring-no-properties (region-beginning) (region-end))
                (thing-at-point 'url-or-file 'no-properties))))
(global-set-key (kbd "C-c C-a") #'my-browse-region)



;;
;;; Dired
;;
;; - +icons needs a nerd font in the dired buffer; already installed.

(setq dired-listing-format
      ;; - must be ONE value: wrap the per-column entries in `list'. Writing
      ;;   `(cons ...)' and the alist as two separate arguments is a 3-argument
      ;;   setq, which throws wrong-number-of-arguments and aborts the rest of
      ;;   config.el at startup.
      (list (cons 'dired-extension "[%X%y %m %d %H:%M:%S]\n")
            '((dired-permits "%M %m %u %g  %d\n")
              (dired-size     "%10s\n")
              (dired-date     "%d %H:%M:%S\n"))))

(setq dired-listing-delete-markup t
      dired-use-listing-filters nil
      dired-filter-hidden-files nil
      dired-confirm-delete nil)


;;
;;; Neotree
;;
;; - git-aware sidebar (ranger-like), rather than treemacs.

(setq neo-tree-auto-indent t
      neo-tree-indentation-level 2
      neo-tree-dirname-separator "/"
      neo-tree-show-file-types nil)


;;
;;; Org
;;
;; - Treesitter-first: org-modern is installed via :lang org +pretty.

(setq org-startup-with-inline-tasks t
      org-directory "~/org/"
      org-default-notes-file "~/org/notes.org"
      org-roam-directory "~/org/roam/"
      org-log-into-drawer t
      org-adapt-indentation nil
      org-src-block-preserve-indentation nil
      org-cycle-close-headers-state-sublevels nil)


;;
;;; DAP / Dape
;;
;; - :tools debugger is dape. No config needed for C/C++/Rust out of the box;
;;   register extra debug types here as you need them.

;; (add-to-list 'dape-adapters '((:id "some-id") (:program "...")))


;;
;;; Spell
;;
;; - hunspell + hunspellDicts.en_US come from the flake. Deliberately NOT
;;   spell-checking prog-mode: it flags every identifier (gcmh, defcustom, ...)
;;   and is the main source of Emacs pauses on large files. Use
;;   `:checkers (spell +hunspell +everywhere)` in init.el if you want it in
;;   comments only.

(setq spell-fu-incremental-timers t
      spell-fu-execute-enqueue-executor-async t)

;; - flyspell in comments and prose, which is where it's actually useful.
(add-hook 'text-mode-hook #'flyspell-mode)
(add-hook 'markdown-mode-hook #'flyspell-mode)
(add-hook 'org-mode-hook #'flyspell-mode)
