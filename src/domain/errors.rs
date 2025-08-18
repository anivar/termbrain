use thiserror::Error;

#[derive(Debug, Error)]
pub enum TermbrainError {
    #[error("Repository error: {0}")]
    Repository(String),
    
    #[error("Invalid command: {0}")]
    InvalidCommand(String),
    
    #[error("Workflow not found: {0}")]
    WorkflowNotFound(String),
    
    #[error("Workflow already exists: {0}")]
    WorkflowExists(String),
    
    #[error("Configuration error: {0}")]
    Configuration(String),
    
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
    
    #[error("Database error: {0}")]
    Database(String),
    
    #[error("Serialization error: {0}")]
    Serialization(#[from] serde_json::Error),
    
    #[error("Invalid state: {0}")]
    InvalidState(String),
}

pub type Result<T> = std::result::Result<T, TermbrainError>;