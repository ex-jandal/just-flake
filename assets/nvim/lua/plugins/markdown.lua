local M = {
  {
    "epwalsh/obsidian.nvim",
    ui = { enable = false },
    version = "*",  -- recommended, use latest release instead of latest commit
    lazy = true,
    ft = "markdown",
    -- Replace the above line with this if you only want to load obsidian.nvim for markdown files in your vault:
    -- event = {
    --   -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    --   -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/*.md"
    --   -- refer to `:h file-pattern` for more examples
    --   "BufReadPre Documents/Main-Notes/*.md",
    --   "BufNewFile Documents/Main-Notes/*.md",
    -- },
    dependencies = {
      -- Required.
      "nvim-lua/plenary.nvim",

      -- see below for full list of optional dependencies 👇
    },
    opts = {
      workspaces = {
        {
          name = "personal",
          path = "~/Documents/Main-Notes/",
        },
        -- {
        --   name = "work",
        --   path = "~/vaults/work",
        -- },
      },

      -- see below for full list of options 👇
    },
  },

  {
    'brianhuster/live-preview.nvim',
    dependencies = {
      -- You can choose one of the following pickers
      'nvim-telescope/telescope.nvim',
      'ibhagwan/fzf-lua',
      'echasnovski/mini.pick',
    },
  },

  -- {
  --   "OXY2DEV/markview.nvim",
  --     lazy = false,
  --
  --     -- For `nvim-treesitter` users.
  --     priority = 49,
  --
  --     -- For blink.cmp's completion
  --     -- source
  --     dependencies = {
  --         "saghen/blink.cmp"
  --     },
  -- },

  {
    'MeanderingProgrammer/render-markdown.nvim',
    lazy = false,
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.nvim' }, -- if you use the mini.nvim suite
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'echasnovski/mini.icons' }, -- if you use standalone mini plugins
    -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' }, -- if you prefer nvim-web-devicons
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {},
    config = function ()
      require('render-markdown').setup({
        completions = { lsp = { enabled = true } },
        callout = {
          -- Callouts are a special instance of a 'block_quote' that start with a 'shortcut_link'.
          -- The key is for healthcheck and to allow users to change its values, value type below.
          -- | raw        | matched against the raw text of a 'shortcut_link', case insensitive |
          -- | rendered   | replaces the 'raw' value when rendering                             |
          -- | highlight  | highlight for the 'rendered' text and quote markers                 |
          -- | quote_icon | optional override for quote.icon value for individual callout       |
          -- | category   | optional metadata useful for filtering                              |

          note      = { raw = '[!NOTE]',      rendered = '󰋽 Note',      highlight = 'RenderMarkdownInfo',    category = 'github'   },
          tip       = { raw = '[!TIP]',       rendered = '󰌶 Tip',       highlight = 'RenderMarkdownSuccess', category = 'github'   },
          important = { raw = '[!IMPORTANT]', rendered = '󰅾 Important', highlight = 'RenderMarkdownHint',    category = 'github'   },
          warning   = { raw = '[!WARNING]',   rendered = '󰀪 Warning',   highlight = 'RenderMarkdownWarn',    category = 'github'   },
          caution   = { raw = '[!CAUTION]',   rendered = '󰳦 Caution',   highlight = 'RenderMarkdownError',   category = 'github'   },
          -- Obsidian: https://help.obsidian.md/Editing+and+formatting/Callouts
          abstract  = { raw = '[!ABSTRACT]',  rendered = '󰨸 Abstract',  highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
          summary   = { raw = '[!SUMMARY]',   rendered = '󰨸 Summary',   highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
          tldr      = { raw = '[!TLDR]',      rendered = '󰨸 Tldr',      highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
          info      = { raw = '[!INFO]',      rendered = '󰋽 Info',      highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
          todo      = { raw = '[!TODO]',      rendered = '󰗡 Todo',      highlight = 'RenderMarkdownInfo',    category = 'obsidian' },
          hint      = { raw = '[!HINT]',      rendered = '󰌶 Hint',      highlight = 'RenderMarkdownSuccess', category = 'obsidian' },
          success   = { raw = '[!SUCCESS]',   rendered = '󰄬 Success',   highlight = 'RenderMarkdownSuccess', category = 'obsidian' },
          check     = { raw = '[!CHECK]',     rendered = '󰄬 Check',     highlight = 'RenderMarkdownSuccess', category = 'obsidian' },
          done      = { raw = '[!DONE]',      rendered = '󰄬 Done',      highlight = 'RenderMarkdownSuccess', category = 'obsidian' },
          question  = { raw = '[!QUESTION]',  rendered = '󰘥 Question',  highlight = 'RenderMarkdownWarn',    category = 'obsidian' },
          help      = { raw = '[!HELP]',      rendered = '󰘥 Help',      highlight = 'RenderMarkdownWarn',    category = 'obsidian' },
          faq       = { raw = '[!FAQ]',       rendered = '󰘥 Faq',       highlight = 'RenderMarkdownWarn',    category = 'obsidian' },
          attention = { raw = '[!ATTENTION]', rendered = '󰀪 Attention', highlight = 'RenderMarkdownWarn',    category = 'obsidian' },
          failure   = { raw = '[!FAILURE]',   rendered = '󰅖 Failure',   highlight = 'RenderMarkdownError',   category = 'obsidian' },
          fail      = { raw = '[!FAIL]',      rendered = '󰅖 Fail',      highlight = 'RenderMarkdownError',   category = 'obsidian' },
          missing   = { raw = '[!MISSING]',   rendered = '󰅖 Missing',   highlight = 'RenderMarkdownError',   category = 'obsidian' },
          danger    = { raw = '[!DANGER]',    rendered = '󱐌 Danger',    highlight = 'RenderMarkdownError',   category = 'obsidian' },
          error     = { raw = '[!ERROR]',     rendered = '󱐌 Error',     highlight = 'RenderMarkdownError',   category = 'obsidian' },
          bug       = { raw = '[!BUG]',       rendered = '󰨰 Bug',       highlight = 'RenderMarkdownError',   category = 'obsidian' },
          example   = { raw = '[!EXAMPLE]',   rendered = '󰉹 Example',   highlight = 'RenderMarkdownHint' ,   category = 'obsidian' },
          quote     = { raw = '[!QUOTE]',     rendered = '󱆨 Quote',     highlight = 'RenderMarkdownQuote',   category = 'obsidian' },
          cite      = { raw = '[!CITE]',      rendered = '󱆨 Cite',      highlight = 'RenderMarkdownQuote',   category = 'obsidian' },
        },

        bullet = {
          -- Useful context to have when evaluating values.
          -- | level | how deeply nested the list is, 1-indexed          |
          -- | index | how far down the item is at that level, 1-indexed |
          -- | value | text value of the marker node                     |

          -- Turn on / off list bullet rendering
          enabled = true,
          -- Additional modes to render list bullets
          render_modes = false,
          -- Replaces '-'|'+'|'*' of 'list_item'.
          -- If the item is a 'checkbox' a conceal is used to hide the bullet instead.
          -- Output is evaluated depending on the type.
          -- | function   | `value(context)`                                    |
          -- | string     | `value`                                             |
          -- | string[]   | `cycle(value, context.level)`                       |
          -- | string[][] | `clamp(cycle(value, context.level), context.index)` |
          icons = { '●', '○', '◆', '◇' },
          -- Replaces 'n.'|'n)' of 'list_item'.
          -- Output is evaluated using the same logic as 'icons'.
          ordered_icons = function(ctx)
            local value = vim.trim(ctx.value)
            local index = tonumber(value:sub(1, #value - 1))
            return ('%d.'):format(index > 1 and index or ctx.index)
          end,
          -- Padding to add to the left of bullet point.
          -- Output is evaluated depending on the type.
          -- | function | `value(context)` |
          -- | integer  | `value`          |
          left_pad = 0,
          -- Padding to add to the right of bullet point.
          -- Output is evaluated using the same logic as 'left_pad'.
          right_pad = 1,
          -- Highlight for the bullet icon.
          -- Output is evaluated using the same logic as 'icons'.
          highlight = 'RenderMarkdownBullet',
          -- Highlight for item associated with the bullet point.
          -- Output is evaluated using the same logic as 'icons'.
          scope_highlight = {},
        },
      })
    end
  },

  {
    "snrogers/mermaider.nvim",
    -- lazy = false,
    dependencies = {
      "3rd/image.nvim", -- Required for image display
    },
    config = function()
      require("mermaider").setup({
        -- Your config here (see Configuration section below)

        -- Command to run the mermaid-cli
        -- {{IN_FILE}} will be replaced with the input file path
        -- {{OUT_FILE}} will be replaced with the output file path
        mermaider_cmd = 'npx -y -p @mermaid-js/mermaid-cli mmdc -i {{IN_FILE}} -o {{OUT_FILE}}.png -s 3',

        -- Directory for temporary files
        temp_dir = vim.fn.expand('$HOME/.cache/mermaider'),

        -- Auto render settings
        auto_render = true,          -- Auto render on save
        auto_render_on_open = true,  -- Auto render when opening a file
        auto_preview = true,         -- Automatically preview after rendering

        -- Mermaid diagram styling
        theme            = "forest",    -- "dark", "light", "forest", "neutral"
        background_color = "#1e1e2e", -- Background color for diagrams

        -- Additional mmdc options
        mmdc_options = "",

        -- Window size settings
        max_width_window_percentage = 80,    -- Maximum width as percentage of window
        max_height_window_percentage = 80,   -- Maximum height as percentage of window

        -- Render settings
        inline_render = true,            -- Use inline rendering instead of split window

        -- Split window settings (used when inline_render is false)
        use_split = true,                -- Use a split window to show diagram
        split_direction = "vertical",    -- "vertical" or "horizontal"
        split_width = 50,                -- Width of the split (if vertical)
        })
    end,
    ft = { "mmd", "mermaid" },
  }
}

return M
