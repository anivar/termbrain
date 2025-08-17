#!/usr/bin/env bash
# Generate Cognitive Context Use Case

source "${TERMBRAIN_LIB}/infrastructure/repositories/intention_repository.sh"
source "${TERMBRAIN_LIB}/infrastructure/repositories/knowledge_repository.sh"

GenerateContext::cognitive() {
    local query="${1:-general}"
    local output="${2:-$TERMBRAIN_HOME/cognitive-context.md}"
    
    {
        echo "# Termbrain Cognitive Context"
        echo "Generated: $(date)"
        echo ""
        
        # Current cognitive state
        GenerateContext::current_state
        echo ""
        
        # Relevant knowledge
        GenerateContext::relevant_knowledge "$query"
        echo ""
        
        # Applicable workflows
        GenerateContext::applicable_workflows "$query"
        echo ""
        
        # Historical experiences
        GenerateContext::past_experiences "$query"
        echo ""
        
        # Connections and relationships
        GenerateContext::show_connections "$query"
        
    } > "$output"
    
    # Copy to AI providers
    cp "$output" .termbrain-context.md
    echo "🧠 Cognitive context generated!"
    echo "📄 Saved to: $output"
}

GenerateContext::current_state() {
    echo "## Your Current State"
    
    local current_focus=$(sqlite3 "$TERMBRAIN_DB" "
        SELECT semantic_type
        FROM commands
        WHERE session_id = '$TERMBRAIN_SESSION_ID'
        GROUP BY semantic_type
        ORDER BY COUNT(*) DESC
        LIMIT 1;
    " || echo "general")
    
    echo "- Focus Area: $current_focus"
    
    local state_file="$TERMBRAIN_HOME/cache/intention_state"
    if [[ -f "$state_file" ]]; then
        source "$state_file"
        local intention=$(IntentionRepository::find_by_id "$intention_id" | jq -r '.goal')
        echo "- Active Goal: $intention"
    fi
    
    # Recent productivity
    local recent_productivity=$(sqlite3 "$TERMBRAIN_DB" "
        SELECT AVG(productivity_score)
        FROM cognitive_state
        WHERE timestamp > datetime('now', '-1 day');
    " || echo "N/A")
    
    echo "- Recent Productivity: ${recent_productivity:-N/A}/10"
}

GenerateContext::relevant_knowledge() {
    local query="$1"
    
    echo "## What You Know About: $query"
    
    local knowledge=$(KnowledgeRepository::find_by_topic "$query" 10)
    
    if [[ -n "$knowledge" ]]; then
        echo "$knowledge" | jq -r '.[] | "- \(.insight) (confidence: \(.confidence)/10, source: \(.source))"'
    else
        echo "- No specific knowledge found for: $query"
    fi
}

GenerateContext::applicable_workflows() {
    local query="$1"
    
    echo "## Your Workflows"
    
    sqlite3 "$TERMBRAIN_DB" "
        SELECT printf('**%s** (%.0f%% effective, used %d times)\n%s\n',
               name, effectiveness * 100, usage_count, 
               COALESCE(description, 'No description'))
        FROM mental_models
        WHERE name LIKE '%$query%' 
           OR description LIKE '%$query%'
           OR pattern LIKE '%$query%'
        ORDER BY effectiveness DESC
        LIMIT 5;
    " || echo "No workflows found for: $query"
}

GenerateContext::past_experiences() {
    local query="$1"
    
    echo "## Past Experiences"
    
    local experiences=$(IntentionRepository::find_successful "$query" 5)
    
    if [[ -n "$experiences" && "$experiences" != "[]" ]]; then
        echo "$experiences" | jq -r '.[] | "### Goal: \(.goal)\n**Learned**: \(.learnings)\n**Time**: \(.time_spent / 60) minutes\n"'
    else
        echo "No past experiences found for: $query"
    fi
}

GenerateContext::show_connections() {
    local query="$1"
    
    echo "## How Things Connect"
    
    # Show command sequences related to query
    sqlite3 "$TERMBRAIN_DB" "
        SELECT printf('- After %s, you often: %s (%d times)',
               c1.semantic_type,
               c2.semantic_type,
               COUNT(*))
        FROM commands c1
        JOIN commands c2 ON c2.id = c1.id + 1
        WHERE c1.session_id = c2.session_id
          AND (c1.semantic_type LIKE '%$query%' 
               OR c2.semantic_type LIKE '%$query%')
        GROUP BY c1.semantic_type, c2.semantic_type
        HAVING COUNT(*) > 2
        ORDER BY COUNT(*) DESC
        LIMIT 5;
    " || echo "No connection patterns found"
}

# Convenience function
tb::context_cognitive() {
    GenerateContext::cognitive "$@"
}