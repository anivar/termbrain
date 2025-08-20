# TermBrain Shell Integration

Automatic command recording and shell hooks for TermBrain.

## Supported Shells

- **Bash** (4.0+)
- **Zsh** 
- **Fish**

## Quick Installation

```bash
# Auto-detect shell and install
./install.sh

# Install for specific shell
./install.sh --shell zsh

# Preview what would be installed
./install.sh --dry-run
```

## Manual Installation

### Bash

Add to `~/.bashrc` or `~/.bash_profile`:

```bash
source /path/to/termbrain/shell-integration/bash/termbrain.bash
```

### Zsh

Add to `~/.zshrc`:

```zsh
source /path/to/termbrain/shell-integration/zsh/termbrain.zsh
```

### Fish

Add to `~/.config/fish/config.fish`:

```fish
source /path/to/termbrain/shell-integration/fish/termbrain.fish
```

## Features

### Automatic Command Recording

- Records every command execution with exit code, duration, and working directory
- Skips TermBrain commands to avoid recursion
- Asynchronous recording to avoid shell slowdown

### Session Tracking

- Unique session IDs for each terminal session
- Tracks shell type and environment

### Manual Controls

```bash
tbe            # Enable recording
tbd            # Disable recording  
tbs            # Show status
termbrain_status  # Detailed status
```

### Tab Completion

Auto-completion for `tb` command and subcommands.

## Configuration

Environment variables:

```bash
export TERMBRAIN_ENABLED=1        # Enable/disable (1/0)
export TERMBRAIN_AUTO_RECORD=1    # Auto-record commands (1/0)
export TERMBRAIN_SESSION_ID=...   # Custom session ID
```

## Privacy & Performance

- Commands are recorded locally only
- Asynchronous background recording
- No network requests
- Can be disabled instantly with `tbd`

## Troubleshooting

### Commands Not Recording

1. Check if integration is loaded: `tbs`
2. Verify CLI is available: `which tb`
3. Check if recording is enabled: `echo $TERMBRAIN_ENABLED`

### Performance Issues

1. Disable recording: `tbd`
2. Check for conflicting shell hooks
3. Verify TermBrain CLI is responding: `tb status`

### Shell-Specific Issues

**Bash**: Requires Bash 4.0+ for pre-command hooks. On older versions, only post-command recording works.

**Zsh**: Uses `preexec` and `precmd` hooks. May conflict with frameworks like Oh My Zsh if they override these functions.

**Fish**: Uses event-based hooks. Should work with all Fish configurations.

## Uninstallation

Remove the source line from your shell config file and restart your terminal.

## Development

The integration files are self-contained and can be customized:

- `bash/termbrain.bash` - Bash integration
- `zsh/termbrain.zsh` - Zsh integration  
- `fish/termbrain.fish` - Fish integration
- `install.sh` - Installation script