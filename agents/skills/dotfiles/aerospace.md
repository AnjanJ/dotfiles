# AeroSpace (window manager), sketchybar, borders

Read this before changing keybindings, workspaces, window rules, the status bar or window borders.

## Files

- `~/.config/aerospace/aerospace.toml` — everything: layout defaults, `[mode.main.binding]`, `[mode.service.binding]`, `[[on-window-detected]]` rules. The block between `# DOTFILES_LAUNCHERS_START` and `# DOTFILES_LAUNCHERS_END` is written by `dotfiles webapp install` / `dotfiles tui install`; do not edit inside it by hand, and keep it above the app-wide rules because AeroSpace applies only the first matching rule
- `~/.config/aerospace/scripts/startup-apps.sh` — launches the daily app set at login (`Ctrl+Shift+R` re-runs it; `dotfiles toggle startup-apps off` disables it)
- `~/.config/aerospace/scripts/cycle-app-windows.sh`, `cycle-extra-workspaces.sh` — helpers bound to keys
- `~/.config/sketchybar/sketchybarrc`, `plugins/*.sh` — status bar; colours come from the generated `colors.sh`
- `~/.config/borders/bordersrc` — JankyBorders; colours from the generated `colors.sh`; `dotfiles toggle borders off` stops it launching

## Conventions

- Modifier scheme: `ctrl-shift-*` focus/launch/workspace, `ctrl-alt-*` move window / move to workspace, `alt-shift-*` monitors and Zen window cycling, `ctrl-shift-cmd-*` move window to monitor, `ctrl-shift-semicolon` enters service mode (`esc` reload, `r` reset layout, `f` float toggle, `k` cheatsheet).
- Workspaces 1-7 have homes: 1 Warp, 2 Zen, 3 Chrome, 4 Zed/VS Code, 5 Proton Mail, 6 Obsidian (+ Slack, Ente Auth floating), 7 Claude/ChatGPT (floating). 8-9 free, 10-12 overflow via `ctrl-shift-0` / `ctrl-alt-0`. 1Password floats on the current workspace so its Touch ID prompt is where you are looking.
- Apps land on their workspace through `[[on-window-detected]]` rules, so launcher bindings only launch. To add an app: find its id with `aerospace list-windows --all --format '%{app-bundle-id}|%{app-name}'`, add a rule, then a launcher binding.

## Editing a binding

1. Add or change the line under the right `[mode.*.binding]` table.
2. Put `# desc: …` on the line directly above when the command alone would not read well in the cheatsheet (launchers should say the workspace; scripts should say what they do). Plain commands like `focus left` need no desc.
3. `aerospace reload-config` — errors mean the TOML is broken; fix before continuing.
4. `dotfiles keys --update` — regenerates the block in `docs/KEYBINDINGS.md`; CI fails if it drifts.
5. `dotfiles keys` shows the result (fzf); `Ctrl+Shift+;` then `K` opens it in Ghostty.

## sketchybar and borders

- Never write a colour into `sketchybarrc`, a plugin, or `bordersrc`; use the exported variables (`$ACCENT_COLOR`, `$ITEM_BG_COLOR`, `$WHITE`, `$BORDERS_ACTIVE_COLOR` …) that the theme provides. Plugins must `source "$HOME/.config/sketchybar/colors.sh"` themselves; they do not inherit the bar's environment.
- Apply with `sketchybar --reload`. `sketchybar --query bar` shows the live state.
- Borders restart: `brew services restart borders` or re-login (it is launched by AeroSpace's `after-startup-command`).
