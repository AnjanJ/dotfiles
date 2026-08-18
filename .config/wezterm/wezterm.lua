local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- ── Appearance ────────────────────────────────────────────────────────────────
config.front_end = 'WebGpu'
config.macos_window_background_blur = 20
config.window_background_opacity = 0.96
config.window_decorations = 'INTEGRATED_BUTTONS | RESIZE'
config.native_macos_fullscreen_mode = true
config.audible_bell = 'Disabled'
config.scrollback_lines = 50000

-- ── Font (JetBrains Mono Nerd Font + ligatures) ───────────────────────────────
config.font = wezterm.font_with_fallback {
  {
    family = 'JetBrainsMono Nerd Font',
    weight = 'Medium',
    harfbuzz_features = { 'calt=1', 'clig=1', 'liga=1' },
  },
  { family = 'Symbols Nerd Font Mono' },
  'Noto Color Emoji',
}
config.font_size = 16.0
config.freetype_load_target = 'Light'
config.freetype_render_target = 'HorizontalLcd'

-- ── Aura theme (ported from daltonmenezes/aura-theme Alacritty palette) ───────
config.colors = {
  foreground = '#edecee',
  background = '#15141b',
  cursor_bg = '#a277ff',
  cursor_fg = '#15141b',
  cursor_border = '#a277ff',
  selection_fg = '#edecee',
  selection_bg = '#29263c',
  ansi = {
    '#110f18', -- black
    '#ff6767', -- red
    '#61ffca', -- green
    '#ffca85', -- yellow
    '#a277ff', -- blue (Aura purple)
    '#a277ff', -- magenta
    '#61ffca', -- cyan
    '#edecee', -- white
  },
  brights = {
    '#4d4d4d', '#ff6767', '#61ffca', '#ffca85',
    '#a277ff', '#a277ff', '#61ffca', '#edecee',
  },
  tab_bar = {
    background = '#110f18',
    active_tab = { bg_color = '#a277ff', fg_color = '#15141b' },
    inactive_tab = { bg_color = '#15141b', fg_color = '#6d6d6d' },
    inactive_tab_hover = { bg_color = '#29263c', fg_color = '#edecee' },
    new_tab = { bg_color = '#15141b', fg_color = '#a277ff' },
    new_tab_hover = { bg_color = '#29263c', fg_color = '#a277ff' },
  },
}

-- ── Tab bar ───────────────────────────────────────────────────────────────────
config.enable_tab_bar = true
config.use_fancy_tab_bar = true
config.tab_bar_at_bottom = false
config.hide_tab_bar_if_only_one_tab = false
config.show_tab_index_in_tab_bar = true
config.tab_max_width = 32
config.window_frame = { font_size = 14.0 }

-- Custom tab title: respects user-set name; otherwise shows cwd + running process
wezterm.on('format-tab-title', function(tab, tabs, panes, conf, hover, max_width)
  if tab.tab_title and #tab.tab_title > 0 then
    return ' ' .. tab.tab_title .. ' '
  end
  local pane = tab.active_pane
  local proc = (pane.foreground_process_name or ''):match('([^/]+)$') or ''
  local cwd_str = ''
  if pane.current_working_dir then
    local p = tostring(pane.current_working_dir):gsub('^file://[^/]*', '')
    cwd_str = p:match('([^/]+)/?$') or p
  end
  local title = string.format(' %d  %s  %s ', tab.tab_index + 1, cwd_str, proc)
  if tab.is_active then
    return { { Attribute = { Intensity = 'Bold' } }, { Text = title } }
  end
  return title
end)

-- Right status: active workspace + clock
wezterm.on('update-right-status', function(window, pane)
  window:set_right_status(wezterm.format {
    { Foreground = { Color = '#a277ff' } },
    { Text = ' [' .. window:active_workspace() .. '] ' },
    { Foreground = { Color = '#6d6d6d' } },
    { Text = wezterm.strftime('%a %H:%M ') },
  })
end)

-- ── Keys (macOS, CMD-driven) ──────────────────────────────────────────────────
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = true

-- ── Clipboard ────────────────────────────────────────────
-- Selecting with the mouse copies to the system clipboard immediately.
-- WezTerm's default is PrimarySelection only, which macOS apps cannot
-- read -- the same trap Ghostty has.
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection 'Clipboard',
  },
  -- Cmd-click opens a link instead of selecting.
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CMD',
    action = act.OpenLinkAtMouseCursor,
  },
}

