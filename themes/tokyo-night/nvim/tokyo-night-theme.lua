-- Tokyo Night theme with excellent statusline support
return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    style = "night", -- storm, moon, night (darkest)
    transparent = false,
    terminal_colors = true,
    styles = {
      comments = { italic = true },
      keywords = { italic = true },
      functions = {},
      variables = {},
    },
  },
}
