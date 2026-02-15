# Emasoft Universal Clipboard

Cross-platform clipboard operations plugin for Claude Code agents. Provides native copy/paste support on macOS, Windows, WSL2, and Linux (Wayland and X11) with 20-item FIFO history tracking.

## Installation

### From Marketplace

```bash
claude plugin marketplace add https://github.com/Emasoft/emasoft-plugins
claude plugin install emasoft-universal-clipboard@emasoft-plugins --scope user
```

### For Development

```bash
claude --plugin-dir ./emasoft-universal-clipboard
```

## Components

| Type | Name | Description |
|------|------|-------------|
| Agent | `euc-clipboard-agent` | Expert agent for cross-platform clipboard operations |
| Skill | `euc-universal-clipboard` | Clipboard copy/paste skill with platform detection |
| Script | `copy.sh` | Linux copy-to-clipboard with history (installs as `xcp`) |
| Script | `paste.sh` | Linux paste-from-clipboard with live reading and history (installs as `xps`) |

## Platform Support

| Platform | Copy Command | Paste Command | Scripts Needed |
|----------|-------------|---------------|----------------|
| macOS | `echo "text" \| pbcopy` | `pbpaste` | No |
| Windows | `echo "text" \| clip` | `powershell.exe -command "Get-Clipboard"` | No |
| WSL2 | `echo "text" \| clip.exe` | `powershell.exe -command "Get-Clipboard"` | No |
| Linux (Wayland) | `echo "text" \| xcp` | `xps` | Yes (install with `sudo ./copy.sh --install`) |
| Linux (X11) | `echo "text" \| xcp` | `xps` | Yes (install with `sudo ./copy.sh --install`) |

**Note**: On Windows and WSL2, the `clip`/`clip.exe` command is write-only. To read from the clipboard, use `powershell.exe -command "Get-Clipboard"`.

## Usage Examples

### Copy text to clipboard

```bash
# macOS
echo "Hello World" | pbcopy

# Windows / WSL2
echo "Hello World" | clip.exe

# Linux (with scripts installed)
echo "Hello World" | xcp
xcp "Hello World"
```

### Paste from clipboard

```bash
# macOS
pbpaste

# Windows / WSL2
powershell.exe -command "Get-Clipboard"

# Linux (with scripts installed)
xps              # reads live clipboard, falls back to history
xps -i 1         # paste first item from history
xps --list       # show clipboard history
```

### Copy file/directory reference (Linux)

```bash
xcp /path/to/file.png
xcp /path/to/directory/
```

### Clear clipboard and history (Linux)

```bash
xcp --clear
xps --clear
```

### Install scripts globally (Linux)

```bash
chmod +x copy.sh paste.sh
sudo ./copy.sh --install
# Creates 'xcp' and 'xps' commands in /usr/local/bin/
```

## License

MIT License. See [LICENSE](./LICENSE) for details.
