//! Domain entities

// Placeholder entities for repository traits
#[derive(Debug, Clone)]
pub struct Command {
    pub id: uuid::Uuid,
    pub command: String,
}

#[derive(Debug, Clone)]
pub struct Session {
    pub id: String,
}

#[derive(Debug, Clone)]
pub struct Pattern {
    pub id: uuid::Uuid,
}

#[derive(Debug, Clone)]
pub struct Workflow {
    pub id: uuid::Uuid,
}