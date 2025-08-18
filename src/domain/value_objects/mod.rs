use serde::{Deserialize, Serialize};

// Re-export types from entities that are used as value objects
pub use crate::domain::entities::{SemanticType, CommandType};

// Simple session ID generation
pub fn generate_session_id() -> String {
    format!("{}_{}", std::process::id(), chrono::Utc::now().timestamp())
}

// Validation functions
pub fn is_sensitive_command(cmd: &str) -> bool {
    let lower = cmd.to_lowercase();
    SENSITIVE_PATTERNS.iter().any(|pattern| lower.contains(pattern))
}

const SENSITIVE_PATTERNS: &[&str] = &[
    "password", "passwd", "pwd", "secret", "key", "token",
    "api_key", "access_key", "authorization:", "bearer ",
    "private", "credential",
];