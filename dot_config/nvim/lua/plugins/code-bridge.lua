return {
  "samir-roy/code-bridge.nvim",
  event = "VeryLazy",
  config = function()
    require("code-bridge").setup({
      tmux = {
        target_mode = "window_name",
        window_name = "codex",
        process_name = "codex",
        switch_to_target = true,
      },
    })
  end,
}
