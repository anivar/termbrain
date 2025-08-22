-- Add embedding column to commands table
-- Note: We'll store embeddings as BLOB for now
-- In production, we'd load sqlite-vec extension and use proper vector types
-- Using a pragma to check if column exists would be complex, so we'll handle errors in code

-- Create a regular table for embeddings (fallback approach)
CREATE TABLE IF NOT EXISTS command_embeddings (
    command_id TEXT PRIMARY KEY,
    embedding BLOB,
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_command_embeddings_id ON command_embeddings(command_id);