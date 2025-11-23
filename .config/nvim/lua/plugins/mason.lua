-- Customize Mason for Ruby and Elixir development
---@type LazySpec
return {
  -- use mason-tool-installer for automatically installing Mason packages
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    -- overrides `require("mason-tool-installer").setup(...)`
    opts = {
      -- Make sure to use the names found in `:Mason`
      ensure_installed = {
        -- Core language servers
        "lua-language-server",

        -- Ruby language servers and tools
        "ruby-lsp", -- Official Ruby LSP (preferred)
        "solargraph", -- Alternative Ruby LSP
        "rubocop", -- Ruby linter
        "erb-lint", -- ERB linter

        -- Formatters
        "stylua", -- Lua formatter

        -- Debuggers
        "debugpy", -- Python debugger (if needed)

        -- Other useful tools
        "tree-sitter-cli",
      },
    },
  },
}
