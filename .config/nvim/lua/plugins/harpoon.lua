-- Harpoon2 configuration for quick file navigation
-- Based on ThePrimeagen's workflow
---@type LazySpec
return {
  "ThePrimeagen/harpoon",
  branch = "harpoon2",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "AstroNvim/astrocore",
  },
  opts = {
    menu = {
      width = vim.api.nvim_win_get_width(0) - 4,
    },
    settings = {
      save_on_toggle = true,
    },
  },
  config = function(_, opts)
    local harpoon = require "harpoon"
    harpoon:setup(opts)

    -- Register keybindings with AstroCore
    local astrocore = require "astrocore"
    astrocore.set_mappings {
      n = {
        -- Add current file to harpoon
        ["<Leader>ha"] = {
          function() harpoon:list():add() end,
          desc = "Harpoon: Add file",
        },
        -- Toggle harpoon menu
        ["<Leader>hh"] = {
          function() harpoon.ui:toggle_quick_menu(harpoon:list()) end,
          desc = "Harpoon: Toggle menu",
        },
        -- Quick navigation to harpooned files (1-4)
        ["<C-h>"] = {
          function() harpoon:list():select(1) end,
          desc = "Harpoon: File 1",
        },
        ["<C-j>"] = {
          function() harpoon:list():select(2) end,
          desc = "Harpoon: File 2",
        },
        ["<C-k>"] = {
          function() harpoon:list():select(3) end,
          desc = "Harpoon: File 3",
        },
        ["<C-l>"] = {
          function() harpoon:list():select(4) end,
          desc = "Harpoon: File 4",
        },
        -- Navigate to next/previous harpooned file
        ["<Leader>hn"] = {
          function() harpoon:list():next() end,
          desc = "Harpoon: Next file",
        },
        ["<Leader>hp"] = {
          function() harpoon:list():prev() end,
          desc = "Harpoon: Previous file",
        },
      },
    }
  end,
}
