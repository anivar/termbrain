#!/usr/bin/env bash
# Extract Knowledge Use Case

source "${TERMBRAIN_LIB}/domain/entities/knowledge.sh"
source "${TERMBRAIN_LIB}/infrastructure/repositories/knowledge_repository.sh"

ExtractKnowledge::from_experience() {
    local insight="$1"
    local source="${2:-experience}"
    
    # Analyze recent commands to understand topic
    local topic=$(ExtractKnowledge::detect_topic)
    
    # Create knowledge entity
    local knowledge=$(Knowledge::new "$topic" "$insight" "$source")
    
    # Save to repository
    KnowledgeRepository::save "$knowledge"
    
    # Create connections to related commands
    ExtractKnowledge::link_to_commands "$topic"
}

ExtractKnowledge::from_error() {
    local error_id="$1"
    local solution="$2"
    
    # Extract insight from error resolution
    local insight="Error fixed by: $solution"
    ExtractKnowledge::from_experience "$insight" "error"
    
    # Increase confidence for similar solutions
    local topic=$(ExtractKnowledge::detect_topic)
    KnowledgeRepository::increase_confidence "$topic" "$solution"
}

ExtractKnowledge::detect_topic() {
    # Get the most common semantic type from recent commands
    sqlite3 "$TERMBRAIN_DB" "
        SELECT semantic_type
        FROM commands
        WHERE session_id = '$TERMBRAIN_SESSION_ID'
        GROUP BY semantic_type
        ORDER BY COUNT(*) DESC
        LIMIT 1;
    " || echo "general"
}

ExtractKnowledge::link_to_commands() {
    local topic="$1"
    
    # This would create connections in a connections table
    # For now, just a placeholder
    return 0
}

ExtractKnowledge::suggest_related() {
    local topic="$1"
    
    # Find related knowledge
    KnowledgeRepository::find_by_topic "$topic" 5 | jq -r '.[] | "- \(.insight) (confidence: \(.confidence)/10)"'
}

# Convenience function
tb::learn() {
    ExtractKnowledge::from_experience "$@"
}