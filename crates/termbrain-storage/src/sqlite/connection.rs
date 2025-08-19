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
            .after_connect(|conn, _meta| {
                Box::pin(async move {
                    // Load sqlite-vec extension
                    conn.execute("SELECT load_extension('vec0')")
                        .await?;
                    Ok(())
                })
            })
            .connect("sqlite::memory:")
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