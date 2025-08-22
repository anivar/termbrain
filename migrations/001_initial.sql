-- Create commands table
CREATE TABLE IF NOT EXISTS commands (
    id TEXT PRIMARY KEY,
    raw TEXT NOT NULL,
    parsed_command TEXT NOT NULL,
    arguments TEXT NOT NULL, -- JSON array
    working_directory TEXT NOT NULL,
    exit_code INTEGER NOT NULL DEFAULT 0,
    duration_ms INTEGER NOT NULL DEFAULT 0,
    timestamp TEXT NOT NULL, -- ISO 8601 string
    session_id TEXT NOT NULL,
    shell TEXT NOT NULL,
    user TEXT NOT NULL,
    hostname TEXT NOT NULL,
    terminal TEXT NOT NULL,
    environment TEXT NOT NULL, -- JSON object
    ai_agent TEXT,
    ai_session_id TEXT,
    ai_context TEXT
);

-- Create sessions table
CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    start_time TEXT NOT NULL, -- ISO 8601 string
    end_time TEXT, -- ISO 8601 string, nullable
    shell TEXT NOT NULL,
    terminal TEXT NOT NULL
);

-- Create patterns table
CREATE TABLE IF NOT EXISTS patterns (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL,
    pattern_type TEXT NOT NULL, -- JSON serialized PatternType
    frequency INTEGER NOT NULL DEFAULT 1,
    last_seen TEXT NOT NULL, -- ISO 8601 string
    confidence REAL NOT NULL DEFAULT 0.0
);

-- Create workflows table
CREATE TABLE IF NOT EXISTS workflows (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,
    steps TEXT NOT NULL, -- JSON array of WorkflowStep
    created_at TEXT NOT NULL, -- ISO 8601 string
    updated_at TEXT NOT NULL, -- ISO 8601 string
    usage_count INTEGER NOT NULL DEFAULT 0
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_commands_timestamp ON commands(timestamp);
CREATE INDEX IF NOT EXISTS idx_commands_session ON commands(session_id);
CREATE INDEX IF NOT EXISTS idx_commands_exit_code ON commands(exit_code);
CREATE INDEX IF NOT EXISTS idx_commands_working_directory ON commands(working_directory);
CREATE INDEX IF NOT EXISTS idx_commands_parsed_command ON commands(parsed_command);
CREATE INDEX IF NOT EXISTS idx_patterns_frequency ON patterns(frequency);
CREATE INDEX IF NOT EXISTS idx_patterns_confidence ON patterns(confidence);
CREATE INDEX IF NOT EXISTS idx_sessions_start_time ON sessions(start_time);