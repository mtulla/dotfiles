-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Indentations
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.api.nvim_create_autocmd("FileType", {
  pattern = {"lua", "html"}, -- Apply to Lua files
  desc = "Set specific tab length for Lua files",
  callback = function()
    -- Set buffer-local options for tab length (e.g., 2 spaces)
    vim.opt.tabstop = 2
    vim.opt.shiftwidth = 2
    vim.opt.softtabstop = 2
  end,
})
