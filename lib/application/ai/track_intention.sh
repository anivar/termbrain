#!/usr/bin/env bash
# Track Intention Use Case

source "${TERMBRAIN_LIB}/domain/entities/intention.sh"
source "${TERMBRAIN_LIB}/infrastructure/repositories/intention_repository.sh"

TrackIntention::start() {
    local goal="$1"
    local context="${2:-$(TrackIntention::get_context_summary)}"
    
    if [[ -z "$goal" ]]; then
        echo "🎯 What are you trying to accomplish?"
        read -r goal
    fi
    
    # Create intention
    local intention=$(Intention::new "$goal" "$context")
    
    # Save to repository
    local intention_id=$(IntentionRepository::save "$intention")
    
    # Save to state file
    local state_file="$TERMBRAIN_HOME/cache/intention_state"
    mkdir -p "$TERMBRAIN_HOME/cache"
    echo "intention_id=$intention_id" > "$state_file"
    echo "start=$(date +%s)" >> "$state_file"
    
    echo "🎯 Intention set: $goal"
    echo "💡 I'll track your progress and learn from your approach"
}

TrackIntention::complete() {
    local state_file="$TERMBRAIN_HOME/cache/intention_state"
    
    if [[ ! -f "$state_file" ]]; then
        echo "❓ No active intention. What did you accomplish?"
        read -r goal
        TrackIntention::start "$goal"
        return 0
    fi
    
    source "$state_file"
    local duration=$(($(date +%s) - start))
    
    echo "✅ Great! What did you learn?"
    read -r learnings
    
    # Get current intention
    local intention=$(IntentionRepository::find_by_id "$intention_id")
    
    # Mark as achieved
    intention=$(Intention::mark_achieved "$intention" "$learnings" "$duration")
    
    # Update in repository
    IntentionRepository::update "$intention_id" "$intention"
    
    # Extract knowledge from the experience
    TrackIntention::extract_knowledge "$learnings"
    
    rm -f "$state_file"
    echo "🎉 Achievement recorded and knowledge extracted!"
}

TrackIntention::get_context_summary() {
    # Get recent command types
    local recent_types=$(sqlite3 "$TERMBRAIN_DB" "
        SELECT semantic_type 
        FROM commands 
        WHERE session_id = '$TERMBRAIN_SESSION_ID'
        ORDER BY timestamp DESC 
        LIMIT 5;
    " | tr '\n' ',' | sed 's/,$//')
    
    echo "Recent activity: $recent_types"
}

TrackIntention::extract_knowledge() {
    local insight="$1"
    
    # This would integrate with the ExtractKnowledge use case
    # For now, just log it
    echo "📚 Knowledge recorded: $insight"
}

# Convenience functions
tb::intend() {
    TrackIntention::start "$@"
}

tb::achieved() {
    TrackIntention::complete
}