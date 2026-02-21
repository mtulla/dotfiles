local options = {
  formatters_by_ft = {
    lua = { "stylua" },
    python = { "ruff_imports", "ruff_format" },
    json = { "fixjson" },
    yaml = { "prettier" },
    markdown = { "prettier" },
    terraform = { "terraform_fmt" },
    rust = { "rustfmt", lsp_format = "fallback" },
    typescript = { "prettier" },
    javascript = { "prettier" },
    typescriptreact = { "prettier" },
    javascriptreact = { "prettier" },
    go = { "gofumpt", "goimports" },
  },

  formatters = {
    ruff_imports = {
      command = "ruff",
      args = { "check", "--select", "I", "--fix", "--stdin-filename", "$FILENAME", "-" },
      stdin = true,
    },
    ruff_format = {
      command = "ruff",
      args = { "format", "--stdin-filename", "$FILENAME", "-" },
      stdin = true,
    },
  },

  format_on_save = {
    timeout_ms = 2000,
    lsp_fallback = true,
  },
}

require("conform").setup(options)
