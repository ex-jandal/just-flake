return {
  {
    "luckasRanarison/tailwind-tools.nvim",
    lazy = false,
    build = ":UpdateRemotePlugins",
    config = function()
      -- require("tailwind-tools").setup {
      --   autocompletion = true,
      --   -- tweak these as you like
      --   document_color = {
      --     enabled = true,
      --     -- kind = "foreground",    -- "inline" | "foreground" | "background"
      --     inline_symbol = " ",  -- inline symbol when using inline mode
      --   },
      --   cmp = {
      --     highlight = "foreground", -- how to render previews in cmp
      --   },
      -- }
    end,
  },

  -- {
  --   "roobert/tailwindcss-colorizer-cmp.nvim",
  --   -- optionally, override the default options:
  --   config = function()
  --     require("tailwindcss-colorizer-cmp").setup({
  --       color_square_width = 1,
  --     })
  --   end
  -- },

  {
    "vuejs/vetur",
    opts = {
      ensure_installed = {
        "vls",
      },
    },
    config = function ()
      require('vetur').setup()
    end
  },

  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
    opts = {
      enable_autocmd = false,
    },
    config = function()
      require('ts_context_commentstring').setup()
    end,
  },
}
