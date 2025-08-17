#!/usr/bin/env bash
# Knowledge Repository - SQLite implementation

source "${TERMBRAIN_LIB}/domain/services/safety_checker.sh"

KnowledgeRepository::save() {
    local knowledge="$1"
    
    local topic=$(echo "$knowledge" | jq -r '.topic')
    local insight=$(echo "$knowledge" | jq -r '.insight')
    local source=$(echo "$knowledge" | jq -r '.source')
    local confidence=$(echo "$knowledge" | jq -r '.confidence')
    
    sqlite3 "$TERMBRAIN_DB" "
        INSERT INTO knowledge (topic, insight, source, confidence)
        VALUES (
            '$(SafetyChecker::escape_sql "$topic")',
            '$(SafetyChecker::escape_sql "$insight")',
            '$source',
            $confidence
        );
    "
}

KnowledgeRepository::update() {
    local id="$1"
    local knowledge="$2"
    
    local confidence=$(echo "$knowledge" | jq -r '.confidence')
    local verified=$(echo "$knowledge" | jq -r '.verified')
    
    sqlite3 "$TERMBRAIN_DB" "
        UPDATE knowledge
        SET confidence = $confidence,
            verified = $(if [[ "$verified" == "true" ]]; then echo 1; else echo 0; fi),
            last_used = CURRENT_TIMESTAMP
        WHERE id = $id;
    "
}

KnowledgeRepository::find_by_topic() {
    local topic="$1"
    local limit="${2:-10}"
    
    sqlite3 "$TERMBRAIN_DB" -json "
        SELECT 
            id,
            topic,
            insight,
            confidence,
            source,
            verified,
            created_at,
            last_used
        FROM knowledge
        WHERE topic LIKE '%$(SafetyChecker::escape_sql "$topic")%'
           OR insight LIKE '%$(SafetyChecker::escape_sql "$topic")%'
        ORDER BY confidence DESC, last_used DESC
        LIMIT $limit;
    "
}

KnowledgeRepository::find_verified() {
    local limit="${1:-20}"
    
    sqlite3 "$TERMBRAIN_DB" -json "
        SELECT 
            id,
            topic,
            insight,
            confidence,
            source
        FROM knowledge
        WHERE verified = 1
        ORDER BY confidence DESC
        LIMIT $limit;
    "
}

KnowledgeRepository::increase_confidence() {
    local topic="$1"
    local pattern="$2"
    
    sqlite3 "$TERMBRAIN_DB" "
        UPDATE knowledge
        SET confidence = MIN(10, confidence + 1),
            verified = 1,
            last_used = CURRENT_TIMESTAMP
        WHERE topic = '$(SafetyChecker::escape_sql "$topic")'
          AND insight LIKE '%$(SafetyChecker::escape_sql "$pattern")%';
    "
}