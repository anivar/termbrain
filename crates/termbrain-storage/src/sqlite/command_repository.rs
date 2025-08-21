//! SQLite implementation of CommandRepository

use anyhow::Result;
use async_trait::async_trait;
use chrono::{DateTime, Utc};
use sqlx::{SqlitePool, Row};
use termbrain_core::domain::{Command, CommandRepository, CommandMetadata};
use uuid::Uuid;
use std::collections::HashMap;

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
        let arguments_json = serde_json::to_string(&command.arguments)?;
        let environment_json = serde_json::to_string(&command.metadata.environment)?;
        
        sqlx::query(
            r#"
            INSERT INTO commands (
                id, raw, parsed_command, arguments, working_directory, 
                exit_code, duration_ms, timestamp, session_id,
                shell, user, hostname, terminal, environment
            ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14)
            "#,
        )
        .bind(command.id.to_string())
        .bind(&command.raw)
        .bind(&command.parsed_command)
        .bind(&arguments_json)
        .bind(&command.working_directory)
        .bind(command.exit_code)
        .bind(command.duration_ms as i64)
        .bind(command.timestamp.to_rfc3339())
        .bind(&command.session_id)
        .bind(&command.metadata.shell)
        .bind(&command.metadata.user)
        .bind(&command.metadata.hostname)
        .bind(&command.metadata.terminal)
        .bind(&environment_json)
        .execute(&self.pool)
        .await?;
        
        Ok(())
    }
    
    async fn find_by_id(&self, id: &Uuid) -> Result<Option<Command>> {
        let result = sqlx::query(
            r#"
            SELECT id, raw, parsed_command, arguments, working_directory,
                   exit_code, duration_ms, timestamp, session_id,
                   shell, user, hostname, terminal, environment
            FROM commands 
            WHERE id = ?1
            "#,
        )
        .bind(id.to_string())
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(result.map(|row| self.row_to_command(row)).transpose()?)
    }
    
    async fn find_by_session(&self, session_id: &str) -> Result<Vec<Command>> {
        let results = sqlx::query(
            r#"
            SELECT id, raw, parsed_command, arguments, working_directory,
                   exit_code, duration_ms, timestamp, session_id,
                   shell, user, hostname, terminal, environment
            FROM commands 
            WHERE session_id = ?1
            ORDER BY timestamp DESC
            "#,
        )
        .bind(session_id)
        .fetch_all(&self.pool)
        .await?;
        
        self.rows_to_commands(results)
    }
    
    async fn find_recent(&self, limit: usize) -> Result<Vec<Command>> {
        let results = sqlx::query(
            r#"
            SELECT id, raw, parsed_command, arguments, working_directory,
                   exit_code, duration_ms, timestamp, session_id,
                   shell, user, hostname, terminal, environment
            FROM commands 
            ORDER BY timestamp DESC 
            LIMIT ?1
            "#,
        )
        .bind(limit as i64)
        .fetch_all(&self.pool)
        .await?;
        
        self.rows_to_commands(results)
    }
    
    async fn find_by_pattern(&self, pattern: &str) -> Result<Vec<Command>> {
        let results = sqlx::query(
            r#"
            SELECT id, raw, parsed_command, arguments, working_directory,
                   exit_code, duration_ms, timestamp, session_id,
                   shell, user, hostname, terminal, environment
            FROM commands 
            WHERE raw LIKE ?1
            ORDER BY timestamp DESC
            "#,
        )
        .bind(format!("%{}%", pattern))
        .fetch_all(&self.pool)
        .await?;
        
        self.rows_to_commands(results)
    }
    
    async fn find_by_directory(&self, directory: &str) -> Result<Vec<Command>> {
        let results = sqlx::query(
            r#"
            SELECT id, raw, parsed_command, arguments, working_directory,
                   exit_code, duration_ms, timestamp, session_id,
                   shell, user, hostname, terminal, environment
            FROM commands 
            WHERE working_directory = ?1
            ORDER BY timestamp DESC
            "#,
        )
        .bind(directory)
        .fetch_all(&self.pool)
        .await?;
        
        self.rows_to_commands(results)
    }
    
    async fn find_by_time_range(&self, start: DateTime<Utc>, end: DateTime<Utc>) -> Result<Vec<Command>> {
        let results = sqlx::query(
            r#"
            SELECT id, raw, parsed_command, arguments, working_directory,
                   exit_code, duration_ms, timestamp, session_id,
                   shell, user, hostname, terminal, environment
            FROM commands 
            WHERE timestamp >= ?1 AND timestamp <= ?2
            ORDER BY timestamp DESC
            "#,
        )
        .bind(start.to_rfc3339())
        .bind(end.to_rfc3339())
        .fetch_all(&self.pool)
        .await?;
        
        self.rows_to_commands(results)
    }
    
    async fn delete_by_id(&self, id: &Uuid) -> Result<()> {
        sqlx::query(r#"DELETE FROM commands WHERE id = ?1"#)
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;
        
        Ok(())
    }
    
    async fn search(&self, query: &str, limit: usize, directory: Option<&str>, since: Option<DateTime<Utc>>) -> Result<Vec<Command>> {
        let mut sql = r#"
            SELECT id, raw, parsed_command, arguments, working_directory,
                   exit_code, duration_ms, timestamp, session_id,
                   shell, user, hostname, terminal, environment
            FROM commands 
            WHERE raw LIKE ?
        "#.to_string();
        
        if directory.is_some() {
            sql.push_str(" AND working_directory = ?");
        }
        
        if since.is_some() {
            sql.push_str(" AND timestamp >= ?");
        }
        
        sql.push_str(" ORDER BY timestamp DESC LIMIT ?");
        
        let search_term = format!("%{}%", query);
        let mut query_builder = sqlx::query(&sql);
        query_builder = query_builder.bind(&search_term);
        
        if let Some(dir) = directory {
            query_builder = query_builder.bind(dir);
        }
        
        if let Some(since_time) = since {
            query_builder = query_builder.bind(since_time.to_rfc3339());
        }
        
        query_builder = query_builder.bind(limit as i64);
        
        let results = query_builder.fetch_all(&self.pool).await?;
        
        self.rows_to_commands(results)
    }
    
    async fn search_semantic(&self, query: &str, limit: usize) -> Result<Vec<Command>> {
        // TODO: Implement proper semantic search with sqlite-vec
        // For now, we'll use a more sophisticated text search that looks for
        // similar commands based on keywords
        
        let keywords: Vec<&str> = query.split_whitespace().collect();
        const MAX_KEYWORDS: usize = 10;
        
        if keywords.len() > MAX_KEYWORDS {
            return Err(anyhow::anyhow!(
                "Too many keywords in search query. Maximum {} keywords supported", 
                MAX_KEYWORDS
            ));
        }
        
        let patterns: Vec<String> = keywords.iter()
            .map(|keyword| format!("%{}%", keyword))
            .collect();
        
        let sql = r#"
            WITH keyword_matches AS (
                SELECT id, raw, parsed_command, arguments, working_directory,
                       exit_code, duration_ms, timestamp, session_id,
                       shell, user, hostname, terminal, environment,
                       (CASE WHEN raw LIKE ?1 THEN 1 ELSE 0 END +
                        CASE WHEN raw LIKE ?2 THEN 1 ELSE 0 END +
                        CASE WHEN raw LIKE ?3 THEN 1 ELSE 0 END +
                        CASE WHEN raw LIKE ?4 THEN 1 ELSE 0 END +
                        CASE WHEN raw LIKE ?5 THEN 1 ELSE 0 END +
                        CASE WHEN raw LIKE ?6 THEN 1 ELSE 0 END +
                        CASE WHEN raw LIKE ?7 THEN 1 ELSE 0 END +
                        CASE WHEN raw LIKE ?8 THEN 1 ELSE 0 END +
                        CASE WHEN raw LIKE ?9 THEN 1 ELSE 0 END +
                        CASE WHEN raw LIKE ?10 THEN 1 ELSE 0 END) as match_count
                FROM commands
                WHERE raw LIKE ?1 OR raw LIKE ?2 OR raw LIKE ?3 OR 
                      raw LIKE ?4 OR raw LIKE ?5 OR raw LIKE ?6 OR
                      raw LIKE ?7 OR raw LIKE ?8 OR raw LIKE ?9 OR 
                      raw LIKE ?10
            )
            SELECT * FROM keyword_matches
            WHERE match_count > 0
            ORDER BY match_count DESC, timestamp DESC
            LIMIT ?11
        "#;
        
        let mut query_builder = sqlx::query(sql);
        
        for i in 0..MAX_KEYWORDS {
            if i < patterns.len() {
                query_builder = query_builder.bind(&patterns[i]);
            } else {
                query_builder = query_builder.bind("__IMPOSSIBLE_PATTERN__");
            }
        }
        
        query_builder = query_builder.bind(limit as i64);
        
        let results = query_builder.fetch_all(&self.pool).await?;
        
        self.rows_to_commands(results)
    }

    async fn count(&self) -> Result<usize> {
        let result = sqlx::query(r#"SELECT COUNT(*) as count FROM commands"#)
            .fetch_one(&self.pool)
            .await?;
        
        Ok(result.get::<i64, _>("count") as usize)
    }
}

impl SqliteCommandRepository {
    fn row_to_command(&self, row: sqlx::sqlite::SqliteRow) -> Result<Command> {
        let arguments_json: String = row.get("arguments");
        let environment_json: String = row.get("environment");
        let timestamp_str: String = row.get("timestamp");
        
        let arguments: Vec<String> = serde_json::from_str(&arguments_json)?;
        let environment: HashMap<String, String> = serde_json::from_str(&environment_json)?;
        let timestamp = DateTime::parse_from_rfc3339(&timestamp_str)?.with_timezone(&Utc);
        
        Ok(Command {
            id: Uuid::parse_str(row.get("id"))?,
            raw: row.get("raw"),
            parsed_command: row.get("parsed_command"),
            arguments,
            working_directory: row.get("working_directory"),
            exit_code: row.get("exit_code"),
            duration_ms: row.get::<i64, _>("duration_ms") as u64,
            timestamp,
            session_id: row.get("session_id"),
            metadata: CommandMetadata {
                shell: row.get("shell"),
                user: row.get("user"),
                hostname: row.get("hostname"),
                terminal: row.get("terminal"),
                environment,
            },
        })
    }
    
    fn rows_to_commands(&self, rows: Vec<sqlx::sqlite::SqliteRow>) -> Result<Vec<Command>> {
        rows.into_iter()
            .map(|row| self.row_to_command(row))
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use sqlx::sqlite::SqlitePoolOptions;
    use tempfile::NamedTempFile;

    async fn setup_test_db() -> Result<SqlitePool> {
        let temp_file = NamedTempFile::new()?;
        let db_path = temp_file.path().to_str().unwrap();
        let pool = SqlitePoolOptions::new()
            .connect(&format!("sqlite:{}", db_path))
            .await?;
        
        // Create schema
        sqlx::query(include_str!("../../../../migrations/001_initial.sql"))
            .execute(&pool)
            .await?;
        
        Ok(pool)
    }

    #[tokio::test]
    async fn test_save_and_find_command() -> Result<()> {
        let pool = setup_test_db().await?;
        let repo = SqliteCommandRepository::new(pool);
        
        let command = Command {
            id: Uuid::new_v4(),
            raw: "git status".to_string(),
            parsed_command: "git".to_string(),
            arguments: vec!["status".to_string()],
            working_directory: "/home/test".to_string(),
            exit_code: 0,
            duration_ms: 100,
            timestamp: Utc::now(),
            session_id: "test-session".to_string(),
            metadata: CommandMetadata {
                shell: "bash".to_string(),
                user: "testuser".to_string(),
                hostname: "testhost".to_string(),
                terminal: "xterm".to_string(),
                environment: HashMap::new(),
            },
        };
        
        repo.save(&command).await?;
        
        let found = repo.find_by_id(&command.id).await?;
        assert!(found.is_some());
        
        let found_cmd = found.unwrap();
        assert_eq!(found_cmd.raw, command.raw);
        assert_eq!(found_cmd.exit_code, command.exit_code);
        
        Ok(())
    }
}