use crate::domain::repositories::CommandRepository;
use crate::application::dto::SearchResult;
use anyhow::Result;

pub struct SearchCommands<'a> {
    command_repository: &'a dyn CommandRepository,
}

impl<'a> SearchCommands<'a> {
    pub fn new(command_repository: &'a dyn CommandRepository) -> Self {
        Self { command_repository }
    }
    
    pub async fn execute(&self, query: &str, limit: usize) -> Result<Vec<SearchResult>> {
        let commands = self.command_repository.search(query, limit).await?;
        
        Ok(commands.into_iter()
            .map(SearchResult::from_command)
            .collect())
    }
}