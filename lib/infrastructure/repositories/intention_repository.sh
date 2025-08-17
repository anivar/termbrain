#!/usr/bin/env bash
# Intention Repository - SQLite implementation

source "${TERMBRAIN_LIB}/domain/services/safety_checker.sh"

IntentionRepository::save() {
    local intention="$1"
    
    local goal=$(echo "$intention" | jq -r '.goal')
    local context=$(echo "$intention" | jq -r '.context')
    local complexity=$(echo "$intention" | jq -r '.complexity')
    
    local id=$(sqlite3 "$TERMBRAIN_DB" "
        INSERT INTO intentions (goal, context, complexity)
        VALUES (
            '$(SafetyChecker::escape_sql "$goal")',
            '$(SafetyChecker::escape_sql "$context")',
            $complexity
        );
        SELECT last_insert_rowid();
    ")
    
    echo "$id"
}

IntentionRepository::update() {
    local id="$1"
    local intention="$2"
    
    local success=$(echo "$intention" | jq -r '.success')
    local learnings=$(echo "$intention" | jq -r '.learnings // ""')
    local time_spent=$(echo "$intention" | jq -r '.time_spent')
    
    sqlite3 "$TERMBRAIN_DB" "
        UPDATE intentions
        SET success = $(if [[ "$success" == "true" ]]; then echo 1; else echo 0; fi),
            learnings = '$(SafetyChecker::escape_sql "$learnings")',
            time_spent = $time_spent
        WHERE id = $id;
    "
}

IntentionRepository::find_by_id() {
    local id="$1"
    
    sqlite3 "$TERMBRAIN_DB" -json "
        SELECT 
            id,
            goal,
            context,
            complexity,
            success,
            learnings,
            time_spent,
            timestamp
        FROM intentions
        WHERE id = $id;
    " | jq '.[0]'
}

IntentionRepository::find_recent() {
    local limit="${1:-10}"
    
    sqlite3 "$TERMBRAIN_DB" -json "
        SELECT 
            id,
            goal,
            context,
            complexity,
            success,
            learnings,
            time_spent,
            timestamp
        FROM intentions
        ORDER BY timestamp DESC
        LIMIT $limit;
    "
}

IntentionRepository::find_successful() {
    local topic="${1:-}"
    local limit="${2:-10}"
    
    local where_clause=""
    if [[ -n "$topic" ]]; then
        where_clause="AND goal LIKE '%$(SafetyChecker::escape_sql "$topic")%'"
    fi
    
    sqlite3 "$TERMBRAIN_DB" -json "
        SELECT 
            id,
            goal,
            learnings,
            time_spent,
            timestamp
        FROM intentions
        WHERE success = 1 $where_clause
        ORDER BY timestamp DESC
        LIMIT $limit;
    "
}