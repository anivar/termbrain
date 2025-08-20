//! SQLite connection pool management

use anyhow::Result;
use sqlx::{sqlite::SqlitePoolOptions, SqlitePool, Executor};
use std::path::Path;

pub struct SqliteStorage {
    pool: SqlitePool,
}

impl SqliteStorage {
    pub async fn new(database_path: impl AsRef<Path>) -> Result<Self> {
        let database_url = format!("sqlite:{}", database_path.as_ref().display());
        
        let pool = SqlitePoolOptions::new()
            .max_connections(5)
            .after_connect(|conn, _meta| {
                Box::pin(async move {
                    // Load sqlite-vec extension
                    conn.execute("SELECT load_extension('vec0')")
                        .await?;
                    Ok(())
                })
            })
            .connect(&database_url)
            .await?;
        
        Ok(Self { pool })
    }
    
    pub async fn in_memory() -> Result<Self> {
        let pool = SqlitePoolOptions::new()
            .max_connections(1)
            .connect("sqlite::memory:")
            .await?;
        
        // Create basic tables for testing
        sqlx::query(
            r#"
            CREATE TABLE IF NOT EXISTS commands (
                id TEXT PRIMARY KEY,
                command TEXT NOT NULL,
                created_at INTEGER NOT NULL,
                working_directory TEXT DEFAULT '/',
                exit_code INTEGER DEFAULT 0
            )
            "#
        )
        .execute(&pool)
        .await?;
        
        Ok(Self { pool })
    }
    
    pub fn pool(&self) -> &SqlitePool {
        &self.pool
    }
    
    pub async fn run_migrations(&self) -> Result<()> {
        sqlx::migrate!("../../migrations")
            .run(&self.pool)
            .await?;
        Ok(())
    }
}