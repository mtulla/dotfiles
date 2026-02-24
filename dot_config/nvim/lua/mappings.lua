-- NvChad defaults we keep (cherry-picked from nvchad.mappings)
local map = vim.keymap.set

map("i", "<C-b>", "<ESC>^i", { desc = "Move to beginning of line" })
map("i", "<C-e>", "<End>", { desc = "Move to end of line" })
map("i", "<C-h>", "<Left>", { desc = "Move left" })
map("i", "<C-l>", "<Right>", { desc = "Move right" })
map("i", "<C-j>", "<Down>", { desc = "Move down" })
map("i", "<C-k>", "<Up>", { desc = "Move up" })

map("n", "<Esc>", "<cmd>noh<CR>", { desc = "Clear highlights" })
map("n", "<C-s>", "<cmd>w<CR>", { desc = "Save file" })
map("n", "<C-c>", "<cmd>%y+<CR>", { desc = "Copy whole file" })
map("n", "<leader>rn", "<cmd>set rnu!<CR>", { desc = "Toggle relative number" })
map("n", "<leader>ch", "<cmd>NvCheatsheet<CR>", { desc = "NvChad cheatsheet" })
map("n", "<leader>ds", vim.diagnostic.setloclist, { desc = "Diagnostic loclist" })
map("n", "<leader>/", "gcc", { desc = "Toggle comment", remap = true })
map("v", "<leader>/", "gc", { desc = "Toggle comment", remap = true })

map("n", "<leader>th", function()
  require("nvchad.themes").open()
end, { desc = "NvChad themes" })

map("t", "<C-x>", "<C-\\><C-N>", { desc = "Exit terminal mode" })
map("n", "<leader>h", function()
  require("nvchad.term").new { pos = "sp" }
end, { desc = "New horizontal terminal" })
map("n", "<leader>v", function()
  require("nvchad.term").new { pos = "vsp" }
end, { desc = "New vertical terminal" })
map({ "n", "t" }, "<A-v>", function()
  require("nvchad.term").toggle { pos = "vsp", id = "vtoggleTerm" }
end, { desc = "Toggle vertical terminal" })
map({ "n", "t" }, "<A-h>", function()
  require("nvchad.term").toggle { pos = "sp", id = "htoggleTerm" }
end, { desc = "Toggle horizontal terminal" })
map({ "n", "t" }, "<A-i>", function()
  require("nvchad.term").toggle { pos = "float", id = "floatTerm" }
end, { desc = "Toggle floating terminal" })

map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "WhichKey all keymaps" })
map("n", "<leader>wk", function()
  vim.cmd("WhichKey " .. vim.fn.input "WhichKey: ")
end, { desc = "WhichKey query lookup" })

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

-- ========== Copy filepath ==========
map("n", "<leader>pr", function()
  vim.fn.setreg("+", vim.fn.expand "%")
  vim.notify("Copied: " .. vim.fn.expand "%")
end, { desc = "Copy relative path" })
map("n", "<leader>pa", function()
  vim.fn.setreg("+", vim.fn.expand "%:p")
  vim.notify("Copied: " .. vim.fn.expand "%:p")
end, { desc = "Copy absolute path" })

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
map("n", "<S-h>", function() require("nvchad.tabufline").prev() end, { desc = "Previous buffer" })
map("n", "<S-l>", function() require("nvchad.tabufline").next() end, { desc = "Next buffer" })

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
map("n", "<leader>fs", function()
  snacks.picker.lsp_symbols()
end, { desc = "Document symbols" })
map("n", "<leader>fS", function()
  snacks.picker.lsp_workspace_symbols()
end, { desc = "Workspace symbols" })

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

-- ========== Format ==========
map({ "n", "v" }, "<leader>mp", function()
  require("conform").format {
    lsp_fallback = true,
    async = false,
    timeout_ms = 10000,
  }
end, { desc = "Format file or range" })

