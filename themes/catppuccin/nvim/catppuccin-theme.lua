-- Catppuccin Mocha theme with excellent tree-sitter and LSP support
return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  opts = {
    flavour = "mocha", -- latte, frappe, macchiato, mocha (darkest)
    transparent_background = false,
    term_colors = true,
    styles = {
      comments = { "italic" },
      keywords = { "italic" },
      functions = {},
      variables = {},
    },
    integrations = {
      cmp = true,
      gitsigns = true,
      treesitter = true,
      telescope = { enabled = true },
      mason = true,
      native_lsp = { enabled = true },
    },
  },
}
