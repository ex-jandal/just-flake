return {
  {
    "nickjvandyke/opencode.nvim",
    lazy = false,
    -- nixpkgs ships `opencode` 1.x, but the default "main" branch targets
    -- OpenCode v2's /api/* REST surface. Pin to the latest stable release
    -- (v1.0.2, requires opencode >= 1.17) so it talks to nixpkgs' 1.x server.
    version = "*",
    config = function()
      ---@type opencode.Opts
      vim.g.opencode_opts = {
        -- Your configuration, if any; goto definition on the type for details
      }

      -- Recommended/example keymaps
      vim.keymap.set({ "n", "x" }, "aia",   function() require("opencode").ask("@this: ") end,                    { desc = "Ask OpenCode…" })
      vim.keymap.set({ "n", "x" }, "aix>",   function() require("opencode").select() end,                          { desc = "Select OpenCode…" })
      vim.keymap.set({ "n", "x" }, "ais",      function() return require("opencode").operator("@this") end,         { desc = "Send range to OpenCode", expr = true })
      vim.keymap.set({ "n" },      "ail",     function() return require("opencode").operator("@this") .. "_" end,  { desc = "Send line to OpenCode", expr = true })
    end,
  },
}