-- ========== Lazygit ==========
map("n", "<leader>lg", function()
  snacks.lazygit()
end, { desc = "Lazygit", nowait = true, silent = true })

-- ========== Git ==========
-- Diffview
map("n", "<leader>go", "<cmd>DiffviewOpen<CR>", { noremap = true, silent = true, desc = "Diffview open (merge/conflicts)" })
map("n", "<leader>gd", function()
  require("utils.git").open_diff_default_base()
end, { noremap = true, silent = true, desc = "Diff vs main" })
map("n", "<leader>gD", function()
  require("utils.git").open_diff_pick_base_snacks()
end, { noremap = true, silent = true, desc = "Diff pick base" })
map("n", "<leader>gc", "<cmd>DiffviewClose<CR>", { noremap = true, silent = true, desc = "Close diffview" })
map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<CR>", { noremap = true, silent = true, desc = "File history" })
-- Fugitive (blame & GitHub)
map("n", "<leader>gb", "<cmd>Git blame<CR>", { noremap = true, silent = true, desc = "Git blame" })
map("n", "<leader>gB", function()
  snacks.gitbrowse()
end, { noremap = true, silent = true, desc = "Open in GitHub" })
-- Git pickers (snacks)
map("n", "<leader>gs", function()
  snacks.picker.git_status()
end, { desc = "Git status" })
map("n", "<leader>gl", function()
  snacks.picker.git_log()
end, { desc = "Git log" })
map("n", "<leader>gL", function()
  snacks.picker.git_log_line()
end, { desc = "Git log line" })
map("n", "<leader>gf", function()
  snacks.picker.git_log_file()
end, { desc = "Git log file" })
map("n", "<leader>gp", function()
  snacks.picker.git_diff()
end, { desc = "Git diff (patches)" })
map("n", "<leader>gr", function()
  snacks.picker.git_branches()
end, { desc = "Git branches" })

-- ========== Harpoon ==========
local harpoon = require "harpoon"
map("n", "<leader>0", function()
  harpoon:list():add()
end, { desc = "Harpoon add file" })

map("n", "<leader><tab>", function()
  require("utils.harpoon-picker").pick()
end, { desc = "Harpoon picker", nowait = true, silent = true })

map("n", "<tab>", function()
  local list = harpoon:list()

  -- Collect non-empty entries with their original indices
  local valid = {}
  for i = 1, list:length() do
    local item = list.items[i]
    if item and item.value and item.value ~= "" then
      valid[#valid + 1] = { idx = i, value = item.value }
    end
  end
  if #valid == 0 then return end

  local current = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":.")
  local current_pos = 0
  for pos, entry in ipairs(valid) do
    if entry.value == current then
      current_pos = pos
      break
    end
  end

  local next_pos = (current_pos % #valid) + 1
  list:select(valid[next_pos].idx)
end, { desc = "Harpoon next file", nowait = true, silent = true })

map("n", "<S-tab>", function()
  local list = harpoon:list()

  -- Collect non-empty entries with their original indices
  local valid = {}
  for i = 1, list:length() do
    local item = list.items[i]
    if item and item.value and item.value ~= "" then
      valid[#valid + 1] = { idx = i, value = item.value }
    end
  end
  if #valid == 0 then return end

  local current = vim.fn.fnamemodify(vim.fn.expand("%:p"), ":.")
  local current_pos = 0
  for pos, entry in ipairs(valid) do
    if entry.value == current then
      current_pos = pos
      break
    end
  end

  local prev_pos = current_pos <= 1 and #valid or current_pos - 1
  list:select(valid[prev_pos].idx)
end, { desc = "Harpoon previous file", nowait = true, silent = true })

for i = 1, 9 do
  map("n", "<leader>" .. i, function()
    harpoon:list():select(i)
  end, { desc = "Harpoon file " .. i, nowait = true, silent = true })
end

-- ========== Claude Code ==========
map("n", "<leader>ac", "<cmd>ClaudeCode<cr>", { desc = "Toggle Claude" })
map("n", "<leader>af", "<cmd>ClaudeCodeFocus<cr>", { desc = "Focus Claude" })
map("n", "<leader>ar", "<cmd>ClaudeCode --resume<cr>", { desc = "Resume Claude" })
map("n", "<leader>aC", "<cmd>ClaudeCode --continue<cr>", { desc = "Continue Claude" })
map("n", "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", { desc = "Select Claude model" })
map("n", "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", { desc = "Add current buffer" })
map("v", "<leader>as", "<cmd>ClaudeCodeSend<cr>", { desc = "Send to Claude" })
map("n", "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", { desc = "Accept diff" })
map("n", "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", { desc = "Deny diff" })
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw" },
  callback = function()
    map("n", "<leader>as", "<cmd>ClaudeCodeTreeAdd<cr>", { buffer = true, desc = "Add file" })
  end,
})

