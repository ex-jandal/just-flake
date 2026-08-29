-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "gruvchad",
  transparency = true,
  hl_override = require("highlights").override,

	-- hl_override = {
	-- 	Comment = { italic = true },
	-- 	["@comment"] = { italic = true },
	-- },
}

M.ui = {
  cmp = {
    style = "default",
  },
  statusline = {
    -- enabled = false,
    theme = "minimal",
    separator_style = "block",
    -- order = { "mode", "file", "git", "%=", "lsp_msg", "%=", "lsp", "cwd", "xyz", "abc" },
    -- modules = {
    --  abc = function()
    --    return "hi"
    --  end,
    --
    --  xyz =  "hi",
    --  f = "%F"
    -- }
  },
}

--    header = [[
--      ⠀⠀⠀⠀⠀⠀⠀⣀⣠⣤⣤⣤⣴⢶⡶⣶⣴⣤⣤⡶⣶⣶⣶⣶⣦⣤⣄⠀⠀
--      ⠀⠀⠀⠀⣠⣴⣿⣻⠽⠿⠚⠙⠋⠛⠽⠷⣯⡿⣽⣻⢷⣻⣊⣰⡌⢻⣽⣷⠀
--      ⠀⠀⣠⣾⢿⠻⠊⠀⢀⣀⣀⣀⠀⠀⠀⠀⠀⠙⠿⣽⣻⣟⣿⠏⢠⣾⣷⣻⠇
--      ⠀⣴⡿⡯⠃⠀⠀⠀⢸⡿⣟⣿⣧⠀⠀⠀⠀⠀⠀⠘⢷⡿⣁⣐⣛⢳⣯⡟⠀
--      ⣰⡿⡟⠀⠀⠀⠀⠀⠀⠀⠈⣿⢾⡆⠀⠀⠀⠀⠀⠀⠈⢿⣟⡿⣽⣯⡟⠀⠀
--      ⣿⣻⠃⠀⠀⠀⠀⠀⠀⢀⣼⡿⣯⣿⡄⠀⠀⠀⠀⠀⠀⠸⣯⣿⣻⡾⠀⠀⠀
--      ⣿⣟⠀⠀⠀⠀⠀⠀⢀⣾⣯⡿⢻⣳⣷⡀⠀⠀⠀⠀⠀⠀⣿⣳⣿⠁⠀⠀⠀
--      ⣿⣽⡄⠀⠀⠀⠀⢠⣿⣻⡞⠀⠀⢻⣾⢧⠀⠀⠀⠀⠀⢰⣿⣻⠂⠀⠀⠀⠀
--      ⢹⣯⣷⡀⠀⠀⣰⡿⣯⠏⠀⠀⠀⠈⣿⢯⣷⡿⣇⠀⢀⣾⣟⠇⠀⠀⠀⠀⠀
--      ⠀⠻⡾⣷⣄⠀⠉⠉⠁⠀⠀⠀⠀⠀⠘⠛⠁⠁⠀⣠⣾⣟⠎⠀⠀⠀⠀⠀⠀
--      ⠀⠀⠙⢷⣟⣷⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣾⣟⡷⠋⠀⠀⠀⠀⠀⠀⠀
--      ⠀⠀⠀⠀⠙⠳⢿⣻⢷⣶⣦⣤⣤⣴⣶⡾⣟⣯⠗⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀
--      ⠀⠀⠀⠀⠀⠀⠀⠈⠉⠓⠛⠓⠋⠛⠚⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
--  Powered By 󰂩 Bl󰘧ck Mesa]],

M.nvdash = {
  load_on_startup = false,

  header = {
   "                            ",
   "     ▄▄         ▄ ▄▄▄▄▄▄▄   ",
   "   ▄▀███▄     ▄██ █████▀    ",
   "   ██▄▀███▄   ███           ",
   "   ███  ▀███▄ ███           ",
   "   ███    ▀██ ███           ",
   "   ███      ▀ ███           ",
   "   ▀██ █████▄▀█▀▄██████▄    ",
   "     ▀ ▀▀▀▀▀▀▀ ▀▀▀▀▀▀▀▀▀▀   ",
   "                            ",
   "     Powered By  eovim    ",
   "                            ",
  },

  buttons = {
    { txt = "  Find File", keys = "Spc f f", cmd = "Telescope find_files" },
    { txt = "  Recent Files", keys = "Spc f o", cmd = "Telescope oldfiles" },
    -- more... check nvconfig.lua file for full list of buttons
  },
}
  -- telescope = { style = "bordered" },
-- M.nvdash = { load_on_startup = true }
-- M.ui = {
--       tabufline = {
--          lazyload = false
--      }
--}

return M
