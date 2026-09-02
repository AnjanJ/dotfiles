#!/usr/bin/env bash

# ============================================
# PACKAGE GROUP UTILITIES
# ============================================
# Functions for selecting which Brewfile groups to install.
# Sourced by: install.sh, update.sh
# ============================================

PACKAGES_STATE_FILE="$HOME/.dotfiles-packages"

# Groups that cannot be deselected
_REQUIRED_GROUPS=("taps" "core")

# ── Group Descriptions ───────────────────────

_get_group_description() {
    case "$1" in
        taps)           echo "Homebrew tap registries" ;;
        core)           echo "Essential CLI tools" ;;
        editors)        echo "Code editors & terminals" ;;
        window-mgmt)    echo "Tiling WM & status bar" ;;
        terminal-tools) echo "Terminal enhancements & TUI tools" ;;
        ai)             echo "AI/LLM CLI tooling & desktop apps" ;;
        databases)      echo "Database engines & GUI clients" ;;
        cloud-deploy)   echo "Cloud & deployment CLIs" ;;
        media)          echo "Media processing tools" ;;
        communication)  echo "Personal messaging" ;;
        productivity)   echo "Personal productivity" ;;
        work)           echo "Enterprise & work apps" ;;
        languages)      echo "Language-specific tools" ;;
        browsers)       echo "Web browsers" ;;
        utilities)      echo "Misc desktop utilities" ;;
        fonts)          echo "Nerd Fonts collection" ;;
        vscode-ext)     echo "VS Code extensions" ;;
        extras)         echo "CLI tap tools & low-level libs" ;;
        *)              echo "$1" ;;
    esac
}

# ── Tiny set helpers ─────────────────────────
# macOS ships bash 3.2, which has no associative arrays, and the curl
# bootstrap runs install.sh under /bin/bash before Homebrew bash exists.
# A "set" here is a newline-delimited string with a leading and trailing
# newline, so members may contain spaces (mas names like "GIPHY CAPTURE").
_set_has() {
    # Args: varname, member
    local _s="${!1}"
    [[ "$_s" == *$'\n'"$2"$'\n'* ]]
}
_set_add() {
    # Args: varname, member — assigns in place (printf -v) rather than via
    # $(...), which would strip the trailing newline the format relies on.
    local _s="${!1}"
    [[ -z "$_s" ]] && _s=$'\n'
    if ! _set_has 1 "$2"; then
        printf -v "$1" '%s%s\n' "$_s" "$2"
    fi
}
_set_del() {
    # Args: varname, member — assigns in place
    local _s="${!1}"
    if _set_has 1 "$2"; then
        printf -v "$1" '%s' "${_s/$'\n'$2$'\n'/$'\n'}"
    fi
}

# ── Brewfile Parsing ─────────────────────────

# Parse group names from Brewfile (in order)
_parse_brewfile_groups() {
    local brewfile="$1"
    sed -n 's/^# @group \([^ ]*\).*/\1/p' "$brewfile"
}

# Get the line count for a group
_get_group_package_count() {
    local brewfile="$1"
    local group="$2"
    _get_group_entries "$brewfile" "$group" | wc -l | tr -d ' '
}

