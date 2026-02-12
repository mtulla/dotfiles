-- Waiting for length fix
local harpoonTabs = {}

-- define visual settings for harpoon tabline
vim.api.nvim_set_hl(0, "HarpoonInactive", {})
vim.api.nvim_set_hl(0, "HarpoonActive", { fg = "#8bc2f0" })
vim.api.nvim_set_hl(0, "HarpoonNumberActive", {})
vim.api.nvim_set_hl(0, "HarpoonNumberInactive", {})
vim.api.nvim_set_hl(0, "TabLineFill", {})

local harpoon = require "harpoon"

function harpoonTabs.harpoonFiles()
  local contents = {}
  local harpoon_list = harpoon:list()
  local marks_length = harpoon_list:length()
  local current_file_path = vim.fn.fnamemodify(vim.fn.expand "%:p", ":.")

  print(marks_length)

  for index = 1, marks_length do
    local harpoon_file_path = harpoon_list:get(index).value

    local label = ""
    if vim.startswith(harpoon_file_path, "oil") then
      local dir_path = string.sub(harpoon_file_path, 7)
      dir_path = vim.fn.fnamemodify(dir_path, ":.")
      label = "[" .. dir_path .. "]"
    elseif harpoon_file_path ~= "" then
      label = vim.fn.fnamemodify(harpoon_file_path, ":t")
    end

    label = label ~= "" and label or "(empty)"
    if current_file_path == harpoon_file_path then
      contents[index] = string.format("%%#HarpoonNumberActive# %s. %%#HarpoonActive#%s ", index, label)
    else
      contents[index] = string.format("%%#HarpoonNumberInactive# %s. %%#HarpoonInactive#%s ", index, label)
    end
  end

  return table.concat(contents) .. "%#HarpoonActive# ⇌% "
end

-- require("lualine").setup {
--   tabline = {
--     lualine_a = { { Harpoon_files } },
--   },
--   -- other config
-- }{}
--

return harpoonTabs
