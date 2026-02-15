---
name: euc-universal-clipboard
description: >-
  Cross-platform clipboard copy/paste for Claude Code agents.
  Supports macOS, Windows, WSL2, Linux Wayland/X11 with 20-item FIFO history.
version: 1.0.0
license: MIT
tags: [system, clipboard, wayland, pbcopy, pbpaste, clip.exe, copy, paste, insert, append, text]
---

# Universal Clipboard Skill

## Overview

Robust cross-platform skill to copy and paste text and files to/from the system clipboard.
The skill provides two scripts to create the CLI global commands on Linux: `xcp <data>` and `xps [--index N]` to manage system clipboard operations across diverse environments.

## When to Use This Skill
- Use this skill when the user asks to copy something on the clipboard
- Use this skill when the user asks to paste something from the clipboard
- For example: `User: Copy the results of the tests to the clipboard`
- For example: `User: Copy the content of this text file and paste it at the beginning of the main.py`
- Use when you need to copy something to the system clipboard
- Use when you need to paste something from the system clipboard
- Use when you need to use copy/paste operations in bash scripts you are writing

## Prerequisites

- **macOS**: `pbcopy` and `pbpaste` are pre-installed.
- **Windows**: `clip` is pre-installed; PowerShell `Get-Clipboard` cmdlet is required for paste.
- **WSL2**: `clip.exe` for copy; PowerShell `Get-Clipboard` via `powershell.exe` for paste.
- **Linux Wayland**: `wl-clipboard` package must be installed (`sudo apt install wl-clipboard` or equivalent).
- **Linux X11**: `xclip` package must be installed (`sudo apt install xclip` or equivalent).
- **Linux script installation**: The provided `copy.sh` and `paste.sh` scripts must be installed (see Scripts Installation below).

## Instructions

### For non Linux platforms

### To Copy (non-Linux)
To copy text to the clipboard, pipe data to the platform-specific command:

- macOS: `echo "text" | pbcopy`
- Windows: `echo "text" | clip`
- WSL2: `echo "text" | clip.exe`

### To Paste (non-Linux)
To paste text from the clipboard, use the platform-specific command:

- macOS: `pbpaste`
- Windows: `powershell.exe -command "Get-Clipboard"`
- WSL2: `powershell.exe -command "Get-Clipboard"`

Note: The Windows `clip` and `clip.exe` commands are write-only (they can only copy TO the clipboard). To read FROM the clipboard on Windows or WSL2, you must use PowerShell's `Get-Clipboard` cmdlet as shown above.

### For Linux platforms
On Linux you are required to install the provided 2 scripts.

### To Copy (Linux)
To copy text to the clipboard, pipe data to the provided script command:

- Linux: `echo "text" | xcp`

### To Paste (Linux)
To paste text from the clipboard use the provided script command:

- Linux: `xps` (reads live system clipboard; falls back to history if clipboard is empty)
- Linux: `xps -i 1` (paste first item from history)

### Provided scripts for Linux platforms
The included scripts paths are:
- To Copy: `<SKILL ROOT>/scripts/copy.sh`  (once installed, it will become `xcp`)
- To Paste: `<SKILL ROOT>/scripts/paste.sh` (once installed, it will become `xps`)
Use `--help` to get detailed usage informations.

### Scripts Installation
1. Save `copy.sh` and `paste.sh` in the same directory (or use them directly from `<SKILL ROOT>/scripts/`).
2. Run `chmod +x copy.sh paste.sh`.
3. Run `sudo ./copy.sh --install`.

### Scripts Capabilities
- **Cross-Engine Support**: Seamlessly switches between Wayland (`wl-clipboard`), X11 (`xclip`), and WSL (`clip.exe`).
- **Health Monitoring**: Real-time diagnostic reporting for missing dependencies or permission issues.
- **Persistence**: Maintains a 20-item FIFO history in `~/.universal_clipboard_history`.
- **MIME Awareness**: Distinguishes between raw text and file/directory URI references.
- **Live Clipboard Reading**: The paste script reads the live system clipboard by default, falling back to history when the clipboard is empty.

### Scripts Commands

