return {
  "sindrets/diffview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewToggleFiles" },
  opts = {
    view = { default = { winbar_info = true } },
    file_panel = {
      listing_style = "list", -- one line per file
      win_config = { position = "left", width = 35 },
    },
    enhanced_diff_hl = true,
  },
}
