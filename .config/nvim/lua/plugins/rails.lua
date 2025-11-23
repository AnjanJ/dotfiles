-- Rails development plugins
---@type LazySpec
return {
  -- Core Rails plugin
  {
    "tpope/vim-rails",
    ft = { "ruby", "eruby" },
    dependencies = {
      "tpope/vim-bundler",
      "tpope/vim-rake",
    },
    config = function()
      -- Rails.vim configuration
      vim.g.rails_projections = {
        ["app/controllers/*_controller.rb"] = {
          test = { "spec/requests/{}_spec.rb", "spec/controllers/{}_controller_spec.rb" },
          alternate = "spec/requests/{}_spec.rb",
        },
        ["spec/requests/*_spec.rb"] = {
          alternate = "app/controllers/{}_controller.rb",
        },
      }
    end,
  },

  -- Bundler integration
  {
    "tpope/vim-bundler",
    ft = { "ruby", "eruby" },
  },

  -- Rake integration
  {
    "tpope/vim-rake",
    ft = { "ruby", "eruby" },
  },

  -- Ruby test runner
  {
    "vim-test/vim-test",
    ft = { "ruby", "eruby" },
    dependencies = {
      "AstroNvim/astrocore",
    },
    config = function()
      vim.g["test#strategy"] = "neovim"
      vim.g["test#neovim#term_position"] = "vert botright"
      vim.g["test#ruby#rspec#executable"] = "bundle exec rspec"

      local astrocore = require "astrocore"
      astrocore.set_mappings {
        n = {
          ["<Leader>tn"] = { "<cmd>TestNearest<cr>", desc = "Test nearest" },
          ["<Leader>tf"] = { "<cmd>TestFile<cr>", desc = "Test file" },
          ["<Leader>ts"] = { "<cmd>TestSuite<cr>", desc = "Test suite" },
          ["<Leader>tl"] = { "<cmd>TestLast<cr>", desc = "Test last" },
          ["<Leader>tv"] = { "<cmd>TestVisit<cr>", desc = "Test visit" },
        },
      }
    end,
  },

  -- Enhanced Ruby syntax
  {
    "vim-ruby/vim-ruby",
    ft = { "ruby", "eruby" },
  },

  -- Rails keybindings via AstroCore
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      local maps = opts.mappings or {}
      maps.n = maps.n or {}

      -- Rails specific navigation
      maps.n["<Leader>rc"] = { "<cmd>Econtroller<cr>", desc = "Rails: Go to controller" }
      maps.n["<Leader>rm"] = { "<cmd>Emodel<cr>", desc = "Rails: Go to model" }
      maps.n["<Leader>rv"] = { "<cmd>Eview<cr>", desc = "Rails: Go to view" }
      maps.n["<Leader>rs"] = { "<cmd>Espec<cr>", desc = "Rails: Go to spec" }
      maps.n["<Leader>rh"] = { "<cmd>Ehelper<cr>", desc = "Rails: Go to helper" }
      maps.n["<Leader>ra"] = { "<cmd>A<cr>", desc = "Rails: Alternate file" }
      maps.n["<Leader>rr"] = { "<cmd>R<cr>", desc = "Rails: Related file" }

      -- Rails commands
      maps.n["<Leader>rg"] = { "<cmd>Rails generate ", desc = "Rails: Generate" }
      maps.n["<Leader>rd"] = { "<cmd>Rails destroy ", desc = "Rails: Destroy" }
      maps.n["<Leader>rb"] = { "<cmd>Rails console<cr>", desc = "Rails: Console" }

      return opts
    end,
  },
}
