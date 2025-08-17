#!/usr/bin/env bash
# Track Flow State Use Case

source "${TERMBRAIN_LIB}/domain/services/semantic_analyzer.sh"

TrackFlow::start() {
    local flow_file="$TERMBRAIN_HOME/cache/flow_state"
    mkdir -p "$TERMBRAIN_HOME/cache"
    
    echo "start=$(date +%s)" > "$flow_file"
    echo "interruptions=0" >> "$flow_file"
    
    echo "🌊 Flow state tracking started"
}

TrackFlow::end() {
    local flow_file="$TERMBRAIN_HOME/cache/flow_state"
    
    if [[ ! -f "$flow_file" ]]; then
        echo "💤 No active flow session"
        return 1
    fi
    
    source "$flow_file"
    local duration=$(($(date +%s) - start))
    
    echo "Rate your productivity (1-10):"
    read -r productivity
    
    # Validate productivity score
    if ! [[ "$productivity" =~ ^[0-9]$ ]] && [[ "$productivity" != "10" ]]; then
        productivity=5
    fi
    
    # Detect focus area
    local focus_area=$(TrackFlow::detect_focus_area)
    
    # Save to database
    sqlite3 "$TERMBRAIN_DB" "
        INSERT INTO cognitive_state 
        (focus_area, productivity_score, interruption_count, flow_duration)
        VALUES (
            '$focus_area',
            $productivity,
            ${TB_FLOW_INTERRUPTIONS:-0},
            $duration
        );
    "
    
    echo "🌊 Flow session recorded: $(($duration / 60)) minutes"
    echo "📊 Productivity: $productivity/10"
    echo "🎯 Focus: $focus_area"
    echo "🚫 Interruptions: ${TB_FLOW_INTERRUPTIONS:-0}"
    
    rm -f "$flow_file"
}

TrackFlow::status() {
    local flow_file="$TERMBRAIN_HOME/cache/flow_state"
    
    if [[ -f "$flow_file" ]]; then
        source "$flow_file"
        local elapsed=$(( ($(date +%s) - start) / 60 ))
        echo "🌊 In flow for $elapsed minutes"
        echo "🎯 Focus: $(TrackFlow::detect_focus_area)"
        echo "🚫 Interruptions: ${interruptions:-0}"
    else
        echo "💤 Not in flow state. Use 'tb flow start' to begin"
    fi
}

TrackFlow::detect_focus_area() {
    sqlite3 "$TERMBRAIN_DB" "
        SELECT semantic_type
        FROM commands
        WHERE session_id = '$TERMBRAIN_SESSION_ID'
        GROUP BY semantic_type
        ORDER BY COUNT(*) DESC
        LIMIT 1;
    " || echo "general"
}

TrackFlow::track_interruption() {
    local flow_file="$TERMBRAIN_HOME/cache/flow_state"
    
    if [[ -f "$flow_file" ]]; then
        source "$flow_file"
        ((interruptions++))
        sed -i.tmp "s/interruptions=.*/interruptions=$interruptions/" "$flow_file"
        rm -f "${flow_file}.tmp"
    fi
}

# Main flow command handler
TrackFlow::main() {
    local action="${1:-status}"
    
    case "$action" in
        start)
            TrackFlow::start
            ;;
        end|stop)
            TrackFlow::end
            ;;
        status)
            TrackFlow::status
            ;;
        *)
            echo "Usage: tb flow [start|end|status]"
            return 1
            ;;
    esac
}

# Convenience function
tb::flow() {
    TrackFlow::main "$@"
}