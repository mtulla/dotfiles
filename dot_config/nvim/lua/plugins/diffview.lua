local function current_branch()
  return (vim.fn.system("git rev-parse --abbrev-ref HEAD"):gsub("%s+", ""))
end

local function origin_default_branch()
  local head = vim.fn.system("git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null"):gsub("%s+", "")
  if vim.v.shell_error == 0 and head ~= "" then
    return head:gsub("^refs/remotes/", "")
  end
  for _, name in ipairs({ "main", "master", "trunk", "develop" }) do
    vim.fn.system("git rev-parse --verify origin/" .. name)
    if vim.v.shell_error == 0 then
      return "origin/" .. name
    end
  end
  return "origin/main"
end

return {
  "sindrets/diffview.nvim",
  config = function()
    -- Monkey-patch GitAdapter:show_untracked to include untracked files in
    -- ANY rev-vs-working-tree diff (e.g. `:DiffviewOpen origin/main`), not
    -- just bare `:DiffviewOpen`.
    --
    -- Upstream hard-codes the gate at lua/diffview/vcs/adapters/git/init.lua
    -- (`show_untracked`) to fire only when revs are exactly STAGE..LOCAL,
    -- which means rev comparisons silently drop untracked files. The
    -- `--untracked-files` flag does NOT bypass this; it's checked after.
    --
    -- The override widens the gate to "right side is LOCAL" (working tree),
    -- which is the only condition under which listing untracked files makes
    -- sense, and preserves the downstream `dv_opt.show_untracked` and
    -- `git config status.showUntrackedFiles` checks.
    local GitAdapter = require("diffview.vcs.adapters.git").GitAdapter
    local RevType = require("diffview.vcs.rev").RevType

    function GitAdapter:show_untracked(opt)
      opt = opt or {}
      if opt.revs and opt.revs.right and opt.revs.right.type ~= RevType.LOCAL then
        return false
      end
      if opt.dv_opt and type(opt.dv_opt.show_untracked) == "boolean"
         and not opt.dv_opt.show_untracked then
        return false
      end
      local out = self:exec_sync(
        { "config", "status.showUntrackedFiles" },
        { cwd = self.ctx.toplevel, silent = true }
      )
      return vim.trim(out[1] or "") ~= "no"
    end
  end,
  keys = {
    { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diffview (index)" },
    {
      "<leader>go",
      function()
        vim.cmd("DiffviewOpen origin/" .. current_branch())
      end,
      desc = "Diffview vs origin of current branch",
    },
    {
      "<leader>gm",
      function()
        vim.cmd("DiffviewOpen " .. origin_default_branch())
      end,
      desc = "Diffview vs origin default branch",
    },
  },
}
