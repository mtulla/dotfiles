local M = {}

function M.pick()
  local harpoon = require("harpoon")
  local Snacks = require("snacks")
  local list = harpoon:list()

  Snacks.picker({
    title = "Harpoon",
    finder = function(opts, ctx)
      local items = {}
      for i = 1, list:length() do
        local item = list.items[i]
        if item and item.value and item.value ~= "" then
          items[#items + 1] = {
            text = item.value,
            file = item.value,
            idx = i,
          }
        end
      end
      return items
    end,
    format = "file",
    confirm = function(picker, item)
      picker:close()
      if item then
        list:select(item.idx)
      end
    end,
    actions = {
      harpoon_delete = function(picker, item)
        local to_remove = item or picker:current()
        if to_remove then
          list:remove(list.items[to_remove.idx])
          picker:refresh()
        end
      end,
    },
    win = {
      input = {
        keys = {
          ["<c-x>"] = { "harpoon_delete", mode = { "n", "i" }, desc = "Delete mark" },
        },
      },
      list = {
        keys = {
          ["dd"] = { "harpoon_delete", desc = "Delete mark" },
        },
      },
    },
  })
end

return M
