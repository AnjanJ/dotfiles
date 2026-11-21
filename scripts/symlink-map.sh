#!/usr/bin/env bash
# ============================================
# SYMLINK MAP — single source of truth
# ============================================
# Every symlink this repo manages, in one place. Before this file
# existed, five scripts each carried their own copy of this list
# (install.sh, update.sh, dotfiles-sync, dotfiles-doctor,
# health-check.sh) and they drifted apart — new bin/ scripts and
# config files were silently missing from some of them.
#
# To add a managed file: add ONE entry here. Install, update, sync,
# doctor, and health all pick it up automatically.
#
# Requires: DOTFILES_DIR set before sourcing.
# Bash 3.2 compatible (macOS stock bash) — no associative arrays.
#
# Entry format: "<repo-relative source>:<absolute target>"
# Entries whose source doesn't exist in the repo are skipped,
# so optional files need no guards at the call sites.

DOTFILES_LINKS=(
    # Shell configuration
    ".zshrc:$HOME/.zshrc"
    ".zshrc-terminal-enhancements:$HOME/.zshrc-terminal-enhancements"
    ".zshrc-dhh-additions:$HOME/.zshrc-dhh-additions"
    ".zshrc-elixir-additions:$HOME/.zshrc-elixir-additions"
    ".zshrc-work-completions:$HOME/.zshrc-work-completions"

    # Loose home-directory dotfiles
    # .gitconfig carries identity, delta pager wiring, rerere and the gh
    # credential helpers -- worth versioning so a rebuilt machine keeps them.
    ".gitconfig:$HOME/.gitconfig"
    ".gitignore_global:$HOME/.gitignore_global"
    ".rubocop.yml:$HOME/.rubocop.yml"
    # wezterm lives under .config/wezterm/ but wezterm reads ~/.wezterm.lua first
    ".config/wezterm/wezterm.lua:$HOME/.wezterm.lua"

    # Whole config directories
    ".config/aerospace:$HOME/.config/aerospace"
    ".config/ghostty:$HOME/.config/ghostty"
    ".config/nvim:$HOME/.config/nvim"
    ".config/zellij:$HOME/.config/zellij"
    ".config/lazygit:$HOME/.config/lazygit"
    ".config/borders:$HOME/.config/borders"
    ".config/sketchybar:$HOME/.config/sketchybar"

    # Single config files (starship.toml is not here: it is rendered per
    # theme from themes/_templates/starship.toml.tpl and read via $STARSHIP_CONFIG)
    ".config/mise/config.toml:$HOME/.config/mise/config.toml"
    ".config/zed/settings.json:$HOME/.config/zed/settings.json"
    ".config/zed/tasks.json:$HOME/.config/zed/tasks.json"

    # VS Code (lives under ~/Library/Application Support/Code/User — note
    # the space in the path; each entry is a single quoted string so the
    # target survives word-splitting)
    ".config/vscode/settings.json:$HOME/Library/Application Support/Code/User/settings.json"
    ".config/vscode/keybindings.json:$HOME/Library/Application Support/Code/User/keybindings.json"

    # AI layer. Global Claude Code config (permissions, hooks, enabled
    # plugins, statusline) — NOT the repo's own .claude/, which is
    # project-scoped context. Secrets (API keys) are stored elsewhere by
    # each tool, never in these files. The llm default-model preference
    # lives beside llm's machine state (logs.db etc.), so only the one
    # file is linked, not the directory.
    ".config/claude/settings.json:$HOME/.claude/settings.json"
    ".config/claude/CLAUDE.md:$HOME/.claude/CLAUDE.md"
    ".config/claude/statusline-command.sh:$HOME/.claude/statusline-command.sh"
    ".config/claude/handoff-check.sh:$HOME/.claude/handoff-check.sh"
    # The end-user skill: how to manage this machine, for Claude Code (agents/skills/dotfiles/SKILL.md)
    "agents/skills/dotfiles:$HOME/.claude/skills/dotfiles"
    ".config/llm/default_model.txt:$HOME/Library/Application Support/io.datasette.llm/default_model.txt"
)

# Directories whose contents are linked file-by-file into the target
# directory (so ~/bin stays a real directory that can hold non-dotfiles
# entries too).
DOTFILES_LINK_DIRS=(
    "bin:$HOME/bin"
    ".config/zed/snippets:$HOME/.config/zed/snippets"
)

# Links made only when the agent that reads them is set up on this
# machine (its config directory, the target's grandparent, exists), so a
# machine without Codex never grows a ~/.codex. The Claude link above is
# unconditional because Claude Code is this repo's default agent.
DOTFILES_OPTIONAL_LINKS=(
    "agents/skills/dotfiles:$HOME/.agents/skills/dotfiles"
    "agents/skills/dotfiles:$HOME/.codex/skills/dotfiles"
    "agents/skills/dotfiles:$HOME/.gemini/config/skills/dotfiles"
)

# dotfiles_for_each_link <callback>
#
# Invokes: <callback> <absolute source> <absolute target> <display name>
# once per managed link whose source exists in the repo (and, for the
# optional links, whose agent directory exists). Pure iteration —
# no mkdir/ln side effects here, so checkers can use it without mutating
# anything; fixer callbacks create parent directories themselves.
# dotfiles_link <source> <target>
# Points <target> at <source> the one safe way, for install, update and
# sync alike. A real file or directory at the target is backed up
# (backup_if_needed, from scripts/_helpers.sh, which callers source) and
# removed first: `ln -sf` over a directory would nest the link inside it,
# and over a file would discard it. -n keeps a symlink to a directory from
# being followed for the same reason. Sets DOTFILES_LINK_RESULT to
# "current" (already right), "linked", or "replaced" (a real file or
# directory was backed up and replaced).
# shellcheck disable=SC2034  # DOTFILES_LINK_RESULT is read by the caller
dotfiles_link() {
    local source="$1" target="$2"
    if [[ -L "$target" && "$(readlink "$target")" == "$source" ]]; then
        DOTFILES_LINK_RESULT=current
        return 0
    fi
    DOTFILES_LINK_RESULT=linked
    if [[ -e "$target" && ! -L "$target" ]]; then
        backup_if_needed "$target"
        rm -rf "$target"
        DOTFILES_LINK_RESULT=replaced
    fi
    mkdir -p "$(dirname "$target")"
    ln -sfn "$source" "$target"
}

dotfiles_for_each_link() {
    local _cb="$1" _entry _name _src _dst _dir _file
    for _entry in "${DOTFILES_LINKS[@]}"; do
        _name="${_entry%%:*}"
        _src="$DOTFILES_DIR/$_name"
        _dst="${_entry#*:}"
        [ -e "$_src" ] || continue
        "$_cb" "$_src" "$_dst" "$_name"
    done
    for _entry in "${DOTFILES_OPTIONAL_LINKS[@]}"; do
        _name="${_entry%%:*}"
        _src="$DOTFILES_DIR/$_name"
        _dst="${_entry#*:}"
        [ -e "$_src" ] || continue
        [ -d "$(dirname "$(dirname "$_dst")")" ] || continue
        "$_cb" "$_src" "$_dst" "$_name -> ${_dst#"$HOME"/}"
    done
    for _entry in "${DOTFILES_LINK_DIRS[@]}"; do
        _dir="${_entry%%:*}"
        _dst="${_entry#*:}"
        [ -d "$DOTFILES_DIR/$_dir" ] || continue
        for _file in "$DOTFILES_DIR/$_dir"/*; do
            [ -e "$_file" ] || continue
            "$_cb" "$_file" "$_dst/$(basename "$_file")" "$_dir/$(basename "$_file")"
        done
    done
}
