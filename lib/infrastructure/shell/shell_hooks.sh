#!/usr/bin/env bash
# Shell Hook Integration

source "${TERMBRAIN_LIB}/application/commands/record_command.sh"
source "${TERMBRAIN_LIB}/infrastructure/repositories/sqlite_command_repository.sh"

# Initialize shell hooks
ShellHooks::init() {
    # Initialize command repository
    SqliteCommandRepository::init
    
    # Set up hooks based on shell type
    if [[ -n "$BASH_VERSION" ]]; then
        ShellHooks::setup_bash
    elif [[ -n "$ZSH_VERSION" ]]; then
        ShellHooks::setup_zsh
    else
        echo "Warning: Unsupported shell. Some features may not work." >&2
    fi
}

# Bash-specific setup
ShellHooks::setup_bash() {
    # Preexec hook for Bash
    _termbrain_preexec() {
        RecordCommand::start "$BASH_COMMAND"
    }
    
    # Precmd hook for Bash
    _termbrain_precmd() {
        RecordCommand::complete "$?"
    }
    
    # Set up hooks
    trap '_termbrain_preexec "$BASH_COMMAND"' DEBUG
    
    # Add to PROMPT_COMMAND
    if [[ -z "$PROMPT_COMMAND" ]]; then
        PROMPT_COMMAND="_termbrain_precmd"
    else
        PROMPT_COMMAND="$PROMPT_COMMAND; _termbrain_precmd"
    fi
}

# Zsh-specific setup
ShellHooks::setup_zsh() {
    # Load zsh hooks
    autoload -U add-zsh-hook
    
    # Preexec hook for Zsh
    _termbrain_preexec() {
        RecordCommand::start "$1"
    }
    
    # Precmd hook for Zsh
    _termbrain_precmd() {
        RecordCommand::complete "$?"
    }
    
    # Register hooks
    add-zsh-hook preexec _termbrain_preexec
    add-zsh-hook precmd _termbrain_precmd
}

# Check if hooks are active
ShellHooks::is_active() {
    if [[ -n "$BASH_VERSION" ]]; then
        # Check if DEBUG trap is set
        if trap -p DEBUG | grep -q "_termbrain_preexec"; then
            return 0
        fi
    elif [[ -n "$ZSH_VERSION" ]]; then
        # Check if zsh hooks are registered
        if [[ " ${preexec_functions[*]} " =~ " _termbrain_preexec " ]]; then
            return 0
        fi
    fi
    return 1
}

# Disable hooks
ShellHooks::disable() {
    if [[ -n "$BASH_VERSION" ]]; then
        trap - DEBUG
        # Remove from PROMPT_COMMAND
        PROMPT_COMMAND="${PROMPT_COMMAND//_termbrain_precmd/}"
        PROMPT_COMMAND="${PROMPT_COMMAND//;;/;}"
        PROMPT_COMMAND="${PROMPT_COMMAND%;}"
        PROMPT_COMMAND="${PROMPT_COMMAND#;}"
    elif [[ -n "$ZSH_VERSION" ]]; then
        # Remove zsh hooks
        if command -v add-zsh-hook >/dev/null 2>&1; then
            add-zsh-hook -d preexec _termbrain_preexec
            add-zsh-hook -d precmd _termbrain_precmd
        fi
    fi
}

# Enable hooks
ShellHooks::enable() {
    ShellHooks::init
}