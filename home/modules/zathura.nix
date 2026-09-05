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

  # zathurarc + noctaliarc ported verbatim from Arch ~/.config/zathura/.
  # zathurarc = gruvbox palette; noctaliarc = Noctalia blue-on-dark palette.
  home.file.".config/zathura/zathurarc".source = ../../assets/zathura/zathurarc;
  home.file.".config/zathura/noctaliarc".source = ../../assets/zathura/noctaliarc;
}
