local data_path = vim.fn.stdpath("data")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "dbout",
  callback = function()
    vim.opt_local.number = false    -- no line numbers
    vim.opt_local.relativenumber = false
    vim.opt_local.cursorline = false -- no cursor line
    vim.opt_local.signcolumn = "no"  -- no sign column
    vim.opt_local.conceallevel = 0   -- show all text
    vim.opt_local.foldenable = false
    vim.opt_local.wrap = false        -- no line wrapping
    vim.opt_local.linebreak = false   -- don’t break words
    vim.opt_local.list = false        -- hide wrap symbols
  end,
})

return {
  {
    "tpope/vim-dadbod",
    lazy = false,
    dependencies = {
      "mattn/webapi-vim",
    },
    config = function()
      vim.g.db_ui_auto_execute_table_helpers = 1
      vim.g.db_ui_save_location = data_path .. "/dadbod_ui"
      vim.g.db_ui_show_database_icon = true
      vim.g.db_ui_tmp_query_location = data_path .. "/dadbod_ui/tmp"
      vim.g.db_ui_use_nerd_fonts = true
      vim.g.db_ui_use_nvim_notify = true

      -- NOTE: The default behavior of auto-execution of queries on save is disabled
      -- this is useful when you have a big query that you don't want to run every time
      -- you save the file running those queries can crash neovim to run use the
      -- default keymap: <leader>S
      vim.g.db_ui_execute_on_save = false
    end,
  },

  {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
      {
        'tpope/vim-dadbod',
        lazy = true
      },
      {
        'kristijanhusak/vim-dadbod-completion',
        ft = { 'sql', 'mysql', 'plsql' },
        lazy = true,
        config = function()
          vim.g.dadbod_completion_use_default_mappings = 1
        end
      },
    },
    keys = {
      { "<leader>D", "<cmd>DBUIToggle<CR>", desc = "Toggle DBUI" },
    },
    cmd = {
      'DBUI',
      'DBUIToggle',
      'DBUIAddConnection',
      'DBUIFindBuffer',
    },
    init = function()
      -- Your DBUI configuration
      require "surreal_adapter"
      vim.g.db_ui_use_nerd_fonts = 1
      vim.g.dbs = {
        -- { name = 'dev', url = 'postgres://postgres:mypassword@localhost:5432/my-dev-db' },
        -- { name = 'staging', url = 'postgres://postgres:mypassword@localhost:5432/my-staging-db' },

        { name = 'mariadb_neo', url = 'mariadb://sultan:sultan@localhost/neo' },
        { name = 'PG_chatting_app', url = 'mariadb://pg_chatting_app:pg_chatting_app@localhost/pg_chatting_app' },
        { name = 'oracle_neo', url = 'oracle://sultan:sultan@localhost/neo' },
        { name = 'Postgres_neo', url = 'postgresql://sultan:sultan@localhost:5432/neo'},
        { name = 'Postgres_karka-deh', url = 'postgresql://karka_deh:86400051@localhost:5432/karka_deh'},
        { name = 'SQLite_neo', url = 'sqlite:///home/abu_jandal/project/sqlite3/neo.db'},
        -- { name = 'MongoDB_art-social', url = 'mongodb://localhost:27017/art-social'},
        { name = 'MongoDB_neo', url = 'mongodb://localhost:27017/neo'},

        { name = 'SQLite_signalbot', url = 'sqlite:///home/abu_jandal/signalbot/db.sqlite'},
        -- { name = 'Redis', url = 'redis://localhost:6379'},
        -- { name = "surreal_local", url = "surreal://localhost:8000/test/test" },
        -- {
        --   name = 'surreal',
        --   url = function()
        --     return vim.fn.system('http://localhost:8000/')
        --   end
        -- },
      }
    end,
  },

  -- {
  --   'nanotee/sqls.nvim',
  --   lazy = false,
  --   dependencies = { 'neovim/nvim-lspconfig' },
  --   config = function()
  --     local lspconfig = require('lspconfig')
  --
  --     lspconfig.sqls.setup {
  --       on_attach = function(client, bufnr)
  --         require('sqls').on_attach(client, bufnr)
  --       end,
  --       cmd = { 'sqls' },
  --       settings = {
  --         sqls = {
  --           connections = {
  --             {
  --               driver = 'mysql',
  --               dataSourceName = 'sultan:sultan@tcp(127.0.0.1:3306)/neo',
  --             },
  --           },
  --         },
  --       },
  --     }
  --   end
  -- },
}
