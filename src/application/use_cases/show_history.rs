use crate::domain::repositories::CommandRepository;
use crate::application::dto::SearchResult;
use anyhow::Result;

pub struct ShowHistory<'a> {
    command_repository: &'a dyn CommandRepository,
}

impl<'a> ShowHistory<'a> {
    pub fn new(command_repository: &'a dyn CommandRepository) -> Self {
        Self { command_repository }
    }
    
    pub async fn execute(&self, semantic_type: Option<&str>, limit: usize) -> Result<Vec<SearchResult>> {
        let commands = if let Some(sem_type) = semantic_type {
            self.command_repository.get_by_semantic_type(sem_type, limit).await?
        } else {
            self.command_repository.get_recent(limit).await?
        };
        
        Ok(commands.into_iter()
            .map(SearchResult::from_command)
            .collect())
    }
}