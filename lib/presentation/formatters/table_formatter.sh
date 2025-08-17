#!/usr/bin/env bash
# Table Formatter - Formats output as ASCII tables

TableFormatter::format() {
    local data="$1"
    local headers="${2:-}"
    
    if [[ -n "$headers" ]]; then
        echo "$headers" | tr ',' '\t'
        echo "$headers" | tr ',' '\t' | sed 's/[^\t]/-/g'
    fi
    
    echo "$data"
}

TableFormatter::format_commands() {
    local json_data="$1"
    
    # Print header
    printf "%-20s %-50s %-15s %s\n" "Time" "Command" "Type" "Exit"
    printf "%-20s %-50s %-15s %s\n" "----" "-------" "----" "----"
    
    # Format each command
    echo "$json_data" | jq -r '.[] | 
        [.timestamp, .command, .semantic_type, .exit_code] | 
        @tsv' | while IFS=$'\t' read -r timestamp cmd type exit_code; do
        
        # Truncate long commands
        if [[ ${#cmd} -gt 50 ]]; then
            cmd="${cmd:0:47}..."
        fi
        
        # Format timestamp
        timestamp=$(date -d "$timestamp" "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "$timestamp")
        
        printf "%-20s %-50s %-15s %s\n" "$timestamp" "$cmd" "$type" "${exit_code:-0}"
    done
}

TableFormatter::format_stats() {
    local json_data="$1"
    
    echo "$json_data" | jq -r '
        "Total Commands: \(.total_commands)",
        "Time Range: \(.time_range)",
        "",
        "Top Command Types:",
        (.top_types[] | "  \(.type): \(.count) (\(.percentage)%)"),
        "",
        "Activity by Hour:",
        (.hourly_activity | to_entries | .[] | "  \(.key):00 - \(.value) commands")
    '
}

TableFormatter::format_workflows() {
    local json_data="$1"
    
    printf "%-30s %-50s %s\n" "Name" "Description" "Commands"
    printf "%-30s %-50s %s\n" "----" "-----------" "--------"
    
    echo "$json_data" | jq -r '.[] | 
        [.name, .description, (.commands | length)] | 
        @tsv' | while IFS=$'\t' read -r name desc count; do
        
        # Truncate long descriptions
        if [[ ${#desc} -gt 50 ]]; then
            desc="${desc:0:47}..."
        fi
        
        printf "%-30s %-50s %d\n" "$name" "$desc" "$count"
    done
}