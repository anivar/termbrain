-- Initial schema for TermBrain

CREATE TABLE IF NOT EXISTS commands (
    id TEXT PRIMARY KEY,
    command TEXT NOT NULL,
    created_at INTEGER NOT NULL
);

CREATE INDEX idx_commands_created_at ON commands(created_at DESC);

-- Create virtual table for vector similarity search
CREATE VIRTUAL TABLE IF NOT EXISTS command_embeddings USING vec0(
    id TEXT PRIMARY KEY,
    embedding float[768]  -- 768-dimensional vectors for embeddings
);