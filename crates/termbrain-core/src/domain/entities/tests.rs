#[cfg(test)]
mod tests {
    use super::super::*;
    use chrono::Utc;
    
    #[test]
    fn test_command_creation() {
        let cmd = Command {
            id: uuid::Uuid::new_v4(),
            raw: "git commit -m 'test'".to_string(),
            parsed_command: "git".to_string(),
            arguments: vec!["commit".to_string(), "-m".to_string(), "test".to_string()],
            working_directory: "/home/user/project".to_string(),
            exit_code: 0,
            duration_ms: 150,
            timestamp: Utc::now(),
            session_id: "session-123".to_string(),
            metadata: CommandMetadata {
                shell: "bash".to_string(),
                user: "testuser".to_string(),
                hostname: "localhost".to_string(),
                terminal: "xterm-256color".to_string(),
                environment: std::collections::HashMap::new(),
            },
        };
        
        assert_eq!(cmd.parsed_command, "git");
        assert_eq!(cmd.exit_code, 0);
    }
    
    #[test]
    fn test_pattern_types() {
        let seq_pattern = PatternType::CommandSequence(vec![
            "cd project".to_string(),
            "git pull".to_string(),
            "cargo test".to_string(),
        ]);
        
        matches!(seq_pattern, PatternType::CommandSequence(_));
    }
}