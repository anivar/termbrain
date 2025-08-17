#!/usr/bin/env bash
# Session Entity - Represents a terminal session

# Session constructor
Session::new() {
    local shell="${1:-$SHELL}"
    local user="${2:-$USER}"
    local hostname="${3:-$HOSTNAME}"
    local working_dir="${4:-$PWD}"
    
    # Generate unique session ID
    local session_id="session-$(date +%s)-$$"
    
    # Return session data
    printf '%s\n' "id:$session_id"
    printf '%s\n' "shell:$shell"
    printf '%s\n' "user:$user"
    printf '%s\n' "hostname:$hostname"
    printf '%s\n' "working_dir:$working_dir"
    printf '%s\n' "start_time:$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '%s\n' "status:active"
}

# Get session property
Session::get() {
    local session_data="$1"
    local property="$2"
    echo "$session_data" | grep "^$property:" | cut -d: -f2-
}

# Mark session as ended
Session::end() {
    local session_data="$1"
    local end_time="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    
    echo "$session_data" | sed "s/^status:.*/status:ended/" | sed "s/^end_time:.*/end_time:$end_time/"
    
    # Add end_time if not present
    if ! echo "$session_data" | grep -q "^end_time:"; then
        printf '%s\n' "end_time:$end_time"
    fi
}

# Validate session
Session::validate() {
    local session_data="$1"
    
    local session_id=$(Session::get "$session_data" "id")
    if [[ -z "$session_id" ]]; then
        echo "ERROR: Session ID is required" >&2
        return 1
    fi
    
    return 0
}

# Get current session ID
Session::current_id() {
    echo "${TERMBRAIN_SESSION_ID:-session-$(date +%s)-$$}"
}