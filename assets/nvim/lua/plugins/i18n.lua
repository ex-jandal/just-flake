return {
  {
    'yelog/i18n.nvim',
    lazy = false,
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      -- optional pickers:
      -- 'ibhagwan/fzf-lua',
      -- 'nvim-telescope/telescope.nvim',
    },
    config = function()
      require('i18n').setup({
        locales = { 'en', 'ar' },
        sources = { 'locales/{locales}.json' },
      })
    end
  }
}
