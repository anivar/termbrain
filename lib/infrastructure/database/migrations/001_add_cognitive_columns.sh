#!/usr/bin/env bash
# Migration: Add cognitive columns to existing database

Migration001::up() {
    local db="$1"
    
    echo "Running migration: Add cognitive columns..."
    
    # Add intent and complexity columns to commands table if they don't exist
    sqlite3 "$db" "
        -- Check if columns exist before adding
        SELECT COUNT(*) FROM pragma_table_info('commands') WHERE name='intent';
    " | grep -q "0" && sqlite3 "$db" "
        ALTER TABLE commands ADD COLUMN intent TEXT DEFAULT NULL;
    "
    
    sqlite3 "$db" "
        SELECT COUNT(*) FROM pragma_table_info('commands') WHERE name='complexity';
    " | grep -q "0" && sqlite3 "$db" "
        ALTER TABLE commands ADD COLUMN complexity INTEGER DEFAULT 1;
    "
    
    # Create cognitive tables if they don't exist
    sqlite3 "$db" <<'EOF'
-- Ensure all cognitive tables exist
CREATE TABLE IF NOT EXISTS intentions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    goal TEXT NOT NULL,
    context TEXT,
    success BOOLEAN DEFAULT 0,
    learnings TEXT,
    time_spent INTEGER DEFAULT 0,
    complexity INTEGER DEFAULT 5
);

CREATE TABLE IF NOT EXISTS knowledge (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    insight TEXT NOT NULL,
    confidence INTEGER DEFAULT 5,
    source TEXT DEFAULT 'experience',
    verified BOOLEAN DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_used DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS cognitive_state (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    focus_area TEXT,
    productivity_score INTEGER DEFAULT 5,
    interruption_count INTEGER DEFAULT 0,
    flow_duration INTEGER DEFAULT 0,
    energy_level INTEGER DEFAULT 5
);

CREATE TABLE IF NOT EXISTS mental_models (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    pattern TEXT,
    context_triggers TEXT,
    effectiveness REAL DEFAULT 0.5,
    usage_count INTEGER DEFAULT 0
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_commands_intent ON commands(intent);
CREATE INDEX IF NOT EXISTS idx_commands_complexity ON commands(complexity);
EOF
    
    echo "Migration completed successfully"
}

Migration001::down() {
    local db="$1"
    
    echo "Rolling back migration: Remove cognitive columns..."
    
    # SQLite doesn't support DROP COLUMN easily, would need to recreate table
    echo "Warning: Rollback would require table recreation. Skipping."
}

# Check if migration is needed
Migration001::needed() {
    local db="$1"
    
    # Check if intent column exists
    local has_intent=$(sqlite3 "$db" "
        SELECT COUNT(*) FROM pragma_table_info('commands') WHERE name='intent';
    ")
    
    if [[ "$has_intent" == "0" ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Run migration if needed
if [[ -n "$1" ]]; then
    if [[ $(Migration001::needed "$1") == "true" ]]; then
        Migration001::up "$1"
    else
        echo "Migration already applied" >&2
    fi
fi