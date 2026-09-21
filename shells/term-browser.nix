{ pkgs }:
let
  # FHS Environment to wrap the browser dependencies so the binary can find them
  browserEnv = pkgs.buildFHSEnv {
    name = "terminal-browser";
    # Merge the full closure of the listed packages into /usr so every
    # transitive Electron/GTK dependency (gdk-pixbuf, harfbuzz, fribidi,
    # at-spi2, Xi, Xcursor, ...) is present, not just the explicit list.
    includeClosures = true;
    targetPkgs =
      pkgs: with pkgs; [
        # Your requested libraries
        nss # libnss3
        gtk3 # libgtk-3-0
        alsa-lib # libasound2t64
        mesa # libgbm1

        # Critical Chromium/Electron runtime requirements
        glib
        nspr
        atk
        at-spi2-core
        at-spi2-atk
        cups
        dbus
        expat
        fontconfig
        freetype
        libxkbcommon
        pango
        cairo
        systemd # Provides libudev.so.1

        # X11 requirements
        libx11
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxrandr
        libxrender
        libxtst
        libxcb
      ];
    # \${HOME} expands at runtime inside the FHS env (a bare `~` would not).
    runScript = "\${HOME}/.local/bin/terminal-browser";
  };
in
pkgs.mkShell {
  packages = with pkgs; [
    # Node runtime required if you install terminal-browser via npm
    nodejs_22

    # Puts ${browserEnv}/bin first on PATH, so `terminal-browser` launches
    # the app inside the FHS environment.
    browserEnv
  ];

  shellHook = ''
    echo "terminal-browser devShell"
    echo "  run: terminal-browser <url>"
    echo "  (falls back to terminal-browser --no-sandbox if the sandbox complains)"
  '';
}
