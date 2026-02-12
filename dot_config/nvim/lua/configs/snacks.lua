-- Common excludes for giant repos
local EXCLUDES = {
  ".git",
  "node_modules",
  "dist",
  "build",
  "target",
  ".next",
  ".turbo",
  "coverage",
  "venv",
  ".venv",
  ".pnpm-store",
  ".cache",
}

-- Build fd args from EXCLUDES
local function fd_args(hidden)
  local args = {}
  if hidden then
    table.insert(args, "--hidden")
  end
  for _, e in ipairs(EXCLUDES) do
    table.insert(args, "--exclude")
    table.insert(args, e)
  end
  return args
end

-- Cheap check for being in a git repo
local function in_git_repo()
  return vim.fn.finddir(".git", ".;") ~= ""
end

-- Smart file picker: git_files in repos, fd (pruned) otherwise
local function smart_files()
  if in_git_repo() then
    Snacks.picker.git_files {} -- super fast on huge trees
  else
    Snacks.picker.files {
      fd_args = fd_args(true), -- walk FS, but prune heavy dirs
      filter = { cwd = true },
    }
  end
end

-- Files (always fd, pruned)
local function files_fs()
  Snacks.picker.files {
    fd_args = fd_args(true),
    filter = { cwd = true },
  }
end

-- Recent in project
local function recent_in_cwd()
  Snacks.picker.zoxide { filter = { cwd = true } }
end

-- Grep scoped to project root; add your own globs on the fly with " -- "
local function grep_cwd()
  Snacks.picker.grep {
    cwd = vim.uv.cwd(), -- search only from current root
    filter = { cwd = true },
    -- Tip while searching: "foo -- -g '!**/node_modules/**' -t ts"
  }
end

-- Buffers
local function buffers()
  Snacks.picker.buffers {}
end

-- --- Optional: module defaults (applies to all pickers)
-- This file is not used - keymaps are now in lua/plugins/snacks.lua
-- require("snacks").setup {
--   bigfile = { enabled = true }, -- avoid heavy features on huge files
--   picker = {
--     sources = {
--       files = {
--         fd_args = fd_args(true), -- global default for files source
--       },
--     },
--   },
-- }

-- Picker
-- vim.keymap.set("n", "<leader>ff", smart_files, { noremap = true, silent = true, desc = "Smart find file (git or pruned fd)" })

-- vim.keymap.set("n", "<leader>fa", files_fs, { noremap = true, silent = true, desc = "Find file (pruned fd)" })

-- vim.keymap.set("n", "<leader>fr", recent_in_cwd, { noremap = true, silent = true, desc = "Recent files (cwd)" })

-- vim.keymap.set("n", "<leader>fb", buffers, { noremap = true, silent = true, desc = "Find buffers" })

-- vim.keymap.set("n", "<leader>fw", grep_cwd, { noremap = true, silent = true, desc = "Grep (cwd)" })
