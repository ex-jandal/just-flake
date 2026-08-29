return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "vim",
        "lua",
        "vimdoc",
        "html",
        "css",
        "scss",
        "javascript",
        "typescript",
        "markdown",
        "rust",
        "python",
        "vue",
        "svelte",
        "java",
        "php",
        "blade",
        "c_sharp",
        "c",
        "sql",
        "http",
        "graphql",
        "asm",
        "nasm",
        "query",
        "zig",
        "kulala_http",
        "nim",
        "go",
        "gomod",
        "vala",
        "meson",
        "cmake",
        "odin",
        "kotlin",
        "dart",
        "c3",
      },
      highlight = { enable = true },
    },
  },

  -- {
  --   'nvim-treesitter/playground',
  --   lazy = false,
  --   config = function()
  --     require "nvim-treesitter.configs".setup {
  --       playground = {
  --         enable = true,
  --         disable = {},
  --         updatetime = 25, -- Debounced time for highlighting nodes in the playground from source code
  --         persist_queries = false, -- Whether the query persists across vim sessions
  --         keybindings = {
  --           toggle_query_editor = 'o',
  --           toggle_hl_groups = 'i',
  --           toggle_injected_languages = 't',
  --           toggle_anonymous_nodes = 'a',
  --           toggle_language_display = 'I',
  --           focus_language = 'f',
  --           unfocus_language = 'F',
  --           update = 'R',
  --           goto_node = '<cr>',
  --           show_help = '?',
  --         },
  --       }
  --     }
  --   end,
  -- },
}
