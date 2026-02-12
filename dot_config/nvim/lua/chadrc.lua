-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v2.5/lua/nvconfig.lua

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "tokyonight",
  theme_toggle = { "tokyonight", "one_light" },
  hl_override = {
    St_HarpoonActive = { fg = "green", bg = "statusline_bg", bold = true, underline = true },
    St_HarpoonInactive = { fg = "light_grey", bg = "statusline_bg" },
  },
}

M.ui = {
  tabufline = {
    enabled = true,
  },
  statusline = {
    theme = "default",
    order = { "harpoon", "%=", "diagnostics", "cwd" },
    modules = {
      harpoon = function()
        return require("configs.statusline").harpoon()
      end,
    },
  },
}

return M
