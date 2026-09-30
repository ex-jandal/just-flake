{ ... }:
{
  programs.opencode = {
    enable = true;
    settings = {
      lsp = true;
      formatter = true;
      autoupdate = true;
      mcp = {
        context7 = {
          type = "remote";
          url = "https://mcp.context7.com/mcp";
        };
      };
      # plugins = [
      #   ""
      #   ""
      # ];
    };
  };
}
