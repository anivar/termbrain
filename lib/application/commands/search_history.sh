#!/usr/bin/env bash
# Search History Use Case

source "${TERMBRAIN_LIB}/domain/repositories/command_repository.sh"

# Search command history
SearchHistory::execute() {
    local query="$1"
    local format="${2:-table}"
    local limit="${3:-20}"
    
    if [[ -z "$query" ]]; then
        # Return recent commands if no query
        local results=$(CommandRepository::get_recent "$limit")
    else
        # Search for specific query
        local results=$(CommandRepository::search "$query" "$limit")
    fi
    
    if [[ -z "$results" ]]; then
        echo "No commands found."
        return 0
    fi
    
    # Format output
    case "$format" in
        table)
            SearchHistory::format_table "$results"
            ;;
        json)
            SearchHistory::format_json "$results"
            ;;
        simple)
            SearchHistory::format_simple "$results"
            ;;
        *)
            SearchHistory::format_table "$results"
            ;;
    esac
}

# Format as table
SearchHistory::format_table() {
    local results="$1"
    
    printf "%-5s %-50s %-20s %-6s %-15s\n" "ID" "Command" "Time" "Status" "Type"
    printf "%-5s %-50s %-20s %-6s %-15s\n" "---" "-------" "----" "------" "----"
    
    while IFS='|' read -r id command timestamp exit_code semantic_type; do
        # Truncate long commands
        local short_cmd="${command:0:47}"
        if [[ ${#command} -gt 47 ]]; then
            short_cmd="${short_cmd}..."
        fi
        
        # Format timestamp
        local short_time="${timestamp:11:8}"
        
        # Status indicator
        local status="✓"
        if [[ "$exit_code" != "0" ]]; then
            status="✗"
        fi
        
        printf "%-5s %-50s %-20s %-6s %-15s\n" "$id" "$short_cmd" "$short_time" "$status" "$semantic_type"
    done <<< "$results"
}

# Format as JSON
SearchHistory::format_json() {
    local results="$1"
    
    echo "["
    local first=true
    while IFS='|' read -r id command timestamp exit_code semantic_type; do
        if [[ "$first" == "true" ]]; then
            first=false
        else
            echo ","
        fi
        
        printf '  {
    "id": %s,
    "command": "%s",
    "timestamp": "%s",
    "exit_code": %s,
    "semantic_type": "%s"
  }' "$id" "${command//\"/\\\"}" "$timestamp" "$exit_code" "$semantic_type"
    done <<< "$results"
    echo ""
    echo "]"
}

# Format as simple list
SearchHistory::format_simple() {
    local results="$1"
    
    while IFS='|' read -r id command timestamp exit_code semantic_type; do
        local status_icon="✓"
        if [[ "$exit_code" != "0" ]]; then
            status_icon="✗"
        fi
        echo "$status_icon $command"
    done <<< "$results"
}

# Search by semantic type
SearchHistory::by_semantic_type() {
    local semantic_type="$1"
    local limit="${2:-20}"
    
    local results=$(CommandRepository::find_by_semantic_type "$semantic_type" "$limit")
    
    if [[ -z "$results" ]]; then
        echo "No $semantic_type commands found."
        return 0
    fi
    
    echo "Recent $semantic_type commands:"
    SearchHistory::format_table "$results"
}

# Get command statistics by type
SearchHistory::stats_by_type() {
    sqlite3 "$TERMBRAIN_DB" -column -header <<EOF
SELECT 
    semantic_type as Type,
    COUNT(*) as Count,
    printf('%.1f%%', 100.0 * COUNT(*) / (SELECT COUNT(*) FROM commands)) as Percentage,
    printf('%.1f%%', 100.0 * SUM(CASE WHEN exit_code = 0 THEN 1 ELSE 0 END) / COUNT(*)) as Success
FROM commands 
WHERE is_sensitive = 0
GROUP BY semantic_type 
ORDER BY COUNT(*) DESC 
LIMIT 10;
EOF
}