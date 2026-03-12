-- Aura Dark theme
-- Repository: https://github.com/daltonmenezes/aura-theme
-- Note: This is a monorepo — neovim theme lives under packages/neovim
return {
  "baliestri/aura-theme",
  lazy = false,
  priority = 1000,
  init = function(plugin)
    -- Must add to rtp before AstroUI tries to set the colorscheme
    vim.opt.rtp:append(plugin.dir .. "/packages/neovim")
  end,
}
