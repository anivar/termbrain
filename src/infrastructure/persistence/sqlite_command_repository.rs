use async_trait::async_trait;
use sqlx::{SqlitePool, sqlite::SqlitePoolOptions};
use anyhow::Result;
use std::path::Path;
use uuid::Uuid;

use crate::domain::{
    entities::Command,
    value_objects::SemanticType,
    repositories::{CommandRepository, CommandStats},
};

pub struct SqliteCommandRepository {
    pool: SqlitePool,
}

impl SqliteCommandRepository {
    pub async fn new(db_path: &Path) -> Result<Self> {
        // Ensure directory exists
        if let Some(parent) = db_path.parent() {
            std::fs::create_dir_all(parent)?;
        }
        
        let db_url = format!("sqlite://{}?mode=rwc", db_path.display());
        
        let pool = SqlitePoolOptions::new()
            .max_connections(5)
            .connect(&db_url)
            .await?;
        
        // Run migrations
        super::run_migrations(&pool).await?;
        
        Ok(Self { pool })
    }
}

#[async_trait]
impl CommandRepository for SqliteCommandRepository {
    async fn save(&self, command: &Command) -> Result<()> {
        let id = command.id.to_string();
        let timestamp = command.timestamp.timestamp();
        let semantic_type = serde_json::to_string(&command.semantic_type)?;
        let project_type = command.project_type.as_ref()
            .map(|pt| serde_json::to_string(pt).unwrap_or_default());
        
        sqlx::query!(
            r#"
            INSERT INTO commands (
                id, timestamp, command, directory, exit_code, duration_ms,
                session_id, semantic_type, git_branch, project_type,
                is_sensitive, intent, complexity
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            "#,
            id,
            timestamp,
            command.command,
            command.directory,
            command.exit_code,
            command.duration_ms,
            command.session_id,
            semantic_type,
            command.git_branch,
            project_type,
            command.is_sensitive,
            command.intent,
            command.complexity
        )
        .execute(&self.pool)
        .await?;
        
        Ok(())
    }
    
    async fn find_by_id(&self, id: &str) -> Result<Option<Command>> {
        let record = sqlx::query!(
            r#"
            SELECT * FROM commands WHERE id = ?
            "#,
            id
        )
        .fetch_optional(&self.pool)
        .await?;
        
        match record {
            Some(r) => {
                let semantic_type: SemanticType = serde_json::from_str(&r.semantic_type)?;
                let project_type = r.project_type
                    .map(|pt| serde_json::from_str(&pt).ok())
                    .flatten();
                
                Ok(Some(Command {
                    id: Uuid::parse_str(&r.id)?,
                    timestamp: chrono::DateTime::from_timestamp(r.timestamp, 0).unwrap().into(),
                    command: r.command,
                    directory: r.directory,
                    exit_code: r.exit_code as i32,
                    duration_ms: r.duration_ms as u64,
                    session_id: r.session_id,
                    semantic_type,
                    git_branch: r.git_branch,
                    project_type,
                    is_sensitive: r.is_sensitive != 0,
                    intent: r.intent,
                    complexity: r.complexity as u8,
                }))
            }
            None => Ok(None),
        }
    }
    
    async fn search(&self, query: &str, limit: usize) -> Result<Vec<Command>> {
        let pattern = format!("%{}%", query);
        let limit = limit as i64;
        
        let records = sqlx::query!(
            r#"
            SELECT * FROM commands 
            WHERE command LIKE ? AND is_sensitive = 0
            ORDER BY timestamp DESC
            LIMIT ?
            "#,
            pattern,
            limit
        )
        .fetch_all(&self.pool)
        .await?;
        
        let mut commands = Vec::new();
        for r in records {
            let semantic_type: SemanticType = serde_json::from_str(&r.semantic_type)?;
            let project_type = r.project_type
                .map(|pt| serde_json::from_str(&pt).ok())
                .flatten();
            
            commands.push(Command {
                id: Uuid::parse_str(&r.id)?,
                timestamp: chrono::DateTime::from_timestamp(r.timestamp, 0).unwrap().into(),
                command: r.command,
                directory: r.directory,
                exit_code: r.exit_code as i32,
                duration_ms: r.duration_ms as u64,
                session_id: r.session_id,
                semantic_type,
                git_branch: r.git_branch,
                project_type,
                is_sensitive: false, // Already filtered
                intent: r.intent,
                complexity: r.complexity as u8,
            });
        }
        
        Ok(commands)
    }
    
    async fn get_recent(&self, limit: usize) -> Result<Vec<Command>> {
        self.search("", limit).await
    }
    
    async fn get_by_semantic_type(&self, semantic_type: &str, limit: usize) -> Result<Vec<Command>> {
        let limit = limit as i64;
        
        let records = sqlx::query!(
            r#"
            SELECT * FROM commands 
            WHERE semantic_type = ? AND is_sensitive = 0
            ORDER BY timestamp DESC
            LIMIT ?
            "#,
            semantic_type,
            limit
        )
        .fetch_all(&self.pool)
        .await?;
        
        // Convert records to commands (same as search method)
        let mut commands = Vec::new();
        for r in records {
            let semantic_type: SemanticType = serde_json::from_str(&r.semantic_type)?;
            let project_type = r.project_type
                .map(|pt| serde_json::from_str(&pt).ok())
                .flatten();
            
            commands.push(Command {
                id: Uuid::parse_str(&r.id)?,
                timestamp: chrono::DateTime::from_timestamp(r.timestamp, 0).unwrap().into(),
                command: r.command,
                directory: r.directory,
                exit_code: r.exit_code as i32,
                duration_ms: r.duration_ms as u64,
                session_id: r.session_id,
                semantic_type,
                git_branch: r.git_branch,
                project_type,
                is_sensitive: false,
                intent: r.intent,
                complexity: r.complexity as u8,
            });
        }
        
        Ok(commands)
    }
    
    async fn get_statistics(&self, range: &str) -> Result<CommandStats> {
        // Calculate date range
        let since = match range {
            "today" => chrono::Utc::now() - chrono::Duration::days(1),
            "week" => chrono::Utc::now() - chrono::Duration::weeks(1),
            "month" => chrono::Utc::now() - chrono::Duration::days(30),
            _ => chrono::DateTime::from_timestamp(0, 0).unwrap().into(), // all time
        };
        
        let since_timestamp = since.timestamp();
        
        // Get basic stats
        let stats = sqlx::query!(
            r#"
            SELECT 
                COUNT(*) as total,
                COUNT(CASE WHEN exit_code = 0 THEN 1 END) as successful,
                COUNT(CASE WHEN exit_code != 0 THEN 1 END) as failed,
                COUNT(DISTINCT command) as unique_commands,
                AVG(duration_ms) as avg_duration
            FROM commands
            WHERE timestamp >= ?
            "#,
            since_timestamp
        )
        .fetch_one(&self.pool)
        .await?;
        
        // Get by type
        let by_type = sqlx::query!(
            r#"
            SELECT semantic_type, COUNT(*) as count
            FROM commands
            WHERE timestamp >= ?
            GROUP BY semantic_type
            ORDER BY count DESC
            "#,
            since_timestamp
        )
        .fetch_all(&self.pool)
        .await?;
        
        // Get by hour
        let by_hour = sqlx::query!(
            r#"
            SELECT 
                CAST(strftime('%H', datetime(timestamp, 'unixepoch')) AS INTEGER) as hour,
                COUNT(*) as count
            FROM commands
            WHERE timestamp >= ?
            GROUP BY hour
            ORDER BY hour
            "#,
            since_timestamp
        )
        .fetch_all(&self.pool)
        .await?;
        
        // Get by directory
        let by_directory = sqlx::query!(
            r#"
            SELECT directory, COUNT(*) as count
            FROM commands
            WHERE timestamp >= ?
            GROUP BY directory
            ORDER BY count DESC
            LIMIT 10
            "#,
            since_timestamp
        )
        .fetch_all(&self.pool)
        .await?;
        
        Ok(CommandStats {
            total_commands: stats.total as u64,
            successful_commands: stats.successful as u64,
            failed_commands: stats.failed as u64,
            unique_commands: stats.unique_commands as u64,
            by_type: by_type.into_iter()
                .map(|r| (r.semantic_type, r.count as u64))
                .collect(),
            by_hour: by_hour.into_iter()
                .map(|r| (r.hour as u8, r.count as u64))
                .collect(),
            by_directory: by_directory.into_iter()
                .map(|r| (r.directory, r.count as u64))
                .collect(),
            average_duration_ms: stats.avg_duration.unwrap_or(0.0),
        })
    }
    
    async fn update(&self, command: &Command) -> Result<()> {
        let id = command.id.to_string();
        let semantic_type = serde_json::to_string(&command.semantic_type)?;
        let project_type = command.project_type.as_ref()
            .map(|pt| serde_json::to_string(pt).unwrap_or_default());
        
        sqlx::query!(
            r#"
            UPDATE commands SET
                exit_code = ?, duration_ms = ?, git_branch = ?,
                project_type = ?, intent = ?, complexity = ?
            WHERE id = ?
            "#,
            command.exit_code,
            command.duration_ms,
            command.git_branch,
            project_type,
            command.intent,
            command.complexity,
            id
        )
        .execute(&self.pool)
        .await?;
        
        Ok(())
    }
    
    async fn delete(&self, id: &str) -> Result<()> {
        sqlx::query!("DELETE FROM commands WHERE id = ?", id)
            .execute(&self.pool)
            .await?;
        
        Ok(())
    }
    
    async fn count(&self) -> Result<u64> {
        let result = sqlx::query!("SELECT COUNT(*) as count FROM commands")
            .fetch_one(&self.pool)
            .await?;
        
        Ok(result.count as u64)
    }
    
    async fn get_by_directory(&self, directory: &str, limit: usize) -> Result<Vec<Command>> {
        let limit = limit as i64;
        
        let records = sqlx::query!(
            r#"
            SELECT * FROM commands 
            WHERE directory = ? AND is_sensitive = 0
            ORDER BY timestamp DESC
            LIMIT ?
            "#,
            directory,
            limit
        )
        .fetch_all(&self.pool)
        .await?;
        
        let mut commands = Vec::new();
        for r in records {
            let semantic_type: SemanticType = serde_json::from_str(&r.semantic_type)?;
            let project_type = r.project_type
                .map(|pt| serde_json::from_str(&pt).ok())
                .flatten();
            
            commands.push(Command {
                id: Uuid::parse_str(&r.id)?,
                timestamp: chrono::DateTime::from_timestamp(r.timestamp, 0).unwrap().into(),
                command: r.command,
                directory: r.directory,
                exit_code: r.exit_code as i32,
                duration_ms: r.duration_ms as u64,
                session_id: r.session_id,
                semantic_type,
                git_branch: r.git_branch,
                project_type,
                is_sensitive: false,
                intent: r.intent,
                complexity: r.complexity as u8,
            });
        }
        
        Ok(commands)
    }
    
    async fn get_since(&self, since: chrono::DateTime<chrono::Utc>) -> Result<Vec<Command>> {
        let since_timestamp = since.timestamp();
        
        let records = sqlx::query!(
            r#"
            SELECT * FROM commands 
            WHERE timestamp >= ? AND is_sensitive = 0
            ORDER BY timestamp DESC
            "#,
            since_timestamp
        )
        .fetch_all(&self.pool)
        .await?;
        
        let mut commands = Vec::new();
        for r in records {
            let semantic_type: SemanticType = serde_json::from_str(&r.semantic_type)?;
            let project_type = r.project_type
                .map(|pt| serde_json::from_str(&pt).ok())
                .flatten();
            
            commands.push(Command {
                id: Uuid::parse_str(&r.id)?,
                timestamp: chrono::DateTime::from_timestamp(r.timestamp, 0).unwrap().into(),
                command: r.command,
                directory: r.directory,
                exit_code: r.exit_code as i32,
                duration_ms: r.duration_ms as u64,
                session_id: r.session_id,
                semantic_type,
                git_branch: r.git_branch,
                project_type,
                is_sensitive: false,
                intent: r.intent,
                complexity: r.complexity as u8,
            });
        }
        
        Ok(commands)
    }
    
    async fn get_all(&self) -> Result<Vec<Command>> {
        let records = sqlx::query!(
            r#"
            SELECT * FROM commands 
            WHERE is_sensitive = 0
            ORDER BY timestamp DESC
            "#
        )
        .fetch_all(&self.pool)
        .await?;
        
        let mut commands = Vec::new();
        for r in records {
            let semantic_type: SemanticType = serde_json::from_str(&r.semantic_type)?;
            let project_type = r.project_type
                .map(|pt| serde_json::from_str(&pt).ok())
                .flatten();
            
            commands.push(Command {
                id: Uuid::parse_str(&r.id)?,
                timestamp: chrono::DateTime::from_timestamp(r.timestamp, 0).unwrap().into(),
                command: r.command,
                directory: r.directory,
                exit_code: r.exit_code as i32,
                duration_ms: r.duration_ms as u64,
                session_id: r.session_id,
                semantic_type,
                git_branch: r.git_branch,
                project_type,
                is_sensitive: false,
                intent: r.intent,
                complexity: r.complexity as u8,
            });
        }
        
        Ok(commands)
    }
}