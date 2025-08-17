#!/usr/bin/env bash
# Intention Entity - Represents user goals and intentions

Intention::new() {
    local goal="$1"
    local context="${2:-}"
    local complexity="${3:-5}"
    
    # Validate goal
    if [[ -z "$goal" ]]; then
        echo "ERROR: Goal is required for intention" >&2
        return 1
    fi
    
    # Create intention JSON
    jq -n \
        --arg goal "$goal" \
        --arg context "$context" \
        --arg complexity "$complexity" \
        --arg timestamp "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{
            goal: $goal,
            context: $context,
            complexity: ($complexity | tonumber),
            timestamp: $timestamp,
            success: false,
            learnings: null,
            time_spent: 0
        }'
}

Intention::mark_achieved() {
    local intention="$1"
    local learnings="$2"
    local time_spent="$3"
    
    echo "$intention" | jq \
        --arg learnings "$learnings" \
        --arg time_spent "$time_spent" \
        '.success = true | 
         .learnings = $learnings | 
         .time_spent = ($time_spent | tonumber)'
}

Intention::get_goal() {
    local intention="$1"
    echo "$intention" | jq -r '.goal'
}

Intention::get_complexity() {
    local intention="$1"
    echo "$intention" | jq -r '.complexity'
}

Intention::is_achieved() {
    local intention="$1"
    echo "$intention" | jq -r '.success'
}