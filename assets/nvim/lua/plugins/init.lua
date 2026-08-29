local M = {
  {
    "stevearc/conform.nvim",
    -- event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  -- {
  -- 	"nvim-treesitter/nvim-treesitter",
  -- 	opts = {
  -- 		ensure_installed = {
  -- 			"vim", "lua", "vimdoc",
  --      "html", "css"
  -- 		},
  -- 	},
  -- },

  {
    "folke/todo-comments.nvim",
    lazy = false,
    config = function()
      require("todo-comments").setup()
    end,
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  {
    "3rd/image.nvim",
    build = false, -- so that it doesn't build the rock https://github.com/3rd/image.nvim/issues/91#issuecomment-2453430239
    opts = {
        processor = "magick_cli",
    }
  },

  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "marksman",
        "html",
        "shellcheck",
        "cssls",
        "ts_ls",
        "tailwindcss-language-server",
        "svelte",
        "vls",
        "pyright",
        "texlab",
        "rust-analyzer",
        "clangd",
        "intelephense",
        "nil_ls",
        "dcm",
        "sqls",
        "codelldb",
        "jdtls",
        "java-debug-adapter",
        "java-test",
        "roslyn",
      },
    },
  },
}

table.insert(M, require "plugins.rust_plugins")
table.insert(M, require "plugins.dap_plugins")
table.insert(M, require "plugins.snacks")
table.insert(M, require "plugins.frontend_plugins")
-- table.insert(M, require "markdown")

return M
