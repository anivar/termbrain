//! SQLite connection pool management

use anyhow::Result;
use sqlx::{sqlite::SqlitePoolOptions, SqlitePool};
use std::path::Path;

pub struct SqliteStorage {
    pool: SqlitePool,
}

impl SqliteStorage {
    pub async fn new(database_path: impl AsRef<Path>) -> Result<Self> {
        let database_url = format!("sqlite:{}", database_path.as_ref().display());
        
        let pool = SqlitePoolOptions::new()
            .max_connections(5)
            .connect(&database_url)
            .await?;
        
        Ok(Self { pool })
    }
    
    pub async fn in_memory() -> Result<Self> {
        let pool = SqlitePoolOptions::new()
            .max_connections(1)
            .connect("sqlite::memory:")
            .await?;
        
        // Create schema
        sqlx::query(include_str!("../../../../migrations/001_initial.sql"))
            .execute(&pool)
            .await?;
        
        Ok(Self { pool })
    }
    
    pub fn pool(&self) -> &SqlitePool {
        &self.pool
    }
    
    pub async fn ensure_schema(&self) -> Result<()> {
        // Create schema directly without migrations
        sqlx::query(include_str!("../../../../migrations/001_initial.sql"))
            .execute(&self.pool)
            .await?;
        Ok(())
    }
}