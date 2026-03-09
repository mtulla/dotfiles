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
-- ts_ls only starts when tsgo (faster Go-based server) is NOT available in the project
lspconfig.ts_ls.setup {
  on_attach = function(client, bufnr)
    on_attach(client, bufnr)
    client.server_capabilities.documentFormattingProvider = false
    client.server_capabilities.documentRangeFormattingProvider = false
  end,
  capabilities = capabilities,
  single_file_support = false,
  root_dir = function(fname)
    -- Yield to tsgo when it's bundled anywhere up the tree (monorepo root)
    local tsgo_root = vim.fs.root(fname, function(_, path)
      return vim.fn.filereadable(path .. "/.yarn/sdks/typescript-go/lib/tsgo") == 1
    end)
    if tsgo_root then return nil end
    return require("lspconfig.util").root_pattern("tsconfig.json", "jsconfig.json", "package.json", ".git")(fname)
  end,
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

-- tsgo (fast Go-based TS server) — starts when binary exists in project
local ts_filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" }

vim.api.nvim_create_autocmd("FileType", {
  pattern = ts_filetypes,
  callback = function(args)
    -- Find monorepo root by looking for the tsgo binary itself
    local root = vim.fs.root(args.buf, function(_, path)
      return vim.fn.filereadable(path .. "/.yarn/sdks/typescript-go/lib/tsgo") == 1
    end)
    if not root then return end

    local tsgo_binary = root .. "/.yarn/sdks/typescript-go/lib/tsgo"

    vim.lsp.start({
      name = "tsgo",
      cmd = { tsgo_binary, "--lsp", "--stdio" },
      root_dir = root,
      capabilities = (function()
        local caps = vim.deepcopy(capabilities)
        caps.workspace = vim.tbl_extend("force", caps.workspace or {}, {
          didChangeWatchedFiles = { dynamicRegistration = false },
        })
        return caps
      end)(),
      on_attach = function(client, bufnr)
        on_attach(client, bufnr)
        client.server_capabilities.documentFormattingProvider = false
        client.server_capabilities.documentRangeFormattingProvider = false
        -- Prevent dual TS servers: stop ts_ls if it attached
        for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = "ts_ls" })) do
          c.stop()
        end
      end,
      settings = {
        typescript = {
          preferences = {
            importModuleSpecifier = "non-relative",
            autoImportSpecifierExcludeRegexes = { "packages/", "^packages" },
          },
          tsserver = {
            useSyntaxServer = "auto",
            maxTsServerMemory = 1024 * 24,
            nodePath = "node",
            watchOptions = {
              excludeDirectories = { "**/node_modules", "**/.yarn", "**/.sarif" },
              excludeFiles = { ".pnp.cjs" },
            },
          },
        },
      },
    })
  end,
})

-- ESLint configuration
lspconfig.eslint.setup {
  on_attach = on_attach,
  capabilities = capabilities,
  filetypes = { "javascript", "javascriptreact", "javascript.jsx", "typescript", "typescriptreact", "typescript.tsx" },
  settings = {
    nodePath = ".yarn/sdks",
    packageManager = "yarn",
    rulesCustomizations = {
      -- Suppress noise from autofixable rules
      { rule = "prettier/prettier", severity = "off" },
      { rule = "arca/import-ordering", severity = "off" },
      { rule = "arca/newline-after-import-section", severity = "off" },
      { rule = "@typescript-eslint/consistent-type-imports", severity = "off" },
      { rule = "quotes", severity = "off" },
      { rule = "import/no-duplicates", severity = "off" },
      { rule = "unused-imports/no-unused-imports", severity = "off" },
    },
    run = "onType",
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
local gopls_cmd = vim.fn.executable("dd-gopls") == 1 and { "dd-gopls" } or { "gopls" }
local gopls_env = vim.fn.executable("dd-gopls") == 1 and { GOPLS_DISABLE_MODULE_LOADS = "1" } or {}

lspconfig.gopls.setup {
  on_attach = on_attach,
  on_init = on_init,
  capabilities = capabilities,
  cmd = gopls_cmd,
  cmd_env = gopls_env,
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
