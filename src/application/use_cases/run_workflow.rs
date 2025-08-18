use crate::domain::repositories::WorkflowRepository;
use anyhow::Result;
use std::process::Command;

pub struct RunWorkflow<'a> {
    workflow_repository: &'a dyn WorkflowRepository,
}

impl<'a> RunWorkflow<'a> {
    pub fn new(workflow_repository: &'a dyn WorkflowRepository) -> Self {
        Self { workflow_repository }
    }
    
    pub async fn execute(&self, name: &str) -> Result<()> {
        // Get workflow
        let mut workflow = self.workflow_repository
            .get_by_name(name)
            .await?
            .ok_or_else(|| anyhow::anyhow!("Workflow '{}' not found", name))?;
        
        println!("🚀 Running workflow: {}", workflow.name);
        println!("📝 {}", workflow.description);
        println!();
        
        // Execute each command
        for (idx, cmd) in workflow.commands.iter().enumerate() {
            println!("  [{}/{}] {}", idx + 1, workflow.commands.len(), cmd);
            
            // Execute command
            let output = Command::new("sh")
                .arg("-c")
                .arg(cmd)
                .output()?;
            
            if output.status.success() {
                println!("  ✓ Success");
            } else {
                let stderr = String::from_utf8_lossy(&output.stderr);
                println!("  ✗ Failed: {}", stderr);
                anyhow::bail!("Workflow failed at step {}", idx + 1);
            }
        }
        
        // Update execution count
        workflow.execution_count += 1;
        workflow.updated_at = chrono::Utc::now();
        self.workflow_repository.save(&workflow).await?;
        
        println!();
        println!("✓ Workflow completed successfully");
        
        Ok(())
    }
}