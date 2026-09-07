{
  ...
}:
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "Sultan Majed";
        email = "sultan.m.alsalahi@gmail.com";
      };
      init.defaultBranch = "main";
      core.editor = "nvim";
    };
  };

  home.sessionVariables.GIT_EDITOR = "nvim";
}
