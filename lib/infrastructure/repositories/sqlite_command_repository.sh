#!/usr/bin/env bash
# SQLite Command Repository Implementation

source "${TERMBRAIN_LIB}/domain/repositories/command_repository.sh"

# Initialize repository
SqliteCommandRepository::init() {
    sqlite3 "$TERMBRAIN_DB" <<EOF
CREATE TABLE IF NOT EXISTS commands (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    command TEXT NOT NULL,
    directory TEXT,
    exit_code INTEGER,
    duration_ms INTEGER,
    git_branch TEXT,
    project_type TEXT,
    semantic_type TEXT,
    session_id TEXT,
    is_sensitive BOOLEAN DEFAULT FALSE,
    intent TEXT,
    complexity INTEGER DEFAULT 1
);

CREATE INDEX IF NOT EXISTS idx_commands_timestamp ON commands(timestamp);
CREATE INDEX IF NOT EXISTS idx_commands_semantic ON commands(semantic_type);
CREATE INDEX IF NOT EXISTS idx_commands_session ON commands(session_id);
CREATE INDEX IF NOT EXISTS idx_commands_intent ON commands(intent);
EOF
}

# Implement save
CommandRepository::save() {
    local command_data="$1"
    
    # Extract command properties
    local command=$(echo "$command_data" | grep "^command:" | cut -d: -f2-)
    local directory=$(echo "$command_data" | grep "^directory:" | cut -d: -f2-)
    local exit_code=$(echo "$command_data" | grep "^exit_code:" | cut -d: -f2-)
    local duration_ms=$(echo "$command_data" | grep "^duration_ms:" | cut -d: -f2-)
    local session_id=$(echo "$command_data" | grep "^session_id:" | cut -d: -f2-)
    local timestamp=$(echo "$command_data" | grep "^timestamp:" | cut -d: -f2-)
    local git_branch=$(echo "$command_data" | grep "^git_branch:" | cut -d: -f2-)
    local is_sensitive=$(echo "$command_data" | grep "^is_sensitive:" | cut -d: -f2-)
    local semantic_type=$(echo "$command_data" | grep "^semantic_type:" | cut -d: -f2-)
    local project_type=$(echo "$command_data" | grep "^project_type:" | cut -d: -f2-)
    local intent=$(echo "$command_data" | grep "^intent:" | cut -d: -f2-)
    local complexity=$(echo "$command_data" | grep "^complexity:" | cut -d: -f2-)
    
    # Set defaults
    exit_code="${exit_code:-0}"
    duration_ms="${duration_ms:-0}"
    is_sensitive="${is_sensitive:-false}"
    complexity="${complexity:-1}"
    
    # Convert boolean to integer
    local is_sensitive_int=0
    if [[ "$is_sensitive" == "true" ]]; then
        is_sensitive_int=1
    fi
    
    # Insert command
    local command_id=$(sqlite3 "$TERMBRAIN_DB" <<EOF
INSERT INTO commands (
    command, directory, exit_code, duration_ms, session_id, 
    git_branch, is_sensitive, semantic_type, project_type, 
    intent, complexity
) VALUES (
    '${command//\'/\'\'}', 
    '${directory//\'/\'\'}', 
    $exit_code, 
    $duration_ms, 
    '${session_id//\'/\'\'}',
    '${git_branch//\'/\'\'}', 
    $is_sensitive_int, 
    '${semantic_type//\'/\'\'}', 
    '${project_type//\'/\'\'}',
    '${intent//\'/\'\'}', 
    $complexity
);
SELECT last_insert_rowid();
EOF
)
    
    echo "$command_id"
}

# Implement find by ID
CommandRepository::find_by_id() {
    local id="$1"
    
    local data=$(sqlite3 "$TERMBRAIN_DB" -separator '|' <<EOF
SELECT command, directory, exit_code, duration_ms, session_id, 
       timestamp, git_branch, is_sensitive, semantic_type, 
       project_type, intent, complexity
FROM commands WHERE id = $id;
EOF
)
    
    if [[ -z "$data" ]]; then
        return 1
    fi
    
    # Convert to command format
    IFS='|' read -r cmd dir exit dur session ts branch sensitive semantic project intent_val complex <<< "$data"
    
    printf "id:%s\n" "$id"
    printf "command:%s\n" "$cmd"
    printf "directory:%s\n" "$dir"
    printf "exit_code:%s\n" "$exit"
    printf "duration_ms:%s\n" "$dur"
    printf "session_id:%s\n" "$session"
    printf "timestamp:%s\n" "$ts"
    printf "git_branch:%s\n" "$branch"
    printf "is_sensitive:%s\n" "$([ "$sensitive" = "1" ] && echo "true" || echo "false")"
    printf "semantic_type:%s\n" "$semantic"
    printf "project_type:%s\n" "$project"
    printf "intent:%s\n" "$intent_val"
    printf "complexity:%s\n" "$complex"
}

# Implement search
CommandRepository::search() {
    local query="$1"
    local limit="${2:-50}"
    
    sqlite3 "$TERMBRAIN_DB" -separator '|' <<EOF
SELECT id, command, timestamp, exit_code, semantic_type
FROM commands 
WHERE command LIKE '%${query//\'/\'\'}%' 
AND is_sensitive = 0
ORDER BY timestamp DESC 
LIMIT $limit;
EOF
}

# Implement get recent
CommandRepository::get_recent() {
    local limit="${1:-20}"
    
    sqlite3 "$TERMBRAIN_DB" -separator '|' <<EOF
SELECT id, command, timestamp, exit_code, semantic_type
FROM commands 
WHERE is_sensitive = 0
ORDER BY timestamp DESC 
LIMIT $limit;
EOF
}

# Implement find by semantic type
CommandRepository::find_by_semantic_type() {
    local semantic_type="$1"
    local limit="${2:-50}"
    
    sqlite3 "$TERMBRAIN_DB" -separator '|' <<EOF
SELECT id, command, timestamp, exit_code
FROM commands 
WHERE semantic_type = '${semantic_type//\'/\'\'}' 
AND is_sensitive = 0
ORDER BY timestamp DESC 
LIMIT $limit;
EOF
}

# Implement get statistics
CommandRepository::get_statistics() {
    sqlite3 "$TERMBRAIN_DB" <<EOF
SELECT 
    COUNT(*) as total_commands,
    COUNT(CASE WHEN exit_code = 0 THEN 1 END) as successful_commands,
    COUNT(CASE WHEN exit_code != 0 THEN 1 END) as failed_commands,
    COUNT(DISTINCT semantic_type) as semantic_types,
    COUNT(DISTINCT session_id) as sessions,
    AVG(duration_ms) as avg_duration_ms
FROM commands;
EOF
}

# Implement update
CommandRepository::update() {
    local command_data="$1"
    
    local id=$(echo "$command_data" | grep "^id:" | cut -d: -f2-)
    local exit_code=$(echo "$command_data" | grep "^exit_code:" | cut -d: -f2-)
    local duration_ms=$(echo "$command_data" | grep "^duration_ms:" | cut -d: -f2-)
    
    if [[ -n "$id" ]]; then
        sqlite3 "$TERMBRAIN_DB" <<EOF
UPDATE commands 
SET exit_code = $exit_code, duration_ms = $duration_ms 
WHERE id = $id;
EOF
    fi
}

# Implement count
CommandRepository::count() {
    sqlite3 "$TERMBRAIN_DB" "SELECT COUNT(*) FROM commands;"
}

# Implement delete
CommandRepository::delete() {
    local id="$1"
    sqlite3 "$TERMBRAIN_DB" "DELETE FROM commands WHERE id = $id;"
}