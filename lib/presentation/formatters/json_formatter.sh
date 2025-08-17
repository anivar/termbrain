#!/usr/bin/env bash
# JSON Formatter - Formats output as JSON

JsonFormatter::format() {
    local data="$1"
    
    # If already JSON, pretty print it
    if echo "$data" | jq . >/dev/null 2>&1; then
        echo "$data" | jq .
    else
        # Convert to JSON
        jq -n --arg data "$data" '{output: $data}'
    fi
}

JsonFormatter::format_commands() {
    local json_data="$1"
    
    # Already in JSON format, just ensure it's pretty
    echo "$json_data" | jq .
}

JsonFormatter::format_stats() {
    local json_data="$1"
    
    # Already in JSON format
    echo "$json_data" | jq .
}

JsonFormatter::format_workflows() {
    local json_data="$1"
    
    # Already in JSON format
    echo "$json_data" | jq .
}

JsonFormatter::wrap_result() {
    local result="$1"
    local metadata="$2"
    
    jq -n \
        --arg result "$result" \
        --argjson metadata "${metadata:-{}}" \
        '{
            timestamp: now | strftime("%Y-%m-%dT%H:%M:%SZ"),
            result: $result,
            metadata: $metadata
        }'
}