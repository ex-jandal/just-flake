{
  ...
}:
{
  programs.git = {
    enable = true;
    settings = {
      init.defaultBranch = "main";
      url."git@github.com:".insteadOf = "https://github.com/";
      core.editor = "nvim";
    };
  };

  home.sessionVariables.GIT_EDITOR = "nvim";
}
