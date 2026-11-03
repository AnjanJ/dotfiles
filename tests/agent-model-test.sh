#!/usr/bin/env bash

# ============================================
# AGENT MODEL TEST SUITE
# ============================================
# Tests bin/dotfiles-agent-model against a fake ollama (never the real
# server or a real download): the rebuilt model uses the qwen3.5 renderer,
# starts from the weight blobs and inherits no generated template or
# "<think>" stop, the hf.co import name is removed, a second run does
# nothing, and the script parses under bash 3.2.
# Usage: tests/run agent-model   (or /opt/homebrew/bin/bash tests/agent-model-test.sh)
# ============================================

set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/base-test.sh"

T="$ROOT/bin/dotfiles-agent-model"

section "syntax"
/bin/bash -n "$T" || fail "agent model builder parses under /bin/bash 3.2"
pass "agent model builder parses under /bin/bash 3.2"

section "options"
out=$(bash "$T" --help 2>&1) || fail "--help exits 0"
assert_contains "$out" "qwen3.6-35b-a3b:iq4xs" "--help names the model it builds"
rc=0; bash "$T" --bogus >/dev/null 2>&1 || rc=$?
assert_eq "$rc" 2 "an unknown option exits 2"

section "rebuild with a fake ollama"
# Models "exist" as files under $FAKE_OLLAMA/models; every call is logged.
export FAKE_OLLAMA="$TEST_TMP/fake-ollama"
mkdir -p "$FAKE_OLLAMA/bin" "$FAKE_OLLAMA/models"
cat > "$FAKE_OLLAMA/bin/ollama" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
store="$FAKE_OLLAMA/models"
key() { printf '%s' "$1" | tr '/:' '__'; }
echo "$*" >> "$FAKE_OLLAMA/calls"
case "$1" in
    pull) printf 'FROM /blobs/weights\nFROM /blobs/projector\nTEMPLATE "{{ if .Prompt }} .Prompt }}"\nPARAMETER stop <think>\n' > "$store/$(key "$2")" ;;
    show) [[ -f "$store/$(key "$3")" ]] && cat "$store/$(key "$3")" ;;
    create) cp "$4" "$store/$(key "$2")" ;;
    rm) rm "$store/$(key "$2")" ;;
esac
FAKE
chmod +x "$FAKE_OLLAMA/bin/ollama"
out=$(PATH="$FAKE_OLLAMA/bin:$PATH" bash "$T" 2>&1) || fail "model builder succeeds" "$out"
pass "model builder succeeds"
built="$FAKE_OLLAMA/models/qwen3.6-35b-a3b_iq4xs"
assert_file_contains "$built" "RENDERER qwen3.5" "rebuilt model uses the qwen3.5 renderer"
assert_file_contains "$built" "FROM /blobs/weights" "rebuilt model starts from the weight blobs"
if grep -q "think\|TEMPLATE" "$built"; then
    fail "rebuilt model inherits no template or <think> stop"
fi
pass "rebuilt model inherits no template or <think> stop"
if [[ -f "$FAKE_OLLAMA/models/hf.co_unsloth_Qwen3.6-35B-A3B-GGUF_UD-IQ4_XS" ]]; then
    fail "import name is removed after the rebuild"
fi
pass "import name is removed after the rebuild"
out=$(PATH="$FAKE_OLLAMA/bin:$PATH" bash "$T" 2>&1)
assert_contains "$out" "already built" "a second run does nothing"
calls_before=$(wc -l < "$FAKE_OLLAMA/calls")
out=$(PATH="$FAKE_OLLAMA/bin:$PATH" bash "$T" --force --keep-import 2>&1) || fail "--force rebuilds" "$out"
assert_contains "$(tail -n +"$((calls_before + 1))" "$FAKE_OLLAMA/calls")" "create qwen3.6-35b-a3b:iq4xs" "--force rebuilds"
[[ -f "$FAKE_OLLAMA/models/hf.co_unsloth_Qwen3.6-35B-A3B-GGUF_UD-IQ4_XS" ]] || fail "--keep-import keeps the import name"
pass "--keep-import keeps the import name"
