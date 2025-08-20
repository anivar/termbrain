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
    
    async fn search(&self, query: &str, limit: usize, directory: Option<&str>, since: Option<DateTime<Utc>>) -> Result<Vec<Command>> {
        let mut sql = "SELECT id, command, created_at FROM commands WHERE command LIKE ?1".to_string();
        let mut params: Vec<Box<dyn sqlx::Encode<'_, sqlx::Sqlite> + Send + 'static>> = vec![];
        
        // Add query parameter with wildcards
        params.push(Box::new(format!("%{}%", query)));
        
        let mut param_index = 2;
        
        // Add directory filter if provided
        if let Some(dir) = directory {
            sql.push_str(&format!(" AND working_directory = ?{}", param_index));
            params.push(Box::new(dir.to_string()));
            param_index += 1;
        }
        
        // Add time filter if provided
        if let Some(since_time) = since {
            sql.push_str(&format!(" AND created_at >= ?{}", param_index));
            params.push(Box::new(since_time.timestamp()));
        }
        
        sql.push_str(" ORDER BY created_at DESC LIMIT ?");
        sql.push_str(&param_index.to_string());
        
        let mut query_builder = sqlx::query(&sql);
        
        // Bind the search term
        query_builder = query_builder.bind(format!("%{}%", query));
        
        // Bind directory if provided
        if let Some(dir) = directory {
            query_builder = query_builder.bind(dir);
        }
        
        // Bind since time if provided
        if let Some(since_time) = since {
            query_builder = query_builder.bind(since_time.timestamp());
        }
        
        // Bind limit
        query_builder = query_builder.bind(limit as i64);
        
        let results = query_builder.fetch_all(&self.pool).await?;
        
        Ok(results
            .into_iter()
            .map(|row| Command {
                id: uuid::Uuid::parse_str(row.get("id")).unwrap_or_else(|_| uuid::Uuid::new_v4()),
                raw: row.get("command"),
                parsed_command: row.get::<String, _>("command"),
                arguments: vec![],
                working_directory: "/".to_string(),
                exit_code: 0,
                duration_ms: 0,
                timestamp: DateTime::from_timestamp(row.get::<i64, _>("created_at"), 0).unwrap_or_else(|| Utc::now()),
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
    
    async fn search_semantic(&self, query: &str, limit: usize) -> Result<Vec<Command>> {
        // For now, implement as regular text search
        // In a full implementation, this would use vector similarity search with sqlite-vec
        let results = sqlx::query(
            r#"
            SELECT id, command, created_at FROM commands 
            WHERE command LIKE ?1
            ORDER BY created_at DESC 
            LIMIT ?2
            "#,
        )
        .bind(format!("%{}%", query))
        .bind(limit as i64)
        .fetch_all(&self.pool)
        .await?;
        
        Ok(results
            .into_iter()
            .map(|row| Command {
                id: uuid::Uuid::parse_str(row.get("id")).unwrap_or_else(|_| uuid::Uuid::new_v4()),
                raw: row.get("command"),
                parsed_command: row.get::<String, _>("command"),
                arguments: vec![],
                working_directory: "/".to_string(),
                exit_code: 0,
                duration_ms: 0,
                timestamp: DateTime::from_timestamp(row.get::<i64, _>("created_at"), 0).unwrap_or_else(|| Utc::now()),
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

    async fn count(&self) -> Result<usize> {
        let result = sqlx::query(r#"SELECT COUNT(*) as count FROM commands"#)
            .fetch_one(&self.pool)
            .await?;
        
        Ok(result.get::<i64, _>("count") as usize)
    }
}
