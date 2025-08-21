#!/bin/zsh
# TermBrain shell integration for Zsh
# This file should be sourced in ~/.zshrc

# Configuration
export TERMBRAIN_ENABLED="${TERMBRAIN_ENABLED:-1}"
export TERMBRAIN_AUTO_RECORD="${TERMBRAIN_AUTO_RECORD:-1}"
export TERMBRAIN_SESSION_ID="${TERMBRAIN_SESSION_ID:-$(date +%s)-$$}"

# Check if termbrain CLI is available
if ! command -v tb >/dev/null 2>&1; then
    echo "Warning: termbrain CLI (tb) not found in PATH" >&2
    return 1
fi

# Function to record command execution
_termbrain_record_command() {
    local exit_code=$?
    local end_time=$(date +%s%3N)
    
    # Skip if termbrain is disabled
    [[ "$TERMBRAIN_ENABLED" != "1" ]] && return $exit_code
    [[ "$TERMBRAIN_AUTO_RECORD" != "1" ]] && return $exit_code
    
    # Get the last command from history
    local last_command=$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')
    
    # Skip empty commands or termbrain commands
    [[ -z "$last_command" ]] && return $exit_code
    [[ "$last_command" =~ ^tb[[:space:]] ]] && return $exit_code
    [[ "$last_command" =~ ^termbrain[[:space:]] ]] && return $exit_code
    
    # Calculate duration if start time is available
    local duration_ms=""
    if [[ -n "$TERMBRAIN_COMMAND_START_TIME" ]]; then
        duration_ms=$((end_time - TERMBRAIN_COMMAND_START_TIME))
        unset TERMBRAIN_COMMAND_START_TIME
    fi
    
    # Record the command asynchronously
    # Use -- to prevent command injection and safely handle paths
    (
        tb record -- "$last_command" \
            --exit-code "$exit_code" \
            --directory "$(realpath -- "$PWD" 2>/dev/null || print -r -- "$PWD")" \
            ${duration_ms:+--duration "$duration_ms"} \
            >/dev/null 2>&1 &
    )
    
    return $exit_code
}

# Function to record command start time
_termbrain_pre_command() {
    [[ "$TERMBRAIN_ENABLED" == "1" ]] && export TERMBRAIN_COMMAND_START_TIME=$(date +%s%3N)
}

# Set up command recording using Zsh hooks
if [[ "$TERMBRAIN_ENABLED" == "1" ]]; then
    # Pre-command hook
    preexec_functions+=(_termbrain_pre_command)
    
    # Post-command hook
    precmd_functions+=(_termbrain_record_command)
fi

# Utility functions for manual control
termbrain_enable() {
    export TERMBRAIN_ENABLED=1
    if ! (( ${preexec_functions[(I)_termbrain_pre_command]} )); then
        preexec_functions+=(_termbrain_pre_command)
    fi
    if ! (( ${precmd_functions[(I)_termbrain_record_command]} )); then
        precmd_functions+=(_termbrain_record_command)
    fi
    echo "TermBrain recording enabled"
}

termbrain_disable() {
    export TERMBRAIN_ENABLED=0
    preexec_functions=(${preexec_functions[@]//_termbrain_pre_command})
    precmd_functions=(${precmd_functions[@]//_termbrain_record_command})
    echo "TermBrain recording disabled"
}

termbrain_status() {
    echo "TermBrain Status:"
    echo "  Enabled: ${TERMBRAIN_ENABLED}"
    echo "  Auto-record: ${TERMBRAIN_AUTO_RECORD}"
    echo "  Session ID: ${TERMBRAIN_SESSION_ID}"
    echo "  Shell: ${SHELL}"
    echo "  PWD: ${PWD}"
    echo "  Zsh Version: ${ZSH_VERSION}"
}

# Aliases for convenience
alias tbs='termbrain_status'
alias tbe='termbrain_enable'
alias tbd='termbrain_disable'

# Tab completion for termbrain commands
if command -v tb >/dev/null 2>&1; then
    # Zsh completion function
    _tb_completion() {
        local -a commands
        commands=(
            'record:Record a command execution'
            'search:Search command history'
            'history:Show recent command history'
            'statistics:Show usage statistics'
            'patterns:Detect and show usage patterns'
            'workflow:Manage workflows'
            'export:Export command data'
            'install:Setup shell integration'
            'interactive:Start interactive session'
            'status:Show system status'
            'help:Show help information'
        )
        _describe 'termbrain commands' commands
    }
    
    compdef _tb_completion tb
fi

echo "TermBrain shell integration loaded (Zsh)"