require "nvchad.mappings"

-- Delete NvChad defaults we override
local nomap = vim.keymap.del
nomap("n", "<C-n>")
nomap("n", "<leader>n")
nomap("n", "<leader>ff")
nomap("n", "<leader>fa")
nomap("n", "<leader>fb")
nomap("n", "<leader>fw")
nomap("n", "<C-h>")
nomap("n", "<C-j>")
nomap("n", "<C-k>")
nomap("n", "<C-l>")

local map = vim.keymap.set

-- ========== Tmux Navigation ==========
map("n", "<C-h>", "<cmd>TmuxNavigateLeft<CR>", { desc = "Navigate left (tmux-aware)" })
map("n", "<C-j>", "<cmd>TmuxNavigateDown<CR>", { desc = "Navigate down (tmux-aware)" })
map("n", "<C-k>", "<cmd>TmuxNavigateUp<CR>", { desc = "Navigate up (tmux-aware)" })
map("n", "<C-l>", "<cmd>TmuxNavigateRight<CR>", { desc = "Navigate right (tmux-aware)" })
map("t", "<C-h>", "<C-\\><C-n><cmd>TmuxNavigateLeft<CR>", { desc = "Navigate left (tmux-aware)" })
map("t", "<C-j>", "<C-\\><C-n><cmd>TmuxNavigateDown<CR>", { desc = "Navigate down (tmux-aware)" })
map("t", "<C-k>", "<C-\\><C-n><cmd>TmuxNavigateUp<CR>", { desc = "Navigate up (tmux-aware)" })
map("t", "<C-l>", "<C-\\><C-n><cmd>TmuxNavigateRight<CR>", { desc = "Navigate right (tmux-aware)" })

-- ========== General ==========
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save" })
map("n", "<leader>W", "<cmd>wa<CR>", { desc = "Save all" })
map("n", "<leader>q", "<cmd>q<CR>", { desc = "Quit" })
map("n", "<leader>Q", "<cmd>qa<CR>", { desc = "Quit all" })
map("n", "<leader>nh", "<cmd>nohl<CR>", { desc = "Clear search highlight" })
map("t", "<Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode", nowait = true, silent = true })

-- ========== Navigation (centered) ==========
map("n", "<C-d>", "<C-d>zz", { desc = "Half-page down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half-page up (centered)" })
map("n", "n", "nzzzv", { desc = "Search next (centered)" })
map("n", "N", "Nzzzv", { desc = "Search prev (centered)" })

-- ========== Visual mode ==========
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })
map("x", "<leader>p", [["_dP]], { desc = "Paste without register replacement" })

-- ========== Splits ==========
map("n", "<leader>sv", "<C-w>v", { desc = "Split vertical" })
map("n", "<leader>sh", "<C-w>s", { desc = "Split horizontal" })
map("n", "<leader>se", "<C-w>=", { desc = "Equalize splits" })
map("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close split" })
map("n", "<C-A-h>", "<C-w><", { desc = "Decrease width", nowait = true, silent = true })
map("n", "<C-A-l>", "<C-w>>", { desc = "Increase width", nowait = true, silent = true })
map("n", "<C-A-j>", "<C-w>+", { desc = "Increase height", nowait = true, silent = true })
map("n", "<C-A-k>", "<C-w>-", { desc = "Decrease height", nowait = true, silent = true })

-- ========== Tabs ==========
map("n", "<leader>tc", "<cmd>tabnew<CR>", { desc = "New tab" })
map("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close tab" })
map("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Next tab" })
map("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Previous tab" })
map("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Buffer to tab" })
map("n", "<S-h>", "<cmd>tabp<CR>", { desc = "Previous tab" })
map("n", "<S-l>", "<cmd>tabn<CR>", { desc = "Next tab" })

-- ========== Explorer & Find (snacks.nvim) ==========
local snacks = require "snacks"
map("n", "<leader>ee", function()
  snacks.explorer()
end, { desc = "Toggle explorer" })
map("n", "<leader><leader>", function()
  snacks.picker.smart { filter = { cwd = true } }
end, { desc = "Smart find file" })
map("n", "<leader>ff", function()
  snacks.picker.files()
end, { desc = "Find file" })
map("n", "<leader>fr", function()
  snacks.picker.recent { filter = { cwd = true } }
end, { desc = "Recent files" })
map("n", "<leader>fb", function()
  snacks.picker.buffers()
end, { desc = "Find buffers" })
map("n", "<leader>fw", function()
  snacks.picker.grep()
end, { desc = "Grep" })
map("n", "<leader>fl", function()
  snacks.picker.notifications()
end, { desc = "List notifications" })
map("n", "<leader>f;", function()
  snacks.picker.commands()
end, { desc = "Commands" })
map("n", "<leader>fd", function()
  snacks.picker.diagnostics()
end, { desc = "Diagnostics" })
map("n", "<leader>fgb", function()
  snacks.picker.git_branches()
end, { desc = "Git branches" })
map("n", "<leader>fgl", function()
  snacks.picker.git_log()
end, { desc = "Git log" })
map("n", "<leader>fgL", function()
  snacks.picker.git_log_line()
end, { desc = "Git log line" })
map("n", "<leader>fgs", function()
  snacks.picker.git_status()
end, { desc = "Git status" })
map("n", "<leader>fgd", function()
  snacks.picker.git_diff()
end, { desc = "Git diff" })
map("n", "<leader>fgf", function()
  snacks.picker.git_log_file()
end, { desc = "Git log file" })

