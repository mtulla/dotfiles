-- bazel_helpers.lua
-- Small Neovim module for running Bazel commands for the current file's package.

local M = {}

-- NvChad terminal helper: opens/reuses a terminal split to run commands
local runner = require("nvchad.term").runner

-- Join paths safely-ish (simple version).
local function join_path(a, b)
  return a .. "/" .. b
end

-- Returns true if a file exists and is readable.
local function file_exists(path)
  return vim.fn.filereadable(path) == 1
end

-- Move one directory up: "/a/b/c" -> "/a/b"
local function parent_dir(dir)
  return vim.fn.fnamemodify(dir, ":h")
end

-- Search upward from `start_dir` until we find ANY file in `filenames`.
-- Returns the directory that contains the file, or nil if not found.
local function find_directory_upwards(start_dir, filenames)
  local current_dir = start_dir

  -- Stop at filesystem root on Unix.
  while current_dir ~= "/" do
    for _, filename in ipairs(filenames) do
      local candidate = join_path(current_dir, filename)
      if file_exists(candidate) then
        return current_dir
      end
    end

    -- Go up one directory and try again
    current_dir = parent_dir(current_dir)
  end

  return nil
end

-- Get the directory of the current file in Neovim.
local function current_file_dir()
  -- %     = current file
  -- :p    = full path
  -- :h    = directory (head)
  return vim.fn.expand "%:p:h"
end

-- Find the Bazel workspace root directory for the current file.
-- Bazel workspaces usually have WORKSPACE or WORKSPACE.bazel at the root.
local function find_workspace_root()
  local start = current_file_dir()
  return find_directory_upwards(start, { "WORKSPACE", "WORKSPACE.bazel" })
end

-- Find the Bazel package directory for the current file.
-- Bazel packages have BUILD or BUILD.bazel files.
local function find_package_dir()
  local start = current_file_dir()
  return find_directory_upwards(start, { "BUILD", "BUILD.bazel" })
end

-- Convert an absolute package dir to a Bazel label like:
--   //relative/path:all
local function make_package_label(workspace_root, package_dir)
  -- Example:
  -- workspace_root = /home/me/repo
  -- package_dir    = /home/me/repo/foo/bar
  -- relative_path  = foo/bar

  -- +2 skips the trailing "/" after the workspace_root
  local relative_path = package_dir:sub(#workspace_root + 2)

  return "//" .. relative_path .. ":all"
end

-- Main helper: figure out the current package label, or return nil and warn.
local function get_current_package_label()
  local workspace_root = find_workspace_root()
  if not workspace_root then
    vim.notify("Not in a Bazel workspace (no WORKSPACE file found).", vim.log.levels.WARN)
    return nil
  end

  local package_dir = find_package_dir()
  if not package_dir then
    vim.notify("No Bazel package found (no BUILD file found).", vim.log.levels.WARN)
    return nil
  end

  return make_package_label(workspace_root, package_dir)
end

-- Run a bazel command in a split terminal.
local function run_in_terminal(command)
  runner {
    pos = "sp", -- split
    id = "bazelTerm", -- reuse terminal with this id
    cmd = command,
  }
end

-- Factory that returns a function that runs `bazel <subcmd> <label>`
local function bazel_package_command(subcmd)
  return function()
    local label = get_current_package_label()
    if not label then
      return
    end

    run_in_terminal("bazel " .. subcmd .. " " .. label)
  end
end

-- Public API
M.build = bazel_package_command "build"
M.test = bazel_package_command "test"

M.yank = function()
  local label = get_current_package_label()
  if not label then
    return
  end

  -- Copy to system clipboard
  vim.fn.setreg("+", label)
  vim.notify("Copied: " .. label)
end

M.gazelle = function()
  run_in_terminal "bazel run //:gazelle"
end

M.format_java = function()
  run_in_terminal "bzl run //rules/format:format_java"
end

return M
