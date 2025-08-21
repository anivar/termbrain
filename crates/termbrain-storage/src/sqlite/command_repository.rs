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
    
    /// Helper to parse command arguments from raw command string
    fn parse_arguments(command: &str) -> Vec<String> {
        // Simple argument parsing - in production, use shell_words crate
        command.split_whitespace()
            .skip(1) // Skip the command itself
            .map(|s| s.to_string())
            .collect()
    }
    
    /// Helper to extract command name from raw command
    fn parse_command_name(command: &str) -> String {
        command.split_whitespace()
            .next()
            .unwrap_or("")
            .to_string()
    }
}

#[async_trait]
impl CommandRepository for SqliteCommandRepository {
    async fn save(&self, command: &Command) -> Result<()> {
        
        sqlx::query(
            r#"
            INSERT INTO commands (
                id, timestamp, command, directory, exit_code, 
                duration_ms, session_id, semantic_type, git_branch, 
                project_type, is_sensitive, intent, complexity
            ) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13)
            "#,
        )
        .bind(command.id.to_string())
        .bind(command.timestamp.timestamp())
        .bind(&command.raw)
        .bind(&command.working_directory)
        .bind(command.exit_code)
        .bind(command.duration_ms as i64)
        .bind(&command.session_id)
        .bind("general") // TODO: Implement semantic type detection
        .bind(None::<String>) // TODO: Detect git branch
        .bind(None::<String>) // TODO: Detect project type
        .bind(0) // TODO: Implement sensitive command detection
        .bind(None::<String>) // TODO: Implement intent detection
        .bind(1) // TODO: Calculate complexity
        .execute(&self.pool)
        .await?;
        
