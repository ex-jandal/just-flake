{ pkgs }:
pkgs.mkShell {
  packages = with pkgs; [
    # Compilers + build tools
    gcc gnumake cmake pkg-config
    meson ninja

    # Clang ecosystem
    clang clang-tools

    # Debuggers + profilers
    gdb lldb valgrind strace

    # Linting
    cppcheck

    # Common C++ libraries (headers + pkg-config files)
    gtest catch2 spdlog fmt nlohmann_json
  ];

  shellHook = ''
    echo "C/C++ devShell active"
    echo "  gcc:   $(gcc --version | head -1)"
    echo "  clang: $(clang --version | head -1)"
    echo "  cmake: $(cmake --version | head -1)"
  '';
}
