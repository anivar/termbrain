use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Command {
    pub id: Uuid,
    pub timestamp: DateTime<Utc>,
    pub command: String,
    pub directory: String,
    pub exit_code: i32,
    pub duration_ms: u64,
    pub session_id: String,
    pub semantic_type: SemanticType,
    pub git_branch: Option<String>,
    pub project_type: Option<ProjectType>,
    pub is_sensitive: bool,
    pub intent: Option<String>,
    pub complexity: u8,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Workflow {
    pub id: Uuid,
    pub name: String,
    pub description: String,
    pub commands: Vec<WorkflowCommand>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub execution_count: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkflowCommand {
    pub position: u32,
    pub command: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Intention {
    pub id: Uuid,
    pub session_id: String,
    pub intention: String,
    pub created_at: DateTime<Utc>,
    pub achieved: bool,
    pub commands_count: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Pattern {
    pub id: Uuid,
    pub pattern: String,
    pub frequency: u32,
    pub contexts: Vec<String>,
    pub suggested_workflow: Option<String>,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum SemanticType {
    VersionControl,
    PackageManagement,
    Testing,
    Building,
    Container,
    FileOperation,
    Navigation,
    ProcessManagement,
    Network,
    SystemAdmin,
    Database,
    Monitoring,
    Searching,
    General,
}

#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq)]
#[serde(rename_all = "snake_case")]
pub enum ProjectType {
    Rust,
    JavaScript,
    Python,
    Go,
    Ruby,
    Java,
    CSharp,
    Cpp,
    Shell,
    Unknown,
}

impl Command {
    pub fn new(command: String, directory: String) -> Self {
        Self {
            id: Uuid::new_v4(),
            timestamp: Utc::now(),
            command: command.clone(),
            directory,
            exit_code: 0,
            duration_ms: 0,
            session_id: std::process::id().to_string(),
            semantic_type: SemanticType::from_command(&command),
            git_branch: None,
            project_type: None,
            is_sensitive: Self::is_sensitive_command(&command),
            intent: None,
            complexity: Self::calculate_complexity(&command),
        }
    }
    
    fn is_sensitive_command(cmd: &str) -> bool {
        let sensitive_patterns = [
            "password", "passwd", "pwd", "secret", "key", "token",
            "api_key", "access_key", "Authorization:", "Bearer ",
        ];
        
        sensitive_patterns.iter().any(|pattern| {
            cmd.to_lowercase().contains(&pattern.to_lowercase())
        })
    }
    
    fn calculate_complexity(cmd: &str) -> u8 {
        let pipe_count = cmd.matches('|').count() as u8;
        let redirect_count = cmd.matches(&['<', '>'][..]).count() as u8;
        let has_subshell = cmd.contains('$') || cmd.contains('(');
        
        let mut complexity = 1 + pipe_count;
        if redirect_count > 0 {
            complexity += 1;
        }
        if has_subshell {
            complexity += 1;
        }
        
        complexity.min(5)
    }
}

impl SemanticType {
    fn from_command(cmd: &str) -> Self {
        let cmd_lower = cmd.to_lowercase();
        
        if cmd_lower.starts_with("git") || cmd_lower.starts_with("svn") {
            SemanticType::VersionControl
        } else if cmd_lower.starts_with("npm") || cmd_lower.starts_with("cargo") 
                || cmd_lower.starts_with("pip") || cmd_lower.starts_with("brew") {
            SemanticType::PackageManagement
        } else if cmd_lower.contains("test") || cmd_lower.contains("spec") {
            SemanticType::Testing
        } else if cmd_lower.starts_with("docker") || cmd_lower.starts_with("kubectl") {
            SemanticType::Container
        } else if cmd_lower.starts_with("ls") || cmd_lower.starts_with("cd") {
            SemanticType::Navigation
        } else if cmd_lower.starts_with("cp") || cmd_lower.starts_with("mv") 
                || cmd_lower.starts_with("rm") {
            SemanticType::FileOperation
        } else {
            SemanticType::General
        }
    }
}