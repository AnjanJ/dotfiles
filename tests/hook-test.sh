#!/usr/bin/env bash
# ============================================
# HOOK SUITE — dotfiles hook, hook install, samples
# ============================================
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

HOOKS="$HOME/.config/dotfiles/hooks"
HOOK="$ROOT/bin/dotfiles-hook"
INSTALL="$ROOT/bin/dotfiles-hook-install"

section "samples in the repo"
for event in theme-set post-sync post-update post-install; do
    assert_succeeds "hooks/$event.d/ has a sample" bash -c "ls '$ROOT/hooks/$event.d/'*.sample >/dev/null"
done
for s in "$ROOT"/hooks/*.d/*.sample; do
    assert_succeeds "$(basename "$(dirname "$s")")/$(basename "$s") parses" bash -n "$s"
done

section "--seed"
out=$(bash "$HOOK" --seed)
n=$(find "$ROOT/hooks" -name '*.sample' | wc -l | tr -d ' ')
assert_contains "$out" "Seeded $n sample hook(s)" "every sample copied on a fresh machine"
assert_file_exists "$HOOKS/theme-set.d/notify.sample" "sample lands in the user's hook dir"
assert_perm "$HOOKS/theme-set.d/notify.sample" "755" "sample is executable"
echo "edited" > "$HOOKS/theme-set.d/notify.sample"
rm "$HOOKS/post-sync.d/log.sample"
mv "$HOOKS/post-update.d/notify.sample" "$HOOKS/post-update.d/notify"
out=$(bash "$HOOK" --seed)
assert_contains "$out" "Seeded 1 sample hook(s)" "only the deleted sample is re-seeded"
assert_eq "$(cat "$HOOKS/theme-set.d/notify.sample")" "edited" "an edited sample is not overwritten"
assert_file_not_exists "$HOOKS/post-update.d/notify.sample" "an enabled sample is not re-added"

section "samples are inert"
printf '#!/bin/bash\necho ran > "%s/ran"\n' "$HOME" > "$HOOKS/theme-set.d/notify.sample"
bash "$HOOK" theme-set aura
assert_file_not_exists "$HOME/ran" "a .sample file does not run"
# shellcheck disable=SC2016  # $1 is meant for the hook, not this shell
printf '#!/bin/bash\necho "ran $1" > "%s/ran"\n' "$HOME" > "$HOOKS/theme-set.d/10-real.sh"
bash "$HOOK" theme-set aura
assert_eq "$(cat "$HOME/ran")" "ran aura" "a real hook runs with the event's argument"

section "--list"
out=$(bash "$HOOK" --list)
assert_contains "$out" "theme-set:" "lists events"
assert_contains "$out" "$HOOKS/theme-set.d/10-real.sh" "shows installed hooks"
assert_contains "$out" "notify.sample (sample, inactive)" "marks samples"
assert_contains "$out" "$HOOKS/post-update.d/notify" "shows an enabled sample"
assert_matches "$out" "^post-sync:" "post-sync listed"

section "hook install"
printf '#!/bin/bash\necho installed > "%s/installed"\n' "$HOME" > "$HOME/mine.sh"
out=$(bash "$INSTALL" post-sync "$HOME/mine.sh")
assert_contains "$out" "Installed post-sync hook: $HOOKS/post-sync.d/mine.sh" "reports the destination"
assert_perm "$HOOKS/post-sync.d/mine.sh" "755" "installed hook is executable"
bash "$HOOK" post-sync
assert_file_exists "$HOME/installed" "installed hook runs on its event"
set +e; out=$(bash "$INSTALL" custom-thing "$HOME/mine.sh" 2>&1); rc=$?; set -e
assert_eq "$rc" "0" "an unknown event is accepted"
assert_contains "$out" "nothing in the dotfiles tooling fires 'custom-thing'" "with a warning"
set +e; out=$(bash "$INSTALL" post-sync "$HOME/nope.sh" 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "missing file refused"
set +e; out=$(bash "$INSTALL" "Bad Name" "$HOME/mine.sh" 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "bad event name refused"
set +e; out=$(bash "$INSTALL" 2>&1); rc=$?; set -e
assert_eq "$rc" "1" "no arguments is a usage error"

section "events fired by the tooling are all known"
fired=$(/usr/bin/grep -rhoE 'dotfiles-hook"? [a-z][a-z-]*' "$ROOT/bin" "$ROOT/scripts" "$ROOT/install.sh" "$ROOT/update.sh" | awk '{print $NF}' | sort -u)
for event in $fired; do
    /usr/bin/grep -q "$event" "$ROOT/bin/dotfiles-hook-install" || fail "hook install knows every fired event" "$event"
    [[ -d "$ROOT/hooks/$event.d" ]] || fail "every fired event ships a sample directory" "$event"
done
pass "every fired event is known to hook install and has a sample"
assert_contains "$fired" "post-install" "install.sh fires post-install"

section "bash 3.2"
assert_succeeds "dotfiles-hook parses under /bin/bash" /bin/bash -n "$HOOK"
assert_succeeds "hook install parses under /bin/bash" /bin/bash -n "$INSTALL"
out=$(/bin/bash "$HOOK" --list)
assert_contains "$out" "theme-set:" "--list runs under /bin/bash"
