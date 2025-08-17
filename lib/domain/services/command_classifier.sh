#!/usr/bin/env bash
# Command Classifier Service

# Classify command by semantic type
CommandClassifier::classify() {
    local command="$1"
    
    # Version control
    if [[ "$command" =~ ^(git|svn|hg|mercurial) ]]; then
        echo "version_control"
        return
    fi
    
    # Testing (check before package management to catch npm test)
    if [[ "$command" =~ ^(npm|yarn|pnpm)\ (test|run\ test) ]] || \
       [[ "$command" =~ ^(pytest|unittest|phpunit|jest|mocha) ]] || \
       [[ "$command" =~ ^\./(run_)?tests?\.sh ]] || \
       [[ "$command" =~ \.(test|spec)\.js ]]; then
        echo "testing"
        return
    fi
    
    # Package management (after testing check)
    if [[ "$command" =~ ^(npm|yarn|pnpm|pip|pip3|gem|cargo|go|apt|apt-get|yum|dnf|brew|snap|composer) ]]; then
        echo "package_management"
        return
    fi
    
    # Building/Compilation
    if [[ "$command" =~ ^(make|cmake|gcc|g\+\+|clang|rustc|go build|npm run build|yarn build|mvn|gradle) ]]; then
        echo "building"
        return
    fi
    
    # Containers
    if [[ "$command" =~ ^(docker|docker-compose|kubectl|podman|containerd) ]]; then
        echo "container"
        return
    fi
    
    # File operations
    if [[ "$command" =~ ^(cp|mv|rm|mkdir|touch|chmod|chown) ]]; then
        echo "file_operation"
        return
    fi
    
    # Navigation
    if [[ "$command" =~ ^(cd|ls|pwd|find|locate|tree) ]]; then
        echo "navigation"
        return
    fi
    
    # Process management
    if [[ "$command" =~ ^(ps|top|htop|kill|killall|jobs|fg|bg) ]]; then
        echo "process_management"
        return
    fi
    
    # Network
    if [[ "$command" =~ ^(curl|wget|ping|nc|netcat|ssh|scp|rsync|telnet) ]]; then
        echo "network"
        return
    fi
    
    # System administration
    if [[ "$command" =~ ^(sudo|su|systemctl|service|journalctl) ]]; then
        echo "system_admin"
        return
    fi
    
    # Database
    if [[ "$command" =~ ^(mysql|psql|mongo|redis-cli|sqlite3) ]]; then
        echo "database"
        return
    fi
    
    # Monitoring
    if [[ "$command" =~ (tail|head|less|more|watch|grep|awk|sed) ]] && \
       [[ "$command" =~ (log|\.log) ]]; then
        echo "monitoring"
        return
    fi
    
    # Searching
    if [[ "$command" =~ ^(grep|egrep|fgrep|ag|rg|ack|find.*-name) ]]; then
        echo "searching"
        return
    fi
    
    # Default
    echo "general"
}

# Check if command contains sensitive information
CommandClassifier::is_sensitive() {
    local command="$1"
    
    # Check for passwords
    if [[ "$command" =~ (password|passwd|pwd|secret|key|token|api_key|access_key) ]]; then
        echo "true"
        return
    fi
    
    # Check for credentials in environment variables
    if [[ "$command" =~ (export|set).*(_KEY|_TOKEN|_SECRET|_PASSWORD|_PASSWD) ]]; then
        echo "true"
        return
    fi
    
    # Check for auth tokens in URLs
    if [[ "$command" =~ (https?://[^@]+@|Authorization:|Bearer\s) ]]; then
        echo "true"
        return
    fi
    
    echo "false"
}

# Get command complexity (1-5 scale)
CommandClassifier::get_complexity() {
    local command="$1"
    local pipe_count=$(echo "$command" | grep -o '|' | wc -l | tr -d ' ')
    local redirect_count=$(echo "$command" | grep -o '[<>]' | wc -l | tr -d ' ')
    local subshell_count=$(echo "$command" | grep -o '[$()]' | wc -l | tr -d ' ')
    
    # Calculate complexity
    local complexity=1
    
    # Each pipe adds to complexity
    complexity=$((complexity + pipe_count))
    
    # Redirects add complexity
    if [[ $redirect_count -gt 0 ]]; then
        complexity=$((complexity + 1))
    fi
    
    # Subshells add complexity
    if [[ $subshell_count -gt 2 ]]; then
        complexity=$((complexity + 1))
    fi
    
    # Complex commands like xargs add complexity
    if [[ "$command" =~ (xargs|parallel|find.*-exec) ]]; then
        complexity=$((complexity + 1))
    fi
    
    # Cap at 5
    if [[ $complexity -gt 5 ]]; then
        complexity=5
    fi
    
    echo "$complexity"
}

# Export functions
export -f CommandClassifier::classify
export -f CommandClassifier::is_sensitive
export -f CommandClassifier::get_complexity