{
  pkgs,
  ...
}:
{
  # tmux — config copied verbatim. TPM fetches plugins at runtime (approved).
  home.packages = [ pkgs.tmux ];

  home.file.".config/tmux/tmux.conf".source = ../../assets/tmux/tmux.conf;

  # Provide TPM so the copied config resolves its plugins at runtime.
  # Pinned to the v3.1.0 commit; fetched at eval (matches the runtime-fetch choice).
  home.file.".tmux/plugins/tpm" = {
    source = builtins.fetchGit {
      url = "https://github.com/tmux-plugins/tpm";
      rev = "7bdb7ca33c9cc6440a600202b50142f401b6fe21";
      allRefs = true;
    };
  };
}