-- ========== Wiremux: Tmux ==========
map("n", "<leader>at", function()
  require("wiremux").send("{file}", { focus = true })
end, { desc = "Send file to Claude (tmux)" })
map("v", "<leader>at", function()
  require("wiremux").send("{selection}", { focus = true })
end, { desc = "Send selection to Claude (tmux)" })
map("n", "<leader>aT", function()
  local lines = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buflisted then
      local name = vim.api.nvim_buf_get_name(buf)
      if name ~= "" then
        local content = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n")
        table.insert(lines, "--- " .. vim.fn.fnamemodify(name, ":.") .. " ---\n" .. content)
      end
    end
  end
  require("wiremux").send(table.concat(lines, "\n\n"), { focus = true })
end, { desc = "Send all buffers (tmux)" })
map("n", "<leader>ai", function()
  require("wiremux").send({
    { label = "Explain", value = "Explain {this}" },
    { label = "Fix", value = "Can you fix {this}?" },
    { label = "Review changes", value = "Can you review my changes?\n{changes}" },
    { label = "Fix diagnostics", value = "Can you fix these diagnostics?\n{diagnostics_all}" },
    { label = "Optimize", value = "How can {this} be optimized?" },
    { label = "Write tests", value = "Can you write tests for {this}?" },
  }, { focus = true })
end, { desc = "Interactive prompt (tmux)" })
map("n", "<leader>aD", function()
  require("wiremux").send("{changes}", { focus = true })
end, { desc = "Send git diff (tmux)" })
map("n", "<leader>aR", function()
  local recent = vim.v.oldfiles
  local lines = {}
  local cwd = vim.fn.getcwd()
  for i, f in ipairs(recent) do
    if i > 20 then break end
    if vim.startswith(f, cwd) then
      table.insert(lines, vim.fn.fnamemodify(f, ":."))
    end
  end
  require("wiremux").send(table.concat(lines, "\n"), { focus = true })
end, { desc = "Send recent files (tmux)" })
map("n", "<leader>ae", function()
  require("wiremux").send("{diagnostics_all}", { focus = true })
end, { desc = "Send diagnostics (tmux)" })
map("n", "<leader>aW", function()
  require("wiremux").create()
end, { desc = "Create wiremux target" })
map("n", "<leader>aX", function()
  require("wiremux").close()
end, { desc = "Close wiremux target" })

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

-- ========== Bazel ==========
local bazel = require "configs.bazel"
map("n", "<leader>bb", bazel.build, { desc = "Bazel build" })
map("n", "<leader>bt", bazel.test, { desc = "Bazel test" })
map("n", "<leader>by", bazel.yank, { desc = "Bazel yank target" })
map("n", "<leader>bg", bazel.gazelle, { desc = "Bazel gazelle" })
map("n", "<leader>bs", function()
  local label = bazel.get_label()
  if not label then return end
  require("wiremux").send({
    { label = "Build target", value = "bazel build " .. label },
    { label = "Test target", value = "bazel test " .. label },
    { label = "Target label", value = label },
  }, { focus = true })
end, { desc = "Send bazel target (tmux)" })
