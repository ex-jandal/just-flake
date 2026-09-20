{ pkgs }:
let
  # - scheme-small base + curated extras, new `withPackages` API
  #   (texlive.combine is deprecated since Nixpkgs 25.x and removed in 27.05).
  tex = pkgs.texliveSmall.withPackages (ps: [
    # - engines / drivers
    ps.latex-bin
    ps.luatex
    ps.lualatex-math
    ps.xetex
    ps.dvipdfmx

    # - fontspec + unicode math for LuaLaTeX
    ps.fontspec
    ps.luaotfload
    ps.unicode-math
    ps.selnolig

    # - icon / dingbat fonts
    ps.fontawesome5
    ps.fontawesome6
    ps.academicons
    ps.psnfss

    # - extra fonts (TeX tree; luaotfload picks them up via kpathsea)
    ps.tex-gyre
    ps.libertinus
    ps.stix2-otf

    # - multilingual (Arabic via LuaLaTeX)
    ps.polyglossia
    ps.babel
    ps.arabluatex

    # - bibliography
    ps.biblatex
    ps.biber
    ps.latexmk

    # - tooling shipped inside TeX Live
    ps.latexindent
    ps.texcount
    ps.texdoc
    ps.chktex
    ps.lacheck

    # - commonly-needed packages
    ps.amsmath
    ps.mathtools
    ps.tools
    ps.graphics
    ps.geometry
    ps.xcolor
    ps.hyperref
    ps.etoolbox
    ps.caption
    ps.float
    ps.booktabs
    ps.multirow
    ps.enumitem
    ps.titlesec
    ps.fancyhdr
    ps.microtype
    ps.csquotes
    ps.cleveref
    ps.siunitx
    ps.standalone
    ps.pgf
    ps.pgfplots
    ps.tikz-cd
    ps.tcolorbox
    ps.todonotes
    ps.imakeidx
    ps.glossaries
    ps.lipsum
    ps.blindtext
    ps.listings
    ps.fancyvrb
  ]);
in
pkgs.mkShell {
  packages = with pkgs; [
    tex

    # - Language Server + build/lint tooling
    #   (chktex/lacheck ship inside the TeX Live env above)
    texlab
    latexrun
    bibtool
  ];

  shellHook = ''
    echo "LaTeX devShell — $(lualatex --version | head -1)"
    echo "  latexmk $(latexmk --version | grep -oP '\d+\.\d+.*' | head -1)"
    echo "  latexrun $(latexrun --help 2>&1 | grep -i version | head -1)"
    echo "  biber $(biber --version)"
    echo "  texlab $(texlab --version)"
    echo "LuaLaTeX: lualatex / xelatex / pdflatex · fontspec + polyglossia / arabluatex"
    echo "Document compilation: vimtex is configured for latexrun (latexmk -xelatex also available)."
  '';
}
