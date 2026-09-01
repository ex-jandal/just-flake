{
  pkgs,
  ...
}: {
  # zathura alone is backendless; zathuraPkgs.* holds the rendering plugins in
  # this nixpkgs snapshot. Install both the mupdf and poppler backends (mupdf
  # listed first = default: PDF + ePub + DJVU + comic, fast) so heavy-text PDFs
  # can still be force-rendered with poppler if ever needed.
  home.packages = with pkgs; [
    zathura
    zathuraPkgs.zathura_pdf_mupdf
    zathuraPkgs.zathura_pdf_poppler
    # comic-book (cb), djvu and postscript backends to round out document types.
    zathuraPkgs.zathura_cb
    zathuraPkgs.zathura_djvu
    zathuraPkgs.zathura_ps
  ];

  # zathurarc — vi-style bindings + Noctalia palette baked in (dark #101510 bg,
  # green #9ad4a1 accent, teal #1d404b selection).
  home.file.".config/zathura/zathurarc".text = ''
    # --- colors (Noctalia palette) ---
    set default-bg                "#101510"
    set default-fg                "#e8ece4"
    set statusbar-bg              "#101510"
    set statusbar-fg              "#9ad4a1"
    set inputbar-bg               "#101510"
    set inputbar-fg               "#e8ece4"
    set completion-bg             "#101510"
    set completion-fg             "#e8ece4"
    set completion-highlight-bg   "#1d404b"
    set completion-highlight-fg   "#e8ece4"
    set highlight-active-color    "#9ad4a1"
    set highlight-color           "#1d404b"
    set index-bg                  "#101510"
    set index-fg                  "#9ad4a1"
    set recolor                   true
    set recolor-darkcolor         "#101510"
    set recolor-lightcolor        "#e8ece4"

    # --- keys (vi-style) ---
    map j           scroll down
    map k           scroll up
    map h           scroll left
    map l           scroll right
    map gg          goto first
    map G           goto last
    map /           search forward
    map ?           search backward
    map n           search next
    map N           search backward
    map +           zoom in
    map -           zoom out
    map U           toggle reading
    map F           toggle fullscreen
    map R           reload
    map <C-p>       print
    map dd          close

    # --- behaviour ---
    set scroll-step      30
    set zoom-step        30
    set smooth-scroll    true
    set adjust-open      250
    set font             "monospace 12"
    set pagesize         letter
    set selection-clipboard clipboard
  '';
}