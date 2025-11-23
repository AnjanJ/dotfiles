-- Treesitter configuration for Rails/Elixir development
---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    -- Only auto-install parsers for languages you actually use
    ensure_installed = {
      -- Core Neovim
      "lua",
      "vim",
      "vimdoc",
      "query",

      -- Ruby/Rails
      "ruby",
      "embedded_template", -- ERB templates

      -- Elixir/Phoenix
      "elixir",
      "heex", -- Phoenix templates
      "eex",  -- Elixir templates

      -- Web development
      "html",
      "css",
      "scss",
      "javascript",
      "typescript",
      "tsx",
      "json",
      "yaml",

      -- SQL (for Rails migrations)
      "sql",

      -- Markdown for docs
      "markdown",
      "markdown_inline",

      -- Git
      "git_config",
      "git_rebase",
      "gitcommit",
      "gitignore",

      -- Shell scripting
      "bash",

      -- Config files
      "toml",
      "dockerfile",
    },

    -- Auto install missing parsers when entering buffer
    auto_install = true,

    -- Highlight settings
    highlight = {
      enable = true,
      additional_vim_regex_highlighting = false,
    },

    -- Incremental selection
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<C-space>",
        node_incremental = "<C-space>",
        scope_incremental = false,
        node_decremental = "<bs>",
      },
    },

    -- Indentation
    indent = {
      enable = true,
    },
  },
}
