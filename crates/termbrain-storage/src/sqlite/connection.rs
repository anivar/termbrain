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
            
        // Add vector search support (ignore errors if already exists)
        let _ = sqlx::query(include_str!("../../../../migrations/002_add_vector_search.sql"))
            .execute(&self.pool)
            .await;
            
        Ok(())
    }
    
    /// Delete oldest commands (for garbage collection)
    pub async fn delete_oldest_commands(&self, count: usize) -> Result<usize> {
        let result = sqlx::query(
            r#"
            DELETE FROM commands 
            WHERE id IN (
                SELECT id FROM commands 
                ORDER BY timestamp ASC 
                LIMIT ?
            )
            "#
        )
        .bind(count as i64)
        .execute(&self.pool)
        .await?;
        
        Ok(result.rows_affected() as usize)
    }
    
    /// Delete commands before a certain timestamp
    pub async fn delete_commands_before(&self, timestamp: chrono::DateTime<chrono::Utc>) -> Result<usize> {
        let result = sqlx::query(
            r#"
            DELETE FROM commands 
            WHERE timestamp < ?
            "#
        )
        .bind(timestamp)
        .execute(&self.pool)
        .await?;
        
        Ok(result.rows_affected() as usize)
    }
    
    /// Vacuum database to reclaim space
    pub async fn vacuum(&self) -> Result<()> {
        sqlx::query("VACUUM")
            .execute(&self.pool)
            .await?;
        Ok(())
    }
    
    /// Get database file size in bytes
    pub async fn get_database_size(&self) -> Result<u64> {
        #[derive(sqlx::FromRow)]
        struct SizeResult {
            size: Option<i64>,
        }
        
        let result: SizeResult = sqlx::query_as(
            "SELECT page_count * page_size as size FROM pragma_page_count(), pragma_page_size()"
        )
        .fetch_one(&self.pool)
        .await?;
        
        Ok(result.size.unwrap_or(0) as u64)
    }
}
