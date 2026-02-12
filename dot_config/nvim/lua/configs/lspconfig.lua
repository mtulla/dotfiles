local on_attach = require("nvchad.configs.lspconfig").on_attach
local on_init = require("nvchad.configs.lspconfig").on_init
local capabilities = require("nvchad.configs.lspconfig").capabilities

local lspconfig = require "lspconfig"
local servers = { "html", "cssls", "terraformls", "tflint", "jsonls", "rust_analyzer", "gopls", "clangd", "bashls" }

-- lsps with default config
for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = on_attach,
    on_init = on_init,
    capabilities = capabilities,
  }
end

-- python
lspconfig.ruff.setup {
  on_attach = function(client, bufnr)
    -- Call the common on_attach function
    on_attach(client, bufnr)

    -- Disable formatting if you want to use black
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
  capabilities = capabilities,
  filetypes = { "python" },
  before_init = function(_, config_arg)
    local pythonUtils = require "utils.python"
    local root_dir = config_arg.root_dir
    local pythonPath = pythonUtils.getPythonPath(root_dir)

    -- Set the Python interpreter path for Ruff
    config_arg.settings = config_arg.settings or {}
    config_arg.settings.python = config_arg.settings.python or {}
    config_arg.settings.python.pythonPath = pythonPath
  end,
  settings = {
    -- Ruff-specific settings
    ruff = {
      lint = {
        run = "onType", -- Run Ruff on the fly for maximum speed
        -- Enable specific rules for imports
      },
      organizeImports = true, -- Equivalent to running Ruff with the I001 rule enabled
      fixAll = true, -- Enables the "Fix all" action
    },
  },
  -- Tell Ruff to use the pyproject.toml file in the project
  init_options = {
    settings = {
      -- Use the pyproject.toml file for configuration
      args = {
        "--config=pyproject.toml",
      },
    },
  },
}

lspconfig.pyright.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { "python" },
  before_init = function(_, config_arg)
    local pythonUtils = require "utils.python"
    local root_dir = config_arg.root_dir
    local pythonPath = pythonUtils.getPythonPath(root_dir)

    config_arg.settings.python.pythonPath = pythonPath
  end,
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "strict",
        autoSearchPaths = true,
        diagnosticMode = "openFilesOnly",
        useLibraryCodeForTypes = true,
      },
    },
  },
}

-- Terraform
lspconfig.tflint.setup {
  on_attach = on_attach,
}

lspconfig.terraformls.setup {
  on_attach = on_attach,
}

-- TS / JS

-- JavaScript/TypeScript specific configuration
lspconfig.ts_ls.setup {
  on_attach = function(client, bufnr)
    -- Call the common on_attach function
    on_attach(client, bufnr)

    -- Disable formatting if you're using prettier or other formatters
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
  capabilities = capabilities,
  -- cmd = { "node", ".yarn/sdks/typescript/bin/tsserver" },
  -- root_dir = lspconfig.util.root_pattern("tsconfig.json", "package.json", ".git"),
  filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
  settings = {
    typescript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
    },
    javascript = {
      inlayHints = {
        includeInlayParameterNameHints = "all",
        includeInlayParameterNameHintsWhenArgumentMatchesName = false,
        includeInlayFunctionParameterTypeHints = true,
        includeInlayVariableTypeHints = true,
        includeInlayPropertyDeclarationTypeHints = true,
        includeInlayFunctionLikeReturnTypeHints = true,
        includeInlayEnumMemberValueHints = true,
      },
    },
  },
}

-- ESLint configuration
lspconfig.eslint.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
  settings = {
    codeAction = {
      disableRuleComment = {
        enable = true,
        location = "separateLine",
      },
      showDocumentation = {
        enable = true,
      },
    },
    codeActionOnSave = {
      enable = true,
      mode = "all",
    },
    format = true,
    nodePath = "",
    onIgnoredFiles = "off",
    packageManager = "npm",
    quiet = false,
    rulesCustomizations = {},
    run = "onType",
    useESLintClass = false,
    validate = "on",
    workingDirectory = {
      mode = "location",
    },
  },
}

-- Lua
lspconfig.lua_ls.setup {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
      completion = { callSnippet = "Replace" },
    },
  },
}

-- rust
lspconfig.rust_analyzer.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    ["rust-analyzer"] = {
      assist = {
        importGranularity = "module",
        importPrefix = "self",
      },
      cargo = {
        loadOutDirsFromCheck = true,
        allFeatures = true,
      },
      procMacro = {
        enable = true,
      },
      checkOnSave = {
        command = "clippy",
      },
      inlayHints = {
        lifetimeElisionHints = {
          enable = true,
          useParameterNames = true,
        },
        reborrowHints = {
          enable = true,
        },
        chainingHints = {
          enable = true,
        },
        closureReturnTypeHints = {
          enable = true,
        },
      },
    },
  },
}

-- Go
local util = require "lspconfig.util"

lspconfig.gopls.setup {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  cmd = { "dd-gopls" },
  cmd_env = {
    GOPACKAGESDRIVER_BAZEL = "bzl",
    GOPLS_DISABLE_MODULE_LOADS = "1",
  },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_dir = util.root_pattern("go.work", "go.mod", ".git"),
  settings = {
    gopls = {
      expandWorkspaceToModule = false,

      completeUnimported = true,
      usePlaceholders = true,
      semanticTokens = false,
      diagnosticsTrigger = "Save",

      -- Analyses
      analyses = {
        unusedparams = true,
        unreachable = true,
        nilness = true,
        shadow = true,
        unusedwrite = true,
        useany = true,
      },

      -- Inlay hints (shown via LSP inlay hints)
      hints = {
        assignVariableTypes = true,
        compositeLiteralFields = true,
        compositeLiteralTypes = true,
        constantValues = true,
        functionTypeParameters = true,
        parameterNames = true,
        rangeVariableTypes = true,
      },
    },
  },
}
