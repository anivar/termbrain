//! Storage implementations for TermBrain

pub mod sqlite;
pub mod embeddings;

pub use sqlite::SqliteStorage;
pub use embeddings::EmbeddingGenerator;
