-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
local map = vim.keymap.set

-- ========== Copy filepath ==========
map("n", "<leader>pr", function()
  vim.fn.setreg("+", vim.fn.expand("%"))
  vim.notify("Copied: " .. vim.fn.expand("%"))
end, { desc = "Copy relative path" })
map("n", "<leader>pa", function()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
  vim.notify("Copied: " .. vim.fn.expand("%:p"))
end, { desc = "Copy absolute path" })

-- ========== CodeBridge: Tmux ==========
map("n", "<leader>at", "<cmd>CodeBridgeTmux<cr>", { desc = "Send file to Claude (tmux)" })
map("v", "<leader>at", ":'<,'>CodeBridgeTmux<cr>", { desc = "Send selection to Claude (tmux)" })
map("n", "<leader>aT", "<cmd>CodeBridgeTmuxAll<cr>", { desc = "Send all buffers (tmux)" })
map("n", "<leader>ai", "<cmd>CodeBridgeTmuxInteractive<cr>", { desc = "Interactive prompt (tmux)" })
map("n", "<leader>aD", "<cmd>CodeBridgeTmuxDiff<cr>", { desc = "Send git diff (tmux)" })
map("n", "<leader>aR", "<cmd>CodeBridgeTmuxRecent<cr>", { desc = "Send recent files (tmux)" })
map("n", "<leader>ae", "<cmd>CodeBridgeTmuxDiagnostics<cr>", { desc = "Send diagnostics (tmux)" })
