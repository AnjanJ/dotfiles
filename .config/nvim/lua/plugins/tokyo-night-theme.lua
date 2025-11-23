-- Tokyo Night theme with excellent statusline support
-- To use: rename this file to remove .bak extension
-- Then delete or rename aura-theme.lua
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
-- Then in astroui.lua, set: colorscheme = "tokyonight"
