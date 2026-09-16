{
  pkgs,
  ...
}:
{
  # - zathura alone is backendless; zathuraPkgs.* holds the rendering plugins.
  #   Install both mupdf (default: PDF + ePub + DJVU + comic, fast) and poppler
  #   backends so heavy-text PDFs can be force-rendered if ever needed.
  home.packages = with pkgs; [
    zathura
    zathuraPkgs.zathura_pdf_mupdf
    zathuraPkgs.zathura_pdf_poppler
    # - comic-book (cb), djvu and postscript backends round out document types
    zathuraPkgs.zathura_cb
    zathuraPkgs.zathura_djvu
    zathuraPkgs.zathura_ps
  ];

  # - zathurarc + noctaliarc ported verbatim from Arch ~/.config/zathura/
  #   (zathurarc = gruvbox palette; noctaliarc = Noctalia blue-on-dark).
  home.file.".config/zathura/zathurarc".source = ../../assets/zathura/zathurarc;
  home.file.".config/zathura/noctaliarc".source = ../../assets/zathura/noctaliarc;
}
