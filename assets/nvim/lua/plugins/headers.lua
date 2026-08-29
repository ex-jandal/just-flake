-- autocmd! Filetype c,cpp noremap<buffer> <leader>sv :vsplit \| Ouroboros<CR>

local opts = { noremap = true, silent = true }
local function merge_opts(extra)
  return vim.tbl_extend("force", opts, extra or {})
end

vim.keymap.set("n", "<Leader>cs", "<cmd>vsplit | Ouroboros<CR>", merge_opts { desc = "open header file in split screen" })
vim.keymap.set("n", "<Leader>cf", "<cmd>Ouroboros<CR>", merge_opts { desc = "open header file" })

return {
  -- {
  --   "attilarepka/header.nvim",
  --   lazy = false,
  --   config = function()
  --     require("header").setup({
  --       allow_autocmds = true,
  --       file_name = true,
  --       author = "Sultan Majed",
  --       project = nil,
  --       date_created = true,
  --       date_created_fmt = "%Y-%m-%d %H:%M:%S",
  --       date_modified = false,
  --       date_modified_fmt = "%Y-%m-%d %H:%M:%S",
  --       line_separator = "------",
  --       use_block_header = false,
  --       copyright_text = {
  --         "Copyright (c) 2026 Abu_Jandal",
  --         "Project is available under the LICENSE file."
  --       },
  --       license_from_file = false,
  --       author_from_git = true,
  --     })
  --   end,
  -- },

  {
    "Diogo-ss/42-header.nvim",
    cmd = { "Stdheader" },
    keys = { "<F1>" },
    opts = {
      default_map = true,                   -- Default mapping <F1> in normal mode.
      auto_update = true,                   -- Update header when saving.
      user = "ex-jandal",                   -- Your user.
      mail = "sultan.m.alsalahi@gmail.com", -- Your mail.
      -- add other options.
      git = {
        enable = true,
        user_global = true,
        email_global = true,
      },
    },
    config = function(_, opts)
      require("42header").setup(opts)
    end,
  },

  {
    'jakemason/ouroboros',
    lazy = false,
    dependencies = {
      { 'nvim-lua/plenary.nvim' }
    },
  },
}
