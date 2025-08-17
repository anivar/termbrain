#!/usr/bin/env bash
# Search Commands Implementation

source "${TERMBRAIN_LIB}/domain/repositories/command_repository.sh"
source "${TERMBRAIN_LIB}/infrastructure/repositories/sqlite_command_repository.sh"

# Initialize repository
SqliteCommandRepository::init

# Search for commands
SearchCommands::execute() {
    local query="$1"
    local limit="${2:-50}"
    
    if [[ -z "$query" ]]; then
        echo "Usage: tb search <query>"
        return 1
    fi
    
    local results=$(CommandRepository::search "$query" "$limit")
    
    if [[ -z "$results" ]]; then
        echo "No commands found matching: $query"
        return 0
    fi
    
    echo "Commands matching '$query':"
    echo ""
    
    # Format results
    while IFS='|' read -r id command timestamp exit_code semantic_type; do
        local status_icon="✓"
        if [[ "$exit_code" != "0" ]]; then
            status_icon="✗"
        fi
        
        printf "%s %s\n" "$status_icon" "$command"
        printf "   %s • %s\n" "$timestamp" "${semantic_type:-general}"
        echo ""
    done <<< "$results"
}

# Export functions
export -f SearchCommands::execute