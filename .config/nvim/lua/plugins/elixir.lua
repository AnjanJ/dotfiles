-- Elixir development plugins
-- Using elixir-tools.nvim (official from José Valim ecosystem)
---@type LazySpec
return {
  {
    "elixir-tools/elixir-tools.nvim",
    version = "*",
    ft = { "elixir", "eex", "heex", "surface" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "AstroNvim/astrocore",
    },
    config = function()
      local elixir = require "elixir"
      local elixirls = require "elixir.elixirls"

      elixir.setup {
        nextls = {
          enable = true,
          init_options = {
            experimental = {
              completions = {
                enable = true,
              },
            },
          },
        },
        elixirls = {
          enable = true,
          settings = elixirls.settings {
            dialyzerEnabled = true,
            enableTestLenses = true,
            suggestSpecs = true,
          },
          on_attach = function(client, bufnr)
            -- Custom on_attach for Elixir LSP
            local astrocore = require "astrocore"
            astrocore.set_mappings({
              n = {
                ["<Leader>efp"] = {
                  "<cmd>ElixirFromPipe<cr>",
                  desc = "Elixir: From pipe",
                  buffer = bufnr,
                },
                ["<Leader>etp"] = {
                  "<cmd>ElixirToPipe<cr>",
                  desc = "Elixir: To pipe",
                  buffer = bufnr,
                },
                ["<Leader>eem"] = {
                  "<cmd>ElixirExpandMacro<cr>",
                  desc = "Elixir: Expand macro",
                  buffer = bufnr,
                },
              },
              v = {
                ["<Leader>efp"] = {
                  "<cmd>ElixirFromPipe<cr>",
                  desc = "Elixir: From pipe",
                  buffer = bufnr,
                },
                ["<Leader>etp"] = {
                  "<cmd>ElixirToPipe<cr>",
                  desc = "Elixir: To pipe",
                  buffer = bufnr,
                },
                ["<Leader>eem"] = {
                  "<cmd>ElixirExpandMacro<cr>",
                  desc = "Elixir: Expand macro",
                  buffer = bufnr,
                },
              },
            }, { buffer = bufnr })
          end,
        },
        projectionist = {
          enable = true,
        },
      }

      -- Additional Elixir keybindings
      local astrocore = require "astrocore"
      astrocore.set_mappings {
        n = {
          ["<Leader>et"] = { "<cmd>MixTest<cr>", desc = "Elixir: Run tests" },
          ["<Leader>ec"] = { "<cmd>MixClean<cr>", desc = "Elixir: Clean" },
          ["<Leader>ex"] = { "<cmd>IEx<cr>", desc = "Elixir: IEx console" },
        },
      }
    end,
  },

  -- Mix format on save
  {
    "mhinz/vim-mix-format",
    ft = { "elixir", "eex", "heex", "surface" },
    config = function()
      vim.g.mix_format_on_save = 1
      vim.g.mix_format_silent_errors = 1
    end,
  },

  -- Phoenix framework support
  {
    "c-brenn/phoenix.vim",
    ft = { "elixir", "eex", "heex" },
  },

  -- Additional Elixir syntax and patterns
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      -- Set Elixir-specific options
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "elixir", "eex", "heex", "surface" },
        callback = function()
          vim.opt_local.expandtab = true
          vim.opt_local.shiftwidth = 2
          vim.opt_local.softtabstop = 2
          vim.opt_local.tabstop = 2
        end,
      })

      return opts
    end,
  },
}
