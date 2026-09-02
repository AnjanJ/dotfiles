#!/usr/bin/env bash

# ============================================
# THEME RENDERER
# ============================================
# Renders {{ token }} templates from a theme's colors.toml plus a flat
# vars file (theme.conf values, theme_name, ...). One palette file per
# theme is enough to produce every app config; hand-written files in
# themes/<name>/overrides/ win over templates.
#
# Pure bash 3.2 + awk, so it runs on a fresh Mac before Homebrew bash.
#
# Sourced by: apply-theme.sh. Direct use:
#   bash scripts/theme-render.sh <colors.toml> <vars-file|""> <template> [output]
#
# Tokens:
#   {{ key }}            value as written (e.g. #7aa2f7)
#   {{ key_strip }}      hex without the leading #
#   {{ key_rgb }}        decimal "r,g,b"
#   {{ key_argb }}       0xffRRGGBB (sketchybar / borders)
#   {{ mix a b 30% }}    blend colour a toward colour b; _strip/_rgb/_argb
#                        variants exist (mix_strip, mix_rgb, mix_argb)
#
# Any key in colors.toml or the vars file is a token. Derived keys are
# filled in when a theme leaves them out (accent, muted, selection,
# bright_*, dark_background, mode, is_light, black/white, ...), so a
# minimal palette still renders every template.
# ============================================

# shellcheck disable=SC2016  # awk program, not shell expansion
_THEME_RENDER_AWK='
function trim(s) { sub(/^[ \t]+/, "", s); sub(/[ \t]+$/, "", s); return s }

