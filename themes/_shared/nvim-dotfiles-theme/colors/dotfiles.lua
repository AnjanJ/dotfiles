-- `:colorscheme dotfiles` — a base16 scheme built from the active
-- palette. Installed next to the rendered theme by `dotfiles theme` and
-- loaded through themes/_shared/nvim/dotfiles-theme.lua.
local ok, theme = pcall(dofile, os.getenv("HOME") .. "/.local/state/dotfiles/current/theme/nvim.lua")
if not ok or type(theme) ~= "table" or type(theme.colors) ~= "table" then
  vim.notify("dotfiles colorscheme: no rendered palette (run: dotfiles theme <name>)", vim.log.levels.WARN)
  return
end
local c = theme.colors
local light = theme.mode == "light"

vim.o.background = light and "light" or "dark"
require("base16-colorscheme").setup({
  base00 = c.background,          -- default background
  base01 = c.dark_background,     -- lighter background (status bars)
  base02 = c.selection,           -- selection background
  base03 = c.muted,               -- comments, invisibles
  base04 = c.dark_foreground,     -- dark foreground (status bars)
  base05 = c.foreground,          -- default foreground
  base06 = c.light_foreground,    -- light foreground
  base07 = c.bright_foreground,   -- lightest foreground
  base08 = c.red,                 -- variables, tags, deletions
  base09 = c.orange,              -- integers, constants
  base0A = c.yellow,              -- classes, search
  base0B = c.green,               -- strings, insertions
  base0C = c.cyan,                -- regex, escapes
  base0D = c.blue,                -- functions, headings
  base0E = c.magenta,             -- keywords, storage
  base0F = c.brown,               -- deprecated, embedded tags
})
vim.g.colors_name = "dotfiles"
