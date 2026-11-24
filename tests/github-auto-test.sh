#!/usr/bin/env bash
# doc: GitHub remote helper — `bin/git-remote-github-auto`: HTTPS while gh has a token, SSH through the connect protocol otherwise, forced routes, GIT_SSH_COMMAND, rejected URLs and services, an offline clone and push through real git, bash 3.2

# Stub gh, git and ssh record what the helper runs; the end-to-end part uses
# real git with a stub ssh that serves a local bare repository, so nothing
# reaches GitHub, 1Password or the real gh login.
# Usage: tests/run github-auto

set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

HELPER="$ROOT/bin/git-remote-github-auto"
URL="github-auto://github.com/octo/repo.git"
STUB="$TEST_TMP/stub"
LOG="$TEST_TMP/log"
REAL_GIT="$(command -v git)"
mkdir -p "$STUB" "$LOG"

# gh: logged in or out. Logged in, it also swallows any stdin it is given,
# so a helper that forgot </dev/null would lose git's conversation.
cat > "$STUB/gh-in" <<'EOF'
#!/bin/sh
cat > /dev/null
echo "gho_stub"
EOF
cat > "$STUB/gh-out" <<'EOF'
#!/bin/sh
exit 1
EOF
# git: record `remote-https` calls and the stdin they get; pass the rest on.
cat > "$STUB/git" <<EOF
#!/bin/sh
if [ "\$1" = remote-https ]; then
    echo "\$*" > "$LOG/https-args"
    cat > "$LOG/https-stdin"
    exit 0
