{ pkgs }:
pkgs.mkShell {
  packages = with pkgs; [
    (python3.withPackages (
      ps: with ps; [
        numpy
        pandas
        requests
        fastapi
        uvicorn
        rich
        pydantic
        pytest
        pytest-cov
      ]
    ))

    uv
    pipx
    rye

    ruff
    black
    mypy
    pyright

    pkg-config
  ];

  shellHook = ''
    echo "Python devShell — python $(python --version | cut -d' ' -f2)"
    echo "  uv $(uv --version | cut -d' ' -f2) | ruff $(ruff --version | cut -d' ' -f2)"
    echo "  pytest $(pytest --version | cut -d' ' -f2)"
  '';
}