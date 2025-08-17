#!/usr/bin/env bash
# Safety and security utilities for Termbrain

# Enhanced sensitive data detection
tb::check_sensitive_enhanced() {
    local cmd="$1"
    
    # Check for various sensitive patterns
    local patterns=(
        "password|passwd|pwd"
        "token|api_key|apikey|api-key"
        "secret|private|priv"
        "credential|cred"
        "auth|authorization"
        "\\bkey\\b|\\bkeys\\b"
        "cert|certificate"
        "ssh|gpg|pgp"
        "aws_access|aws_secret"
        "database_url|db_url|connection_string"
    )
    
    for pattern in "${patterns[@]}"; do
        if [[ "$cmd" =~ $pattern ]]; then
            return 0  # Is sensitive
        fi
    done
    
    # Check for environment variable assignments
    if [[ "$cmd" =~ ^[A-Z_]+=[^[:space:]]+ ]]; then
        return 0  # Likely sensitive
    fi
    
    # Check for base64 encoded data
    if [[ "$cmd" =~ [A-Za-z0-9+/]{40,}={0,2} ]]; then
        return 0  # Possibly sensitive
    fi
    
    return 1  # Not sensitive
}

# Redact sensitive information
tb::redact_sensitive() {
    local text="$1"
    
    # Redact common patterns
    text=$(echo "$text" | sed -E 's/(password|token|key|secret)=[^ ]+/\1=***REDACTED***/gi')
    text=$(echo "$text" | sed -E 's/[A-Za-z0-9+/]{40,}={0,2}/***BASE64-REDACTED***/g')
    text=$(echo "$text" | sed -E 's/[0-9a-f]{32,}/***HASH-REDACTED***/g')
    
    echo "$text"
}

# Validate file paths to prevent traversal
tb::validate_path() {
    local path="$1"
    local resolved=$(realpath "$path" 2>/dev/null)
    
    # Check if path is within allowed directories
    if [[ ! "$resolved" =~ ^($HOME|/tmp|/var/tmp) ]]; then
        return 1  # Invalid path
    fi
    
    # Check for suspicious patterns
    if [[ "$path" =~ \.\./\.\./\.\. ]]; then
        return 1  # Path traversal attempt
    fi
    
    return 0  # Valid path
}