config.keys = {
  -- Clipboard. CopyTo 'Clipboard' always copies the selection; the default
  -- cmd+c is already this, but it is stated here so it cannot be shadowed
  -- by a later binding.
  { key = 'c', mods = 'CMD',       action = act.CopyTo 'Clipboard' },
  { key = 'v', mods = 'CMD',       action = act.PasteFrom 'Clipboard' },

  -- Tabs
  { key = 't', mods = 'CMD',       action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'w', mods = 'CMD',       action = act.CloseCurrentPane { confirm = true } },
  { key = '[', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(-1) },
  { key = ']', mods = 'CMD|SHIFT', action = act.ActivateTabRelative(1) },
  { key = '1', mods = 'CMD',       action = act.ActivateTab(0) },
  { key = '2', mods = 'CMD',       action = act.ActivateTab(1) },
  { key = '3', mods = 'CMD',       action = act.ActivateTab(2) },
  { key = '4', mods = 'CMD',       action = act.ActivateTab(3) },
  { key = '5', mods = 'CMD',       action = act.ActivateTab(4) },
  { key = '6', mods = 'CMD',       action = act.ActivateTab(5) },
  { key = '7', mods = 'CMD',       action = act.ActivateTab(6) },
  { key = '8', mods = 'CMD',       action = act.ActivateTab(7) },
  { key = '9', mods = 'CMD',       action = act.ActivateTab(8) },

  -- Rename current tab
  {
    key = ',', mods = 'CMD',
    action = act.PromptInputLine {
      description = 'Enter new tab title',
      action = wezterm.action_callback(function(window, pane, line)
        if line then window:active_tab():set_title(line) end
      end),
    },
  },

  -- Panes
  { key = 'd', mods = 'CMD',       action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 'd', mods = 'CMD|SHIFT', action = act.SplitVertical   { domain = 'CurrentPaneDomain' } },
  { key = 'h', mods = 'CMD|ALT',   action = act.ActivatePaneDirection 'Left' },
  { key = 'l', mods = 'CMD|ALT',   action = act.ActivatePaneDirection 'Right' },
  { key = 'k', mods = 'CMD|ALT',   action = act.ActivatePaneDirection 'Up' },
  { key = 'j', mods = 'CMD|ALT',   action = act.ActivatePaneDirection 'Down' },
  { key = 'z', mods = 'CMD|SHIFT', action = act.TogglePaneZoomState },

  -- Workspaces (one per project: rails, phoenix, zig, react…)
  { key = 's', mods = 'CMD|SHIFT', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
  {
    key = 'n', mods = 'CMD|SHIFT',
    action = act.PromptInputLine {
      description = 'New workspace name:',
      action = wezterm.action_callback(function(win, pane, line)
        if line and #line > 0 then
          win:perform_action(act.SwitchToWorkspace { name = line }, pane)
        end
      end),
    },
  },
  { key = ']', mods = 'CMD|CTRL',  action = act.SwitchWorkspaceRelative(1) },
  { key = '[', mods = 'CMD|CTRL',  action = act.SwitchWorkspaceRelative(-1) },

  -- Search / scrollback / quick-select
  { key = 'f', mods = 'CMD',       action = act.Search { CaseInSensitiveString = '' } },
  { key = 'f', mods = 'CMD|SHIFT', action = act.QuickSelect },
  { key = 'k', mods = 'CMD',       action = act.ClearScrollback 'ScrollbackAndViewport' },

  -- Reload config
  { key = 'r', mods = 'CMD|SHIFT', action = act.ReloadConfiguration },
}

-- ── QuickSelect: file:line[:col] across Ruby/Elixir/Zig/TS/JS ─────────────────
config.quick_select_patterns = {
  [[\b[\w./\-]+\.(rb|ex|exs|eex|heex|leex|zig|ts|tsx|js|jsx):\d+(:\d+)?\b]],
  [[[\w./\-]+\.rb:\d+]],
  [[\b[\w./\-]+\.(ex|exs|heex):\d+]],
  [[[0-9a-f]{7,40}]], -- git SHAs
}

-- ── Hyperlink rules: CMD-click stack-trace paths ──────────────────────────────
config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, {
  regex = [[\b([\w./\-]+\.(rb|ex|exs|heex|leex|zig|ts|tsx|js|jsx)):(\d+)(?::(\d+))?\b]],
  format = 'file://$1#L$3',
  highlight = 1,
})

return config
