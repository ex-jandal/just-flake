-- Format the current buffer
vim.keymap.set('n', '<leader>dxf', '<cmd>DxFormatBuffer<cr>',
    { desc = 'Dioxus: Format Buffer', noremap = true, silent = true })

-- Format just the inline macro
vim.keymap.set('n', '<leader>dxi', '<cmd>DxFormatInline<cr>',
    { desc = 'Dioxus: Format Inline', noremap = true, silent = true })

-- Translation helpers
vim.keymap.set('n', '<leader>dxt', '<cmd>DxTranslateInline<cr>',
    { desc = 'Dioxus: Translate Inline', noremap = true, silent = true })

vim.keymap.set('n', '<leader>dxp', '<cmd>DxTranslatePrompt<cr>',
    { desc = 'Dioxus: Translate Prompt', noremap = true, silent = true })

-- Diagnostic check
vim.keymap.set('n', '<leader>dxc', '<cmd>DxCheckBuffer<cr>',
    { desc = 'Dioxus: Check Buffer', noremap = true, silent = true })

return {
  {
    "mrxiaozhuox/dioxus.nvim",
    opts = {
      format = {
        split_line_attributes = true,
      },
    },
    ft = "rust",
  },
}
