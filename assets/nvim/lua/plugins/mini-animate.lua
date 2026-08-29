return {
  {
    'nvim-mini/mini.animate',
    lazy = true,
    version = false,
    config = function ()
      require('mini.animate').setup({
        cursor = {
          -- Whether to enable this animation
          enable = false,
        },
        scroll = {
          -- Whether to enable this animation
          enable = true,
          timing = function ()
            return 5
          end,
        },
        open = {
          -- Whether to enable this animation
          enable = false,
        },
        close = {
          -- Whether to enable this animation
          enable = false,
        }
      })
    end
  },
}
