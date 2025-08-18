use sqlx::SqlitePool;
use anyhow::Result;

pub async fn run_migrations(pool: &SqlitePool) -> Result<()> {
    // Create commands table
    sqlx::query!(
        r#"
        CREATE TABLE IF NOT EXISTS commands (
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
        )
        "#
    )
    .execute(pool)
    .await?;
    
    // Create indices
    sqlx::query!("CREATE INDEX IF NOT EXISTS idx_commands_timestamp ON commands(timestamp)")
        .execute(pool)
        .await?;
    
    sqlx::query!("CREATE INDEX IF NOT EXISTS idx_commands_semantic ON commands(semantic_type)")
        .execute(pool)
        .await?;
    
    sqlx::query!("CREATE INDEX IF NOT EXISTS idx_commands_session ON commands(session_id)")
        .execute(pool)
        .await?;
    
    // Create workflows table
    sqlx::query!(
        r#"
        CREATE TABLE IF NOT EXISTS workflows (
            id TEXT PRIMARY KEY,
            name TEXT UNIQUE NOT NULL,
            description TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            execution_count INTEGER NOT NULL DEFAULT 0
        )
        "#
    )
    .execute(pool)
    .await?;
    
    // Create workflow_commands table
    sqlx::query!(
        r#"
        CREATE TABLE IF NOT EXISTS workflow_commands (
            workflow_id TEXT NOT NULL,
            position INTEGER NOT NULL,
            command TEXT NOT NULL,
            PRIMARY KEY (workflow_id, position),
            FOREIGN KEY (workflow_id) REFERENCES workflows(id) ON DELETE CASCADE
        )
        "#
    )
    .execute(pool)
    .await?;
    
    // Create patterns table
    sqlx::query!(
        r#"
        CREATE TABLE IF NOT EXISTS patterns (
            id TEXT PRIMARY KEY,
            pattern TEXT NOT NULL,
            frequency INTEGER NOT NULL DEFAULT 1,
            contexts TEXT NOT NULL,
            suggested_workflow TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
        )
        "#
    )
    .execute(pool)
    .await?;
    
    // Create intentions table
    sqlx::query!(
        r#"
        CREATE TABLE IF NOT EXISTS intentions (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            intention TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            achieved INTEGER NOT NULL DEFAULT 0,
            commands_count INTEGER NOT NULL DEFAULT 0
        )
        "#
    )
    .execute(pool)
    .await?;
    
    // Create flow_states table
    sqlx::query!(
        r#"
        CREATE TABLE IF NOT EXISTS flow_states (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            started_at INTEGER NOT NULL,
            ended_at INTEGER,
            productivity_score REAL,
            focus_area TEXT
        )
        "#
    )
    .execute(pool)
    .await?;
    
    // Create cognitive_states table
    sqlx::query!(
        r#"
        CREATE TABLE IF NOT EXISTS cognitive_states (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            mental_model TEXT,
            knowledge_items TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
        )
        "#
    )
    .execute(pool)
    .await?;
    
    Ok(())
}