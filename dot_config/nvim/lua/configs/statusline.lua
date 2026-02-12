local M = {}

-- Set up highlight groups for Harpoon statusline
-- Get the statusline background color
local stl_bg = vim.api.nvim_get_hl(0, { name = "StatusLine" }).bg
if stl_bg then
  stl_bg = string.format("#%06x", stl_bg)
else
  stl_bg = "NONE"
end

vim.api.nvim_set_hl(0, "St_HarpoonActive", {
  fg = "#a6e3a1", -- green
  bg = stl_bg,
  bold = true,
})

vim.api.nvim_set_hl(0, "St_HarpoonInactive", {
  fg = "#6c7086", -- grey
  bg = stl_bg,
})

M.harpoon = function()
  local harpoon = require("harpoon")
  local harpoon_list = harpoon:list()
  local marks_length = harpoon_list:length()

  if marks_length == 0 then
    return ""
  end

  local current_file_path = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":.")
  local parts = {}

  for index = 1, math.min(marks_length, 9) do
    local harpoon_item = harpoon_list:get(index)
    if harpoon_item then
      local harpoon_file_path = harpoon_item.value
      local filename = vim.fn.fnamemodify(harpoon_file_path, ":t")

      if filename == "" then
        filename = "(empty)"
      end

      local is_current = current_file_path == harpoon_file_path
      local hl = is_current and "%#St_HarpoonActive#" or "%#St_HarpoonInactive#"

      table.insert(parts, string.format("%s %d:%s ", hl, index, filename))
    end
  end

  if #parts == 0 then
    return ""
  end

  return " " .. table.concat(parts) .. " "
end

return M
