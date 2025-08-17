use async_trait::async_trait;
use anyhow::Result;
use super::entities::{Command, Workflow, Pattern, Intention};

#[async_trait]
pub trait CommandRepository: Send + Sync {
    async fn save(&self, command: &Command) -> Result<()>;
    async fn find_by_id(&self, id: &str) -> Result<Option<Command>>;
    async fn search(&self, query: &str, limit: usize) -> Result<Vec<Command>>;
    async fn get_recent(&self, limit: usize) -> Result<Vec<Command>>;
    async fn get_by_semantic_type(&self, semantic_type: &str, limit: usize) -> Result<Vec<Command>>;
    async fn get_statistics(&self, range: &str) -> Result<CommandStats>;
    async fn update(&self, command: &Command) -> Result<()>;
    async fn delete(&self, id: &str) -> Result<()>;
}

#[async_trait]
pub trait WorkflowRepository: Send + Sync {
    async fn save(&self, workflow: &Workflow) -> Result<()>;
    async fn find_by_name(&self, name: &str) -> Result<Option<Workflow>>;
    async fn list(&self) -> Result<Vec<Workflow>>;
    async fn update(&self, workflow: &Workflow) -> Result<()>;
    async fn delete(&self, name: &str) -> Result<()>;
}

#[async_trait]
pub trait PatternRepository: Send + Sync {
    async fn save(&self, pattern: &Pattern) -> Result<()>;
    async fn find_patterns(&self, min_frequency: u32) -> Result<Vec<Pattern>>;
    async fn update_frequency(&self, pattern_id: &str) -> Result<()>;
}

#[async_trait]
pub trait IntentionRepository: Send + Sync {
    async fn save(&self, intention: &Intention) -> Result<()>;
    async fn get_current(&self, session_id: &str) -> Result<Option<Intention>>;
    async fn mark_achieved(&self, id: &str) -> Result<()>;
}

#[derive(Debug, Clone)]
pub struct CommandStats {
    pub total_commands: u64,
    pub successful_commands: u64,
    pub failed_commands: u64,
    pub unique_commands: u64,
    pub by_type: Vec<(String, u64)>,
    pub by_hour: Vec<(u8, u64)>,
    pub by_directory: Vec<(String, u64)>,
    pub average_duration_ms: f64,
}