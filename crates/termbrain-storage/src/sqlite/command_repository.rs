//! SQLite implementation of CommandRepository

use anyhow::Result;
use async_trait::async_trait;
use chrono::{DateTime, Utc};
use sqlx::{SqlitePool, Row};
use termbrain_core::domain::{Command, CommandRepository, CommandMetadata};

pub struct SqliteCommandRepository {
    pool: SqlitePool,
}

impl SqliteCommandRepository {
    pub fn new(pool: SqlitePool) -> Self {
        Self { pool }
    }
}

#[async_trait]
impl CommandRepository for SqliteCommandRepository {
    async fn save(&self, command: &Command) -> Result<()> {
        sqlx::query(
            r#"
            INSERT INTO commands (id, command, created_at)
            VALUES (?1, ?2, ?3)
            "#,
        )
        .bind(command.id.to_string())
        .bind(&command.raw)
        .bind(Utc::now().timestamp())
        .execute(&self.pool)
        .await?;
        
        Ok(())
    }
    
    async fn find_by_id(&self, id: &uuid::Uuid) -> Result<Option<Command>> {
        let result = sqlx::query(
            r#"
            SELECT id, command FROM commands WHERE id = ?1
            "#,
        )
        .bind(id.to_string())
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(result.map(|row| Command {
            id: uuid::Uuid::parse_str(row.get("id")).unwrap(),
            raw: row.get("command"),
            parsed_command: row.get::<String, _>("command"),
            arguments: vec![],
            working_directory: "/".to_string(),
            exit_code: 0,
            duration_ms: 0,
            timestamp: Utc::now(),
            session_id: "unknown".to_string(),
            metadata: CommandMetadata {
                shell: "bash".to_string(),
                user: "user".to_string(),
                hostname: "localhost".to_string(),
                terminal: "xterm".to_string(),
                environment: std::collections::HashMap::new(),
            },
        }))
    }
    
    async fn find_by_session(&self, _session_id: &str) -> Result<Vec<Command>> {
        // Placeholder implementation
        Ok(vec![])
    }
    
    async fn find_recent(&self, limit: usize) -> Result<Vec<Command>> {
        let results = sqlx::query(
            r#"
            SELECT id, command FROM commands 
            ORDER BY created_at DESC 
            LIMIT ?1
            "#,
        )
        .bind(limit as i64)
        .fetch_all(&self.pool)
        .await?;
        
        Ok(results
            .into_iter()
            .map(|row| Command {
                id: uuid::Uuid::parse_str(row.get("id")).unwrap(),
                raw: row.get("command"),
                parsed_command: row.get::<String, _>("command"),
                arguments: vec![],
                working_directory: "/".to_string(),
                exit_code: 0,
                duration_ms: 0,
                timestamp: Utc::now(),
                session_id: "unknown".to_string(),
                metadata: CommandMetadata {
                    shell: "bash".to_string(),
                    user: "user".to_string(),
                    hostname: "localhost".to_string(),
                    terminal: "xterm".to_string(),
                    environment: std::collections::HashMap::new(),
                },
            })
            .collect())
    }
    
    async fn find_by_pattern(&self, _pattern: &str) -> Result<Vec<Command>> {
        // Placeholder implementation
        Ok(vec![])
    }
    
    async fn find_by_directory(&self, _directory: &str) -> Result<Vec<Command>> {
        // Placeholder implementation
        Ok(vec![])
    }
    
    async fn find_by_time_range(&self, _start: DateTime<Utc>, _end: DateTime<Utc>) -> Result<Vec<Command>> {
        // Placeholder implementation
        Ok(vec![])
    }
    
    async fn delete_by_id(&self, id: &uuid::Uuid) -> Result<()> {
        sqlx::query(r#"DELETE FROM commands WHERE id = ?1"#)
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;
        
        Ok(())
    }
    
    async fn count(&self) -> Result<usize> {
        let result = sqlx::query(r#"SELECT COUNT(*) as count FROM commands"#)
            .fetch_one(&self.pool)
            .await?;
        
        Ok(result.get::<i64, _>("count") as usize)
    }
}
#[cfg(test)]
mod command_repository_test;
