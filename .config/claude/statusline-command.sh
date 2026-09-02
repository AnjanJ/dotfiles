#!/bin/bash
# Claude Code status line
# Theme: Aura (matches ~/.config/starship.toml)
#   purple #a277ff | cyan #82e2ff | yellow #ffca85 | green #61ffca
# Colors are dimmed since the status line is rendered dim by the terminal.

input=$(cat)

# --- Aura palette (approx 256-color codes) ---
PURPLE=$'\033[38;5;141m'
CYAN=$'\033[38;5;117m'
YELLOW=$'\033[38;5;222m'
GREEN=$'\033[38;5;121m'
RESET=$'\033[0m'

# --- Directory (cyan) ---
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // .cwd')
dir_display=$(basename "$current_dir")
[ "$current_dir" = "$HOME" ] && dir_display="~"

# --- Git branch (purple), skip optional locks for speed/safety ---
git_branch=""
if git -C "$current_dir" --no-optional-locks rev-parse --is-inside-work-tree &>/dev/null; then
  branch=$(git -C "$current_dir" --no-optional-locks branch --show-current 2>/dev/null)
  if [ -z "$branch" ]; then
    branch=$(git -C "$current_dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null)
  fi
  [ -n "$branch" ] && git_branch="${branch}"
fi

# --- Model name (yellow) ---
model_name=$(echo "$input" | jq -r '.model.display_name // empty')

# --- Context / token usage (green) ---
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
context_display=""
if [ -n "$used_pct" ]; then
  context_display=$(printf '%.0f%% ctx' "$used_pct")
fi

# --- Assemble ---
parts=()
parts+=("${CYAN}${dir_display}${RESET}")
[ -n "$git_branch" ] && parts+=("${PURPLE} ${git_branch}${RESET}")
[ -n "$model_name" ] && parts+=("${YELLOW}${model_name}${RESET}")
[ -n "$context_display" ] && parts+=("${GREEN}${context_display}${RESET}")

out=""
for i in "${!parts[@]}"; do
  if [ "$i" -eq 0 ]; then
    out="${parts[$i]}"
  else
    out="${out} ${PURPLE}|${RESET} ${parts[$i]}"
  fi
done

printf '%s' "$out"
