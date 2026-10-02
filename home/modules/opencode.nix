{ ... }:
{
  programs.opencode = {
    enable = true;
    settings = {
      lsp = true;
      formatter = true;
      autoupdate = true;
      mcp = {
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
        };
        # - reaches the emacs-mcp-server running inside Doom Emacs, giving the
        #   agent access to live buffers, diagnostics, elisp and org. The server
        #   side is `mcp-server' in assets/doom/config.el.
        # - socat is the stdio <-> unix-socket bridge, and it is necessary rather
        #   than decorative: opencode's MCP schema only accepts a `command' argv
        #   (McpLocalConfig in opencode.ai/config.json) — there is no socket
        #   transport — so something has to translate. socat itself comes from
        #   extraBinPackages in home/modules/doom-emacs.nix, which guarantees it
        #   on the PATH opencode inherits.
        # - `{env:HOME}' is substituted by opencode at config-resolve time
        #   (verified with `opencode debug config'), so no absolute path is
        #   hardcoded here. It MUST resolve to the same place the server side
        #   writes: assets/doom/config.el sets mcp-server-socket-directory to
        #   doom-local-dir, i.e. ~/.local/share/doom (doomLocalDir in
        #   home/modules/doom-emacs.nix).
        # - This entry is GLOBAL, not scoped to sessions launched from Emacs, so
        #   it also applies to opencode.nvim and terminal runs. Measured
        #   behaviour when Emacs is closed: `opencode mcp list' reports
        #   `✗ emacs failed — MCP error -32000: Connection closed' while
        #   context7 stays connected and sessions run normally. Cosmetic, not
        #   breakage.
        emacs = {
          type = "local";
          command = [
            "socat"
            "-"
            "UNIX-CONNECT:{env:HOME}/.local/share/doom/emacs-mcp-server.sock"
          ];
          enabled = true;
          # - default is 5000ms, which is the MCP handshake budget and is tight
          #   for a cold Emacs. eval-elisp can also legitimately take a while.
          timeout = 30000;
        };
      };
      # - steer the agent toward the emacs_* tools. Written below; kept in this
      #   module rather than assets/opencode/ so the whole opencode<->emacs
      #   wiring sits in one place.
      # - `instructions' is REPLACED rather than merged by later config layers
      #   (verified with `opencode debug config'), so putting it here means no
      #   per-project instructions file can add to it.
      instructions = [ "{env:HOME}/.config/opencode/instructions/emacs.md" ];
      plugin = [
        "@dietrichgebert/ponytail"
      ];
    };
  };

  # - Worded conditionally on purpose. This file is loaded by EVERY opencode
  #   session, including opencode.nvim and plain terminal runs, so it must not
  #   assert that Emacs is present — the upstream README's "You are running
  #   inside Emacs" would be false there. `eval-elisp' / `get-diagnostics' /
  #   `org-*' only exist in the tool list when the MCP server above actually
  #   connected, which is the reliable signal.
  # - `xdg.configFile' rather than `home.file', so this lands under the same
  #   base directory programs.opencode writes opencode.json into — the `instructions'
  #   path above hardcodes ~/.config because {env:HOME} cannot expand into a nix
  #   string, so the two must agree.
  xdg.configFile."opencode/instructions/emacs.md".text = ''
    # Emacs Integration

    You MAY be running inside a live Emacs instance. Check your available tools
    first: if `eval-elisp`, `get-diagnostics`, or any `org-*` tool is present,
    the `emacs` MCP server is connected and you have structured access to the
    user's running editor. If none of them are present, ignore this file
    entirely.

    When they are present, prefer them over reading or editing files on disk
    when the task concerns the live editing session:

    - `eval-elisp` — evaluate elisp in the running Emacs. Use this instead of
      shelling out to `emacsclient` for anything user-facing, and instead of
      `M-x`-equivalent commands. Prefer reading and writing buffers through it
      rather than mutating files behind the editor's back.
    - `get-diagnostics` — current errors and warnings per file. Authoritative;
      do not re-run linters to find out what is already broken.
    - org tools — read and update headings, TODO state, priority, tags,
      properties, schedules and deadlines; `org-capture` for new entries. The
      org-roam tools (`org-roam-search`, `org-roam-get-node`,
      `org-roam-capture`) are available too, and the roam write tools honour
      `org-roam-capture-templates`.

    Ask before editing the user's org files or anything outside the task scope,
    even when a tool would permit it unattended.
  '';
}
