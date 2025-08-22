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

# Function to detect AI agents
_termbrain_detect_ai_agent() {
    # Check if already wrapped by tb wrap
    if [[ -n "$TERMBRAIN_AI_WRAPPED" ]]; then
        return 0
    fi
    
    # Check for common AI agent environment variables
    if [[ -n "$AIDER_CHAT_ID" ]]; then
        export TERMBRAIN_AI_AGENT="aider"
        export TERMBRAIN_AI_SESSION="${AIDER_CHAT_ID}"
        return 0
    fi
    
    if [[ -n "$CURSOR_SESSION_ID" ]] || [[ -n "$CURSOR_CONTEXT" ]]; then
        export TERMBRAIN_AI_AGENT="cursor"
        export TERMBRAIN_AI_SESSION="${CURSOR_SESSION_ID:-$CURSOR_CONTEXT}"
        return 0
    fi
    
    if [[ -n "$CONTINUE_SESSION" ]] || [[ -n "$CONTINUE_CONTEXT_ID" ]]; then
        export TERMBRAIN_AI_AGENT="continue"
        export TERMBRAIN_AI_SESSION="${CONTINUE_SESSION:-$CONTINUE_CONTEXT_ID}"
        return 0
    fi
    
    if [[ -n "$CODY_SESSION_ID" ]] || [[ -n "$CODY_AGENT" ]]; then
        export TERMBRAIN_AI_AGENT="cody"
        export TERMBRAIN_AI_SESSION="${CODY_SESSION_ID:-$CODY_AGENT}"
        return 0
    fi
    
    if [[ -n "$COPILOT_SESSION" ]] || [[ -n "$GITHUB_COPILOT_CHAT" ]]; then
        export TERMBRAIN_AI_AGENT="copilot"
        export TERMBRAIN_AI_SESSION="${COPILOT_SESSION:-$GITHUB_COPILOT_CHAT}"
        return 0
    fi
    
    if [[ -n "$CLAUDE_SESSION_ID" ]] || [[ -n "$ANTHROPIC_SESSION_ID" ]] || [[ -n "$CLAUDE_CONVERSATION_ID" ]]; then
        export TERMBRAIN_AI_AGENT="claude"
        export TERMBRAIN_AI_SESSION="${CLAUDE_SESSION_ID:-${ANTHROPIC_SESSION_ID:-$CLAUDE_CONVERSATION_ID}}"
        return 0
    fi
    
    if [[ -n "$GEMINI_SESSION_ID" ]] || [[ -n "$GOOGLE_AI_SESSION" ]] || [[ -n "$BARD_SESSION_ID" ]]; then
        export TERMBRAIN_AI_AGENT="gemini"
        export TERMBRAIN_AI_SESSION="${GEMINI_SESSION_ID:-${GOOGLE_AI_SESSION:-$BARD_SESSION_ID}}"
        return 0
    fi
    
    # Check process tree for AI agents
    local ppid_chain="$$"
    local current_pid="$$"
    local max_depth=10
    local depth=0
    
    while [[ $depth -lt $max_depth ]]; do
        current_pid=$(ps -o ppid= -p "$current_pid" 2>/dev/null | tr -d ' ')
        [[ -z "$current_pid" ]] || [[ "$current_pid" == "1" ]] && break
        
        local process_name=$(ps -o comm= -p "$current_pid" 2>/dev/null | tr -d ' ')
        
        case "$process_name" in
            *aider*|*Aider*)
                export TERMBRAIN_AI_AGENT="aider"
                export TERMBRAIN_AI_SESSION="pid-${current_pid}"
                return 0
                ;;
            *cursor*|*Cursor*)
                export TERMBRAIN_AI_AGENT="cursor"
                export TERMBRAIN_AI_SESSION="pid-${current_pid}"
                return 0
                ;;
            *continue*|*Continue*)
                export TERMBRAIN_AI_AGENT="continue"
                export TERMBRAIN_AI_SESSION="pid-${current_pid}"
                return 0
                ;;
            *cody*|*Cody*)
                export TERMBRAIN_AI_AGENT="cody"
                export TERMBRAIN_AI_SESSION="pid-${current_pid}"
                return 0
                ;;
            *copilot*|*Copilot*)
                export TERMBRAIN_AI_AGENT="copilot"
                export TERMBRAIN_AI_SESSION="pid-${current_pid}"
                return 0
                ;;
            *claude*|*Claude*|*anthropic*)
                export TERMBRAIN_AI_AGENT="claude"
                export TERMBRAIN_AI_SESSION="pid-${current_pid}"
                return 0
                ;;
            *gemini*|*Gemini*|*bard*|*Bard*)
                export TERMBRAIN_AI_AGENT="gemini"
                export TERMBRAIN_AI_SESSION="pid-${current_pid}"
                return 0
                ;;
        esac
        
        ((depth++))
    done
    
    return 1
}

# Function to record command execution
_termbrain_record_command() {
    local exit_code=$?
    local end_time=$(date +%s%3N)
    
    # Skip if termbrain is disabled
    [[ "$TERMBRAIN_ENABLED" != "1" ]] && return $exit_code
    [[ "$TERMBRAIN_AUTO_RECORD" != "1" ]] && return $exit_code
    
    # Detect AI agents if not already set
    _termbrain_detect_ai_agent
    
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
    # Use printf to safely escape the command and directory
    (
        tb record -- "$last_command" \
            --exit-code "$exit_code" \
            --directory "$(realpath -- "$PWD" 2>/dev/null || printf '%s' "$PWD")" \
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
    # Detect AI agent before showing status
    _termbrain_detect_ai_agent
    
    echo "TermBrain Status:"
    echo "  Enabled: ${TERMBRAIN_ENABLED}"
    echo "  Auto-record: ${TERMBRAIN_AUTO_RECORD}"
    echo "  Session ID: ${TERMBRAIN_SESSION_ID}"
    echo "  Shell: ${SHELL}"
    echo "  PWD: ${PWD}"
    
    # Show AI agent info if detected
    if [[ -n "$TERMBRAIN_AI_AGENT" ]]; then
        echo "  AI Agent: ${TERMBRAIN_AI_AGENT}"
        echo "  AI Session: ${TERMBRAIN_AI_SESSION:-N/A}"
        [[ -n "$TERMBRAIN_AI_CONTEXT" ]] && echo "  AI Context: ${TERMBRAIN_AI_CONTEXT}"
    fi
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