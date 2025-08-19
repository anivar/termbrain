//! Domain entities

// Placeholder for Command entity
#[derive(Debug, Clone)]
pub struct Command {
    pub id: uuid::Uuid,
    pub command: String,
}