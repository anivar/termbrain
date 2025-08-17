#!/usr/bin/env bash
# SQLite Workflow Repository Implementation

source "${TERMBRAIN_LIB}/domain/repositories/workflow_repository.sh"

# Initialize repository
SqliteWorkflowRepository::init() {
    # Ensure tables exist
    sqlite3 "$TERMBRAIN_DB" <<EOF
CREATE TABLE IF NOT EXISTS workflows (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    command_sequence TEXT,
    success_rate REAL DEFAULT 1.0,
    times_used INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS workflow_commands (
    workflow_id INTEGER,
    position INTEGER,
    command TEXT,
    PRIMARY KEY (workflow_id, position),
    FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON DELETE CASCADE
);
EOF
}

# Implement save
WorkflowRepository::save() {
    local workflow="$1"
    
    # Extract workflow properties
    local name=$(echo "$workflow" | grep "^name:" | cut -d: -f2-)
    local description=$(echo "$workflow" | grep "^description:" | cut -d: -f2-)
    local commands=$(echo "$workflow" | grep "^commands:" | cut -d: -f2-)
    local success_rate=$(echo "$workflow" | grep "^success_rate:" | cut -d: -f2-)
    local times_used=$(echo "$workflow" | grep "^times_used:" | cut -d: -f2-)
    
    # Insert workflow
    sqlite3 "$TERMBRAIN_DB" "INSERT INTO workflows (name, description, success_rate, times_used) 
                            VALUES ('${name//\'/\'\'}', '${description//\'/\'\'}', $success_rate, $times_used);"
    
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    # Get workflow ID
    local workflow_id=$(sqlite3 "$TERMBRAIN_DB" "SELECT id FROM workflows WHERE name='${name//\'/\'\'}'")
    
    # Insert commands
    local position=1
    IFS='|' read -ra cmd_array <<< "$commands"
    for cmd in "${cmd_array[@]}"; do
        sqlite3 "$TERMBRAIN_DB" "INSERT INTO workflow_commands (workflow_id, position, command) 
                                VALUES ($workflow_id, $position, '${cmd//\'/\'\'}');"
        ((position++))
    done
    
    return 0
}

# Implement find by name
WorkflowRepository::find_by_name() {
    local name="$1"
    
    local data=$(sqlite3 "$TERMBRAIN_DB" -separator '|' "
        SELECT name, description, success_rate, times_used, created_at 
        FROM workflows 
        WHERE name='${name//\'/\'\'}'")
    
    if [[ -z "$data" ]]; then
        return 1
    fi
    
    # Convert to workflow format
    IFS='|' read -r wf_name wf_desc wf_rate wf_used wf_created <<< "$data"
    
    printf "name:%s\n" "$wf_name"
    printf "description:%s\n" "$wf_desc"
    printf "success_rate:%s\n" "$wf_rate"
    printf "times_used:%s\n" "$wf_used"
    printf "created_at:%s\n" "$wf_created"
}

# Implement find all
WorkflowRepository::find_all() {
    sqlite3 "$TERMBRAIN_DB" -separator '|' "
        SELECT name, description, success_rate, times_used 
        FROM workflows 
        ORDER BY times_used DESC, name"
}

# Implement update
WorkflowRepository::update() {
    local workflow="$1"
    
    local name=$(echo "$workflow" | grep "^name:" | cut -d: -f2-)
    local success_rate=$(echo "$workflow" | grep "^success_rate:" | cut -d: -f2-)
    local times_used=$(echo "$workflow" | grep "^times_used:" | cut -d: -f2-)
    
    sqlite3 "$TERMBRAIN_DB" "
        UPDATE workflows 
        SET success_rate=$success_rate, times_used=$times_used 
        WHERE name='${name//\'/\'\'}'"
}

# Implement delete
WorkflowRepository::delete() {
    local name="$1"
    sqlite3 "$TERMBRAIN_DB" "DELETE FROM workflows WHERE name='${name//\'/\'\'}'"
}

# Implement get commands
WorkflowRepository::get_commands() {
    local name="$1"
    
    sqlite3 "$TERMBRAIN_DB" -separator '|' "
        SELECT wc.position, wc.command
        FROM workflow_commands wc
        JOIN workflows w ON w.id = wc.workflow_id
        WHERE w.name='${name//\'/\'\'}'
        ORDER BY wc.position"
}