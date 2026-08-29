return {
  {
    "giuxtaposition/blink-cmp-copilot",
    lazy = false,
    enabled = false;
  },

  {
    "zbirenbaum/copilot-cmp",
    lazy = false,
    enabled = false;
    config = function ()
      require("copilot_cmp").setup({})
    end
  },

  {
    "zbirenbaum/copilot.lua",
    lazy = false,
    enabled = false;
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  },
}
