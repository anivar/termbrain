#!/usr/bin/env bash
# Knowledge Entity - Represents learned insights and knowledge

Knowledge::new() {
    local topic="$1"
    local insight="$2"
    local source="${3:-experience}"
    local confidence="${4:-5}"
    
    # Validate required fields
    if [[ -z "$topic" ]] || [[ -z "$insight" ]]; then
        echo "ERROR: Topic and insight are required for knowledge" >&2
        return 1
    fi
    
    # Create knowledge JSON
    jq -n \
        --arg topic "$topic" \
        --arg insight "$insight" \
        --arg source "$source" \
        --arg confidence "$confidence" \
        --arg created_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{
            topic: $topic,
            insight: $insight,
            source: $source,
            confidence: ($confidence | tonumber),
            verified: false,
            created_at: $created_at,
            last_used: $created_at
        }'
}

Knowledge::verify() {
    local knowledge="$1"
    echo "$knowledge" | jq '.verified = true'
}

Knowledge::increase_confidence() {
    local knowledge="$1"
    local amount="${2:-1}"
    
    echo "$knowledge" | jq \
        --arg amount "$amount" \
        '.confidence = [(.confidence + ($amount | tonumber)), 10] | min'
}

Knowledge::update_last_used() {
    local knowledge="$1"
    echo "$knowledge" | jq \
        --arg now "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '.last_used = $now'
}

Knowledge::get_topic() {
    local knowledge="$1"
    echo "$knowledge" | jq -r '.topic'
}

Knowledge::get_confidence() {
    local knowledge="$1"
    echo "$knowledge" | jq -r '.confidence'
}