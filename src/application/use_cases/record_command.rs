use crate::domain::repositories::CommandRepository;
use crate::domain::entities::Command;
use anyhow::Result;

pub struct RecordCommand<'a> {
    command_repository: &'a dyn CommandRepository,
}

impl<'a> RecordCommand<'a> {
    pub fn new(command_repository: &'a dyn CommandRepository) -> Self {
        Self { command_repository }
    }
    
    pub async fn execute(
        &self,
        command: &str,
        directory: &str,
        exit_code: i32,
        duration_ms: u64,
    ) -> Result<()> {
        // Skip recording if disabled
        if std::env::var("TERMBRAIN_DISABLED").is_ok() {
            return Ok(());
        }
        
        // Create command entity
        let mut command_entity = Command::new(command.to_string(), directory.to_string());
        command_entity.exit_code = exit_code;
        command_entity.duration_ms = duration_ms;
        
        // Get current git branch if in a git repo
        if let Ok(output) = std::process::Command::new("git")
            .arg("rev-parse")
            .arg("--abbrev-ref")
            .arg("HEAD")
            .current_dir(directory)
            .output()
        {
            if output.status.success() {
                let branch = String::from_utf8_lossy(&output.stdout).trim().to_string();
                command_entity.git_branch = Some(branch);
            }
        }
        
        // Get intention from environment if set
        command_entity.intent = std::env::var("TERMBRAIN_INTENTION").ok();
        
        // Save to repository
        self.command_repository.save(&command_entity).await?;
        
        Ok(())
    }
}