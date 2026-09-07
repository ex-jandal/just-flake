{
  ...
}:
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "abu_jandal";
        email = "me.abujandal@gmail.com";
      };
      init.defaultBranch = "main";
      core.editor = "nvim";
    };
  };

  home.sessionVariables.GIT_EDITOR = "nvim";
}
