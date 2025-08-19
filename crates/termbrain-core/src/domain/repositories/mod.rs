//! Repository trait definitions

use anyhow::Result;
use super::entities::Command;

/// Repository for command storage
pub trait CommandRepository: Send + Sync {
    /// Save a command
    async fn save(&self, command: &Command) -> Result<()>;
    
    /// Find command by ID
    async fn find_by_id(&self, id: &uuid::Uuid) -> Result<Option<Command>>;
}