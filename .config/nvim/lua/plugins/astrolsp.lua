-- AstroLSP configuration for Ruby and Elixir development
---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    -- Configuration table of features provided by AstroLSP
    features = {
      codelens = true,
      inlay_hints = false,
      semantic_tokens = true,
    },
    -- customize lsp formatting options
    formatting = {
      format_on_save = {
        enabled = true,
        allow_filetypes = {
          "ruby",
          "elixir",
        },
      },
      disabled = {},
      timeout_ms = 1000,
    },
    -- enable servers that you already have installed without mason
    servers = {},
    -- customize language server configuration options passed to `lspconfig`
    config = {
      -- Ruby LSP configuration (using ruby-lsp as default)
      ruby_lsp = {
        cmd = { "ruby-lsp" },
        filetypes = { "ruby", "eruby" },
        init_options = {
          enabledFeatures = {
            "diagnostics",
            "documentHighlights",
            "documentSymbols",
            "foldingRanges",
            "formatting",
            "onTypeFormatting",
            "selectionRanges",
            "semanticHighlighting",
            "completion",
            "codeActions",
            "inlayHint",
          },
          featuresConfiguration = {
            inlayHint = {
              enableAll = true,
            },
          },
        },
        settings = {},
      },
      -- Alternative: Solargraph (if preferred)
      solargraph = {
        cmd = { "solargraph", "stdio" },
        filetypes = { "ruby" },
        root_dir = function(fname)
          local util = require "lspconfig.util"
          return util.root_pattern("Gemfile", ".git")(fname)
        end,
        settings = {
          solargraph = {
            diagnostics = true,
            completion = true,
            formatting = true,
          },
        },
      },
    },
    -- customize how language servers are attached
    handlers = {
      -- Disable elixir-ls here since we're using elixir-tools.nvim
      elixirls = false,
      -- Disable solargraph (use ruby-lsp instead)
      solargraph = false,
    },
    -- Configure buffer local auto commands to add when attaching a language server
    autocmds = {
      lsp_codelens_refresh = {
        cond = "textDocument/codeLens",
        {
          event = { "InsertLeave", "BufEnter" },
          desc = "Refresh codelens (buffer)",
          callback = function(args)
            if require("astrolsp").config.features.codelens then vim.lsp.codelens.refresh { bufnr = args.buf } end
          end,
        },
      },
    },
    -- mappings to be set up on attaching of a language server
    mappings = {
      n = {
        -- LSP actions
        gD = {
          function() vim.lsp.buf.declaration() end,
          desc = "Declaration of current symbol",
          cond = "textDocument/declaration",
        },
        gd = {
          function() vim.lsp.buf.definition() end,
          desc = "Go to definition",
          cond = "textDocument/definition",
        },
        gi = {
          function() vim.lsp.buf.implementation() end,
          desc = "Go to implementation",
          cond = "textDocument/implementation",
        },
        gr = {
          function() vim.lsp.buf.references() end,
          desc = "Find references",
          cond = "textDocument/references",
        },
        ["<Leader>la"] = {
          function() vim.lsp.buf.code_action() end,
          desc = "LSP code action",
          cond = "textDocument/codeAction",
        },
        ["<Leader>lf"] = {
          function() vim.lsp.buf.format() end,
          desc = "Format buffer",
          cond = "textDocument/formatting",
        },
        ["<Leader>lh"] = {
          function() vim.lsp.buf.hover() end,
          desc = "Hover symbol",
          cond = "textDocument/hover",
        },
        ["<Leader>ln"] = {
          function() vim.lsp.buf.rename() end,
          desc = "Rename symbol",
          cond = "textDocument/rename",
        },
        ["<Leader>lD"] = {
          function() vim.diagnostic.open_float() end,
          desc = "Show line diagnostics",
        },
        ["[d"] = {
          function() vim.diagnostic.goto_prev() end,
          desc = "Previous diagnostic",
        },
        ["]d"] = {
          function() vim.diagnostic.goto_next() end,
          desc = "Next diagnostic",
        },
        ["<Leader>lq"] = {
          function() vim.diagnostic.setloclist() end,
          desc = "Diagnostics to location list",
        },
        K = {
          function() vim.lsp.buf.hover() end,
          desc = "Hover symbol",
          cond = "textDocument/hover",
        },
        ["<Leader>uY"] = {
          function() require("astrolsp.toggles").buffer_semantic_tokens() end,
          desc = "Toggle LSP semantic highlight (buffer)",
          cond = function(client)
            return client.supports_method "textDocument/semanticTokens/full" and vim.lsp.semantic_tokens ~= nil
          end,
        },
      },
      v = {
        ["<Leader>la"] = {
          function() vim.lsp.buf.code_action() end,
          desc = "LSP code action",
          cond = "textDocument/codeAction",
        },
      },
    },
    -- A custom `on_attach` function to be run after the default `on_attach` function
    on_attach = function(client, bufnr)
      -- Enable inlay hints for Ruby if supported
      if client.server_capabilities.inlayHintProvider and vim.bo[bufnr].filetype == "ruby" then
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
      end
    end,
  },
}
