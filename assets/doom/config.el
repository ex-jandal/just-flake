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
;;   the PATH packages that home/modules/doom-emacs.nix injects — no per-language
;;   wiring needed here.
;; - There used to be a ~25-line `lsp-command-line-functions' block here mapping
;;   20 major-modes to explicit server commands (OmniSharp capitalisation, jdtls
;;   -data, zls for nim, typescript/svelte/css/vue/yaml/toml/go/docker/sql/
;;   terraform…). It was removed because this lsp-mode has no
;;   `lsp-command-line-functions' variable at all, so the whole block never ran —
;;   including the bits that looked load-bearing. lsp-mode resolves all of these
;;   from bare names on $PATH. Note that `:lang java +lsp' is still inert: this
;;   lsp-mode ships no Java client, so jdtls was never started either way.
;;
;; - `lsp-ensure-ignored-invisibles' and `lsp-auto-install-servers' were set here
;;   too; neither exists in this lsp-mode, so they were no-ops as well. Never
;;   letting lsp-mode shell out to npm is not something these controlled — every
;;   server comes from Nix, which is why nothing downloads.

;; - Doom already sets +lsp-optimization-mode on lsp buffers, but this is the
;;   upstream recommendation for lsp-mode's own I/O.
(setq lsp-idle-delay 0.2
      lsp-log-io nil
      lsp-server-install-dir (concat (or (getenv "XDG_DATA_HOME")
                                          (concat (getenv "HOME") "/.local/share"))
                                      "/lsp"))

