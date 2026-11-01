#!/usr/bin/env bash
# Claude Code Stop hook: offer a handoff prompt once context reaches 45%.
#
# Hooks are not told how full the context is, but the status line is, so
# statusline-command.sh records the percentage per session and this reads
# it. The status line can lag by a turn, which only delays the offer. The
# percentage is of the model's full window, the number the status line shows.
#
# Nothing is recorded in `claude -p`, so print runs never see this.
set -euo pipefail

THRESHOLD=45

session=$(jq -r '.session_id // empty' | tr -cd 'A-Za-z0-9_-')
[[ -n "$session" ]] || exit 0

state="${TMPDIR:-/tmp}/claude-handoff"
pct=$(cat "$state/$session.pct" 2>/dev/null || true)
[[ "$pct" =~ ^[0-9]+$ ]] || exit 0

offered="$state/$session.offered"
if ((pct < THRESHOLD)); then
    # Compaction brought usage back down, so the next crossing is a new offer.
    rm -f "$offered"
    exit 0
fi
[[ -e "$offered" ]] && exit 0
: >"$offered"

read -r -d '' message <<EOF || true
Context is at ${pct}%. Ask the user yes or no: should you write a handoff prompt so the work can continue in a fresh session? Use AskUserQuestion. Write nothing else about the handoff until they answer, and do not stop or pause the work on your own.

No: carry on normally and do not raise it again.

Yes: first check the real state (git status, branch, running jobs) instead of relying on memory, then reply with one fenced code block the user can paste as the first message of a new session. It has to stand alone, for a reader who knows nothing about this session, and carry the context and the subtext:
- The goal, in the user's own words, and why it matters to them.
- Current state: repo, branch, uncommitted changes, what is done and how it was verified, what is half done.
- Decisions made and why, including options rejected and why, so they are not reopened.
- The user's preferences, constraints and corrections from this session, and any tone or concern they expressed.
- What was tried and failed, with the exact error, so it is not retried.
- Key files with line numbers, commands, and any facts that were expensive to find.
- What was only assumed or never verified, labelled as such.
- Approvals given this session, labelled as past ones: the new session must ask again before doing anything risky.
- The single next step, then the open questions.

Leave out secrets and credentials. Below the block, tell the user what the block does not cover.
EOF

jq -n --arg context "$message" \
    '{hookSpecificOutput:{hookEventName:"Stop",additionalContext:$context}}'
