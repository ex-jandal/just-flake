{
  pkgs,
  ...
}:
{
  # tmux — config copied verbatim. TPM fetches plugins at runtime (approved).
  home.packages = [ pkgs.tmux ];

  home.file.".config/tmux/tmux.conf".source = ../../assets/tmux/tmux.conf;

  # Provide TPM so the copied config resolves its plugins at runtime.
  # Pinned to the v3.1.0 commit. fetchFromGitHub (hermetic, build-time, cached)
  # instead of builtins.fetchGit (non-hermetic full clone at eval, broke builds).
  home.file.".tmux/plugins/tpm" = {
    source = pkgs.fetchFromGitHub {
      owner = "tmux-plugins";
      repo = "tpm";
      rev = "7bdb7ca33c9cc6440a600202b50142f401b6fe21";
      sha256 = "18i499hhxly1r2bnqp9wssh0p1v391cxf10aydxaa7mdmrd3vqh9";
    };
  };
}
