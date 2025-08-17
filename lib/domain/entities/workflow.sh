#!/usr/bin/env bash
# Workflow Entity - Core business object

# Workflow constructor
Workflow::new() {
    local name="$1"
    local description="$2"
    shift 2
    local commands=("$@")
    
    # Validate business rules
    if [[ -z "$name" ]]; then
        echo "ERROR: Workflow name is required" >&2
        return 1
    fi
    
    if [[ ${#commands[@]} -eq 0 ]]; then
        echo "ERROR: Workflow must have at least one command" >&2
        return 1
    fi
    
    # Return workflow as JSON-like structure
    printf '%s\n' "name:$name"
    printf '%s\n' "description:$description"
    printf '%s\n' "command_count:${#commands[@]}"
    printf '%s\n' "commands:$(IFS='|'; echo "${commands[*]}")"
    printf '%s\n' "created_at:$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    printf '%s\n' "success_rate:1.0"
    printf '%s\n' "times_used:0"
}

# Parse workflow from storage format
Workflow::from_storage() {
    local data="$1"
    echo "$data"
}

# Get workflow property
Workflow::get() {
    local workflow="$1"
    local property="$2"
    echo "$workflow" | grep "^$property:" | cut -d: -f2-
}

# Update workflow statistics
Workflow::update_stats() {
    local workflow="$1"
    local success="$2"
    
    local times_used=$(Workflow::get "$workflow" "times_used")
    local success_rate=$(Workflow::get "$workflow" "success_rate")
    
    # Calculate new stats
    times_used=$((times_used + 1))
    if [[ "$success" == "true" ]]; then
        success_rate=$(echo "scale=4; ($success_rate * ($times_used - 1) + 1) / $times_used" | bc)
    else
        success_rate=$(echo "scale=4; ($success_rate * ($times_used - 1)) / $times_used" | bc)
    fi
    
    # Return updated workflow
    echo "$workflow" | sed "s/^times_used:.*/times_used:$times_used/" | \
                      sed "s/^success_rate:.*/success_rate:$success_rate/"
}

# Validate workflow name
Workflow::validate_name() {
    local name="$1"
    
    # Business rules for workflow names
    if [[ ! "$name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "ERROR: Workflow name can only contain letters, numbers, dash and underscore" >&2
        return 1
    fi
    
    if [[ ${#name} -gt 50 ]]; then
        echo "ERROR: Workflow name must be less than 50 characters" >&2
        return 1
    fi
    
    return 0
}