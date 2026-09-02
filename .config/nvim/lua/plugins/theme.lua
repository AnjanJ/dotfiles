-- Active theme plugin, resolved at startup from the rendered theme state.
--
-- `dotfiles theme <name>` writes ~/.local/state/dotfiles/current/theme/nvim.lua
-- with the path of themes/<name>/nvim/<name>-theme.lua; this file loads that
-- spec so switching themes never edits anything tracked in git. Without a
-- rendered theme (fresh clone) AstroNvim's default astrodark is used.
local theme_ok, theme = pcall(dofile, os.getenv("HOME") .. "/.local/state/dotfiles/current/theme/nvim.lua")
if theme_ok and type(theme) == "table" and theme.plugin_spec then
  local spec_ok, spec = pcall(dofile, theme.plugin_spec)
  if spec_ok and type(spec) == "table" then return spec end
  vim.schedule(function()
    vim.notify("dotfiles theme: could not load " .. theme.plugin_spec, vim.log.levels.WARN)
  end)
end
return {}