### `copy.sh` or `xcp` (if installed)
The copy (or xcp) command copies data to the clipboard and history.
- **Syntax**: `xcp <INPUTS> [FLAGS]`
- **Inputs**: `string` (text) or `path` (existing file/directory).
- **Flags**:
    - `--clear`: Full wipe of history and system buffers.
    - `--install`: System-wide setup with collision detection.
    - `--quiet`: Disables diagnostic stderr output. Can appear anywhere in the argument list.

### `paste.sh` or `xps` (if installed)
The paste (or xps) command retrieves data from the live system clipboard or the history.
- **Syntax**: `xps [FLAGS]`
- **Flags**:
    - `--index <1-20>`: Direct retrieval of a specific history entry.
    - `--list`: Returns the full 20-item history log.
    - `--quiet`: Disables engine status messages.
    - `--clear`: Full wipe of history and system clipboard buffers.

## Examples
- `xcp "text"`: Copy text.
- `xcp file.png`: Copy file reference.
- `xcp example/`: Copy directory reference.
- `xps`: Read live system clipboard (falls back to history menu in interactive mode).
- `xps -i 2`: Paste 2nd item from history. (Non interactive. Use this.)
- `xps --clear`: Wipe everything in the clipboard for privacy.
- `xps --list`: Show all items in clipboard history.

### Dependency Check
Before initiating a workflow, verify the environment:
```bash
copy.sh --quiet "test" && echo "Ready"
```
or:
```bash
xcp --quiet "test" && echo "Ready"
```

### Contextual Pasting
To provide the user with their clipboard history (max 20 entries):
```bash
paste.sh --list
```
or:
```bash
xps --list
```

### Automation Fallback
In non-interactive sessions (pipes/redirects), `paste.sh` (or `xps`) will automatically read the live system clipboard first, falling back to the most recent history item if the clipboard is empty. No prompting occurs.

## Error Handling

The script includes an automatic diagnostic engine. If something is not working, simply run `copy` without `--quiet` to see the health report.

### Common Issues:
1. **Missing Dependencies**: On Wayland, you need `wl-clipboard`. On X11, you need `xclip`.
2. **Permission Denied**: If the history file isn't writable, the script will suggest the correct `chmod` command.
3. **WSL Path**: Ensure `/mnt/c/Windows/System32` is in your PATH to allow `clip.exe` access.
4. **Windows/WSL Paste**: The `clip` and `clip.exe` commands are write-only. Use `powershell.exe -command "Get-Clipboard"` to read the clipboard on Windows and WSL2.

### Scripts Security Notes
- Data is stored in plain text at `$HOME/.universal_clipboard_history`.
- For sensitive operations, agents should recommend `xcp --clear` or `xps --clear` after the task is finished.
- Always verify that the paste operation was executed correctly.

## Output

### Mandatory Output After the Copy to the Clipboard
Once you copied successfully in the clipboard, you must:
- Communicate to the user that what he specified was copied to the system clipboard (on Linux, you must specify which clipboard)
- Suggest to the user the exact cli command to paste what was just copied

### Mandatory Output After the Paste from the Clipboard
Once you paste successfully from the clipboard, you must:
- Communicate to the user that what he specified was pasted from the system clipboard to the place he specified (on Linux, you must specify which clipboard)
- Indicate to the user the file or the folder full path where the required element was pasted, and (in case) the line number of the source file where it was pasted/inserted.


## Checklist

- [ ] Detect the current platform (macOS, Windows, WSL, Linux)
- [ ] Use the correct copy command for the platform
- [ ] Use the correct paste command for the platform
- [ ] Verify clipboard content after copy
- [ ] Report what was copied and how to paste

## Resources

- [AgentSkills.io specification](https://agentskills.io) - Portable agent capabilities specification this skill follows
- [wl-clipboard](https://github.com/bugaevc/wl-clipboard) - Wayland clipboard utilities (Linux Wayland)
- [xclip](https://github.com/astrand/xclip) - X11 clipboard command line interface (Linux X11)
- Script source: `<SKILL ROOT>/scripts/copy.sh` - The copy (xcp) script
- Script source: `<SKILL ROOT>/scripts/paste.sh` - The paste (xps) script