        Ok(())
    }
    
    async fn find_by_id(&self, id: &Uuid) -> Result<Option<Command>> {
        let result = sqlx::query(
            r#"
            SELECT id, timestamp, command, directory, exit_code,
                   duration_ms, session_id, semantic_type
            FROM commands 
            WHERE id = ?1
            "#,
        )
        .bind(id.to_string())
        .fetch_optional(&self.pool)
        .await?;
        
        Ok(result.map(|row| {
            let raw_command: String = row.get("command");
            Command {
                id: Uuid::parse_str(row.get("id")).expect("Invalid UUID in database"),
                raw: raw_command.clone(),
                parsed_command: Self::parse_command_name(&raw_command),
                arguments: Self::parse_arguments(&raw_command),
                working_directory: row.get("directory"),
                exit_code: row.get("exit_code"),
                duration_ms: row.get::<i64, _>("duration_ms") as u64,
                timestamp: DateTime::from_timestamp(row.get("timestamp"), 0)
                    .unwrap_or_else(|| Utc::now()),
                session_id: row.get("session_id"),
                metadata: CommandMetadata {
                    shell: std::env::var("SHELL")
                        .unwrap_or_else(|_| "bash".to_string())
                        .split('/')
                        .last()
                        .unwrap_or("bash")
                        .to_string(),
                    user: std::env::var("USER").unwrap_or_else(|_| "unknown".to_string()),
                    hostname: hostname::get()
                        .map(|h| h.to_string_lossy().to_string())
                        .unwrap_or_else(|_| "localhost".to_string()),
                    terminal: std::env::var("TERM").unwrap_or_else(|_| "xterm".to_string()),
                    environment: HashMap::new(), // TODO: Store relevant env vars
                },
            }
        }))
    }
    
    async fn find_by_session(&self, session_id: &str) -> Result<Vec<Command>> {
        let results = sqlx::query(
            r#"
            SELECT id, timestamp, command, directory, exit_code,
                   duration_ms, session_id, semantic_type
            FROM commands 
            WHERE session_id = ?1
            ORDER BY timestamp DESC
            "#,
        )
        .bind(session_id)
        .fetch_all(&self.pool)
        .await?;
        
        Ok(results
            .into_iter()
            .map(|row| {
                let raw_command: String = row.get("command");
                Command {
                    id: Uuid::parse_str(row.get("id")).expect("Invalid UUID in database"),
                    raw: raw_command.clone(),
                    parsed_command: Self::parse_command_name(&raw_command),
                    arguments: Self::parse_arguments(&raw_command),
                    working_directory: row.get("directory"),
                    exit_code: row.get("exit_code"),
                    duration_ms: row.get::<i64, _>("duration_ms") as u64,
                    timestamp: DateTime::from_timestamp(row.get("timestamp"), 0)
                        .unwrap_or_else(|| Utc::now()),
                    session_id: row.get("session_id"),
                    metadata: CommandMetadata {
                        shell: std::env::var("SHELL")
                            .unwrap_or_else(|_| "bash".to_string())
                            .split('/')
                            .last()
                            .unwrap_or("bash")
                            .to_string(),
                        user: std::env::var("USER").unwrap_or_else(|_| "unknown".to_string()),
                        hostname: hostname::get()
                            .map(|h| h.to_string_lossy().to_string())
                            .unwrap_or_else(|_| "localhost".to_string()),
                        terminal: std::env::var("TERM").unwrap_or_else(|_| "xterm".to_string()),
                        environment: HashMap::new(),
                    },
                }
            })
            .collect())
    }
    
    async fn find_recent(&self, limit: usize) -> Result<Vec<Command>> {
        let results = sqlx::query(
            r#"
            SELECT id, timestamp, command, directory, exit_code,
                   duration_ms, session_id, semantic_type
            FROM commands 
            ORDER BY timestamp DESC 
            LIMIT ?1
            "#,
        )
        .bind(limit as i64)
        .fetch_all(&self.pool)
        .await?;
        
        Ok(results
            .into_iter()
            .map(|row| {
                let raw_command: String = row.get("command");
                Command {
                    id: Uuid::parse_str(row.get("id")).expect("Invalid UUID in database"),
                    raw: raw_command.clone(),
                    parsed_command: Self::parse_command_name(&raw_command),
                    arguments: Self::parse_arguments(&raw_command),
                    working_directory: row.get("directory"),
                    exit_code: row.get("exit_code"),
                    duration_ms: row.get::<i64, _>("duration_ms") as u64,
                    timestamp: DateTime::from_timestamp(row.get("timestamp"), 0)
                        .unwrap_or_else(|| Utc::now()),
                    session_id: row.get("session_id"),
                    metadata: CommandMetadata {
                        shell: std::env::var("SHELL")
                            .unwrap_or_else(|_| "bash".to_string())
                            .split('/')
                            .last()
                            .unwrap_or("bash")
                            .to_string(),
                        user: std::env::var("USER").unwrap_or_else(|_| "unknown".to_string()),
                        hostname: hostname::get()
                            .map(|h| h.to_string_lossy().to_string())
                            .unwrap_or_else(|_| "localhost".to_string()),
                        terminal: std::env::var("TERM").unwrap_or_else(|_| "xterm".to_string()),
                        environment: HashMap::new(),
                    },
                }
            })
            .collect())
    }
    
    async fn find_by_pattern(&self, pattern: &str) -> Result<Vec<Command>> {
        let results = sqlx::query(
            r#"
            SELECT id, timestamp, command, directory, exit_code,
                   duration_ms, session_id, semantic_type
            FROM commands 
            WHERE command LIKE ?1
            ORDER BY timestamp DESC
            "#,
        )
        .bind(format!("%{}%", pattern))
        .fetch_all(&self.pool)
        .await?;
        
        Ok(results
            .into_iter()
            .map(|row| {
                let raw_command: String = row.get("command");
                Command {
                    id: Uuid::parse_str(row.get("id")).expect("Invalid UUID in database"),
                    raw: raw_command.clone(),
                    parsed_command: Self::parse_command_name(&raw_command),
                    arguments: Self::parse_arguments(&raw_command),
                    working_directory: row.get("directory"),
                    exit_code: row.get("exit_code"),
                    duration_ms: row.get::<i64, _>("duration_ms") as u64,
                    timestamp: DateTime::from_timestamp(row.get("timestamp"), 0)
                        .unwrap_or_else(|| Utc::now()),
                    session_id: row.get("session_id"),
                    metadata: CommandMetadata {
                        shell: std::env::var("SHELL")
                            .unwrap_or_else(|_| "bash".to_string())
                            .split('/')
                            .last()
                            .unwrap_or("bash")
                            .to_string(),
                        user: std::env::var("USER").unwrap_or_else(|_| "unknown".to_string()),
                        hostname: hostname::get()
                            .map(|h| h.to_string_lossy().to_string())
                            .unwrap_or_else(|_| "localhost".to_string()),
                        terminal: std::env::var("TERM").unwrap_or_else(|_| "xterm".to_string()),
                        environment: HashMap::new(),
                    },
                }
            })
            .collect())
    }
    
    async fn find_by_directory(&self, directory: &str) -> Result<Vec<Command>> {
        let results = sqlx::query(
            r#"
            SELECT id, timestamp, command, directory, exit_code,
                   duration_ms, session_id, semantic_type
            FROM commands 
            WHERE directory = ?1
            ORDER BY timestamp DESC
            "#,
        )
        .bind(directory)
        .fetch_all(&self.pool)
        .await?;
        
        Ok(results
            .into_iter()
            .map(|row| {
                let raw_command: String = row.get("command");
                Command {
                    id: Uuid::parse_str(row.get("id")).expect("Invalid UUID in database"),
                    raw: raw_command.clone(),
                    parsed_command: Self::parse_command_name(&raw_command),
                    arguments: Self::parse_arguments(&raw_command),
                    working_directory: row.get("directory"),
                    exit_code: row.get("exit_code"),
                    duration_ms: row.get::<i64, _>("duration_ms") as u64,
                    timestamp: DateTime::from_timestamp(row.get("timestamp"), 0)
                        .unwrap_or_else(|| Utc::now()),
                    session_id: row.get("session_id"),
                    metadata: CommandMetadata {
                        shell: std::env::var("SHELL")
                            .unwrap_or_else(|_| "bash".to_string())
                            .split('/')
                            .last()
                            .unwrap_or("bash")
                            .to_string(),
                        user: std::env::var("USER").unwrap_or_else(|_| "unknown".to_string()),
                        hostname: hostname::get()
                            .map(|h| h.to_string_lossy().to_string())
                            .unwrap_or_else(|_| "localhost".to_string()),
                        terminal: std::env::var("TERM").unwrap_or_else(|_| "xterm".to_string()),
                        environment: HashMap::new(),
                    },
                }
            })
            .collect())
    }
    
    async fn find_by_time_range(&self, start: DateTime<Utc>, end: DateTime<Utc>) -> Result<Vec<Command>> {
        let results = sqlx::query(
            r#"
            SELECT id, timestamp, command, directory, exit_code,
                   duration_ms, session_id, semantic_type
            FROM commands 
            WHERE timestamp >= ?1 AND timestamp <= ?2
            ORDER BY timestamp DESC
            "#,
        )
        .bind(start.timestamp())
        .bind(end.timestamp())
        .fetch_all(&self.pool)
        .await?;
        
        Ok(results
            .into_iter()
            .map(|row| {
                let raw_command: String = row.get("command");
                Command {
                    id: Uuid::parse_str(row.get("id")).expect("Invalid UUID in database"),
                    raw: raw_command.clone(),
                    parsed_command: Self::parse_command_name(&raw_command),
                    arguments: Self::parse_arguments(&raw_command),
                    working_directory: row.get("directory"),
                    exit_code: row.get("exit_code"),
                    duration_ms: row.get::<i64, _>("duration_ms") as u64,
                    timestamp: DateTime::from_timestamp(row.get("timestamp"), 0)
                        .unwrap_or_else(|| Utc::now()),
                    session_id: row.get("session_id"),
                    metadata: CommandMetadata {
                        shell: std::env::var("SHELL")
                            .unwrap_or_else(|_| "bash".to_string())
                            .split('/')
                            .last()
                            .unwrap_or("bash")
                            .to_string(),
                        user: std::env::var("USER").unwrap_or_else(|_| "unknown".to_string()),
                        hostname: hostname::get()
                            .map(|h| h.to_string_lossy().to_string())
                            .unwrap_or_else(|_| "localhost".to_string()),
                        terminal: std::env::var("TERM").unwrap_or_else(|_| "xterm".to_string()),
                        environment: HashMap::new(),
                    },
                }
            })
            .collect())
    }
    
    async fn delete_by_id(&self, id: &Uuid) -> Result<()> {
        sqlx::query(r#"DELETE FROM commands WHERE id = ?1"#)
            .bind(id.to_string())
            .execute(&self.pool)
            .await?;
        
        Ok(())
    }
    
    async fn search(&self, query: &str, limit: usize, directory: Option<&str>, since: Option<DateTime<Utc>>) -> Result<Vec<Command>> {
        // Build the complete SQL string first
        let mut sql = r#"
            SELECT id, timestamp, command, directory, exit_code,
                   duration_ms, session_id, semantic_type
            FROM commands 
            WHERE command LIKE ?
        "#.to_string();
        
        if directory.is_some() {
            sql.push_str(" AND directory = ?");
        }
        
        if since.is_some() {
            sql.push_str(" AND timestamp >= ?");
        }
        
        sql.push_str(" ORDER BY timestamp DESC LIMIT ?");
        
        // Now build the query with all parameters
        let search_term = format!("%{}%", query);
        let mut query_builder = sqlx::query(&sql);
        query_builder = query_builder.bind(&search_term);
        
        // Add optional parameters in the same order as SQL
        if let Some(dir) = directory {
            query_builder = query_builder.bind(dir);
        }
        
        if let Some(since_time) = since {
            query_builder = query_builder.bind(since_time.timestamp());
        }
        
        query_builder = query_builder.bind(limit as i64);
        
        let results = query_builder.fetch_all(&self.pool).await?;
        
        Ok(results
            .into_iter()
            .map(|row| {
                let raw_command: String = row.get("command");
                Command {
                    id: Uuid::parse_str(row.get("id")).expect("Invalid UUID in database"),
                    raw: raw_command.clone(),
                    parsed_command: Self::parse_command_name(&raw_command),
                    arguments: Self::parse_arguments(&raw_command),
                    working_directory: row.get("directory"),
                    exit_code: row.get("exit_code"),
                    duration_ms: row.get::<i64, _>("duration_ms") as u64,
                    timestamp: DateTime::from_timestamp(row.get("timestamp"), 0)
                        .unwrap_or_else(|| Utc::now()),
                    session_id: row.get("session_id"),
                    metadata: CommandMetadata {
                        shell: std::env::var("SHELL")
                            .unwrap_or_else(|_| "bash".to_string())
                            .split('/')
                            .last()
                            .unwrap_or("bash")
                            .to_string(),
                        user: std::env::var("USER").unwrap_or_else(|_| "unknown".to_string()),
                        hostname: hostname::get()
                            .map(|h| h.to_string_lossy().to_string())
                            .unwrap_or_else(|_| "localhost".to_string()),
                        terminal: std::env::var("TERM").unwrap_or_else(|_| "xterm".to_string()),
                        environment: HashMap::new(),
                    },
                }
            })
            .collect())
    }
    
    async fn search_semantic(&self, query: &str, limit: usize) -> Result<Vec<Command>> {
        // TODO: Implement proper semantic search with sqlite-vec
        // For now, we'll use a more sophisticated text search that looks for
        // similar commands based on keywords
        
        // Extract keywords from query
        let keywords: Vec<&str> = query.split_whitespace().collect();
        
        // Create patterns vector to own the strings
        let patterns: Vec<String> = keywords.iter()
            .map(|keyword| format!("%{}%", keyword))
            .collect();
        
        // Use a fixed query structure with a maximum number of supported keywords
        // This avoids dynamic SQL construction while maintaining functionality
        const MAX_KEYWORDS: usize = 10;
        
        if keywords.len() > MAX_KEYWORDS {
            return Err(anyhow::anyhow!(
                "Too many keywords in search query. Maximum {} keywords supported", 
                MAX_KEYWORDS
            ));
        }
        
        // Use a pre-built query with placeholders for up to MAX_KEYWORDS
        // This is safe because the SQL structure is fixed at compile time
        let sql = r#"
            WITH keyword_matches AS (
                SELECT id, timestamp, command, directory, exit_code,
                       duration_ms, session_id, semantic_type,
                       (CASE WHEN command LIKE ?1 THEN 1 ELSE 0 END +
                        CASE WHEN command LIKE ?2 THEN 1 ELSE 0 END +
                        CASE WHEN command LIKE ?3 THEN 1 ELSE 0 END +
                        CASE WHEN command LIKE ?4 THEN 1 ELSE 0 END +
                        CASE WHEN command LIKE ?5 THEN 1 ELSE 0 END +
                        CASE WHEN command LIKE ?6 THEN 1 ELSE 0 END +
                        CASE WHEN command LIKE ?7 THEN 1 ELSE 0 END +
                        CASE WHEN command LIKE ?8 THEN 1 ELSE 0 END +
                        CASE WHEN command LIKE ?9 THEN 1 ELSE 0 END +
                        CASE WHEN command LIKE ?10 THEN 1 ELSE 0 END) as match_count
                FROM commands
                WHERE command LIKE ?1 OR command LIKE ?2 OR command LIKE ?3 OR 
                      command LIKE ?4 OR command LIKE ?5 OR command LIKE ?6 OR
                      command LIKE ?7 OR command LIKE ?8 OR command LIKE ?9 OR 
                      command LIKE ?10
            )
            SELECT * FROM keyword_matches
            WHERE match_count > 0
            ORDER BY match_count DESC, timestamp DESC
            LIMIT ?11
        "#;
        
        let mut query_builder = sqlx::query(sql);
        
        // Bind actual patterns for positions we're using
        for i in 0..MAX_KEYWORDS {
            if i < patterns.len() {
                query_builder = query_builder.bind(&patterns[i]);
            } else {
                // Bind an impossible pattern for unused positions
                query_builder = query_builder.bind("__IMPOSSIBLE_PATTERN__");
            }
        }
        
        query_builder = query_builder.bind(limit as i64);
        
        let results = query_builder.fetch_all(&self.pool).await?;
        
        Ok(results
            .into_iter()
            .map(|row| {
                let raw_command: String = row.get("command");
                Command {
                    id: Uuid::parse_str(row.get("id")).expect("Invalid UUID in database"),
                    raw: raw_command.clone(),
                    parsed_command: Self::parse_command_name(&raw_command),
                    arguments: Self::parse_arguments(&raw_command),
                    working_directory: row.get("directory"),
                    exit_code: row.get("exit_code"),
                    duration_ms: row.get::<i64, _>("duration_ms") as u64,
                    timestamp: DateTime::from_timestamp(row.get("timestamp"), 0)
                        .unwrap_or_else(|| Utc::now()),
                    session_id: row.get("session_id"),
                    metadata: CommandMetadata {
                        shell: std::env::var("SHELL")
                            .unwrap_or_else(|_| "bash".to_string())
                            .split('/')
                            .last()
                            .unwrap_or("bash")
                            .to_string(),
                        user: std::env::var("USER").unwrap_or_else(|_| "unknown".to_string()),
                        hostname: hostname::get()
                            .map(|h| h.to_string_lossy().to_string())
                            .unwrap_or_else(|_| "localhost".to_string()),
                        terminal: std::env::var("TERM").unwrap_or_else(|_| "xterm".to_string()),
                        environment: HashMap::new(),
                    },
                }
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

    #[tokio::test]
    async fn test_search_commands() -> Result<()> {
        let pool = setup_test_db().await?;
        let repo = SqliteCommandRepository::new(pool);
        
        // Insert test commands
        for i in 0..5 {
            let command = Command {
                id: Uuid::new_v4(),
                raw: format!("git commit -m 'test{}'", i),
                parsed_command: "git".to_string(),
                arguments: vec!["commit".to_string(), "-m".to_string(), format!("test{}", i)],
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
        }
        
        let results = repo.search("git", 10, None, None).await?;
        assert_eq!(results.len(), 5);
        
        let results = repo.search("commit", 10, None, None).await?;
        assert_eq!(results.len(), 5);
        
        Ok(())
    }
    
    #[tokio::test]
    async fn test_search_semantic_sql_injection_protection() -> Result<()> {
        let pool = setup_test_db().await?;
        let repo = SqliteCommandRepository::new(pool);
        
        // Insert test data
        let cmd = Command {
            id: Uuid::new_v4(),
            raw: "ls -la".to_string(),
            parsed_command: "ls".to_string(),
            arguments: vec!["-la".to_string()],
            working_directory: "/home/user".to_string(),
            exit_code: 0,
            duration_ms: 100,
            timestamp: Utc::now(),
            session_id: "test-session".to_string(),
            metadata: CommandMetadata {
                shell: "bash".to_string(),
                user: "testuser".to_string(),
                hostname: "localhost".to_string(),
                terminal: "xterm".to_string(),
                environment: std::collections::HashMap::new(),
            },
        };
        
        repo.save(&cmd).await?;
        
        // Test 1: SQL injection attempt with quotes
        let malicious_query = "'; DROP TABLE commands; --";
        let result = repo.search_semantic(malicious_query, 10).await;
        assert!(result.is_ok(), "Should handle SQL injection attempt safely");
        
        // Test 2: SQL injection with UNION
        let union_query = "test' UNION SELECT * FROM commands WHERE '1'='1";
        let result = repo.search_semantic(union_query, 10).await;
        assert!(result.is_ok(), "Should handle UNION injection attempt safely");
        
        // Test 3: Too many keywords
        let many_keywords = vec!["keyword"; 15].join(" ");
        let result = repo.search_semantic(&many_keywords, 10).await;
        assert!(result.is_err(), "Should reject queries with too many keywords");
        assert!(result.unwrap_err().to_string().contains("Too many keywords"));
        
        Ok(())
    }
    
    #[tokio::test]
    async fn test_search_with_special_characters() -> Result<()> {
        let pool = setup_test_db().await?;
        let repo = SqliteCommandRepository::new(pool);
        
        // Insert commands with special characters
        let commands = vec![
            "echo 'hello world'",
            "grep \"pattern\" file.txt",
            "find . -name '*.rs'",
            "sed 's/old/new/g'",
            "awk '{print $1}'",
        ];
        
        for (i, cmd_str) in commands.iter().enumerate() {
            let cmd = Command {
                id: Uuid::new_v4(),
                raw: cmd_str.to_string(),
                parsed_command: cmd_str.split_whitespace().next().unwrap().to_string(),
                arguments: vec![],
                working_directory: "/home/user".to_string(),
                exit_code: 0,
                duration_ms: 100,
                timestamp: Utc::now(),
                session_id: format!("session-{}", i),
                metadata: CommandMetadata {
                    shell: "bash".to_string(),
                    user: "testuser".to_string(),
                    hostname: "localhost".to_string(),
                    terminal: "xterm".to_string(),
                    environment: std::collections::HashMap::new(),
                },
            };
            
            repo.save(&cmd).await?;
        }
        
        // Test searching for commands with special characters
        let results = repo.search("'hello", 10, None, None).await?;
        assert_eq!(results.len(), 1);
        assert!(results[0].raw.contains("hello world"));
        
        let results = repo.search("*.rs", 10, None, None).await?;
        assert_eq!(results.len(), 1);
        assert!(results[0].raw.contains("*.rs"));
        
        Ok(())
    }
}