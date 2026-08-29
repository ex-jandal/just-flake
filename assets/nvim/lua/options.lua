require "nvchad.options"

-- add yours here!

local o = vim.o
o.cursorlineopt ='both' -- to enable cursorline!
o.relativenumber = true
o.breakindent = true
o.guifont = "CaskaydiaCove Nerd Font:h14"

vim.opt.mouse = "n"

local g = vim.g
g.neovide_padding_top = 10
g.neovide_padding_bottom = 10
g.neovide_padding_right = 10
g.neovide_padding_left = 10

g.neovide_floating_shadow = true
g.neovide_floating_z_height = 10
g.neovide_light_angle_degrees = 45
g.neovide_light_radius = 5

g.neovide_floating_corner_radius = 20.0
g.neovide_cursor_vfx_mode = {"railgun", "ripple"}

g.neovide_theme = 'bg_color'
-- vim.opt.linespace = 2
-- o.conceallevel = 1;
