# TermBrain Shell Integration Guide

Complete guide for setting up automatic command recording in your shell.

## Overview

TermBrain shell integration automatically records every command you execute, including:
- Command text and arguments
- Exit codes (success/failure)
- Execution duration
- Working directory
- Shell and environment information

## Quick Start

### 1. Install TermBrain CLI

```bash
# Build from source
cargo install --path crates/termbrain-cli

# Or use pre-built binary
# (when available)
```

### 2. Install Shell Integration

```bash
# Auto-detect shell and install
cd termbrain
./shell-integration/install.sh

# Or install for specific shell
./shell-integration/install.sh --shell zsh
```

### 3. Activate Integration

```bash
# Restart terminal or reload config
source ~/.zshrc  # or ~/.bashrc, ~/.config/fish/config.fish
```

### 4. Verify Installation

```bash
tb status          # Check TermBrain status
tbs               # Quick status check
```

## Supported Shells

| Shell | Version | Features |
|-------|---------|----------|
| **Bash** | 4.0+ | Full integration with pre/post command hooks |
| **Zsh** | Any | Full integration with preexec/precmd hooks |
| **Fish** | 3.0+ | Full integration with event-based hooks |

## Installation Options

### Automatic Installation (Recommended)

```bash
./shell-integration/install.sh
```

**Options:**
- `--shell SHELL` - Install for specific shell (bash, zsh, fish)
- `--auto-detect` - Auto-detect current shell (default)
- `--force` - Force reinstall over existing installation
- `--dry-run` - Preview installation without making changes
- `--help` - Show help

### Manual Installation

#### Bash
```bash
echo 'source /path/to/termbrain/shell-integration/bash/termbrain.bash' >> ~/.bashrc
```

#### Zsh
```bash
echo 'source /path/to/termbrain/shell-integration/zsh/termbrain.zsh' >> ~/.zshrc
```

#### Fish
```bash
echo 'source /path/to/termbrain/shell-integration/fish/termbrain.fish' >> ~/.config/fish/config.fish
```

## Usage

### Automatic Recording

Once installed, every command is automatically recorded:

```bash
ls -la                    # ✓ Recorded
git status               # ✓ Recorded  
cargo build              # ✓ Recorded
tb search "git"          # ✗ Skipped (termbrain command)
```

### Manual Controls

```bash
tbe                      # Enable recording
tbd                      # Disable recording
tbs                      # Show status
termbrain_status        # Detailed status
```

### Viewing Data

```bash
tb history               # Recent commands
tb search "git"          # Search commands
tb statistics           # Usage stats
tb patterns             # Command patterns
```

## Configuration

### Environment Variables

Set these in your shell config before sourcing the integration:

```bash
export TERMBRAIN_ENABLED=1        # Enable/disable (1/0)
export TERMBRAIN_AUTO_RECORD=1    # Auto-record commands (1/0) 
export TERMBRAIN_SESSION_ID="custom-id"  # Custom session ID
```

### Per-Session Control

```bash
# Temporarily disable for current session
export TERMBRAIN_ENABLED=0

# Re-enable
export TERMBRAIN_ENABLED=1
```

## Troubleshooting

### Commands Not Being Recorded

1. **Check if integration is loaded:**
   ```bash
   tbs
   ```

2. **Verify CLI is available:**
   ```bash
   which tb
   tb --version
   ```

3. **Check recording status:**
   ```bash
   echo $TERMBRAIN_ENABLED
   echo $TERMBRAIN_AUTO_RECORD
   ```

4. **Test manual recording:**
   ```bash
   tb record "test command" --exit-code 0
   tb history
   ```

### Performance Issues

1. **Disable recording temporarily:**
   ```bash
   tbd
   ```

2. **Check for slow database:**
   ```bash
   tb status  # Shows database size and location
   ```

3. **Verify async recording:**
   - Commands should return immediately
   - Recording happens in background

### Shell-Specific Issues

#### Bash
- **Issue:** Pre-command timing not working
- **Cause:** Bash version < 4.0
- **Solution:** Upgrade Bash or accept post-command recording only

#### Zsh
- **Issue:** Conflicts with frameworks (Oh My Zsh, etc.)
- **Cause:** Framework overrides preexec/precmd
- **Solution:** Load TermBrain integration after framework

#### Fish
- **Issue:** Event handlers not working
- **Cause:** Fish version too old
- **Solution:** Upgrade Fish to 3.0+

### Common Problems

1. **"tb command not found"**
   ```bash
   # Add Cargo bin to PATH
   export PATH="$HOME/.cargo/bin:$PATH"
   ```

2. **"Integration already installed"**
   ```bash
   # Force reinstall
   ./shell-integration/install.sh --force
   ```

3. **"Permission denied"**
   ```bash
   # Make scripts executable
   chmod +x shell-integration/*.sh
   ```

## Uninstallation

### Automatic Uninstall

```bash
./shell-integration/uninstall.sh
```

**Options:**
- `--shell SHELL` - Uninstall from specific shell
- `--auto-detect` - Auto-detect current shell (default)
- `--dry-run` - Preview uninstallation

### Manual Uninstall

1. **Remove source line from shell config:**
   - Edit `~/.bashrc`, `~/.zshrc`, or `~/.config/fish/config.fish`
   - Delete lines containing "termbrain"

2. **Clean environment variables:**
   ```bash
   unset TERMBRAIN_ENABLED
   unset TERMBRAIN_AUTO_RECORD
   unset TERMBRAIN_SESSION_ID
   ```

3. **Restart terminal or reload config**

### Complete Removal

```bash
# Uninstall shell integration
./shell-integration/uninstall.sh

# Remove CLI
cargo uninstall termbrain-cli

# Remove data (optional)
rm -rf ~/.termbrain
```

## Privacy & Security

- **Local Only:** All data stays on your machine
- **No Network:** No data is sent anywhere
- **Transparent:** You can see exactly what's recorded
- **Controllable:** Can be disabled instantly
- **Auditable:** All code is open source

## Advanced Usage

### Custom Session IDs

```bash
export TERMBRAIN_SESSION_ID="project-alpha-$(date +%Y%m%d)"
```

### Conditional Recording

```bash
# Only record in specific directories
if [[ "$PWD" == */projects/* ]]; then
    export TERMBRAIN_ENABLED=1
else
    export TERMBRAIN_ENABLED=0
fi
```

### Integration with Other Tools

```bash
# Git hooks
echo 'tb record "git commit" --exit-code $?' >> .git/hooks/post-commit

# CI/CD
tb record "build step" --exit-code $? --directory "$CI_PROJECT_DIR"
```

## Support

- **Documentation:** [GitHub Wiki](https://github.com/anivar/termbrain/wiki)
- **Issues:** [GitHub Issues](https://github.com/anivar/termbrain/issues)
- **Discussions:** [GitHub Discussions](https://github.com/anivar/termbrain/discussions)