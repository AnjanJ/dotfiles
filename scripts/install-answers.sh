#!/usr/bin/env bash

# ============================================
# INSTALL ANSWERS FILE
# ============================================
# Sourced by install.sh — not meant to be run directly, no `set -e`.
#
# A JSON file answers the installer's questions so a machine can be
# set up unattended without a long flag list (Omarchy's
# user_configuration.json is the model). Precedence, highest first:
# flags, DOTFILES_* environment variables, the answers file, defaults.
# The file is used when --answers <file> or DOTFILES_ANSWERS names it,
# or when ~/.dotfiles-answers.json exists.
#
#   {
#     "name": "AJ",                 -> --name
#     "email": "aj@example.com",    -> --email
#     "work_email": "aj@work.com",  -> --work-email
#     "work_dir": "~/work/code",    -> --work-dir
#     "theme": "tokyo-night",       -> --theme
#     "ssh": "1password",           -> --ssh
#     "groups": ["core", "editors"],-> --groups (a comma string works too)
#     "macos_defaults": false,      -> --no-macos-defaults
#     "runtimes": false             -> --no-runtimes
#   }
#
# Reads JSON with plutil (macOS 12+), python3 when plutil cannot. Runs
# under /bin/bash 3.2 because install.sh does.
# ============================================

INSTALL_ANSWERS_KEYS="name email work_email work_dir theme ssh groups macos_defaults runtimes"

# _answers_get <file> <key> — prints a scalar value (booleans as
# true/false); nothing and exit 1 when the key is absent. Arrays go
# through _answers_array (plutil's raw form of an array is its length).
_answers_get() {
    local file="$1" key="$2" out
    if command -v plutil >/dev/null 2>&1; then
        out=$(plutil -extract "$key" raw -o - "$file" 2>/dev/null) || return 1
        printf '%s' "$out"
        return 0
    fi
    if command -v python3 >/dev/null 2>&1; then
        python3 - "$file" "$key" <<'EOF_PY'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(2)
v = data.get(sys.argv[2])
if v is None:
    sys.exit(1)
if isinstance(v, bool):
    print("true" if v else "false", end="")
elif isinstance(v, list):
    print(",".join(str(x) for x in v), end="")
else:
    print(v, end="")
EOF_PY
        return $?
    fi
    return 1
}

# _answers_array <file> <key> — join a JSON array with commas (plutil's
# raw form of an array is its element count, so walk the indexes)
_answers_array() {
    local file="$1" key="$2" n i el joined=""
    n=$(plutil -extract "$key" raw -o - "$file" 2>/dev/null) || return 1
    [[ "$n" =~ ^[0-9]+$ ]] || { printf '%s' "$n"; return 0; }
    i=0
    while [[ $i -lt $n ]]; do
        el=$(plutil -extract "$key.$i" raw -o - "$file" 2>/dev/null) || break
        joined="${joined:+$joined,}$el"
        i=$((i + 1))
    done
    printf '%s' "$joined"
}

# _answers_keys <file> — the file's top-level keys, one per line (python3
# only; used for the unknown-key warning and skipped without it)
_answers_keys() {
    command -v python3 >/dev/null 2>&1 || return 0
    python3 -c 'import json,sys; [print(k) for k in json.load(open(sys.argv[1])).keys()]' "$1" 2>/dev/null
}

# _answers_valid <file> — 0 when the file parses as JSON (plutil -lint
# only accepts property lists; a conversion to /dev/null does parse JSON)
_answers_valid() {
    local file="$1"
    if command -v plutil >/dev/null 2>&1; then
        plutil -convert json -o /dev/null "$file" >/dev/null 2>&1
        return $?
    fi
    python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$file" >/dev/null 2>&1
}

# install_answers_load <file>
# Fills GIT_NAME, GIT_EMAIL, GIT_WORK_EMAIL, WORK_DIR, SELECTED_THEME,
# SSH_MODE, SELECTED_GROUPS when they are still empty, and turns
# APPLY_MACOS_DEFAULTS / INSTALL_RUNTIMES off when the file says false.
# Prints what it applied; returns 1 on a missing or invalid file.
install_answers_load() {
    local file="$1" v applied="" k known
    if [[ ! -f "$file" ]]; then
        echo "Answers file not found: $file" >&2
        return 1
    fi
    if ! _answers_valid "$file"; then
        echo "Answers file is not valid JSON: $file" >&2
        return 1
    fi

    _answers_apply_string() {
        # $1 json key, $2 variable name
        local val
        [[ -z "${!2:-}" ]] || return 0
        if [[ "$1" == "groups" ]] && command -v plutil >/dev/null 2>&1; then
            val=$(_answers_array "$file" "$1") || return 0
        else
            val=$(_answers_get "$file" "$1") || return 0
        fi
        [[ -n "$val" ]] || return 0
        printf -v "$2" '%s' "$val"
        applied="${applied:+$applied, }$1"
    }
    _answers_apply_string name GIT_NAME
    _answers_apply_string email GIT_EMAIL
    _answers_apply_string work_email GIT_WORK_EMAIL
    _answers_apply_string work_dir WORK_DIR
    _answers_apply_string theme SELECTED_THEME
    _answers_apply_string ssh SSH_MODE
    _answers_apply_string groups SELECTED_GROUPS

    # shellcheck disable=SC2034  # both are install.sh's own switches
    if v=$(_answers_get "$file" macos_defaults) && [[ "$v" == "false" || "$v" == "0" ]]; then
        APPLY_MACOS_DEFAULTS=false
        applied="${applied:+$applied, }macos_defaults=false"
    fi
    # shellcheck disable=SC2034
    if v=$(_answers_get "$file" runtimes) && [[ "$v" == "false" || "$v" == "0" ]]; then
        INSTALL_RUNTIMES=false
        applied="${applied:+$applied, }runtimes=false"
    fi

    for k in $(_answers_keys "$file"); do
        known=false
        case " $INSTALL_ANSWERS_KEYS " in *" $k "*) known=true ;; esac
        [[ "$known" == true ]] || echo "Warning: unknown key '$k' in $file (known: $INSTALL_ANSWERS_KEYS)" >&2
    done

    echo "Answers from $file: ${applied:-nothing new (flags or environment already set everything)}"
    return 0
}
