return {
  "neovim/nvim-lspconfig",
  init = function()
    -- tsgo (fast Go-based TS server) — starts when binary exists in project
    -- Uses vim.lsp.start directly (not lspconfig), so it lives in init
    local ts_filetypes = {
      "javascript",
      "javascriptreact",
      "javascript.jsx",
      "typescript",
      "typescriptreact",
      "typescript.tsx",
    }

    vim.api.nvim_create_autocmd("FileType", {
      pattern = ts_filetypes,
      callback = function(args)
        local root = vim.fs.root(args.buf, function(_, path)
          return vim.fn.filereadable(path .. "/.yarn/sdks/typescript-go/lib/tsgo") == 1
        end)
        if not root then
          return
        end

        local tsgo_binary = root .. "/.yarn/sdks/typescript-go/lib/tsgo"

        vim.lsp.start({
          name = "tsgo",
          cmd = { tsgo_binary, "--lsp", "--stdio" },
          root_dir = root,
          capabilities = (function()
            local caps = vim.lsp.protocol.make_client_capabilities()
            local ok, blink = pcall(require, "blink.cmp")
            if ok then
              caps = vim.tbl_deep_extend("force", caps, blink.get_lsp_capabilities())
            end
            caps.workspace = vim.tbl_extend("force", caps.workspace or {}, {
              didChangeWatchedFiles = { dynamicRegistration = false },
            })
            return caps
          end)(),
          on_attach = function(client, bufnr)
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
            -- Prevent dual TS servers: stop ts_ls or vtsls if attached
            for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = "ts_ls" })) do
              c.stop()
            end
            for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = "vtsls" })) do
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

  end,

  opts = {
    servers = {
      -- Disable vtsls — we use tsgo for TypeScript instead
      vtsls = { enabled = false },

      -- Simple servers with default config
      html = {},
      cssls = {},
      terraformls = {},
      tflint = {},
      jsonls = {},
      clangd = {},
      bashls = {},

      -- Lua
      lua_ls = {
        settings = {
          Lua = {
            diagnostics = { globals = { "vim" } },
            completion = { callSnippet = "Replace" },
          },
        },
      },

      -- Python: Ruff (linter)
      ruff = {
        filetypes = { "python" },
        settings = {
          ruff = {
            lint = { run = "onType" },
            organizeImports = true,
            fixAll = true,
          },
        },
        init_options = {
          settings = {
            args = { "--config=pyproject.toml" },
          },
        },
      },

      -- Python: Pyright (type checker)
      pyright = {
        filetypes = { "python" },
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
      },

      -- TypeScript / JavaScript
      ts_ls = {
        single_file_support = false,
        root_dir = function(fname)
          local tsgo_root = vim.fs.root(fname, function(_, path)
            return vim.fn.filereadable(path .. "/.yarn/sdks/typescript-go/lib/tsgo") == 1
          end)
          if tsgo_root then
            return nil
          end
          return require("lspconfig.util").root_pattern("tsconfig.json", "jsconfig.json", "package.json", ".git")(fname)
        end,
        filetypes = {
          "javascript",
          "javascriptreact",
          "javascript.jsx",
          "typescript",
          "typescriptreact",
          "typescript.tsx",
        },
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
      },

      -- ESLint
      eslint = {
        filetypes = {
          "javascript",
          "javascriptreact",
          "javascript.jsx",
          "typescript",
          "typescriptreact",
          "typescript.tsx",
        },
        settings = {
          nodePath = ".yarn/sdks",
          packageManager = "yarn",
          rulesCustomizations = {
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
          workingDirectory = { mode = "location" },
        },
      },

      -- Rust
      rust_analyzer = {
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
            procMacro = { enable = true },
            checkOnSave = { command = "clippy" },
            inlayHints = {
              lifetimeElisionHints = { enable = true, useParameterNames = true },
              reborrowHints = { enable = true },
              chainingHints = { enable = true },
              closureReturnTypeHints = { enable = true },
            },
          },
        },
      },

      -- Go (use dd-gopls when available, skip Mason in that case)
      gopls = {
        mason = vim.fn.executable("dd-gopls") ~= 1,
        cmd = vim.fn.executable("dd-gopls") == 1 and { "dd-gopls" } or { "gopls" },
        cmd_env = vim.fn.executable("dd-gopls") == 1 and { GOPLS_DISABLE_MODULE_LOADS = "1" } or {},
        filetypes = { "go", "gomod", "gowork", "gotmpl" },
        settings = {
          gopls = {
            expandWorkspaceToModule = false,
            completeUnimported = true,
            usePlaceholders = true,
            semanticTokens = false,
            diagnosticsTrigger = "Save",
            analyses = {
              unusedparams = true,
              unreachable = true,
              nilness = true,
              shadow = true,
              unusedwrite = true,
              useany = true,
            },
            hints = {
              assignVariableTypes = false,
              compositeLiteralFields = false,
              compositeLiteralTypes = false,
              constantValues = false,
              functionTypeParameters = false,
              parameterNames = false,
              rangeVariableTypes = false,
            },
          },
        },
      },
    },

    -- Custom setup handlers — returning nil/false lets LazyVim proceed with normal setup
    setup = {
      ruff = function(_, opts)
        opts.before_init = function(_, config_arg)
          local pythonUtils = require("utils.python")
          local pythonPath = pythonUtils.getPythonPath(config_arg.root_dir)
          config_arg.settings = config_arg.settings or {}
          config_arg.settings.python = config_arg.settings.python or {}
          config_arg.settings.python.pythonPath = pythonPath
        end
        opts.on_attach = function(client)
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end
      end,

      pyright = function(_, opts)
        opts.before_init = function(_, config_arg)
          local pythonUtils = require("utils.python")
          local pythonPath = pythonUtils.getPythonPath(config_arg.root_dir)
          config_arg.settings.python.pythonPath = pythonPath
        end
      end,

      ts_ls = function(_, opts)
        opts.on_attach = function(client)
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
        end
      end,
    },
  },
}
