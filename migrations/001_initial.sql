-- Create commands table
CREATE TABLE commands (
    id TEXT PRIMARY KEY,
    timestamp INTEGER NOT NULL,
    command TEXT NOT NULL,
    directory TEXT NOT NULL,
    exit_code INTEGER NOT NULL DEFAULT 0,
    duration_ms INTEGER NOT NULL DEFAULT 0,
    session_id TEXT NOT NULL,
    semantic_type TEXT NOT NULL,
    git_branch TEXT,
    project_type TEXT,
    is_sensitive INTEGER NOT NULL DEFAULT 0,
    intent TEXT,
    complexity INTEGER NOT NULL DEFAULT 1
);

-- Create workflows table
CREATE TABLE workflows (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    execution_count INTEGER NOT NULL DEFAULT 0
);

-- Create workflow_commands table
CREATE TABLE workflow_commands (
    workflow_id TEXT NOT NULL,
    position INTEGER NOT NULL,
    command TEXT NOT NULL,
    PRIMARY KEY (workflow_id, position),
    FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON DELETE CASCADE
);

-- Create patterns table  
CREATE TABLE patterns (
    id TEXT PRIMARY KEY,
    pattern TEXT NOT NULL,
    frequency INTEGER NOT NULL DEFAULT 1,
    contexts TEXT NOT NULL, -- JSON array
    suggested_workflow TEXT
);

-- Create intentions table
CREATE TABLE intentions (
    id TEXT PRIMARY KEY,
    session_id TEXT NOT NULL,
    intention TEXT NOT NULL,
    created_at INTEGER NOT NULL,
    achieved INTEGER NOT NULL DEFAULT 0,
    commands_count INTEGER NOT NULL DEFAULT 0
);

-- Create indexes for performance
CREATE INDEX idx_commands_timestamp ON commands(timestamp);
CREATE INDEX idx_commands_session ON commands(session_id);
CREATE INDEX idx_commands_semantic_type ON commands(semantic_type);
CREATE INDEX idx_commands_sensitive ON commands(is_sensitive);
CREATE INDEX idx_patterns_frequency ON patterns(frequency);
CREATE INDEX idx_intentions_session ON intentions(session_id);