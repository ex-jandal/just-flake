local M = {}

M.override = {
  -- Popup menu
  Pmenu       = { fg = "#ebdbb2", bg = "#282828" },
  PmenuSel    = { fg = "#282828", bg = "#d79921" }, -- selected item gold
  CmpItemMenu = { fg = "#b16286", bg = "NONE", italic = true },

  -- Matches
  CmpItemAbbrDeprecated  = { fg = "#928374", bg = "NONE", strikethrough = true },
  CmpItemAbbrMatch       = { fg = "#fabd2f", bg = "NONE", bold = true },
  CmpItemAbbrMatchFuzzy  = { fg = "#fabd2f", bg = "NONE", bold = true },

  -- Fields / properties / events → red family
  -- CmpItemKindField    = { fg = "#fbf1c7", bg = "#cc241d" },
  -- CmpItemKindProperty = { fg = "#fbf1c7", bg = "#cc241d" },
  -- CmpItemKindEvent    = { fg = "#fbf1c7", bg = "#cc241d" },

  -- Text / enums / keywords → green family
  -- CmpItemKindText     = { fg = "#fbf1c7", bg = "#98971a" },
  -- CmpItemKindEnum     = { fg = "#fbf1c7", bg = "#98971a" },
  -- CmpItemKindKeyword  = { fg = "#fbf1c7", bg = "#98971a" },

  -- Constants / constructors / refs → yellow family
  -- CmpItemKindConstant   = { fg = "#282828", bg = "#d79921" },
  -- CmpItemKindConstructor= { fg = "#282828", bg = "#d79921" },
  -- CmpItemKindReference  = { fg = "#282828", bg = "#d79921" },

  -- Functions / structs / modules / operators → purple family
  -- CmpItemKindFunction  = { fg = "#fbf1c7", bg = "#b16286" },
  -- CmpItemKindStruct    = { fg = "#fbf1c7", bg = "#b16286" },
  -- CmpItemKindClass     = { fg = "#fbf1c7", bg = "#b16286" },
  -- CmpItemKindModule    = { fg = "#fbf1c7", bg = "#b16286" },
  -- CmpItemKindOperator  = { fg = "#fbf1c7", bg = "#b16286" },

  -- Variables / files → gray family
  -- CmpItemKindVariable = { fg = "#ebdbb2", bg = "#928374" },
  -- CmpItemKindFile     = { fg = "#ebdbb2", bg = "#928374" },

  -- Units / snippets / folders → orange family
  -- CmpItemKindUnit    = { fg = "#282828", bg = "#d65d0e" },
  -- CmpItemKindSnippet = { fg = "#282828", bg = "#d65d0e" },
  -- CmpItemKindFolder  = { fg = "#282828", bg = "#d65d0e" },

  -- Methods / values / enum members → blue family
  -- CmpItemKindMethod     = { fg = "#fbf1c7", bg = "#458588" },
  -- CmpItemKindValue      = { fg = "#fbf1c7", bg = "#458588" },
  -- CmpItemKindEnumMember = { fg = "#fbf1c7", bg = "#458588" },

  -- Interfaces / colors / type parameters → aqua family
  -- CmpItemKindInterface     = { fg = "#fbf1c7", bg = "#689d6a" },
  -- CmpItemKindColor         = { fg = "#fbf1c7", bg = "#689d6a" },
  -- CmpItemKindTypeParameter = { fg = "#fbf1c7", bg = "#689d6a" },
  -- CmpItemKindCopilot      = { fg = "#fbf1c7", bg = "#689d6a" }, -- Copilot
}
for group, opts in pairs(M.override) do
  vim.api.nvim_set_hl(0, group, opts)
end

return M;
