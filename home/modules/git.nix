{
  ...
}:
{
  programs.git = {
    enable = true;
    userName = "Sultan Majed";
    userEmail = "sultan.m.alsalahi@gmail.com";
    
    settings = {
      init.defaultBranch = "main";
      core.editor = "nvim";
    };
  };

  home.sessionVariables.GIT_EDITOR = "nvim";
}