# Get all Brewfile lines belonging to a group
_get_group_entries() {
    local brewfile="$1"
    local group="$2"
    local in_group=false

    while IFS= read -r line; do
        if [[ "$line" =~ ^#\ @group\ ([^ ]+) ]]; then
            local current_group="${BASH_REMATCH[1]}"
            if [[ "$current_group" == "$group" ]]; then
                in_group=true
            else
                if [[ "$in_group" == true ]]; then
                    break
                fi
            fi
            continue
        fi

        if [[ "$in_group" == true ]]; then
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            echo "$line"
        fi
    done < "$brewfile"
}

# Check if a group is required (cannot be deselected)
_is_required_group() {
    local group="$1"
    for req in "${_REQUIRED_GROUPS[@]}"; do
        [[ "$req" == "$group" ]] && return 0
    done
    return 1
}

# ── State Persistence ────────────────────────

# Save selected groups and exclusions to state file
# Args: selections string (one per line: +group or -group or -group:package)
save_selected_groups() {
    local selections="$1"
    cat > "$PACKAGES_STATE_FILE" <<EOF
# Saved package selections (managed by dotfiles installer)
# Format: +group (include) or -group (exclude) or -group:package (exclude individual)
$selections
EOF
}

# Read saved group selections from state file
# Returns the selections string (one per line)
get_saved_groups() {
    [[ -f "$PACKAGES_STATE_FILE" ]] || return 1
    grep -v '^#' "$PACKAGES_STATE_FILE" | grep -v '^$'
}

# ── Interactive Package Picker ───────────────

# Interactive group selection — mirrors theme-utils.sh pattern
# Outputs selections string to stdout (for capture), UI goes to stderr
prompt_package_selection() {
    local brewfile="$1"
    local groups=()
    local selectable_groups=()

    # Read all groups
    while IFS= read -r g; do
        groups+=("$g")
        if ! _is_required_group "$g"; then
            selectable_groups+=("$g")
        fi
    done <<< "$(_parse_brewfile_groups "$brewfile")"

    # Start with all selected; `deselected` holds the groups turned off
    # shellcheck disable=SC2034  # read indirectly by _set_has/_set_add
    local deselected=$'\n'

    # Load previous selections if they exist
    if [[ -f "$PACKAGES_STATE_FILE" ]]; then
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            if [[ "$line" =~ ^-([^:]+)$ ]]; then
                _set_add deselected "${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^\+(.+)$ ]]; then
                _set_del deselected "${BASH_REMATCH[1]}"
            fi
        done <<< "$(get_saved_groups)"
    fi

    echo "" >&2
    echo "  Select package groups to install:" >&2
    echo "  (Enter numbers to TOGGLE, or press Enter to confirm)" >&2
    echo "" >&2

    # Display loop — allow toggling until user confirms
    while true; do
        local i=1
        for g in "${selectable_groups[@]}"; do
            local desc
            desc=$(_get_group_description "$g")
            local count
            count=$(_get_group_package_count "$brewfile" "$g")
            local marker="x"
            _set_has deselected "$g" && marker=" "
            printf "  %2d) [%s] %-16s — %s (%s packages)\n" "$i" "$marker" "$g" "$desc" "$count" >&2
            ((i++))
        done

        echo "" >&2
        # Show core as always-included
        local core_count
        core_count=$(_get_group_package_count "$brewfile" "core")
        echo "  Note: 'core' ($core_count packages) is always installed." >&2
        echo "" >&2
        echo "  Toggle groups (e.g., 8 11 12), 'all' to select all, 'none' to deselect all." >&2
        echo "  Press Enter when done to confirm current selection." >&2
        read -r -p "  > " toggle_input >&2

        if [[ -z "$toggle_input" ]]; then
            # Confirm current selection
            break
        elif [[ "$toggle_input" == "all" ]]; then
            deselected=$'\n'
            echo "" >&2
        elif [[ "$toggle_input" == "none" ]]; then
            # shellcheck disable=SC2034
            deselected=$'\n'
            for g in "${selectable_groups[@]}"; do
                _set_add deselected "$g"
            done
            echo "" >&2
        else
            for num in $toggle_input; do
                if ! [[ "$num" =~ ^[0-9]+$ ]] || [[ "$num" -lt 1 || "$num" -gt ${#selectable_groups[@]} ]]; then
                    echo "  Skipping invalid selection: $num" >&2
                    continue
                fi
                local g="${selectable_groups[$((num-1))]}"
                if _set_has deselected "$g"; then
                    _set_del deselected "$g"
                else
                    _set_add deselected "$g"
                fi
            done
            echo "" >&2
        fi
    done

    # For selected groups, offer individual app deselection
    local excluded_keys=$'\n'
    for g in "${selectable_groups[@]}"; do
        _set_has deselected "$g" && continue

        local entries=()
        while IFS= read -r entry; do
            [[ -z "$entry" ]] && continue
            entries+=("$entry")
        done <<< "$(_get_group_entries "$brewfile" "$g")"

        local count=${#entries[@]}
        [[ "$count" -le 1 ]] && continue

        echo "" >&2
        local desc
        desc=$(_get_group_description "$g")
        echo "  $g — $desc ($count packages):" >&2
        echo "  Enter numbers to EXCLUDE specific packages, or press Enter to install all." >&2
        echo "" >&2

        local i=1
        for entry in "${entries[@]}"; do
            # Extract package name for display
            local display_name
            # shellcheck disable=SC2001  # sed needed for regex group extraction
            display_name=$(echo "$entry" | sed 's/.*"\([^"]*\)".*/\1/')
            printf "  %2d) %s\n" "$i" "$display_name" >&2
            ((i++))
        done

        echo "" >&2
        read -r -p "  Exclude (e.g., 3 5), or Enter to keep all: " exclude_input >&2

        if [[ -n "$exclude_input" ]]; then
            for num in $exclude_input; do
                if ! [[ "$num" =~ ^[0-9]+$ ]] || [[ "$num" -lt 1 || "$num" -gt ${#entries[@]} ]]; then
                    echo "  Skipping invalid selection: $num" >&2
                    continue
                fi
                local entry="${entries[$((num-1))]}"
                local pkg_name
                # shellcheck disable=SC2001  # sed needed for regex group extraction
                pkg_name=$(echo "$entry" | sed 's/.*"\([^"]*\)".*/\1/')
                _set_add excluded_keys "$g:$pkg_name"
            done
        fi
    done

    # Build selections output
    local selections=""
    for g in "${selectable_groups[@]}"; do
        if _set_has deselected "$g"; then
            selections+="-"
        else
            selections+="+"
        fi
        selections+="$g"$'\n'
    done

    # Add individual exclusions
    local key
    while IFS= read -r key; do
        [[ -z "$key" ]] && continue
        selections+="-$key"$'\n'
    done <<< "$excluded_keys"

    # Remove trailing newline
    selections="${selections%$'\n'}"

    # Save selections
    save_selected_groups "$selections"

    echo "$selections"
}

# ── Filtered Brewfile Generation ─────────────

# Generate a temporary Brewfile with only the selected groups
# Args: brewfile_path, selections_string
# Outputs: path to temporary Brewfile
generate_filtered_brewfile() {
    local brewfile="$1"
    local selections="$2"
    local tmp_brewfile
    tmp_brewfile=$(mktemp "${TMPDIR:-/tmp}/Brewfile.XXXXXX")

    # Parse selections into include/exclude sets
    # shellcheck disable=SC2034  # read indirectly by _set_has/_set_add
    local included_groups=$'\n'
    # shellcheck disable=SC2034
    local excluded_packages=$'\n'

    # Required groups always included
    for g in "${_REQUIRED_GROUPS[@]}"; do
        _set_add included_groups "$g"
    done

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        if [[ "$line" =~ ^\+(.+)$ ]]; then
            _set_add included_groups "${BASH_REMATCH[1]}"
        elif [[ "$line" =~ ^-([^:]+):(.+)$ ]]; then
            # Individual package exclusion
            _set_add excluded_packages "${BASH_REMATCH[2]}"
        elif [[ "$line" =~ ^-(.+)$ ]]; then
            # Group exclusion (don't add to included)
            true
        fi
    done <<< "$selections"

    # Walk the Brewfile and emit selected entries
    local current_group=""
    local in_included_group=false

    while IFS= read -r line; do
        if [[ "$line" =~ ^#\ @group\ ([^ ]+) ]]; then
            current_group="${BASH_REMATCH[1]}"
            if _set_has included_groups "$current_group"; then
                in_included_group=true
                echo "$line" >> "$tmp_brewfile"
            else
                in_included_group=false
            fi
            continue
        fi

        if [[ "$in_included_group" == true ]]; then
            # Check individual exclusions
            if [[ "$line" =~ \"([^\"]+)\" ]]; then
                local pkg_name="${BASH_REMATCH[1]}"
                if _set_has excluded_packages "$pkg_name"; then
                    continue
                fi
            fi
            echo "$line" >> "$tmp_brewfile"
        fi
    done < "$brewfile"

    echo "$tmp_brewfile"
}
