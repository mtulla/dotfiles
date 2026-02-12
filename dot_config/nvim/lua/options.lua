require "nvchad.options"

-- shell
vim.opt.shell = "/bin/zsh"

-- Allow local setup files
vim.o.exrc = true

-- local o = vim.o
vim.o.hlsearch = false
vim.opt.hlsearch = true
vim.opt.incsearch = true

-- Make relative line numbers
vim.opt.nu = true
vim.opt.relativenumber = true

-- Enable mouse mode
vim.o.mouse = "a"

-- Indentations
vim.opt.autowriteall = true
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.smartindent = true

-- Sync clipboard between OS and Neovim.
vim.o.clipboard = "unnamedplus"

-- Enable break indent
vim.o.breakindent = true

-- Save undo history
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true

-- Keep signcolumn on by default
vim.wo.signcolumn = "yes"

-- Decrease update time
vim.o.updatetime = 100
vim.o.timeoutlen = 300

-- Scroll
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"
vim.opt.isfname:append "@-@"

-- Set width limit
vim.opt.colorcolumn = "80"

vim.opt.spelllang = "en_us"
vim.opt.spell = true
vim.opt.splitright = true
vim.opt.splitbelow = true

-- Set completeopt to have a better completion experience
vim.o.completeopt = "menuone,noselect"

-- NOTE: You should make sure your terminal supports this
vim.o.termguicolors = true

-- See `:help vim.highlight.on_yank()`
local highlight_group = vim.api.nvim_create_augroup("YankHighlight", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank()
  end,
  group = highlight_group,
  pattern = "*",
})

-- vim filetype
vim.filetype.add {
  extension = {
    tf = "terraform",
    tfstate = "json",
  },
}

vim.opt.cmdheight = 0
