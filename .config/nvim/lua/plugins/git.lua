-- Git integration plugins
---@type LazySpec
return {
  -- Fugitive - Git commands in Neovim
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "G", "Gdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GBrowse", "GRemove", "GRename" },
    dependencies = {
      "AstroNvim/astrocore",
    },
    config = function()
      local astrocore = require "astrocore"
      astrocore.set_mappings {
        n = {
          ["<Leader>gg"] = { "<cmd>Git<cr>", desc = "Git status" },
          ["<Leader>gd"] = { "<cmd>Gdiffsplit<cr>", desc = "Git diff" },
          ["<Leader>gp"] = { "<cmd>Git pull<cr>", desc = "Git pull" },
          ["<Leader>gP"] = { "<cmd>Git push<cr>", desc = "Git push" },
          ["<Leader>gl"] = { "<cmd>Git log<cr>", desc = "Git log" },
          ["<Leader>gB"] = { "<cmd>GBrowse<cr>", desc = "Git browse" },
        },
      }
    end,
  },

  -- Git signs in the gutter
  {
    "lewis6991/gitsigns.nvim",
    event = "User AstroGitFile",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "?" },
      },
      current_line_blame = true,
      current_line_blame_opts = {
        delay = 500,
      },
      on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local astrocore = require "astrocore"

        astrocore.set_mappings({
          n = {
            -- Navigation
            ["]g"] = {
              function()
                if vim.wo.diff then return "]c" end
                vim.schedule(function() gs.next_hunk() end)
                return "<Ignore>"
              end,
              desc = "Next Git hunk",
              expr = true,
            },
            ["[g"] = {
              function()
                if vim.wo.diff then return "[c" end
                vim.schedule(function() gs.prev_hunk() end)
                return "<Ignore>"
              end,
              desc = "Previous Git hunk",
              expr = true,
            },

            -- Actions
            ["<Leader>ghs"] = { function() gs.stage_hunk() end, desc = "Stage hunk" },
            ["<Leader>ghr"] = { function() gs.reset_hunk() end, desc = "Reset hunk" },
            ["<Leader>ghS"] = { function() gs.stage_buffer() end, desc = "Stage buffer" },
            ["<Leader>ghu"] = { function() gs.undo_stage_hunk() end, desc = "Undo stage hunk" },
            ["<Leader>ghR"] = { function() gs.reset_buffer() end, desc = "Reset buffer" },
            ["<Leader>ghp"] = { function() gs.preview_hunk() end, desc = "Preview hunk" },
            ["<Leader>ghb"] = {
              function() gs.blame_line { full = true } end,
              desc = "Blame line",
            },
            ["<Leader>ghd"] = { function() gs.diffthis() end, desc = "Diff this" },
            ["<Leader>ghD"] = {
              function() gs.diffthis "~" end,
              desc = "Diff this ~",
            },

            -- Toggle
            ["<Leader>gtb"] = { function() gs.toggle_current_line_blame() end, desc = "Toggle blame line" },
            ["<Leader>gtd"] = { function() gs.toggle_deleted() end, desc = "Toggle deleted" },
          },
          v = {
            ["<Leader>ghs"] = {
              function() gs.stage_hunk { vim.fn.line ".", vim.fn.line "v" } end,
              desc = "Stage hunk",
            },
            ["<Leader>ghr"] = {
              function() gs.reset_hunk { vim.fn.line ".", vim.fn.line "v" } end,
              desc = "Reset hunk",
            },
          },
        }, { buffer = bufnr })
      end,
    },
  },

  -- GitHub integration
  {
    "tpope/vim-rhubarb",
    dependencies = { "tpope/vim-fugitive" },
    event = "VeryLazy",
  },

  -- Git conflict resolution
  {
    "akinsho/git-conflict.nvim",
    event = "User AstroGitFile",
    version = "*",
    config = function()
      require("git-conflict").setup {
        default_mappings = true,
        default_commands = true,
        disable_diagnostics = true,
      }

      local astrocore = require "astrocore"
      astrocore.set_mappings {
        n = {
          ["<Leader>gco"] = { "<cmd>GitConflictChooseOurs<cr>", desc = "Choose ours (conflict)" },
          ["<Leader>gct"] = { "<cmd>GitConflictChooseTheirs<cr>", desc = "Choose theirs (conflict)" },
          ["<Leader>gcb"] = { "<cmd>GitConflictChooseBoth<cr>", desc = "Choose both (conflict)" },
          ["<Leader>gc0"] = { "<cmd>GitConflictChooseNone<cr>", desc = "Choose none (conflict)" },
          ["<Leader>gcn"] = { "<cmd>GitConflictNextConflict<cr>", desc = "Next conflict" },
          ["<Leader>gcp"] = { "<cmd>GitConflictPrevConflict<cr>", desc = "Previous conflict" },
          ["<Leader>gcl"] = { "<cmd>GitConflictListQf<cr>", desc = "List conflicts" },
        },
      }
    end,
  },

  -- Git worktree
  {
    "ThePrimeagen/git-worktree.nvim",
    dependencies = {
      "nvim-telescope/telescope.nvim",
    },
    config = function()
      require("git-worktree").setup()
      require("telescope").load_extension "git_worktree"

      local astrocore = require "astrocore"
      astrocore.set_mappings {
        n = {
          ["<Leader>gwc"] = {
            "<cmd>lua require('telescope').extensions.git_worktree.create_git_worktree()<cr>",
            desc = "Create worktree",
          },
          ["<Leader>gws"] = {
            "<cmd>lua require('telescope').extensions.git_worktree.git_worktrees()<cr>",
            desc = "Switch worktree",
          },
        },
      }
    end,
  },
}
