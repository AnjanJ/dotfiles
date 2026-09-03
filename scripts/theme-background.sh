#!/usr/bin/env bash

# ============================================
# THEME BACKGROUNDS
# ============================================
# Desktop pictures that follow the theme. Sourced by apply-theme.sh and
# bin/dotfiles-theme-bg; not meant to be run directly, no `set -e`.
#
# Sources, in cycling order:
#   themes/<name>/backgrounds/*             tracked images (optional)
#   ~/.config/dotfiles/backgrounds/<name>/* your own, never committed
#   ~/.local/state/dotfiles/current/theme/background.png
#       a gradient generated from the palette at apply time, so every
#       theme has a matching desktop without a binary in git
#
# ~/.local/state/dotfiles/current/background is a symlink to the one in
# use. Setting the picture goes through `desktoppr` (Brewfile, no
# permission dialog) or System Events via osascript under a 5s watchdog
# (macOS asks once to allow Automation). `dotfiles toggle background off`
# or DOTFILES_NO_BACKGROUND=1 keeps the desktop alone; the link is still
# recorded so `next` keeps cycling.
#
# Pure bash 3.2 + awk + sips (ships with macOS).
# ============================================

THEME_BG_STATE_DIR="${DOTFILES_STATE_DIR:-$HOME/.local/state/dotfiles}"
THEME_BG_LINK="$THEME_BG_STATE_DIR/current/background"
THEME_BG_USER_DIR="${DOTFILES_BACKGROUNDS_DIR:-$HOME/.config/dotfiles/backgrounds}"

