//! Tests for SQLite command repository

#[cfg(test)]
mod tests {
    use super::super::*;
    use sqlx::SqlitePool;
    use termbrain_core::domain::{Command, CommandMetadata};
    use uuid::Uuid;
    use chrono::Utc;
    
    async fn setup_test_db() -> SqlitePool {
        let pool = SqlitePool::connect("sqlite::memory:").await.unwrap();
        
        // Create tables
        sqlx::query(r#"
            CREATE TABLE IF NOT EXISTS commands (
                id TEXT PRIMARY KEY,
                timestamp INTEGER NOT NULL,
                command TEXT NOT NULL,
                directory TEXT NOT NULL,
                exit_code INTEGER NOT NULL,
                duration_ms INTEGER,
                session_id TEXT,
                semantic_type TEXT
            );
            
            CREATE INDEX IF NOT EXISTS idx_commands_timestamp ON commands(timestamp);
            CREATE INDEX IF NOT EXISTS idx_commands_directory ON commands(directory);
        "#)
        .execute(&pool)
        .await
        .unwrap();
        
        pool
    }
    
    #[tokio::test]
    async fn test_search_semantic_sql_injection_protection() {
        let pool = setup_test_db().await;
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
        
        repo.save(&cmd).await.unwrap();
        
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
    }
    
    #[tokio::test]
    async fn test_search_with_special_characters() {
        let pool = setup_test_db().await;
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
            
            repo.save(&cmd).await.unwrap();
        }
        
        // Test searching for commands with special characters
        let results = repo.search("'hello", 10, None, None).await.unwrap();
        assert_eq!(results.len(), 1);
        assert!(results[0].raw.contains("hello world"));
        
        let results = repo.search("*.rs", 10, None, None).await.unwrap();
        assert_eq!(results.len(), 1);
        assert!(results[0].raw.contains("*.rs"));
    }
    
    #[tokio::test]
    async fn test_semantic_search_performance() {
        let pool = setup_test_db().await;
        let repo = SqliteCommandRepository::new(pool);
        
        // Insert many commands
        for i in 0..1000 {
            let cmd = Command {
                id: Uuid::new_v4(),
                raw: format!("command {} with some text", i),
                parsed_command: "command".to_string(),
                arguments: vec![],
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
            
            repo.save(&cmd).await.unwrap();
        }
        
        // Test search with multiple keywords
        let start = std::time::Instant::now();
        let results = repo.search_semantic("command text some", 50).await.unwrap();
        let duration = start.elapsed();
        
        assert!(!results.is_empty());
        assert!(duration.as_millis() < 1000, "Search should complete within 1 second");
    }
}