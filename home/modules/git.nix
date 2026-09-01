{
  ...
}:
{
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      core.editor = "nvim";
    };
  };

  home.sessionVariables.GIT_EDITOR = "nvim";
}
