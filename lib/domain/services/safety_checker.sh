#!/usr/bin/env bash
# Safety Checker Service - Security and privacy protection

# Check if command contains sensitive data
SafetyChecker::is_sensitive() {
    local cmd="$1"
    
    # Basic check from original
    if [[ "$cmd" =~ (password|token|key|secret|credential|auth) ]]; then
        echo "true"
        return 0
    fi
    
    echo "false"
    return 1
}

# Enhanced sensitive data detection
SafetyChecker::is_sensitive_enhanced() {
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
            echo "true"
            return 0
        fi
    done
    
    # Check for environment variable assignments
    if [[ "$cmd" =~ ^[A-Z_]+=[^[:space:]]+ ]]; then
        echo "true"
        return 0
    fi
    
    # Check for base64 encoded data
    if [[ "$cmd" =~ [A-Za-z0-9+/]{40,}={0,2} ]]; then
        echo "true"
        return 0
    fi
    
    echo "false"
    return 1
}

# Redact sensitive information
SafetyChecker::redact() {
    local text="$1"
    
    # Redact common patterns
    text=$(echo "$text" | sed -E 's/(password|token|key|secret)=[^ ]+/\1=***REDACTED***/gi')
    text=$(echo "$text" | sed -E 's/[A-Za-z0-9+/]{40,}={0,2}/***BASE64-REDACTED***/g')
    text=$(echo "$text" | sed -E 's/[0-9a-f]{32,}/***HASH-REDACTED***/g')
    
    echo "$text"
}

# Validate file paths to prevent traversal
SafetyChecker::validate_path() {
    local path="$1"
    local resolved=$(realpath "$path" 2>/dev/null)
    
    # Check if path is within allowed directories
    if [[ ! "$resolved" =~ ^($HOME|/tmp|/var/tmp) ]]; then
        echo "false"
        return 1
    fi
    
    # Check for suspicious patterns
    if [[ "$path" =~ \.\./\.\./\.\. ]]; then
        echo "false"
        return 1
    fi
    
    echo "true"
    return 0
}

# Check if command is safe to execute
SafetyChecker::is_safe_command() {
    local cmd="$1"
    
    # Dangerous commands that should be blocked
    local dangerous_patterns=(
        "rm -rf /"
        "rm -rf /*"
        ":(){ :|:& };:"  # Fork bomb
        "dd if=/dev/zero of="
        "mkfs."
        "> /dev/sda"
    )
    
    for pattern in "${dangerous_patterns[@]}"; do
        if [[ "$cmd" == *"$pattern"* ]]; then
            echo "false"
            return 1
        fi
    done
    
    echo "true"
    return 0
}

# Sanitize SQL input
SafetyChecker::escape_sql() {
    local input="$1"
    # Escape single quotes by doubling them
    echo "$input" | sed "s/'/''/g"
}

# Backwards compatibility
tb::check_sensitive() {
    SafetyChecker::is_sensitive "$1"
}

tb::check_sensitive_enhanced() {
    SafetyChecker::is_sensitive_enhanced "$1"
}

tb::redact_sensitive() {
    SafetyChecker::redact "$1"
}

tb::validate_path() {
    SafetyChecker::validate_path "$1"
}

tb::escape_sql() {
    SafetyChecker::escape_sql "$1"
}