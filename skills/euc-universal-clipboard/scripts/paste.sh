#!/bin/bash
# ==============================================================================
# Universal Paste Script v6.1
# Features: Live clipboard reading, index selection, list mode, clear history,
#           smart file handling.
# ==============================================================================

HIST_FILE="$HOME/.universal_clipboard_history"
TMP_CLIP="/tmp/universal_clipboard_$USER"
INDEX=""
QUIET=false
LIST_ONLY=false
CLEAR=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -i|--index) INDEX="$2"; shift ;;
        -l|--list)  LIST_ONLY=true ;;
        -q|--quiet) QUIET=true ;;
        -c|--clear) CLEAR=true ;;
        -h|--help)  echo "Usage: paste [-i index] [-l] [-q] [-c|--clear]"; exit 0 ;;
    esac
    shift
done

# --- BUG 7 FIX: Implement --clear flag to wipe history and system clipboard buffers ---
clear_history() {
    rm -f "$HIST_FILE" "$TMP_CLIP"
    # Clear the live system clipboard using the detected engine
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

if [ "$CLEAR" = true ]; then
    clear_history
fi

# --- BUG 4 FIX: Function to read the live system clipboard using the detected engine ---
read_live_clipboard() {
    # Try Wayland first (wl-paste)
    if [ -n "$WAYLAND_DISPLAY" ] && command -v wl-paste >/dev/null; then
        wl-paste 2>/dev/null
        return $?
    fi
    # Try X11 (xclip)
    if [ -n "$DISPLAY" ] && command -v xclip >/dev/null; then
        xclip -selection clipboard -o 2>/dev/null
        return $?
    fi
    # Try WSL2 (powershell.exe Get-Clipboard)
    if command -v powershell.exe >/dev/null; then
        powershell.exe -command "Get-Clipboard" 2>/dev/null
        return $?
    fi
    # No clipboard engine available, return failure
    return 1
}

if [ ! -r "$HIST_FILE" ] && [ -f "$HIST_FILE" ]; then
    echo "Error: History file at $HIST_FILE is not readable." >&2
    exit 1
fi

items=()
[ -f "$HIST_FILE" ] && mapfile -t items < <(head -n 20 "$HIST_FILE")

# List mode
if [ "$LIST_ONLY" = true ]; then
    for i in "${!items[@]}"; do echo "$((i+1))) ${items[$i]}"; done
    exit 0
fi

# Content selection logic
if [ -n "$INDEX" ]; then
    # Explicit index requested: retrieve from history
    if [[ "$INDEX" -gt 0 && "$INDEX" -le ${#items[@]} ]]; then
        content="${items[$((INDEX-1))]}"
    else
        echo "Error: Invalid index $INDEX (Available: 1-${#items[@]})" >&2
        exit 1
    fi
elif [ ! -t 1 ]; then
    # Non-interactive (piped): read live clipboard first, fall back to history
    content=$(read_live_clipboard)
    if [ -z "$content" ] && [ ${#items[@]} -gt 0 ]; then
        content="${items[0]}"
    fi
else
    # Interactive: read live clipboard first, fall back to history menu
    content=$(read_live_clipboard)
    if [ -n "$content" ]; then
        # Live clipboard has content, output it directly
        :
    elif [ ${#items[@]} -eq 0 ]; then
        echo "History is empty and live clipboard is empty." >&2
        exit 1
    else
        # Show interactive menu from history
        content=""
        limit=$(( ${#items[@]} < 5 ? ${#items[@]} : 5 ))
        for ((i=0; i<limit; i++)); do
            echo "$((i+1))) $(echo "${items[$i]}" | tr '\n' ' ' | cut -c1-60)" >&2
        done
        read -rn1 -p "Select item (1-$limit, 0 to cancel): " choice >&2; echo "" >&2
        [[ "$choice" == "0" || ! "$choice" =~ [1-$limit] ]] && exit 0
        content="${items[$((choice-1))]}"
    fi
fi

# Final Output Logic
if [[ "$content" == file://* ]]; then
    path=$(echo "$content" | sed 's|^file://||')
    if [ -e "$path" ]; then
        if [[ -t 1 && -z "$INDEX" ]]; then
            cp -r "$path" . && echo "Copied file/folder to current directory." >&2
        else
            echo -n "$path"
        fi
    else
        echo "Error: Source file/folder no longer exists." >&2; exit 1
    fi
else
    echo -n "$content"
fi
