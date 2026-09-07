{
  ...
}:
{
  programs.git = {
    enable = true;
    userName = "abu_jandal";
    userEmail = "me.abujandal@gmail.com";
    
    settings = {
      init.defaultBranch = "main";
      core.editor = "nvim";
    };
  };

  home.sessionVariables.GIT_EDITOR = "nvim";
}
