#!/bin/bash
# TermBrain shell integration for Bash
# This file should be sourced in ~/.bashrc or ~/.bash_profile

# Configuration
export TERMBRAIN_ENABLED="${TERMBRAIN_ENABLED:-1}"
export TERMBRAIN_AUTO_RECORD="${TERMBRAIN_AUTO_RECORD:-1}"
export TERMBRAIN_SESSION_ID="${TERMBRAIN_SESSION_ID:-$(date +%s)-$$}"

# Check if termbrain CLI is available
if ! command -v tb >/dev/null 2>&1; then
    echo "Warning: termbrain CLI (tb) not found in PATH" >&2
    return 1
fi

# Store the original PROMPT_COMMAND
TERMBRAIN_ORIGINAL_PROMPT_COMMAND="$PROMPT_COMMAND"

# Function to record command execution
_termbrain_record_command() {
    local exit_code=$?
    local end_time=$(date +%s%3N)
    
    # Skip if termbrain is disabled
    [[ "$TERMBRAIN_ENABLED" != "1" ]] && return $exit_code
    [[ "$TERMBRAIN_AUTO_RECORD" != "1" ]] && return $exit_code
    
    # Get the last command from history
    local last_command=$(history 1 | sed 's/^[ ]*[0-9]*[ ]*//')
    
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
    (
        tb record "$last_command" \
            --exit-code "$exit_code" \
            --directory "$PWD" \
            ${duration_ms:+--duration "$duration_ms"} \
            >/dev/null 2>&1 &
    )
    
    return $exit_code
}

# Function to record command start time
_termbrain_pre_command() {
    [[ "$TERMBRAIN_ENABLED" == "1" ]] && export TERMBRAIN_COMMAND_START_TIME=$(date +%s%3N)
}

# Set up command recording
if [[ "$TERMBRAIN_ENABLED" == "1" ]]; then
    # Use DEBUG trap for pre-command hook (Bash 4.0+)
    if [[ ${BASH_VERSION%%.*} -ge 4 ]]; then
        trap '_termbrain_pre_command' DEBUG
    fi
    
    # Set up post-command hook
    if [[ -n "$TERMBRAIN_ORIGINAL_PROMPT_COMMAND" ]]; then
        PROMPT_COMMAND="_termbrain_record_command; $TERMBRAIN_ORIGINAL_PROMPT_COMMAND"
    else
        PROMPT_COMMAND="_termbrain_record_command"
    fi
fi

# Utility functions for manual control
termbrain_enable() {
    export TERMBRAIN_ENABLED=1
    echo "TermBrain recording enabled"
}

termbrain_disable() {
    export TERMBRAIN_ENABLED=0
    echo "TermBrain recording disabled"
}

termbrain_status() {
    echo "TermBrain Status:"
    echo "  Enabled: ${TERMBRAIN_ENABLED}"
    echo "  Auto-record: ${TERMBRAIN_AUTO_RECORD}"
    echo "  Session ID: ${TERMBRAIN_SESSION_ID}"
    echo "  Shell: ${SHELL}"
    echo "  PWD: ${PWD}"
}

# Aliases for convenience
alias tbs='termbrain_status'
alias tbe='termbrain_enable'
alias tbd='termbrain_disable'

# Tab completion for termbrain commands
if command -v tb >/dev/null 2>&1 && command -v complete >/dev/null 2>&1; then
    # Basic completion - in a full implementation, this would be more sophisticated
    complete -W "record search history statistics patterns workflow export install interactive status help" tb
fi

echo "TermBrain shell integration loaded (Bash)"