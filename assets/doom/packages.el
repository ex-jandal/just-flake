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

;; - MCP server exposing this live Emacs (buffers, diagnostics, elisp, org) as
;;   MCP tools to the agent. Upstream ships a Doom recipe for it verbatim.
;;   `:files' IS load-bearing: every tool (eval-elisp, get-diagnostics, the 10
;;   org-* and 3 org-roam-* ones) lives in tools/, not the repo root. With the
;;   default :files spec — which only globs root `*.el' — the package installs
;;   with ZERO tools and the MCP server connects but exposes nothing. Verified:
;;   `package-build-expand-files-spec' takes bare globs (the `:defaults' marker
;;   is optional), so this list is valid and needs no `:defaults' prefix, and
;;   that the unpacked result really does contain all 16 tools/*.el files.
;;   The two wrapper scripts are unused (opencode reaches the socket through
;;   plain socat — see mcp.emacs in home/modules/opencode.nix) but cost nothing
;;   to install and leave the wrapper reconnect path open without a rebuild.
;;
;; - NOTE: emacs-opencode is NOT here. It needs `(require 'request)' at compile
;;   time, and a `package!' entry cannot provide that: unstraightened runs
;;   melpaBuild with `emacs --batch -Q' (no package load-path) and derives the
;;   package's build inputs solely from `Package-Requires' headers, which
;;   emacs-opencode does not declare. Declaring `(package! request)' does NOT
;;   help — the resulting emacs-opencode derivation is byte-for-byte identical.
;;   It is therefore built as a `buildEmacsPackage' with request as a
;;   propagateBuildInput in home/modules/doom-emacs.nix instead.
(package! mcp-server
  :recipe (:type git :host github :repo "rhblind/emacs-mcp-server"
           :files ("*.el" "tools/*.el" "mcp-wrapper.py" "mcp-wrapper.sh"))
  :pin "a5d749cf9880598f66308545985526fd4460627f")

;; - Signal client: send/receive over signal-cli's JSON-RPC interface, with
;;   local SQLite persistence and FTS5 full-text search across all history.
;;   Reached with M-x sgn-start / M-x sgn-chat (no keybinding by choice).
;; - A plain `package!' DOES work here, unlike emacs-opencode above: every
;;   (require ...) in all 13 source files resolves to Emacs core — button,
;;   cl-lib, color, image, json, notifications, tabulated-list — or to sgn's own
;;   modules. So unstraightened's melpaBuild (`emacs --batch -Q', no package
;;   load-path) can byte-compile it standalone, which is exactly how upstream's
;;   own Makefile does it. Package-Requires is only ((emacs "29.1")), already
;;   satisfied by the 30.2 this builds against, so there is nothing to fetch.
;; - `:files ("*.el")' is deliberately WIDER than upstream's Makefile, which
;;   lists 12 SRCS but omits sgn-import.el even though sgn.el requires it — so
;;   `make compile' is broken upstream. The root glob picks up all 13 files.
;; - The SQLite layer uses Emacs 29+'s built-in sqlite.el (sqlite-open /
;;   sqlite-execute / sqlite-select), NOT an external emacs-sqlite3 binding,
;;   which is why "no external deps" holds. Confirmed against the built
;;   30.2: sqlite-available-p t, SQLite 3.53.3, FTS5 create/insert/drop all
;;   succeed. sgn hard-fails at startup if FTS5 is missing.
;; - No `(require 'sgn)' in config.el: sgn-start and sgn-chat are both
;;   ;;;###autoload.
;; - sgn-account (the phone number) is deliberately NOT set here — this repo
;;   pushes to GitHub and Codeberg. Set it with
;;   `M-x customize-set-variable' so it lands in the redirected custom-file
;;   instead of in git.
;; - sgn cannot register an account, only link extra devices (M-x sgn-link).
;;   First-time registration is a manual `signal-cli register' (SMS).
(package! sgn
  :recipe (:type git :host github :repo "benthamite/sgn"
           :files ("*.el"))
  :pin "8b9c48306b50819e7454e51d0d580abe0477d1a4")

(package! magit-delta
  :recipe (:host github :repo "dandavison/magit-delta")
  :pin "5fc7dbddcfacfe46d3fd876172ad02a9ab6ac616")
;; - :lang vala does not exist upstream, so Doom never declares vala-mode.
;;   Dropped: `vala-mode` is in nixpkgs emacsPackages, but vala-ls (the LSP)
;;   is not, so this only buys syntax highlighting with no completion.
;;   Uncomment if you want it.
;; (package! vala-mode)

;; - No `:lang svelte' module exists upstream either — Doom's :lang web claims
;;   `\.svelte\' for web-mode but offers no Svelte-aware editing. svelte-mode gives
;;   that (Svelte directives, `{#expr}` blocks, per-submode indentation) and is
;;   what config.el registers with lsp-mode.
;; - No :recipe/:pin: nixpkgs emacsPackages has it, and v1.0.5 declares
;;   `Package-Requires: ((emacs "26.1"))' — it requires only built-ins
;;   (sgml-mode, js, css-mode, prog-mode, subr-x) and treats pug/coffee/sass/
;;   typescript as soft deps, which is why nixpkgs' recipe has an empty `deps'.
(package! svelte-mode)

;; Prefer Doom's own tree-sitter grammars; the nixpkgs set is provided via
;; `extraPackages` (with-all-grammars) so that grammar .so files are compiled
;; ahead of time rather than at first launch.
