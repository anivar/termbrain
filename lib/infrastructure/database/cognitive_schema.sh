#!/usr/bin/env bash
# Cognitive Database Schema

CognitiveSchema::init() {
    sqlite3 "$TERMBRAIN_DB" <<'EOF'
-- Intentions: What were you trying to achieve?
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

-- Knowledge: What you've learned
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

-- Connections: How things relate
CREATE TABLE IF NOT EXISTS connections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_type TEXT NOT NULL,
    from_id INTEGER NOT NULL,
    to_type TEXT NOT NULL,
    to_id INTEGER NOT NULL,
    relationship TEXT NOT NULL,
    strength INTEGER DEFAULT 5
);

-- Mental Models: Your understanding patterns
CREATE TABLE IF NOT EXISTS mental_models (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    pattern TEXT,
    context_triggers TEXT,
    effectiveness REAL DEFAULT 0.5,
    usage_count INTEGER DEFAULT 0
);

-- Cognitive State: Track your focus and flow
CREATE TABLE IF NOT EXISTS cognitive_state (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    focus_area TEXT,
    productivity_score INTEGER DEFAULT 5,
    interruption_count INTEGER DEFAULT 0,
    flow_duration INTEGER DEFAULT 0,
    energy_level INTEGER DEFAULT 5
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_intentions_goal ON intentions(goal);
CREATE INDEX IF NOT EXISTS idx_knowledge_topic ON knowledge(topic);
CREATE INDEX IF NOT EXISTS idx_connections_from ON connections(from_type, from_id);
CREATE INDEX IF NOT EXISTS idx_mental_models_name ON mental_models(name);
CREATE INDEX IF NOT EXISTS idx_cognitive_state_timestamp ON cognitive_state(timestamp);
EOF
}

# Check if cognitive tables exist
CognitiveSchema::exists() {
    local table_count=$(sqlite3 "$TERMBRAIN_DB" "
        SELECT COUNT(*) 
        FROM sqlite_master 
        WHERE type='table' 
        AND name IN ('intentions', 'knowledge', 'connections', 'mental_models', 'cognitive_state');
    ")
    
    if [[ "$table_count" -eq 5 ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# Initialize if needed
CognitiveSchema::ensure() {
    if [[ $(CognitiveSchema::exists) != "true" ]]; then
        CognitiveSchema::init
        echo "🧠 Cognitive database schema initialized"
    fi
}