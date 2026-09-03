-- Palette-driven Neovim colorscheme, used when a theme has no plugin
-- spec of its own: themes installed with `dotfiles theme install` (their
-- nvim/*.lua is code from a stranger and is dropped at staging) and
-- scaffolds that never got one. It builds a base16 scheme from the
-- colours `dotfiles theme` rendered into ~/.local/state/dotfiles/
-- current/theme/nvim.lua, so any colors.toml is enough for an editor
-- theme. The colorscheme is named "dotfiles" (colors/dotfiles.lua).
return {
  { "RRethy/base16-nvim", lazy = false, priority = 1000 },
  {
    dir = os.getenv("HOME") .. "/.local/state/dotfiles/current/theme/nvim-dotfiles-theme",
    name = "dotfiles-theme",
    lazy = false,
    priority = 1000,
    dependencies = { "RRethy/base16-nvim" },
  },
}