# theme_background_generate <colors.toml> <out.png> [vars-file]
# Four palette corners (background, an accent tint, the darker step and
# its tint) on a 32x20 grid, upscaled by sips with smoothing to a
# 2560x1600 PNG. The tiny source is an uncompressed TGA written with
# printf: 18 header bytes then BGR triples.
theme_background_generate() {
    local colors="$1" out="$2" vars="${3:-}"
    local tpl corners tga w=32 h=20
    [[ -f "$colors" ]] || return 1
    command -v sips >/dev/null 2>&1 || return 1
    tpl=$(mktemp "${TMPDIR:-/tmp}/dotfiles-bg.XXXXXX")
    printf '{{ background }} {{ mix background accent 14%% }} {{ darker_background }} {{ mix darker_background accent 22%% }}' > "$tpl"
    corners=$(theme_render "$colors" "$vars" "$tpl" /dev/stdout 2>/dev/null)
    rm -f "$tpl"
    [[ "$corners" =~ ^#[0-9a-fA-F]{6}\ #[0-9a-fA-F]{6}\ #[0-9a-fA-F]{6}\ #[0-9a-fA-F]{6}$ ]] || return 1

    tga="${out%.png}.tga"
    mkdir -p "$(dirname "$out")"
    {
        printf '\000\000\002\000\000\000\000\000\000\000\000\000'
        # width and height as little-endian 16-bit, via %b so the format
        # string stays constant
        printf '%b' "\\0$(printf '%03o' $((w % 256)))\\0$(printf '%03o' $((w / 256)))\\0$(printf '%03o' $((h % 256)))\\0$(printf '%03o' $((h / 256)))"
        printf '\030\040'
        awk -v W="$w" -v H="$h" -v c="$corners" '
            function hx(s, i) { return index("0123456789abcdef", tolower(substr(s, i, 1))) * 16 + index("0123456789abcdef", tolower(substr(s, i + 1, 1))) - 17 }
            BEGIN {
                split(c, p, " ")
                for (k = 1; k <= 4; k++) { R[k] = hx(p[k], 2); G[k] = hx(p[k], 4); B[k] = hx(p[k], 6) }
                for (y = 0; y < H; y++) {
                    v = y / (H - 1)
                    for (x = 0; x < W; x++) {
                        u = x / (W - 1)
                        r = (1-u)*(1-v)*R[1] + u*(1-v)*R[2] + (1-u)*v*R[3] + u*v*R[4]
                        g = (1-u)*(1-v)*G[1] + u*(1-v)*G[2] + (1-u)*v*G[3] + u*v*G[4]
                        b = (1-u)*(1-v)*B[1] + u*(1-v)*B[2] + (1-u)*v*B[3] + u*v*B[4]
                        printf "%c%c%c", int(b + 0.5), int(g + 0.5), int(r + 0.5)
                    }
                }
            }'
    } > "$tga"
    if sips -s format png -z 1600 2560 "$tga" --out "$out" >/dev/null 2>&1 && [[ -s "$out" ]]; then
        rm -f "$tga"
        return 0
    fi
    rm -f "$tga" "$out"
    return 1
}

# theme_background_sources <theme> — one path per line, cycling order
theme_background_sources() {
    local theme="$1" dir f theme_dir
    theme_dir="$(theme_dir_of "$theme" 2>/dev/null || echo "$DOTFILES_DIR/themes/$theme")"
    for dir in "$theme_dir/backgrounds" "$THEME_BG_USER_DIR/$theme"; do
        [[ -d "$dir" ]] || continue
        for f in "$dir"/*; do
            [[ -f "$f" ]] || continue
            case "$(printf '%s' "${f##*.}" | tr '[:upper:]' '[:lower:]')" in
                jpg|jpeg|png|gif|bmp|webp|heic|tiff|tif) printf '%s\n' "$f" ;;
            esac
        done
    done
    f="$THEME_BG_STATE_DIR/current/theme/background.png"
    [[ -f "$f" ]] && printf '%s\n' "$f"
    return 0
}

theme_background_current() {
    [[ -L "$THEME_BG_LINK" ]] && readlink "$THEME_BG_LINK"
    return 0
}

# theme_background_apply <image> — put it on every desktop (best effort)
theme_background_apply() {
    local img="$1" esc pid i=0
    [[ -z "${DOTFILES_NO_BACKGROUND:-}" ]] || return 0
    [[ "$(uname -s)" == "Darwin" ]] || return 0
    if [[ -f "$DOTFILES_DIR/bin/dotfiles-toggle" ]] \
        && ! bash "$DOTFILES_DIR/bin/dotfiles-toggle" --enabled background; then
        return 0
    fi
    if command -v desktoppr >/dev/null 2>&1; then
        desktoppr "$img" >/dev/null 2>&1 && return 0
        return 1
    fi
    esc="${img//\\/\\\\}"
    esc="${esc//\"/\\\"}"
    osascript -e "tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$esc\"" >/dev/null 2>&1 &
    pid=$!
    while kill -0 "$pid" 2>/dev/null && [[ $i -lt 50 ]]; do
        sleep 0.1
        i=$((i + 1))
    done
    if kill -0 "$pid" 2>/dev/null; then
        kill "$pid" 2>/dev/null || true
        return 2
    fi
    wait "$pid"
}

# theme_background_set <image> — record the choice, then apply it.
# Returns 0 on success, 1 for a bad file or failed setter, 2 on the
# osascript timeout (the link is still updated in both failure cases).
theme_background_set() {
    local img="$1" rc
    [[ -f "$img" ]] || return 1
    # Absolute, but not canonicalised: the link must equal the path the
    # candidate list produces, or `next` never finds its place in it.
    [[ "$img" == /* ]] || img="$PWD/$img"
    mkdir -p "$(dirname "$THEME_BG_LINK")"
    ln -nsf "$img" "$THEME_BG_LINK"
    theme_background_apply "$img"
    rc=$?
    return $rc
}

# theme_background_next <theme> — the source after the current one (wraps)
theme_background_next() {
    local theme="$1" current chosen="" first="" prev_matched=false f
    current="$(theme_background_current)"
    while IFS= read -r f; do
        [[ -n "$f" ]] || continue
        [[ -n "$first" ]] || first="$f"
        if [[ "$prev_matched" == true ]]; then
            chosen="$f"
            break
        fi
        [[ "$f" == "$current" ]] && prev_matched=true
    done <<EOF_SOURCES
$(theme_background_sources "$theme")
EOF_SOURCES
    [[ -n "$chosen" ]] || chosen="$first"
    [[ -n "$chosen" ]] || return 1
    theme_background_set "$chosen"
}
