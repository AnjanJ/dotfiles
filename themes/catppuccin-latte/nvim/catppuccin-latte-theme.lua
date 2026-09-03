-- Catppuccin Latte: the light flavour of the same plugin the catppuccin
-- theme uses, so switching between the two needs no :Lazy sync.
return {
  "catppuccin/nvim",
  name = "catppuccin",
  lazy = false,
  priority = 1000,
  opts = {
    flavour = "latte", -- latte (lightest), frappe, macchiato, mocha
    background = { light = "latte", dark = "mocha" },
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
