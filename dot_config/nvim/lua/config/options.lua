-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Indentations
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4

-- Use OSC 52 for clipboard (works over SSH + tmux)
-- Requires Neovim 0.10+ for the built-in vim.ui.clipboard.osc52 module
local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
if ok then
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = osc52.paste("+"),
      ["*"] = osc52.paste("*"),
    },
  }
  -- LazyVim sets clipboard="" over SSH; override so yanks sync via OSC 52
  vim.opt.clipboard = "unnamedplus"
end
