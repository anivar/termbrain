//! Domain value objects

use serde::{Deserialize, Serialize};
use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct ShellType(String);

impl ShellType {
    pub fn new(shell: impl Into<String>) -> Self {
        Self(shell.into())
    }

    pub fn bash() -> Self {
        Self("bash".to_string())
    }

    pub fn zsh() -> Self {
        Self("zsh".to_string())
    }

    pub fn fish() -> Self {
        Self("fish".to_string())
    }
}

impl fmt::Display for ShellType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.0)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CommandContext {
    pub project_root: Option<String>,
    pub git_branch: Option<String>,
    pub virtual_env: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct TimeRange {
    pub start: chrono::DateTime<chrono::Utc>,
    pub end: chrono::DateTime<chrono::Utc>,
}

impl TimeRange {
    pub fn duration(&self) -> chrono::Duration {
        self.end - self.start
    }
}
