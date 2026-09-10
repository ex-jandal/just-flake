{ pkgs }:
pkgs.mkShell {
  # Compile with clang by default so clangd parses the exact same
  # include/flag set (best LSP fidelity). gcc stays explicitly available.
  packages = with pkgs; [
    # Clang ecosystem + LSP
    clang-tools
    gcc

    # Build tools
    cmake meson ninja gnumake pkg-config
    ccache bear

    # Debugging + profiling + coverage
    gdb lldb valgrind strace lcov

    # Linting / formatting
    cppcheck codespell cmake-format

    # Testing
    gtest catch2

    # Common C++ libraries
    fmt spdlog nlohmann_json
  ];

  # Kill the classic fortify + -O0 glibc warning on debug builds.
  hardeningDisable = [ "fortify" ];

  env = {
    CC = "clang";
    CXX = "clang++";
    CMAKE_EXPORT_COMPILE_COMMANDS = "ON";
  };

  shellHook = ''
    echo "C/C++ devShell (clang-based)"
    echo "  gcc:    $(gcc --version | head -1)"
    echo "  clang:  $(clang --version | head -1)"
    echo "  cmake:  $(cmake --version | head -1)"
    echo "  meson:  $(meson --version | head -1)"
    echo "clangd LSP: compile_commands.json auto-exports —"
    echo "  meson in build/, cmake via CMAKE_EXPORT_COMPILE_COMMANDS=ON,"
    echo "  make via \`bear -- make\`."
  '';
}