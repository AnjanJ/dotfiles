-- Enhanced Telescope configuration with custom settings
---@type LazySpec
return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
  },
  opts = function(_, opts)
    local actions = require "telescope.actions"
    return require("astrocore").extend_tbl(opts, {
      defaults = {
        file_ignore_patterns = {
          "node_modules",
          ".git/",
          "tmp/",
          "log/",
          "coverage/",
          "_build/",
          "deps/",
        },
        mappings = {
          i = {
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
            ["<esc>"] = actions.close,
          },
          n = {
            ["q"] = actions.close,
            ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
          },
        },
        prompt_prefix = "   ",
        selection_caret = " ",
        layout_config = {
          horizontal = {
            preview_width = 0.55,
            results_width = 0.8,
          },
          vertical = {
            mirror = false,
          },
          width = 0.87,
          height = 0.80,
          preview_cutoff = 120,
        },
      },
      pickers = {
        find_files = {
          hidden = true,
          theme = "dropdown",
        },
        live_grep = {
          theme = "ivy",
        },
        buffers = {
          theme = "dropdown",
          previewer = false,
          mappings = {
            i = {
              ["<C-d>"] = actions.delete_buffer,
            },
            n = {
              ["dd"] = actions.delete_buffer,
            },
          },
        },
      },
    })
  end,
  config = function(plugin, opts)
    -- Setup telescope with options
    require("telescope").setup(opts)

    -- Load fzf extension for better performance
    require("telescope").load_extension("fzf")
  end,
}
