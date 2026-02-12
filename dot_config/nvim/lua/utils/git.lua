local M = {}

-- Resolve the default remote base (e.g. origin/main) from origin/HEAD
local function default_base_remote()
  local head = vim.fn.systemlist("git symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>/dev/null")[1]
  if head and head ~= "" then
    return head -- already like "origin/main"
  end
  -- Fallback: prefer origin/main then origin/master
  local remotes = vim.fn.systemlist "git branch -r --format='%(refname:short)'"
  local want = { "origin/main", "origin/master" }
  for _, w in ipairs(want) do
    for _, r in ipairs(remotes) do
      if r == w then
        return r
      end
    end
  end
  return "origin/master"
end

-- Open Diffview vs origin/HEAD ... HEAD (PR-style three-dots)
function M.open_diff_default_base()
  local base = default_base_remote()
  vim.cmd("DiffviewOpen " .. base .. "...HEAD")
end

-- Snacks-based picker to choose any branch/ref then open Diffview
function M.open_diff_pick_base_snacks()
  local Snacks = require "snacks"

  -- Grab refs (locals + remotes)
  local refs = vim.fn.systemlist "git for-each-ref --format='%(refname:short)' refs/heads refs/remotes 2>/dev/null"
  if #refs == 0 then
    vim.notify("No git refs found", vim.log.levels.WARN)
    return
  end

  -- Convert to Snacks items
  local items = {}
  for _, ref in ipairs(refs) do
    items[#items + 1] = { text = ref, ref = ref }
  end

  Snacks.picker {
    title = "Compare HEAD against…",
    items = items,
    format = "text", -- 👈 show the text in the list
    -- layout = { preview = false }, -- optionally hide preview if you don't need it
    confirm = function(picker, item) -- (picker, item) is the signature
      local ref = item and item.ref
      if ref and ref ~= "" then
        picker:close()
        vim.cmd("DiffviewOpen " .. ref .. "...HEAD")
      end
    end,
  }
end

return M
