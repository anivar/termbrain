#!/usr/bin/env bash
# Suggest Actions Use Case - Personalized recommendations

source "${TERMBRAIN_LIB}/domain/services/semantic_analyzer.sh"
source "${TERMBRAIN_LIB}/infrastructure/repositories/knowledge_repository.sh"

SuggestActions::display() {
    echo "💡 Personalized Suggestions"
    echo "========================="
    
    # Based on current focus
    local focus=$(SuggestActions::detect_focus)
    echo "📍 You're focusing on: $focus"
    
    # Suggest relevant knowledge
    echo -e "\n📚 Relevant knowledge:"
    SuggestActions::suggest_knowledge "$focus"
    
    # Suggest workflows
    echo -e "\n🧩 Try these workflows:"
    SuggestActions::suggest_workflows "$focus"
    
    # Productivity insights
    echo -e "\n📊 Your productivity:"
    SuggestActions::productivity_insights
}

SuggestActions::detect_focus() {
    sqlite3 "$TERMBRAIN_DB" "
        SELECT semantic_type
        FROM commands
        WHERE session_id = '$TERMBRAIN_SESSION_ID'
        GROUP BY semantic_type
        ORDER BY COUNT(*) DESC
        LIMIT 1;
    " || echo "general"
}

SuggestActions::suggest_knowledge() {
    local focus="$1"
    
    # Get high-confidence relevant knowledge
    local knowledge=$(KnowledgeRepository::find_by_topic "$focus" 3)
    
    if [[ -n "$knowledge" ]]; then
        echo "$knowledge" | jq -r '.[] | select(.confidence >= 7) | "- \(.insight)"'
    else
        echo "- No high-confidence knowledge found for $focus"
        echo "- Try 'tb learn' after completing tasks to build knowledge"
    fi
}

SuggestActions::suggest_workflows() {
    local focus="$1"
    
    # Find effective mental models/workflows
    sqlite3 "$TERMBRAIN_DB" "
        SELECT printf('- %s (%.0f%% success rate)', name, effectiveness * 100)
        FROM mental_models
        WHERE pattern LIKE '%$focus%'
          AND effectiveness > 0.6
        ORDER BY effectiveness DESC
        LIMIT 3;
    " || echo "- No workflows found for $focus"
}

SuggestActions::productivity_insights() {
    local avg_productivity=$(sqlite3 "$TERMBRAIN_DB" "
        SELECT AVG(productivity_score) FROM cognitive_state
        WHERE timestamp > datetime('now', '-7 days');
    " || echo "0")
    
    echo "- 7-day average: ${avg_productivity:-0}/10"
    
    if (( $(echo "${avg_productivity:-0} < 6" | bc -l) )); then
        echo "- 💡 Consider taking breaks or switching tasks"
        echo "- 💡 Your most productive time is $(SuggestActions::best_time)"
    else
        echo "- 🚀 You're in a productive streak!"
        echo "- 💡 Keep focusing on $(SuggestActions::detect_focus)"
    fi
}

SuggestActions::best_time() {
    sqlite3 "$TERMBRAIN_DB" "
        SELECT strftime('%H:00', timestamp)
        FROM cognitive_state
        WHERE productivity_score >= 8
        GROUP BY strftime('%H', timestamp)
        ORDER BY COUNT(*) DESC
        LIMIT 1;
    " || echo "unknown"
}

# Convenience function
tb::suggest() {
    SuggestActions::display
}