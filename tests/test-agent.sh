#!/usr/bin/env bash

# ============================================
# DEFAULT AGENT + SKILL TEST SUITE
# ============================================
# Tests bin/dotfiles-default-agent (state file, launch commands,
# validation) and that the shipped skill is complete and mapped.
# Usage: bash tests/test-agent.sh
# ============================================

set -euo pipefail

REAL_DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
A="$REAL_DOTFILES_DIR/bin/dotfiles-default-agent"

PASS=0
FAIL=0
FAILURES=()
pass() { PASS=$((PASS + 1)); echo -e "  \033[0;32m✓\033[0m $1"; }
fail() { FAIL=$((FAIL + 1)); FAILURES+=("$1"); echo -e "  \033[0;31m✗\033[0m $1"; }
assert_eq() {
    local actual="$1" expected="$2" label="$3"
    if [[ "$actual" == "$expected" ]]; then pass "$label"; else fail "$label (expected '$expected', got '$actual')"; fi
}

STATE=$(mktemp -d)
trap 'rm -rf "$STATE"' EXIT
export DOTFILES_STATE_DIR="$STATE"

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║   Default Agent + Skill Tests                             ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

echo "Test 1: Default and launch commands"
assert_eq "$("$A")" "claude" "default is claude"
assert_eq "$("$A" --command)" "claude --permission-mode auto" "claude launches with a scoped permission mode"
if "$A" --command | /usr/bin/grep -q "dangerously"; then fail "default command skips permissions"; else pass "no --dangerously-skip-permissions in the default"; fi
echo ""

echo "Test 2: Set, persist, list"
out=$("$A" gemini)
assert_eq "$("$A")" "gemini" "set to gemini"
assert_eq "$(cat "$STATE/default-agent")" "gemini" "persisted in state dir"
assert_eq "$("$A" --command)" "gemini --approval-mode auto_edit" "gemini launch command"
out=$("$A" --list)
if echo "$out" | /usr/bin/grep -q "^ \* gemini"; then pass "--list marks the current agent"; else fail "--list does not mark gemini"; fi
"$A" claude >/dev/null
assert_eq "$("$A")" "claude" "set back to claude"
echo ""

echo "Test 3: Validation"
set +e; "$A" skynet >/dev/null 2>&1; rc=$?; set -e
assert_eq "$rc" "1" "unknown agent rejected"
assert_eq "$("$A")" "claude" "state unchanged after rejection"
set +e; /bin/bash "$A" --command >/dev/null; rc=$?; set -e
assert_eq "$rc" "0" "runs under /bin/bash 3.2"
echo ""

echo "Test 4: Skill is complete and mapped"
for f in SKILL.md theming.md aerospace.md commands.md; do
    if [[ -f "$REAL_DOTFILES_DIR/agents/skills/dotfiles/$f" ]]; then pass "agents/skills/dotfiles/$f present"; else fail "missing agents/skills/dotfiles/$f"; fi
done
if head -3 "$REAL_DOTFILES_DIR/agents/skills/dotfiles/SKILL.md" | /usr/bin/grep -q "^name: dotfiles"; then pass "SKILL.md has frontmatter name"; else fail "SKILL.md frontmatter missing"; fi
# shellcheck disable=SC2016  # literal $HOME in the map entry
if /usr/bin/grep -qF 'agents/skills/dotfiles:$HOME/.claude/skills/dotfiles' "$REAL_DOTFILES_DIR/scripts/symlink-map.sh"; then pass "skill is in the symlink map"; else fail "skill not in symlink map"; fi
if [[ "$(cat "$REAL_DOTFILES_DIR/CLAUDE.md")" == "@AGENTS.md" ]]; then pass "CLAUDE.md points at AGENTS.md"; else fail "CLAUDE.md should contain @AGENTS.md"; fi
if /usr/bin/grep -q -- '--permission-mode auto' "$REAL_DOTFILES_DIR/.zshrc" && ! /usr/bin/grep -qE '^ *--dangerously-skip-permissions' "$REAL_DOTFILES_DIR/.zshrc"; then pass "oclaude uses --permission-mode auto"; else fail "oclaude still skips permissions"; fi
echo ""

echo "════════════════════════════════════════════════════════════"
echo -e "  \033[0;32mPassed: $PASS\033[0m  |  \033[0;31mFailed: $FAIL\033[0m"
echo "════════════════════════════════════════════════════════════"
if [[ ${#FAILURES[@]} -gt 0 ]]; then
    echo ""
    for f in "${FAILURES[@]}"; do echo -e "    \033[0;31m✗\033[0m $f"; done
fi
echo ""
[[ $FAIL -eq 0 ]]
