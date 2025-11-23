-- AstroCore configuration for keymaps and options
---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    -- Configure core features of AstroNvim
    features = {
      large_buf = { size = 1024 * 256, lines = 10000 },
      autopairs = true,
      cmp = true,
      diagnostics = { virtual_text = true, virtual_lines = false },
      highlighturl = true,
      notifications = true,
    },
    -- Diagnostics configuration
    diagnostics = {
      virtual_text = true,
      underline = true,
    },
    -- vim options can be configured here
    options = {
      opt = {
        relativenumber = true,
        number = true,
        spell = false,
        signcolumn = "yes",
        wrap = false,
        -- Better search behavior
        ignorecase = true,
        smartcase = true,
        -- Indentation
        expandtab = true,
        shiftwidth = 2,
        softtabstop = 2,
        tabstop = 2,
        -- Scroll behavior
        scrolloff = 8,
        sidescrolloff = 8,
        -- Undo and backup
        undofile = true,
        backup = false,
        writebackup = false,
        swapfile = false,
        -- Update time
        updatetime = 250,
        -- Completion
        completeopt = { "menu", "menuone", "noselect" },
      },
      g = {
        -- Leader key is already set in lazy_setup.lua
        -- Rails.vim default projection
        rails_default_database = "postgresql",
      },
    },
    -- Mappings can be configured through AstroCore
    mappings = {
      -- Normal mode
      n = {
        -- Better window navigation
        ["<C-h>"] = false, -- Disabled for Harpoon
        ["<C-j>"] = false, -- Disabled for Harpoon
        ["<C-k>"] = false, -- Disabled for Harpoon
        ["<C-l>"] = false, -- Disabled for Harpoon

        -- Buffer navigation (keeping these from defaults)
        ["]b"] = { function() require("astrocore.buffer").nav(vim.v.count1) end, desc = "Next buffer" },
        ["[b"] = { function() require("astrocore.buffer").nav(-vim.v.count1) end, desc = "Previous buffer" },

        -- Better buffer close
        ["<Leader>bd"] = {
          function()
            require("astroui.status.heirline").buffer_picker(
              function(bufnr) require("astrocore.buffer").close(bufnr) end
            )
          end,
          desc = "Close buffer from tabline",
        },
        ["<Leader>bD"] = {
          function() require("astrocore.buffer").close(0) end,
          desc = "Close current buffer",
        },

        -- Better navigation
        ["<C-d>"] = { "<C-d>zz", desc = "Scroll down and center" },
        ["<C-u>"] = { "<C-u>zz", desc = "Scroll up and center" },
        ["n"] = { "nzzzv", desc = "Next search result and center" },
        ["N"] = { "Nzzzv", desc = "Previous search result and center" },

        -- Move lines up/down
        ["<A-j>"] = { ":m .+1<CR>==", desc = "Move line down" },
        ["<A-k>"] = { ":m .-2<CR>==", desc = "Move line up" },

        -- Quick save
        ["<Leader>w"] = { "<cmd>w<cr>", desc = "Save file" },

        -- Quick quit
        ["<Leader>q"] = { "<cmd>q<cr>", desc = "Quit" },

        -- Clear search highlight
        ["<Leader>nh"] = { "<cmd>nohlsearch<cr>", desc = "Clear search highlight" },

        -- Better paste (don't yank when pasting over)
        ["<Leader>p"] = { '"_dP', desc = "Paste without yanking" },

        -- System clipboard
        ["<Leader>y"] = { '"+y', desc = "Yank to system clipboard" },
        ["<Leader>Y"] = { '"+Y', desc = "Yank line to system clipboard" },

        -- Quick list navigation
        ["]q"] = { "<cmd>cnext<cr>", desc = "Next quickfix" },
        ["[q"] = { "<cmd>cprev<cr>", desc = "Previous quickfix" },

        -- ThePrimeagen's favorite: Change current word
        ["<Leader>s"] = { ":%s/\\<<C-r><C-w>\\>/<C-r><C-w>/gI<Left><Left><Left>", desc = "Replace word under cursor" },

        -- Make file executable
        ["<Leader>x"] = { "<cmd>!chmod +x %<cr>", desc = "Make file executable" },

        -- Source current file
        ["<Leader>so"] = { "<cmd>source %<cr>", desc = "Source current file" },
      },

      -- Visual mode
      v = {
        -- Move selected lines up/down
        ["<A-j>"] = { ":m '>+1<CR>gv=gv", desc = "Move selection down" },
        ["<A-k>"] = { ":m '<-2<CR>gv=gv", desc = "Move selection up" },

        -- Better indent
        ["<"] = { "<gv", desc = "Indent left and reselect" },
        [">"] = { ">gv", desc = "Indent right and reselect" },

        -- System clipboard
        ["<Leader>y"] = { '"+y', desc = "Yank to system clipboard" },

        -- Better paste (don't yank when pasting over)
        ["<Leader>p"] = { '"_dP', desc = "Paste without yanking" },
      },

      -- Insert mode
      i = {
        -- Better escape
        ["jk"] = { "<Esc>", desc = "Exit insert mode" },
        ["kj"] = { "<Esc>", desc = "Exit insert mode" },
      },

      -- Terminal mode
      t = {
        -- Terminal window navigation
        ["<C-h>"] = { "<C-\\><C-n><C-w>h", desc = "Move to left window" },
        ["<C-j>"] = { "<C-\\><C-n><C-w>j", desc = "Move to bottom window" },
        ["<C-k>"] = { "<C-\\><C-n><C-w>k", desc = "Move to top window" },
        ["<C-l>"] = { "<C-\\><C-n><C-w>l", desc = "Move to right window" },
      },
    },
  },
}
