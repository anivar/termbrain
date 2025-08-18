use crate::domain::repositories::WorkflowRepository;
use crate::domain::entities::Workflow;
use anyhow::Result;
use uuid::Uuid;
use chrono::Utc;

pub struct CreateWorkflow<'a> {
    workflow_repository: &'a dyn WorkflowRepository,
}

impl<'a> CreateWorkflow<'a> {
    pub fn new(workflow_repository: &'a dyn WorkflowRepository) -> Self {
        Self { workflow_repository }
    }
    
    pub async fn execute(
        &self,
        name: &str,
        description: &str,
        commands: Vec<String>,
    ) -> Result<()> {
        // Check if workflow already exists
        if self.workflow_repository.get_by_name(name).await?.is_some() {
            anyhow::bail!("Workflow '{}' already exists", name);
        }
        
        // Create workflow entity
        let workflow = Workflow {
            id: Uuid::new_v4(),
            name: name.to_string(),
            description: description.to_string(),
            commands,
            created_at: Utc::now(),
            updated_at: Utc::now(),
            execution_count: 0,
        };
        
        // Save to repository
        self.workflow_repository.save(&workflow).await?;
        
        Ok(())
    }
}