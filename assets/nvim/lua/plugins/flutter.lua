local dap = require("dap");
dap.configurations.dart = {
  {
    type = "dart",
    request = "launch",
    name = "Launch dart",
    dartSdkPath = "/opt/flutter/bin/cache/dart-sdk/bin/dart", -- ensure this is correct
    flutterSdkPath = "/opt/flutter/bin/flutter",                  -- ensure this is correct
    program = "${workspaceFolder}/lib/main.dart",     -- ensure this is correct
    cwd = "${workspaceFolder}",
  },
  {
    type = "flutter",
    request = "launch",
    name = "Launch flutter",
    dartSdkPath = "/opt/flutter/bin/cache/dart-sdk/bin/dart", -- ensure this is correct
    flutterSdkPath = "/opt/flutter/bin/flutter",             -- ensure this is correct
    program = "${workspaceFolder}/lib/main.dart",     -- ensure this is correct
    cwd = "${workspaceFolder}",
  }
}

return {
  {
    'nvim-flutter/flutter-tools.nvim',
    lazy = false,
    dependencies = {
      'nvim-lua/plenary.nvim',
      'stevearc/dressing.nvim',   -- optional for vim.ui.select
    },
    config = true,
  },
}
