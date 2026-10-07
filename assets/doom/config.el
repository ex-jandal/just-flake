;;; config.el -*- lexical-binding: t; -*-

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
(setq doom-font (font-spec :family "CaskaydiaCove Nerd Font" :size 22)
      doom-variable-pitch-font (font-spec :family "Rubik" :size 23)
      doom-big-font-size 1.33
      doom-big-font-line-height 1.1
      doom-small-font-size 11)

(set-fontset-font t 'arabic "Rubik")
(setq-default bidi-paragraph-direction 'nil)

(setq display-line-numbers-type 'relative)


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

;; - svelte-mode is the one exception to "no per-language wiring needed here":
;;   Doom has no :lang svelte module, so nothing adds `lsp!' to its hook. lsp-svelte
;;   activates on the `.svelte' *extension* (lsp-svelte.el:273), not on a
;;   major-mode/language-id match, so it would come up fine here regardless.
;; - `lsp-deferred', not `lsp': at file-local-vars-hook time lsp-mode is not fully
;;   set up yet. This is what Doom's `lsp!' expands to.
;; - The `require' is load-bearing, not just for the mode. :lang web already claims
;;   `\.svelte\' via `(use-package! web-mode :mode "\\.svelte\\'")'
;;   (modules/lang/web/+html.el:16), and svelte-mode's own
;;   `(add-to-list 'auto-mode-alist '("\\.svelte\\'" . svelte-mode))' PREPENDS when
;;   it loads — so this require is what makes svelte-mode win that extension.
;;   :user has CONFIGDEPTH 105, so this file loads after every module's config.el
;;   and therefore after web-mode's prepend.
(require 'svelte-mode)

(add-hook 'svelte-mode-hook #'lsp-deferred)

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

  (after! rustic
    (setq rustic-analyzer-command '("lspmux" "client"))
  )

  (defun my-rust-disable-clippy-flymake ()
    "Remove Emacs 30's clippy-on-stdin flymake backend for Rust buffers."
    (remove-hook 'flymake-diagnostic-functions 'rust-ts-flymake t))
  
  (dolist (hook '(rustic-mode-hook rust-mode-hook))
    (add-hook hook #'my-rust-disable-clippy-flymake))


;; - No `:lang tailwindcss' module exists upstream (nothing under doomemacs/modules
;;   mentions tailwind), but lsp-mode ships an `lsp-tailwindcss' client and the
;;   binary is already in extraBinPackages.
;;
;; - lsp-tailwindcss.el:273 declares the server with ONLY a `:download' provider
;;   (the vscode extension zip) — no `:system'. Left alone, `lsp-package-path' looks
;;   for ~/.local/share/lsp/tailwindcss/extension/dist/tailwindServer.js, gets nil,
;;   and `lsp' drops the client at its `lsp--server-binary-present?' filter
;;   (lsp-mode.el:9876). SILENTLY: html/svelte/ts still match, so matching-clients is
;;   non-nil and the install-suggestion branch at lsp-mode.el:9915 never runs either.
;; - Overriding the dependency to `:system' points it at the nixpkgs binary.
;; - `with-eval-after-load' on the CLIENT, not on lsp-mode: `lsp-dependency' is an
;;   ht-set, so lsp-tailwindcss's own call at load time clobbers an override made
;;   too early. lsp-mode's own docstring shows this require-then-override order.
;; - Side effect: with no `:download' provider left, `M-x lsp-install-server' reports
;;   "no automatic installation for tailwindcss". Correct — every server in this flake
;;   comes from Nix.
;;
;; - `js-ts-mode' is prepended because upstream's list (lsp-tailwindcss.el:53) has
;;   web-mode, html-mode, css-mode, typescript-mode, typescript-tsx-mode and
;;   tsx-ts-mode but not js-ts-mode, which is what Doom's :lang javascript uses for
;;   plain .js/.jsx. .ts/.tsx already resolve through typescript-mode's ts-mode
;;   ancestry, and .svelte through svelte-mode's html-mode ancestry.
;;
;; - No `lsp-tailwindcss-skip-config-check' needed: `lsp-tailwindcss--activate-p'
;;   wants a tailwind.config.* file OR a v4 package.json entry, and
;;   `lsp-tailwindcss--version-v4-p' matches "^4.3.2" out of devDependencies.
;; - Nothing hooks lsp! into these modes for this client — it is an add-on
;;   (`lsp-tailwindcss-add-on-mode' is t), so it attaches to whatever server already
;;   manages the buffer.
(with-eval-after-load 'lsp-tailwindcss
  (lsp-dependency 'tailwindcss-language-server
                  '(:system "tailwindcss-language-server"))

  (setq lsp-tailwindcss-major-modes
        (cons 'js-ts-mode lsp-tailwindcss-major-modes)))

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

(use-package! which-key
  :init
  (setq which-key-idle-delay 0.2
        which-key-allow-multiple-replacements t)
  :config
  ;; modified from https://tecosaur.github.io/emacs-config/config.html#which-key
  (pushnew!
   which-key-replacement-alist
   '(("" . "\\`+?evil[-:]?\\(?:a-\\)?\\(.*\\)") . (nil . "◂\\1"))
   '(("\\`g s" . "\\`evilem--?motion-\\(.*\\)") . (nil . "◃\\1"))
   '(("" . "\\`+?magit[-:]?\\(?:a-\\)?\\(.*\\)") . (nil . "\\1"))))


(setq corfu-auto-delay 0.2)


(use-package magit-delta
  :hook (magit-mode . magit-delta-mode))


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


;;
;;; OpenCode
;;
;; - Native Emacs client for `opencode serve' (github.com/jdormit/emacs-opencode),
;;   provided as a buildEmacsPackage via `extraPackages' in
;;   home/modules/doom-emacs.nix (NOT a packages.el entry — see the long comment
;;   there on why melpaBuild cannot satisfy its `request' dependency).
;;   `package!'-declared packages are required by the generated profile; this one
;;   is not, so the require below is what loads it.
;;
;; - Doom ships no module for it — checked doomemacs master and its modules
;;   submodule — so there is nothing to add to the `doom!' block in init.el.
;;
;; - The package talks to the SAME server surface as opencode.nvim already does
;;   (both drive `opencode serve' over /session, /event, /agent, /command), so
;;   every route it calls was verified present in nixpkgs' opencode 1.18.21.
;;
;; - M-x opencode is the entry point; it auto-detects the project root from
;;   `project-current' (or default-directory). C-u picks a directory by hand.
;;   In the session buffer: C-c C-c send, C-c C-a agent, C-c C-l model,
;;   C-c C-o slash command.
(require 'emacs-opencode)

;; - `opencode-sse-backend' stays at its default 'auto, which picks the JS
;;   bridge (opencode-sse-bridge.js run under bun or node, both installed) and
;;   falls back to curl if the bridge is unusable. The script is only found
;;   because the postInstall in home/modules/doom-emacs.nix installs it; a
;;   stock melpaBuild drops it and every session then warns "bridge script not
;;   found" (emacs-opencode-sse.el:578). Set this to 'curl if streaming ever
;;   stalls — it works standalone, just chunkier.

;; - Leader keys. The `:leader' + `:prefix' shape is load-bearing, not stylistic:
;;   `:leader' makes map! emit `doom--define-leader-key', which binds into
;;   doom-leader-map and takes the key prefix ONLY from :prefix/:infix
;;   (modules/doom/compat/+keybinds.el:57-79). Spelling the keys out by hand —
;;   (map! :desc "..." "SPC o c a" #'opencode-ask) — expands to
;;   (general-define-key "SPC o c a" …), which hands general the whole string as
;;   one key descriptor, never splitting it into a prefix chain. The binding is
;;   silently dead. Verified expansions:
;;     (map! :leader :prefix ("o c" . "opencode") :desc "Ask" "a" …)
;;     => (doom--define-leader-key :infix "o c" "" (cons "opencode" …) "a" …)
;;     => (define-key doom-leader-map (kbd "o c") …) and (kbd "o c a")
;;   `:prefix' (not `:prefix-map') on purpose: :prefix-map mints a
;;   doom-leader-<desc>-map variable via defvar, and Doom's own bindings already
;;   own doom-leader-open-map and friends — hence its docstring's "DO NOT USE
;;   THIS IN YOUR PRIVATE CONFIG". `:prefix' degrades to :infix internally
;;   because `:leader' set doom--map-fn, which is exactly what we want.
;;   No state keyword => global in every mode, correct for M-x-style commands.
;;
;; - Bare at top level, not in `with-eval-after-load'. That idiom would be dead
;;   here: this Doom has no lisp/doom-key-bindings.el (the key-bindings machinery
;;   moved to modules/doom/compat/+keybinds.el) and nothing provides that
;;   feature, so the hook would never fire. Bare is correct because :user has
;;   CONFIGDEPTH 105 — the highest in the tree — so $DOOMDIR/config.el is the
;;   last config file loaded, after every module's.
;;
;; - `SPC o c' is the only free slot under Doom's open prefix: `a' is the
;;   org-agenda sub-prefix and b d f F r R p P t T e E - are all taken
;;   (modules/config/default/+evil-bindings.el:675-744).
;;
;; - These 8 are exactly the commands upstream leaves UNBOUND, i.e. the whole
;;   gap: every other interactive command in the package is either session-local
;;   (all of those are pre-bound to C-c C-<x>, TAB, RET and mouse-1 by
;;   emacs-opencode-session-mode.el / -session-render.el) or redundant here:
;;     opencode-send-to-session  — subsumed by opencode-send-context-to-session,
;;                                  which falls back to "10 lines around point"
;;                                  when no region is selected
;;     opencode-run-server       — the server starts on demand anyway
;;   The omitted ones stay on M-x.
(map! :leader
  :prefix ("o c" . "opencode")
  :desc "New session"          "c" #'opencode
  :desc "Ask"                  "a" #'opencode-ask
  :desc "Ask with context"     "A" #'opencode-ask-contextual
  :desc "Open session"         "s" #'opencode-open-session
  :desc "Send context"         "t" #'opencode-send-context-to-session
  :desc "MCP status"           "m" #'opencode-mcp-status
  :desc "Shutdown server"      "x" #'opencode-shutdown
  :desc "Shutdown all servers" "X" #'opencode-shutdown-all)

;; Resize windows instantly using Ctrl + Shift + Arrow keys
(map! "C-S-h"  #'evil-window-decrease-width
      "C-S-l"  #'evil-window-increase-width
      "C-S-k"  #'evil-window-decrease-height
      "C-S-j"  #'evil-window-increase-height)


;; - `A' and `t' are the two worth remembering: they mirror the opencode.nvim
;;   maps this repo already ships (assets/nvim/lua/plugins/opencode.lua) —
;;   ask("@this: ") and operator("@this") — so a region or point carries into
;;   the prompt.
;;
;; - `m' reports on the MCP server below, so it is the quickest way to tell
;;   whether the agent can actually reach this Emacs.

;; - The one session-buffer command upstream leaves unbound. Session-local, so
;;   `:map' with NO `:leader' — map! silently ignores `:map' when `:leader' is
;;   present (doomemacs#5532), which would make this a no-op without an error.
;;   `opencode-session-mode-map' is a plain defvar handed straight to
;;   use-local-map (emacs-opencode-session-mode.el:52-77), with no copy made at
;;   mode-init, so this survives into every session buffer.
;;   C-c C-s is free: upstream takes every C-c C-<letter> except b d e g h i j
;;   m q s u w y, plus C-c C-[ and C-c C-].
(map! :map opencode-session-mode-map
  :desc "Rename session" "C-c C-s" #'opencode-session-rename)


;;
;;; Signal (the `sgn' client)
;;
;; - `SPC o s' sits next to `SPC o c' for opencode because `s' is the one letter
;;   left under Doom's open prefix on Linux: the direct bindings there are
;;   A a b d f F r R - plus t T e E D m l and p P, and `s' appears only inside
;;   (:when (modulep! :os macos)) as a "send to application" prefix
;;   (modules/config/default/+evil-bindings.el:676-724). Not on this platform.
;;
;; - THREE sibling map! forms with fully-qualified prefixes, NOT one nested form.
;;   :prefix goes through doom--map-set, which is plist-put (keybinds.el:260) —
;;   it REPLACES the pending prefix rather than appending, so a second :prefix
;;   inside a single form commits the first and binds only `m' at top level.
;;   Sibling forms are fine: doom--map-commit emits general-define-key with
;;   :prefix (:290-301), which walks into the existing `SPC o s' keymap instead
;;   of replacing it. :prefix-map is still avoided — the leader prefix is already
;;   a keymap, not a symbol.
;;
;; - All 25 interactive commands are bound; none need a (require 'sgn) since they
;;   are all ;;;###autoload. The split is by how often you reach for them, not by
;;   topic: the everyday ones are single keys on `SPC o s' so nothing stands
;;   between you and sending a message.
;;
;; - sgn ALSO binds most of these itself, in narrower keymaps. Left alone on
;;   purpose, since those are better keys where they apply:
;;     sgn-chat-mode-map      RET send, C-c C-a attach, C-c C-v voice, C-g cancel
;;     sgn-chat-message-map   r reply, R react, e edit, d delete, f forward,
;;                            P pin, c copy, g more-history — a text property on
;;                            a rendered message, so it does not shadow typing
;;     sgn-dashboard-mode-map RET open, c chat, s search, g refresh, d mark-read
;;     sgn-search-mode-map    RET goto, n next, p prev
;;   The globals below exist to reach those same actions from anywhere else.
;;
;; - `v' (voice note) is bound for completeness but always errors upstream
;;   (sgn.el:578, "not yet implemented").
;;
;;   >>> sgn-account MUST be set, or sgn-start / sgn-chat / sgn-note-to-self all
;;   >>> user-error and signal-cli is spawned with `-a <number>' (sgn-rpc.el:146).
;;   >>> It is set in ~/.config/doom/custom.el, NOT here — see the custom-file
;;   >>> section at the end of this file.
(map! :leader
  :prefix ("o s" . "signal")
  :desc "Dashboard"           "d" #'sgn-dashboard
  :desc "Open chat"           "c" #'sgn-chat
  :desc "Reply"               "r" #'sgn-reply
  :desc "React"               "R" #'sgn-react
  :desc "Forward"             "f" #'sgn-forward
  :desc "Note to self"        "n" #'sgn-note-to-self
  :desc "Attach file"         "a" #'sgn-attach-file
  :desc "Start Signal"        "s" #'sgn-start
  :desc "Stop Signal"         "S" #'sgn-stop
  :desc "Search history"      "/" #'sgn-search
  :desc "Search in chat"      "i" #'sgn-search-in-chat
  :desc "Link device"         "l" #'sgn-link
  :desc "Voice note"          "v" #'sgn-send-voice-note
  :desc "Show log"            "?" #'sgn-show-log
  :desc "Import from Desktop" "I" #'sgn-import-from-desktop)

(map! :leader
  :prefix ("o s m" . "signal message")
  :desc "Edit"               "e" #'sgn-edit
  :desc "Delete"             "d" #'sgn-delete
  :desc "Copy text"          "y" #'sgn-copy-text
  :desc "Toggle pin"         "p" #'sgn-toggle-pin
  :desc "Vote"               "v" #'sgn-vote-poll
  :desc "Disappearing timer" "t" #'sgn-set-disappearing)

(map! :leader
  :prefix ("o s c" . "signal chat")
  :desc "New group"   "g" #'sgn-create-group
  :desc "Create poll" "p" #'sgn-create-poll
  :desc "Block"       "b" #'sgn-block-contact
  :desc "Unblock"     "u" #'sgn-unblock-contact)


;;
;;; Emacs MCP server
;;
;; - github.com/rhblind/emacs-mcp-server exposes this running Emacs to the
;;   agent over a unix socket: buffers, diagnostics, elisp eval, org editing.
;;   opencode reaches it through `mcp.emacs' in home/modules/opencode.nix
;;   (socat bridging stdio to the socket). Only elisp deps are org, which
;;   :lang org already provides.
;;
;; - `mcp-server-socket-directory' MUST be set. It defaults to
;;   `user-emacs-directory', and unstraightened's wrapper passes
;;   --init-directory=$doomSource, a READ-ONLY nix store path — so the default
;;   points at the store and mcp-server-transport-unix's
;;   (make-directory dir t) fails, leaving the server unable to start. doomDir is
;;   likewise a store path. DOOMLOCALDIR (~/.local/share/doom, from
;;   doomLocalDir in home/modules/doom-emacs.nix) is the writable state dir Doom
;;   already creates, so the socket lands at
;;     ~/.local/share/doom/emacs-mcp-server.sock
;;   which is the path home/modules/opencode.nix tells socat to connect to.
(require 'mcp-server)

(setq mcp-server-socket-directory doom-local-dir)

;; - `doom-after-init-hook', NOT the `emacs-startup-hook' upstream suggests.
;;   doom-finalize runs it (doomemacs lisp/doom.el:520), and doom-finalize is
;;   advised onto command-line-1 :after — i.e. after this file has been loaded —
;;   so the require above has definitely run by then. emacs-startup-hook fires
;;   from after-init-hook, which races with Doom's own module loading.
(add-hook 'doom-after-init-hook #'mcp-server-start-unix)

;; - ponytail: every tool enabled, including `eval-elisp'. That tool is remote
;;   code execution in the Emacs process by design, and upstream's static
;;   scanner has known bypasses — it does not walk `let' binding positions and
;;   does not catch runtime (intern ...) construction (their README,
;;   "Security Limitations", issue #10). Deliberate: this is the same trust level
;;   as letting the agent run bash in this project. Tighten if that is not the
;;   deal: (setq mcp-server-emacs-tools-enabled '(get-diagnostics)) drops
;;   eval-elisp and all 13 org tools, leaving read-only diagnostics.
;;
;; - Management: M-x mcp-server-status, mcp-server-stop, mcp-server-list-clients.
;;   Audit trail: M-x mcp-server-security-show-audit-log.
;;
;; - No `server-start' needed: doom-finalize already calls it on every graphic
;;   frame (doomemacs lisp/doom.el:521-529), so emacsclient works too.


;;
;;; Custom file
;;
;; - Doom loads custom-file ONLY if this config left it untouched:
;;     (when (eq custom-file old-custom-file) (doom-load custom-file 'noerror))
;;   at lisp/doom-profiles.el:594, where old-custom-file is captured before the
;;   module configs run. The redirect at the top of this file changes it, so
;;   that guard is ALWAYS false and custom.el is never loaded. Without this form
;;   `M-x customize-set-variable' writes the file and silently does nothing on
;;   the next start.
;; - Placed at the very end, which is where Doom would have loaded it: after
;;   every module's config, so saved customizations win over the setq defaults.
;;   `doom-load' is what Doom itself calls, and 'noerror covers the common case
;;   of the file not existing yet on a fresh machine.
;;
;; - This is what carries sgn-account (the Signal phone number). That number is
;;   passed to signal-cli as `-a' and three entry points user-error without it
;;   (sgn-rpc.el:146, sgn.el:511 and :588), so it is mandatory — but it must not
;;   live in this file, which is pushed to GitHub and Codeberg. Set it once with
;;     M-x customize-set-variable sgn-account RET +15550000000 RET
;;   and it persists here, outside git.
(doom-load custom-file 'noerror)