fi
exec "$REAL_GIT" "\$@"
EOF
# ssh: record its arguments.
cat > "$STUB/ssh" <<EOF
#!/bin/sh
printf '%s|' "\$@" > "$LOG/ssh-args"
EOF
cp "$STUB/ssh" "$STUB/altssh"
sed -i '' "s|ssh-args|altssh-args|" "$STUB/altssh"
chmod +x "$STUB"/*

export PATH="$STUB:$PATH"
unset GITHUB_AUTO_ROUTE GITHUB_AUTO_DEBUG GIT_SSH_COMMAND 2>/dev/null || true

reset_logs() { rm -f "$LOG"/*; }
run_helper() { # <stdin text> [helper args...]; output in $out, status in $rc
    local input="$1"
    shift
    set +e
    out=$(printf '%b' "$input" | "$HELPER" "$@" 2>&1)
    rc=$?
    set -e
}

# ── HTTPS while gh has a token ───────────────
reset_logs
GITHUB_AUTO_GH="$STUB/gh-in" run_helper 'capabilities\n\n' origin "$URL"
assert_eq "$rc" 0 "gh logged in: exits 0"
assert_eq "$(cat "$LOG/https-args")" "remote-https origin https://github.com/octo/repo.git" "gh logged in: hands over to git remote-https with the HTTPS URL"
assert_file_contains "$LOG/https-stdin" "capabilities" "gh logged in: git's conversation reaches git-remote-https untouched"
assert_file_not_exists "$LOG/ssh-args" "gh logged in: ssh is never run"

# ── SSH when gh has no token ─────────────────
reset_logs
GITHUB_AUTO_GH="$STUB/gh-out" run_helper 'capabilities\nconnect git-upload-pack\n' origin "$URL"
assert_eq "$rc" 0 "gh logged out: exits 0"
assert_eq "$out" "connect" "gh logged out: advertises connect, then confirms it with a blank line"
assert_eq "$(cat "$LOG/ssh-args")" "git@github.com|git-upload-pack 'octo/repo.git'|" "gh logged out: runs the same ssh command git runs for an SSH remote"
assert_file_not_exists "$LOG/https-args" "gh logged out: HTTPS is never tried"

reset_logs
GITHUB_AUTO_GH="$STUB/gh-out" run_helper 'capabilities\nconnect git-receive-pack\n' origin "$URL"
assert_eq "$(cat "$LOG/ssh-args")" "git@github.com|git-receive-pack 'octo/repo.git'|" "gh logged out: a push asks ssh for git-receive-pack"

reset_logs
GITHUB_AUTO_GH="$TEST_TMP/no-such-gh" run_helper 'capabilities\nconnect git-upload-pack\n' origin "$URL"
assert_file_exists "$LOG/ssh-args" "gh not installed: falls back to ssh"

# ── Forced routes and debug output ───────────
reset_logs
GITHUB_AUTO_GH="$STUB/gh-in" GITHUB_AUTO_ROUTE=ssh run_helper 'capabilities\nconnect git-upload-pack\n' origin "$URL"
assert_file_exists "$LOG/ssh-args" "GITHUB_AUTO_ROUTE=ssh uses ssh even with gh logged in"

reset_logs
GITHUB_AUTO_GH="$STUB/gh-out" GITHUB_AUTO_ROUTE=https run_helper '' origin "$URL"
assert_file_exists "$LOG/https-args" "GITHUB_AUTO_ROUTE=https uses HTTPS even with gh logged out"

GITHUB_AUTO_ROUTE=ftp run_helper '' origin "$URL"
assert_eq "$rc" 1 "an unknown GITHUB_AUTO_ROUTE is refused"
assert_contains "$out" "must be https or ssh" "the refusal names the allowed routes"

reset_logs
GITHUB_AUTO_GH="$STUB/gh-out" GITHUB_AUTO_DEBUG=1 run_helper '' origin "$URL"
assert_contains "$out" "git-remote-github-auto: ssh for octo/repo.git" "GITHUB_AUTO_DEBUG reports the route taken"

# ── The ssh command, as git would choose it ──
reset_logs
GITHUB_AUTO_GH="$STUB/gh-out" GIT_SSH_COMMAND="$STUB/altssh -o BatchMode=yes" run_helper 'capabilities\nconnect git-upload-pack\n' origin "$URL"
assert_eq "$(cat "$LOG/altssh-args")" "-o|BatchMode=yes|git@github.com|git-upload-pack 'octo/repo.git'|" "GIT_SSH_COMMAND, with its options, replaces ssh"

reset_logs
cfg_repo="$TEST_TMP/cfg-repo"
"$REAL_GIT" init -q "$cfg_repo"
"$REAL_GIT" -C "$cfg_repo" config core.sshCommand "$STUB/altssh"
(cd "$cfg_repo" && GITHUB_AUTO_GH="$STUB/gh-out" run_helper 'capabilities\nconnect git-upload-pack\n' origin "$URL")
assert_file_exists "$LOG/altssh-args" "core.sshCommand replaces ssh when GIT_SSH_COMMAND is unset"

# ── What it refuses ──────────────────────────
run_helper '' origin
assert_eq "$rc" 1 "a missing URL argument is refused"

run_helper '' origin "github-auto://example.com/octo/repo.git"
assert_eq "$rc" 1 "a host other than github.com is refused"
assert_contains "$out" "unsupported URL" "the refusal names the URL problem"

for bad in "octo/re'po" "octo/repo/extra" "octo" "oc to/repo" "octo/repo;rm"; do
    run_helper '' origin "github-auto://github.com/$bad"
    assert_eq "$rc" 1 "repository path '$bad' is refused before anything runs"
done

reset_logs
GITHUB_AUTO_GH="$STUB/gh-out" run_helper 'capabilities\nconnect git-evil\n' origin "$URL"
assert_eq "$rc" 1 "an unknown service is refused"
assert_file_not_exists "$LOG/ssh-args" "an unknown service never reaches ssh"

GITHUB_AUTO_GH="$STUB/gh-out" run_helper 'list\n' origin "$URL"
assert_eq "$rc" 1 "a remote-helper command other than capabilities and connect is refused"

reset_logs
GITHUB_AUTO_GH="$STUB/gh-out" run_helper '\n' origin "$URL"
assert_eq "$rc" 0 "a blank line from git ends the helper cleanly"
assert_file_not_exists "$LOG/ssh-args" "ending without connect runs nothing"

# ── End to end through real git, offline ─────
# A stub ssh that serves $SERVER the way GitHub's SSH endpoint does.
SERVER="$TEST_TMP/server"
mkdir -p "$SERVER/octo"
"$REAL_GIT" init -q --bare "$SERVER/octo/repo.git"
seed="$TEST_TMP/seed"
"$REAL_GIT" init -q -b main "$seed"
"$REAL_GIT" -C "$seed" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false commit -q --allow-empty -m seed
"$REAL_GIT" -C "$seed" push -q "$SERVER/octo/repo.git" main
"$REAL_GIT" -C "$SERVER/octo/repo.git" symbolic-ref HEAD refs/heads/main
cat > "$STUB/fakessh" <<EOF
#!/bin/sh
# \$1 = git@github.com, \$2 = "<service> '<owner>/<repo>'"
service=\${2%% *}
repo=\$(printf '%s' "\${2#* }" | tr -d "'")
exec "$REAL_GIT" "\${service#git-}" "$SERVER/\$repo"
EOF
chmod +x "$STUB/fakessh"

e2e() { # real git, helper on PATH, gh logged out, stub ssh
    GITHUB_AUTO_GH="$STUB/gh-out" GIT_SSH_COMMAND="$STUB/fakessh" \
        PATH="$ROOT/bin:$PATH" "$REAL_GIT" \
        -c url.github-auto://github.com/.insteadOf=git@github.com: \
        -c protocol.github-auto.allow=always "$@"
}
clone="$TEST_TMP/clone"
assert_succeeds "real git clones git@github.com:octo/repo.git through the helper" e2e clone -q git@github.com:octo/repo.git "$clone"
assert_eq "$("$REAL_GIT" -C "$clone" log -1 --format=%s)" "seed" "the clone holds the server's commit"
assert_eq "$("$REAL_GIT" -C "$clone" remote get-url origin)" "git@github.com:octo/repo.git" "the remote keeps its SSH address"
"$REAL_GIT" -C "$clone" -c user.name=t -c user.email=t@example.com -c commit.gpgsign=false commit -q --allow-empty -m pushed
assert_succeeds "real git pushes through the helper" e2e -C "$clone" push -q origin main
assert_eq "$("$REAL_GIT" -C "$SERVER/octo/repo.git" log -1 --format=%s main)" "pushed" "the pushed commit reached the server"

# ── Stock macOS bash ─────────────────────────
if [[ -x /bin/bash ]]; then
    reset_logs
    set +e
    out=$(printf 'capabilities\nconnect git-upload-pack\n' | GITHUB_AUTO_GH="$STUB/gh-out" /bin/bash "$HELPER" origin "$URL" 2>&1)
    rc=$?
    set -e
    assert_eq "$rc" 0 "runs under /bin/bash $("/bin/bash" -c 'echo $BASH_VERSION')"
    assert_file_exists "$LOG/ssh-args" "the ssh route works under /bin/bash"
fi

