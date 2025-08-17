#!/usr/bin/env bash
# Pattern Repository - SQLite implementation

PatternRepository::save() {
    local pattern_json="$1"
    
    # Parse pattern JSON
    local pattern_type=$(echo "$pattern_json" | jq -r '.type')
    local pattern_data=$(echo "$pattern_json" | jq -c '.data')
    local frequency=$(echo "$pattern_json" | jq -r '.frequency')
    
    sqlite3 "$TERMBRAIN_DB" "
        INSERT OR REPLACE INTO patterns (pattern_type, pattern_data, frequency)
        VALUES ('$pattern_type', '$pattern_data', $frequency);
    "
}

PatternRepository::find_by_type() {
    local pattern_type="$1"
    
    sqlite3 "$TERMBRAIN_DB" -json "
        SELECT 
            pattern_type as type,
            pattern_data as data,
            frequency,
            created_at,
            last_seen
        FROM patterns
        WHERE pattern_type LIKE '%$pattern_type%'
        ORDER BY frequency DESC;
    "
}

PatternRepository::find_recent() {
    local limit="${1:-10}"
    
    sqlite3 "$TERMBRAIN_DB" -json "
        SELECT 
            pattern_type as type,
            pattern_data as data,
            frequency,
            created_at,
            last_seen
        FROM patterns
        ORDER BY last_seen DESC
        LIMIT $limit;
    "
}

PatternRepository::update_last_seen() {
    local pattern_type="$1"
    
    sqlite3 "$TERMBRAIN_DB" "
        UPDATE patterns 
        SET last_seen = CURRENT_TIMESTAMP
        WHERE pattern_type = '$pattern_type';
    "
}