;;
;;; LSP clients
;;
;; - lsp-mode ships no pyright client and no Java client, so these three are
;;   registered by hand. Binaries come from extraBinPackages in
;;   home/modules/doom-emacs.nix.
;;
;; - basedpyright: use `basedpyright-langserver', not `basedpyright'. nixpkgs
;;   installs both and the CLI never answers an LSP `initialize'.
;;
;; - rls: only registered so `lsp-rust-switch-server' stops throwing. That command
;;   does (setf (lsp--client-priority (gethash 'rls lsp-clients)) ...), which
;;   signals "void-function \(setf\ lsp--client-priority)" when rls is absent.
;;   Install the rls binary too if you want to actually switch to it.
(with-eval-after-load 'lsp-mode
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection '("basedpyright-langserver" "--stdio"))
    :activation-fn (lsp-activate-on "python")
    :server-id 'basedpyright))

  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection '("jdtls" "--stdio"))
    :activation-fn (lsp-activate-on "java")
    :server-id 'jdtls))

  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection '("rls" "--stdio"))
    :activation-fn (lsp-activate-on "rust")
    :server-id 'rls)))

;; - Heavy per-session allocation. Doom's gcmh handles the GC strategy, so
;;   leave read-process-output-max where the lsp module put it.

;; Hover docs. Doom's `+lsp` module hooks up lsp-ui (so lsp-ui-doc is installed
;; and active), but `SPC c k` calls `lsp-describe-thing-at-point`, which prints to
;; the echo area instead of showing a popup. Rebind both the leader key and `M-.`
;; (the Emacs convention for "describe what's at point").
;; Doom tunes the popup to at-point, 72 cols, 8 rows; only the width and delay are
;; ours.
;;
;; - `lsp-ui-doc-show-with-cursor' is nil ON PURPOSE. flymake-popon--post-command
;;   and lsp-ui-doc--make-request are BOTH on post-command-hook, and both anchor
;;   their frame at point. Rest the cursor on a symbol that also has an error and
;;   both fire, so the two popups render on top of each other. Only one can win,
;;   and the diagnostic popup wins; docs become on-demand instead. Do not set this
;;   back to t without also handling flymake-popon.
;; - Nothing is lost. `lsp-ui-doc-show' binds this flag to t *dynamically* inside
;;   its own body, so SPC c k and M-. still work with the global nil — that is why
;;   those bindings stay wired up below.
(setq lsp-ui-doc-show-with-cursor nil
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

;; - IDE-style inline diagnostics: the error text is printed at the end of the
;;   offending line, so you read it without moving the cursor or hovering.
;; - `flymake-inline-diagnostics' is the only such knob in the flymake Doom
;;   actually loads. `:checkers (syntax +flymake)` pins flymake from git, and
;;   that snapshot shadows the one built into Emacs 30.2 — so check variable
;;   names against the pinned copy, not the Emacs one. This version has no
;;   `flymake-diagnostic-delimator', no `flymake-inline-diagnostics-excludes'
;;   and no `flymake-verbosity', so noise filtering isn't available here.
;; - `short` = only the most severe diagnostic per line. `fancy' would draw it
;;   below the line with Unicode graphics (CaskaydiaCove Nerd Font covers the
;;   glyphs), `eol' shows every one.
;; - The three variables this replaced —
;;   flymake-suppress-diagnostics-when-logging,
;;   flymake-diagnostic-explanation-filter-predicates and
;;   flymake-indicate-diagnostics-faces — exist in neither the built-in flymake
;;   nor the pinned one. They were no-ops.
(setq flymake-inline-diagnostics 'short)

;; - Keep the diagnostic hover popup (`flymake-popon-mode`, enabled by Doom on
;;   flymake-mode). This is the popup that SURVIVED the collision described above:
;;   it shares post-command-hook with lsp-ui-doc--make-request, so only one of
;;   them can be on without the two frames landing on top of each other.
;; - It used to throw on every hover:
;;     Error running timer "flymake-popon--show" : (wrong-type-argument stringp nil)
;; - Cause is NOT a message-less diagnostic. doomelpa/flymake-popon ships a
;;   *stale* flymake-popon.elc next to its own flymake-popon.el, and Emacs
;;   prefers the .elc. Verified: loading the .el over it fixes the crash
;;   outright, giving "*   real message" with face flymake-error-echo. The stale
;;   bytecode reads something that returns nil — `flymake-diagnostic-origin' is
;;   nil for every diagnostic, which fits. It reproduces for a perfectly ordinary
;;   diagnostic, so "the server sent no message" was the wrong theory.
;; - `(setq load-prefer-newer t)` does NOT rescue this: Nix normalises mtimes,
;;   so the .el and .elc are both mtime=1 and Emacs falls back to preferring the
;;   .elc. The store is read-only, so the stale file can't just be deleted.
;; - So format the text ourselves and never call flymake-popon-format-diagnostic.
;;   `flymake-popon-diagnostic-formatter' is the package's own documented
;;   extension point, so overriding it is supported rather than a hack. This is
;;   load-bearing now that the popup stays enabled.
(defun my-flymake-popon-format-diagnostic (diagnostic)
  "Format DIAGNOSTIC for `flymake-popon', clamped to `flymake-popon-width'."
  (let* ((type (or (flymake-diagnostic-type diagnostic) 'error))
         (text (string-trim (or (flymake-diagnostic-text diagnostic) "")))
         ;; types are keywords (:error), so symbol-name gives ":error" — drop ":"
         (head (concat "* " (capitalize
                             (string-remove-prefix
                              ":" (string-replace "-" " " (symbol-name type))))))
         (line (if (string-empty-p text)
                   head
                 (concat head ": " (car (split-string text "[\n\r]")))))
         (width (or flymake-popon-width 65)))
    (if (> (length line) width)
        (concat (substring line 0 (- width 3)) "...")
      line)))

(setq flymake-popon-diagnostic-formatter #'my-flymake-popon-format-diagnostic)


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
;;; Markdown preview in Emacs
;;
;; - `SPC m p' (markdown-preview) always opens a browser: markdown-mode ends it
;;   in browse-url-of-buffer (markdown-mode.el:7929). This leaves that alone and
;;   adds a real in-Emacs view on `SPC m v'.
;; - pandoc converts md -> org, then org-view-mode hides the Org markup so it
;;   reads as prose. Verified pandoc's output keeps headings, /emphasis/,
;;   =code=, #+begin_src blocks and tables intact.
;; - org-view-mode is org-only — it signals "Not in org-mode" otherwise
;;   (org-view-mode.el:653) — which is why the buffer is converted before the
;;   minor mode is switched on.
;; - Snapshot, not live: it re-renders on each keypress, it does not track edits.
(defun my-markdown-view ()
  "Preview the current Markdown buffer inside Emacs, as rendered Org."
  (interactive)
  (unless (executable-find "pandoc")
    (user-error "pandoc not on PATH"))
  (let* ((file (or (buffer-file-name)
                   (user-error "Save the buffer first: %s needs a file" major-mode)))
         (name (format "*%s*" (file-name-nondirectory file)))
         (buf (get-buffer-create name)))
    (unwind-protect
        (with-current-buffer buf
          (let ((inhibit-read-only t))
            (erase-buffer)
            (org-mode)
            (insert-file-contents file)
            (goto-char (point-min))
            (unless (zerop (call-process-region (point-min) (point-max)
                                               "pandoc" nil t nil
                                               "-f" "markdown" "-t" "org"))
              (user-error "pandoc failed to convert %s" file))
            (goto-char (point-min))
            (org-view-mode 1)
            (display-buffer buf)))
      ;; Only clean up if the conversion bailed before display-buffer.
      (unless (get-buffer-window buf)
        (kill-buffer buf)))))

;; - `v' is free on markdown-mode-map: Doom binds o (open), p (preview),
;;   e (export), ' (edit code block) and the i/insert prefix there.
(with-eval-after-load 'markdown-mode
  (map! :map markdown-mode-map :localleader "v" #'my-markdown-view))



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
