return {
  {
    "mistricky/codesnap.nvim",
    tag = "v2.0.0-beta.17",
    lazy = false,

    keys = {
      { "<leader>cc", "<cmd>CodeSnap<cr>", mode = "x", desc = "Save selected code snapshot into clipboard" },
      { "<leader>cs", "<cmd>CodeSnapSave<cr>", mode = "x", desc = "Save selected code snapshot in ~/Pictures" },
    },

    config = function()
      local codesnap = require("codesnap")
      codesnap.setup({
        show_line_number = true,
        highlight_color = "#ffffff20",
        show_workspace = true,
        scale_factor = 10,
        snapshot_config = {
          theme = "candy",
          window = {
            mac_window_bar = true,
            shadow = {
              radius = 20,
              color = "#00000080",
            },
            margin = {
              x = 40,
              y = 82,
            },
            border = {
              width = 2,
              color = "#ffffff30",
            },
            title_config = {
              content = "CodeSnap.nvim",
              color = "#ffffff",
              font_family = "Pacifico",
            },
            size = {
              x = 20,
            }
          },
          themes_folders = {
            "~/.config/codesnap/themes/",
          },
          fonts_folders = {},
          line_number_color = "#495162",
          command_output_config = {
            prompt = "❯",
            font_family = "CaskaydiaCove Nerd Font",
            prompt_color = "#F78FB3",
            command_color = "#98C379",
            string_arg_color = "#ff0000",
          },
          code_config = {
            font_family = "CaskaydiaCove Nerd Font",
            breadcrumbs = {
              enable = true,
              separator = "/",
              color = "#80848b",
              font_family = "CaskaydiaCove Nerd Font",
            },
          },
          watermark = {
            content = "Abu_Jandal",
            font_family = "Pacifico",
            color = "#ffffff",
          },
          background = {
            -- start = {
            --   x = 0,
            --   y = 0,
            -- },
            -- ["end"] = {
            --   x = "max",
            --   y = 0,
            -- },
            -- stops = {
            --   {
            --     position = 0,
            --     color = "#6bcba500",
            --   },
            --   {
            --     position = 1,
            --     color = "#caf4c200",
            --   },
            -- },
          },
        },
      })
    end,
  },
}
