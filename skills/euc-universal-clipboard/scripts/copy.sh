#!/bin/bash
# ==============================================================================
# Universal Copy Script v6.1
# Supports: Wayland, X11, WSL, and Headless Terminal.
# Features: Self-diagnostics, persistent history (20 items), auto-install.
# ==============================================================================

HIST_FILE="$HOME/.universal_clipboard_history"
TMP_CLIP="/tmp/universal_clipboard_$USER"
MAX_ITEMS=20
QUIET=false

# --- Diagnostics & System Health ---
run_diagnostics() {
    local issues=()
    local suggestions=()

    # 1. Check Executability
    if [[ ! -x "$0" ]]; then
        issues+=("Current script is not executable.")
        suggestions+=("Run: chmod +x $(realpath "$0")")
    fi

    # 2. Check History Permissions
    if [[ -f "$HIST_FILE" && ! -w "$HIST_FILE" ]]; then
        issues+=("History file is not writable.")
        suggestions+=("Run: chmod 600 $HIST_FILE")
    fi

    # 3. Check Graphic Engines
    if [[ -n "$WAYLAND_DISPLAY" ]]; then
        if ! command -v wl-copy >/dev/null; then
            issues+=("Wayland detected but 'wl-clipboard' is missing.")
            suggestions+=("Install: sudo apt install wl-clipboard (or equivalent)")
        fi
    elif [[ -n "$DISPLAY" ]]; then
        if ! command -v xclip >/dev/null && ! command -v xsel >/dev/null; then
            issues+=("X11 detected but 'xclip' or 'xsel' is missing.")
            suggestions+=("Install: sudo apt install xclip")
        fi
    fi

    # 4. WSL Privileges
    if grep -qE "(Microsoft|microsoft|WSL)" /proc/version 2>/dev/null; then
        if ! command -v clip.exe >/dev/null; then
            issues+=("WSL detected but 'clip.exe' is not in PATH.")
            suggestions+=("Ensure Windows /system32 is in your \$PATH")
        fi
    fi

    # Report Issues to stderr
    if [ ${#issues[@]} -gt 0 ]; then
        echo -e "\n--- [ SYSTEM HEALTH ALERT ] ---" >&2
        for i in "${!issues[@]}"; do
            echo -e "Issue: ${issues[$i]}" >&2
            echo -e "Fix:   ${suggestions[$i]}" >&2
        done
        echo -e "-------------------------------\n" >&2
    fi
}

check_deps() {
    DEPS=()
    [ -n "$WAYLAND_DISPLAY" ] && command -v wl-copy >/dev/null && DEPS+=("Wayland")
    [ -n "$DISPLAY" ] && command -v xclip >/dev/null && DEPS+=("X11")
    command -v clip.exe >/dev/null && DEPS+=("WSL")
    [ ${#DEPS[@]} -eq 0 ] && DEPS+=("Local-Only")
}

clear_history() {
    rm -f "$HIST_FILE" "$TMP_CLIP"
    if [ -n "$WAYLAND_DISPLAY" ] && command -v wl-copy >/dev/null; then
        wl-copy --clear
    elif [ -n "$DISPLAY" ] && command -v xclip >/dev/null; then
        echo -n "" | xclip -selection clipboard
    elif command -v clip.exe >/dev/null; then
        echo -n "" | clip.exe
    fi
    echo "Local history and live clipboard cleared."
    exit 0
}

install_scripts() {
    local bin_dir="/usr/local/bin"
    if [ ! -w "$bin_dir" ]; then
        echo "Error: Use 'sudo' to install scripts in $bin_dir" >&2
        exit 1
    fi

    local name_cp="copy"
    local name_ps="paste"

    command -v "$name_cp" >/dev/null && name_cp="xcp"
    command -v "$name_ps" >/dev/null && name_ps="xps"

    local cpb_path=$(realpath "$0")
    # BUG 3 FIX: Look for paste.sh (the actual filename) instead of just "paste"
    local psb_path=$(dirname "$cpb_path")/paste.sh

    if [ ! -f "$psb_path" ]; then
        echo "Error: 'paste.sh' script not found at $psb_path" >&2
        exit 1
    fi

    ln -sf "$cpb_path" "$bin_dir/$name_cp"
    ln -sf "$psb_path" "$bin_dir/$name_ps"
    chmod +x "$cpb_path" "$psb_path"

    echo "Installation successful!"
    echo "Commands: '$name_cp' and '$name_ps' are now available globally."
    exit 0
}

# --- Flag Parsing (BUG 8 FIX: Parse all flags in a loop before processing main argument) ---
POSITIONAL_ARGS=()
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        --help|-h)
            echo "Usage: copy [DATA|FILE|DIR] | --install | --clear"
            echo "Options: -q, --quiet suppress engine info."
            exit 0 ;;
        --install) install_scripts ;;
        --clear|-c) clear_history ;;
        --quiet|-q) QUIET=true ;;
        *) POSITIONAL_ARGS+=("$1") ;;
    esac
    shift
done

# Restore positional arguments after flag parsing
set -- "${POSITIONAL_ARGS[@]}"

if [ "$QUIET" = false ]; then
    run_diagnostics
    check_deps
    [ -t 1 ] && echo "Active Engine: ${DEPS[*]}" >&2
fi

TARGET="${1:-$(cat -)}"

save_history() {
    [ -z "$1" ] && return
    touch "$HIST_FILE" 2>/dev/null || return
    (echo "$1"; grep -vxF "$1" "$HIST_FILE" 2>/dev/null | head -n $((MAX_ITEMS - 1))) > "${HIST_FILE}.tmp"
    mv "${HIST_FILE}.tmp" "$HIST_FILE"
    echo -n "$1" > "$TMP_CLIP"
}

if [ -n "$WAYLAND_DISPLAY" ] && command -v wl-copy >/dev/null; then
    [ -e "$TARGET" ] && (ABS=$(realpath "$TARGET"); echo -n "file://$ABS" | wl-copy --type text/uri-list) || (echo -n "$TARGET" | wl-copy)
elif [ -n "$DISPLAY" ] && command -v xclip >/dev/null; then
    [ -e "$TARGET" ] && (ABS=$(realpath "$TARGET"); echo -n "file://$ABS" | xclip -selection clipboard -t text/uri-list) || (echo -n "$TARGET" | xclip -selection clipboard)
elif command -v clip.exe >/dev/null; then
    echo -n "$TARGET" | clip.exe
fi

save_history "$TARGET"
