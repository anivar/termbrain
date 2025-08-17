#!/usr/bin/env bash
# Command Entity - Core business object for terminal commands

# Command constructor
Command::new() {
    local command="$1"
    local directory="${2:-$PWD}"
    local exit_code="${3:-0}"
    local duration_ms="${4:-0}"
    local session_id="${5:-$TERMBRAIN_SESSION_ID}"
    
    # Validate business rules
    if [[ -z "$command" ]]; then
        echo "ERROR: Command text is required" >&2
        return 1
    fi
    
    # Return command as structured data
    printf '%s\n' "command:$command"
    printf '%s\n' "directory:$directory"
    printf '%s\n' "exit_code:$exit_code"
    printf '%s\n' "duration_ms:$duration_ms"
    printf '%s\n' "session_id:$session_id"
    printf '%s\n' "timestamp:$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '%s\n' "git_branch:$(git branch --show-current 2>/dev/null || echo '')"
    printf '%s\n' "is_sensitive:$(Command::is_sensitive "$command")"
}

# Parse command from storage format
Command::from_storage() {
    local data="$1"
    echo "$data"
}

# Get command property
Command::get() {
    local command_data="$1"
    local property="$2"
    echo "$command_data" | grep "^$property:" | cut -d: -f2-
}

# Check if command contains sensitive information
Command::is_sensitive() {
    local command="$1"
    
    # Business rules for sensitive commands
    if [[ "$command" =~ (password|token|secret|api_key|private|ssh.*-i|curl.*-H.*Authorization) ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Check if command is safe to record
Command::is_safe_to_record() {
    local command="$1"
    local directory="${2:-$PWD}"
    
    # Don't record dangerous commands
    case "$command" in
        *"rm -rf /"*|*"dd if="*|*":(){ :|:& };:"*)
            return 1
            ;;
    esac
    
    # Don't record in sensitive directories
    case "$directory" in
        */.ssh*|*/.gnupg*|*/private/*)
            return 1
            ;;
    esac
    
    return 0
}

# Validate command for storage
Command::validate() {
    local command_data="$1"
    
    local command=$(Command::get "$command_data" "command")
    local directory=$(Command::get "$command_data" "directory")
    
    # Check if safe to record
    if ! Command::is_safe_to_record "$command" "$directory"; then
        echo "ERROR: Command not safe to record" >&2
        return 1
    fi
    
    # Check command length
    if [[ ${#command} -gt 1000 ]]; then
        echo "ERROR: Command too long (max 1000 characters)" >&2
        return 1
    fi
    
    return 0
}

# Sanitize command for display
Command::sanitize() {
    local command="$1"
    
    # Replace sensitive patterns
    echo "$command" | sed -E 's/(password|token|secret|api_key)=[^ ]*/\1=****/gi'
}