-- ========== LSP ==========
map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
map("n", "<leader>la", vim.lsp.buf.code_action, { desc = "Code action" })
map("n", "<leader>r", vim.lsp.buf.rename, { desc = "Rename" })
map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Line diagnostic float" })
map("n", "gr", vim.lsp.buf.references, { desc = "Go to references" })
map("n", "<leader>fD", function()
  snacks.picker.diagnostics { filter = { buf = 0 } }
end, { desc = "Buffer diagnostics" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Next diagnostic" })
map("n", "<leader>lh", "<cmd>lua vim.lsp.inlay_hint.enable(false)<CR>", { desc = "Hide inlay hints" })
map("n", "<leader>ls", "<cmd>lua vim.lsp.inlay_hint.enable(true)<CR>", { desc = "Show inlay hints" })
map("n", "<leader>lr", "<cmd>LspRestart<CR>", { desc = "LSP restart" })

-- ========== Git ==========
map("n", "<leader>gs", function()
  snacks.lazygit()
end, { desc = "Lazygit", nowait = true, silent = true })
map("n", "<leader>gd", function()
  require("utils.git").open_diff_default_base()
end, { noremap = true, silent = true, desc = "Diff vs main" })
map("n", "<leader>gD", function()
  require("utils.git").open_diff_pick_base_snacks()
end, { noremap = true, silent = true, desc = "Diff pick base" })
map("n", "<leader>gc", "<cmd>DiffviewClose<CR>", { noremap = true, silent = true, desc = "Close diffview" })
map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", { noremap = true, silent = true, desc = "File history" })

-- ========== Harpoon ==========
local harpoon = require "harpoon"
map("n", "<leader>0", function()
  harpoon:list():add()
end, { desc = "Harpoon add file" })

map("n", "<leader><tab>", function()
  harpoon.ui:toggle_quick_menu(harpoon:list())
end, { desc = "Harpoon quick menu", nowait = true, silent = true })

map("n", "<tab>", function()
  harpoon:list():next()
end, { desc = "Harpoon next file", nowait = true, silent = true })

map("n", "<S-tab>", function()
  harpoon:list():prev()
end, { desc = "Harpoon previous file", nowait = true, silent = true })

for i = 1, 9 do
  map("n", "<leader>" .. i, function()
    harpoon:list():select(i)
  end, { desc = "Harpoon file " .. i, nowait = true, silent = true })
end

-- ========== Sessions (persistence.nvim) ==========
map("n", "<leader>zs", function() require("persistence").load() end, { desc = "Restore session (cwd)" })
map("n", "<leader>zS", function() require("persistence").select() end, { desc = "Select session" })
map("n", "<leader>zl", function() require("persistence").load({ last = true }) end, { desc = "Restore last session" })
map("n", "<leader>zd", function() require("persistence").stop() end, { desc = "Stop session recording" })

-- ========== Debug (DAP) ==========
map("n", "<F5>", function()
  require("dap").continue()
end, { desc = "Debug: Start/Continue" })
map("n", "<F10>", function()
  require("dap").step_over()
end, { desc = "Debug: Step Over" })
map("n", "<F11>", function()
  require("dap").step_into()
end, { desc = "Debug: Step Into" })
map("n", "<F12>", function()
  require("dap").step_out()
end, { desc = "Debug: Step Out" })
map("n", "<leader>db", function()
  require("dap").toggle_breakpoint()
end, { desc = "Toggle breakpoint" })
map("n", "<leader>dB", function()
  require("dap").set_breakpoint(vim.fn.input "Breakpoint condition: ")
end, { desc = "Conditional breakpoint" })
map("n", "<leader>dr", function()
  require("dap").repl.open()
end, { desc = "Open REPL" })
map("n", "<leader>dl", function()
  require("dap").run_last()
end, { desc = "Run last" })
map("n", "<leader>dt", function()
  require("dap").terminate()
end, { desc = "Terminate" })
map("n", "<leader>du", function()
  require("dapui").toggle()
end, { desc = "Toggle debug UI" })

-- ========== Quickfix ==========
map("n", "<leader>kn", "<cmd>cnext<CR>", { desc = "Quickfix next", nowait = true, silent = true })
map("n", "<leader>kN", "<cmd>cprevious<CR>", { desc = "Quickfix previous", nowait = true, silent = true })
