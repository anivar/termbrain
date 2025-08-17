#!/usr/bin/env bash
# Mental Model Entity - Represents understanding patterns and workflows

MentalModel::new() {
    local name="$1"
    local description="${2:-}"
    local pattern="${3:-}"
    local context_triggers="${4:-}"
    
    # Validate name
    if [[ -z "$name" ]]; then
        echo "ERROR: Name is required for mental model" >&2
        return 1
    fi
    
    # Create mental model JSON
    jq -n \
        --arg name "$name" \
        --arg description "$description" \
        --arg pattern "$pattern" \
        --arg context_triggers "$context_triggers" \
        '{
            name: $name,
            description: $description,
            pattern: $pattern,
            context_triggers: $context_triggers,
            effectiveness: 0.5,
            usage_count: 0
        }'
}

MentalModel::use() {
    local model="$1"
    local success="${2:-true}"
    
    # Update usage count and effectiveness
    echo "$model" | jq \
        --arg success "$success" \
        '.usage_count += 1 |
         if $success == "true" then
            .effectiveness = ((.effectiveness * .usage_count + 1) / (.usage_count + 1))
         else
            .effectiveness = ((.effectiveness * .usage_count) / (.usage_count + 1))
         end'
}

MentalModel::get_name() {
    local model="$1"
    echo "$model" | jq -r '.name'
}

MentalModel::get_effectiveness() {
    local model="$1"
    echo "$model" | jq -r '.effectiveness'
}

MentalModel::is_effective() {
    local model="$1"
    local threshold="${2:-0.7}"
    
    local effectiveness=$(MentalModel::get_effectiveness "$model")
    if (( $(echo "$effectiveness > $threshold" | bc -l) )); then
        echo "true"
    else
        echo "false"
    fi
}