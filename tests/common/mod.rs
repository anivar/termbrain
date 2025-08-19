use termbrain::domain::entities::{Command, Workflow, Pattern, Intention};
use termbrain::domain::value_objects::SemanticType;
use uuid::Uuid;
use chrono::{Utc, Duration};

pub struct TestDataBuilder;

impl TestDataBuilder {
    pub fn create_command(text: &str) -> Command {
        Command::new(text.to_string(), "/test".to_string())
    }
    
    pub fn create_command_with_exit_code(text: &str, exit_code: i32) -> Command {
        let mut cmd = Self::create_command(text);
        cmd.exit_code = exit_code;
        cmd
    }
    
    pub fn create_commands_sequence(base: &str, count: usize) -> Vec<Command> {
        (0..count)
            .map(|i| {
                let mut cmd = Command::new(format!("{} {}", base, i), "/test".to_string());
                cmd.timestamp = Utc::now() - Duration::minutes(count as i64 - i as i64);
                cmd
            })
            .collect()
    }
    
    pub fn create_workflow(name: &str, commands: Vec<&str>) -> Workflow {
        Workflow {
            id: Uuid::new_v4(),
            name: name.to_string(),
            description: format!("{} workflow", name),
            commands: commands.into_iter().map(|s| s.to_string()).collect(),
            created_at: Utc::now(),
            updated_at: Utc::now(),
            execution_count: 0,
        }
    }
    
    pub fn create_pattern(pattern: &str, frequency: u32) -> Pattern {
        Pattern {
            id: Uuid::new_v4(),
            pattern: pattern.to_string(),
            frequency,
            contexts: vec!["/test".to_string()],
            suggested_workflow: Some(format!("{} workflow", pattern)),
        }
    }
    
    pub fn create_intention(text: &str, session_id: &str) -> Intention {
        Intention {
            id: Uuid::new_v4(),
            session_id: session_id.to_string(),
            intention: text.to_string(),
            created_at: Utc::now(),
            achieved: false,
            commands_count: 0,
        }
    }
    
    pub fn create_git_workflow_commands() -> Vec<Command> {
        vec![
            Self::create_command("git status"),
            Self::create_command("git add ."),
            Self::create_command("git commit -m 'test'"),
            Self::create_command("git push origin main"),
        ]
    }
    
    pub fn create_mixed_success_commands() -> Vec<Command> {
        vec![
            Self::create_command_with_exit_code("npm test", 0),
            Self::create_command_with_exit_code("npm build", 0),
            Self::create_command_with_exit_code("npm deploy", 1), // Failed
            Self::create_command_with_exit_code("ls -la", 0),
            Self::create_command_with_exit_code("git push", 128), // Failed
        ]
    }
}

/// Create a temporary test environment with isolated settings
pub fn setup_test_env() -> tempfile::TempDir {
    let temp_dir = tempfile::TempDir::new().unwrap();
    std::env::set_var("TERMBRAIN_HOME", temp_dir.path());
    std::env::remove_var("TERMBRAIN_DISABLED");
    std::env::remove_var("TERMBRAIN_INTENTION");
    std::env::remove_var("TERMBRAIN_IN_FLOW");
    temp_dir
}

/// Clean up test environment
pub fn cleanup_test_env() {
    std::env::remove_var("TERMBRAIN_HOME");
    std::env::remove_var("TERMBRAIN_DISABLED");
    std::env::remove_var("TERMBRAIN_INTENTION");
    std::env::remove_var("TERMBRAIN_IN_FLOW");
}