function load(file,    line, eq, k, v) {
    while ((getline line < file) > 0) {
        if (line ~ /^[ \t]*(#|$)/) continue
        eq = index(line, "=")
        if (!eq) continue
        k = trim(substr(line, 1, eq - 1))
        v = trim(substr(line, eq + 1))
        if (v ~ /^"/) {
            if (match(v, /^"[^"]*"/)) v = substr(v, 2, RLENGTH - 2)
        } else if (v ~ /^'"'"'/) {
            if (match(v, /^'"'"'[^'"'"']*'"'"'/)) v = substr(v, 2, RLENGTH - 2)
        } else {
            sub(/[ \t]+#.*$/, "", v)
        }
        if (k ~ /^[A-Za-z_][A-Za-z0-9_]*$/) C[k] = v
    }
    close(file)
}

function hexval(c) { return index("0123456789abcdef", tolower(c)) - 1 }
function hex2(h, i) { return hexval(substr(h, i, 1)) * 16 + hexval(substr(h, i + 1, 1)) }
function ishex(v) { return length(v) == 7 && v ~ /^#[0-9A-Fa-f]+$/ }
function rgb(v) { return hex2(v, 2) "," hex2(v, 4) "," hex2(v, 6) }
function argb(v) { return "0xff" substr(v, 2) }
function strip(v) { sub(/^#/, "", v); return v }

function mix(a, b, amt,    r, g, bl) {
    if (amt ~ /%$/) { sub(/%$/, "", amt); amt = amt / 100 }
    else { amt = amt + 0; if (amt > 1) amt = amt / 100 }
    if (amt < 0) amt = 0
    if (amt > 1) amt = 1
    r  = int(hex2(a, 2) * (1 - amt) + hex2(b, 2) * amt + 0.5)
    g  = int(hex2(a, 4) * (1 - amt) + hex2(b, 4) * amt + 0.5)
    bl = int(hex2(a, 6) * (1 - amt) + hex2(b, 6) * amt + 0.5)
    return sprintf("#%02x%02x%02x", r, g, bl)
}

function setdef(k, v) { if (!(k in C) || C[k] == "") C[k] = v }

function derive(    bg, fg, lum) {
    bg = C["background"]; fg = C["foreground"]
    if (!("mode" in C) || C["mode"] == "") {
        if (("theme_type" in C) && C["theme_type"] != "") C["mode"] = C["theme_type"]
        else {
            lum = hex2(bg, 2) + hex2(bg, 4) + hex2(bg, 6)
            C["mode"] = (lum > 382) ? "light" : "dark"
        }
    }
    C["theme_type"] = C["mode"]
    C["is_light"] = (C["mode"] == "light") ? "true" : "false"

    setdef("accent", C["blue"])
    setdef("orange", C["yellow"])
    setdef("purple", C["magenta"])
    setdef("bright_red",     mix(C["red"],     "#ffffff", "20%"))
    setdef("bright_green",   mix(C["green"],   "#ffffff", "20%"))
    setdef("bright_yellow",  mix(C["yellow"],  "#ffffff", "20%"))
    setdef("bright_blue",    mix(C["blue"],    "#ffffff", "20%"))
    setdef("bright_magenta", mix(C["magenta"], "#ffffff", "20%"))
    setdef("bright_cyan",    mix(C["cyan"],    "#ffffff", "20%"))
    setdef("bright_purple",  C["bright_magenta"])
    setdef("dark_background",    mix(bg, "#000000", "25%"))
    setdef("darker_background",  mix(bg, "#000000", "50%"))
    setdef("lighter_background", mix(bg, fg, "8%"))
    setdef("light_foreground",   fg)
    setdef("bright_foreground",  fg)
    setdef("muted",              mix(fg, bg, "50%"))
    setdef("dark_foreground",    C["muted"])
    setdef("black",              C["dark_background"])
    setdef("bright_black",       C["muted"])
    setdef("white",              fg)
    setdef("bright_white",       C["bright_foreground"])
    setdef("selection",            C["lighter_background"])
    setdef("selection_background", C["selection"])
    setdef("selection_foreground", C["bright_foreground"])
    setdef("cursor",               C["bright_foreground"])
    setdef("brown",                mix(C["orange"], "#000000", "50%"))
}

function lookup(key,    base) {
    if (key in C) return C[key]
    if (key ~ /_strip$/) { base = substr(key, 1, length(key) - 6); if (base in C) return strip(C[base]) }
    if (key ~ /_argb$/)  { base = substr(key, 1, length(key) - 5); if ((base in C) && ishex(C[base])) return argb(C[base]) }
    if (key ~ /_rgb$/)   { base = substr(key, 1, length(key) - 4); if ((base in C) && ishex(C[base])) return rgb(C[base]) }
    return "\001"
}

function resolve(tok,    inner, n, p, a, b, v) {
    inner = trim(substr(tok, 3, length(tok) - 4))
    n = split(inner, p, /[ \t]+/)
    if (n == 1) {
        v = lookup(p[1])
        if (v != "\001") return v
    } else if (n == 4 && p[1] ~ /^mix(_strip|_rgb|_argb)?$/) {
        a = (p[2] in C) ? C[p[2]] : p[2]
        b = (p[3] in C) ? C[p[3]] : p[3]
        if (ishex(a) && ishex(b)) {
            v = mix(a, b, p[4])
            if (p[1] == "mix_strip") return strip(v)
            if (p[1] == "mix_rgb")   return rgb(v)
            if (p[1] == "mix_argb")  return argb(v)
            return v
        }
    }
    unresolved[inner] = 1
    return tok
}

BEGIN {
    load(colors_file)
    if (vars_file != "") load(vars_file)
    if (!("background" in C) || !("foreground" in C) || !ishex(C["background"]) || !ishex(C["foreground"])) {
        print "theme-render: colors.toml needs hex background and foreground" > "/dev/stderr"
        failed = 1
        exit 2
    }
    derive()
}

{
    line = $0; out = ""
    while (match(line, /[{][{][^}]*[}][}]/)) {
        out = out substr(line, 1, RSTART - 1) resolve(substr(line, RSTART, RLENGTH))
        line = substr(line, RSTART + RLENGTH)
    }
    print out line
}

END {
    if (failed) exit 2
    for (k in unresolved) {
        print "theme-render: unresolved token {{ " k " }} in " FILENAME > "/dev/stderr"
        bad = 1
    }
    if (bad) exit 3
}
'

# theme_render <colors.toml> <vars-file|""> <template> <output>
# Exit codes: 0 ok, 2 palette unusable, 3 unresolved tokens (output still
# written so the offending token is visible in it).
theme_render() {
    local colors="$1" vars="$2" template="$3" output="$4"
    awk -v colors_file="$colors" -v vars_file="$vars" "$_THEME_RENDER_AWK" "$template" > "$output"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    if [[ $# -lt 3 ]]; then
        echo "Usage: bash scripts/theme-render.sh <colors.toml> <vars-file|\"\"> <template> [output]" >&2
        exit 1
    fi
    theme_render "$1" "$2" "$3" "${4:-/dev/stdout}"
fi
