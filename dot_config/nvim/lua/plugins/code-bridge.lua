return {
  "samir-roy/code-bridge.nvim",
  event = "VeryLazy",
  config = function()
    require("code-bridge").setup()
  end,
}
