//! Domain entities

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Command {
    pub id: uuid::Uuid,
    pub raw: String,
    pub parsed_command: String,
    pub arguments: Vec<String>,
    pub working_directory: String,
    pub exit_code: i32,
    pub duration_ms: u64,
    pub timestamp: DateTime<Utc>,
    pub session_id: String,
    pub metadata: CommandMetadata,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Default)]
pub struct CommandMetadata {
    pub shell: String,
    pub user: String,
    pub hostname: String,
    pub terminal: String,
    pub environment: HashMap<String, String>,
    pub ai_agent: Option<String>,
    pub ai_session_id: Option<String>,
    pub ai_context: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Session {
    pub id: String,
    pub start_time: DateTime<Utc>,
    pub end_time: Option<DateTime<Utc>>,
    pub shell: String,
    pub terminal: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Pattern {
    pub id: uuid::Uuid,
    pub name: String,
    pub description: String,
    pub pattern_type: PatternType,
    pub frequency: u32,
    pub last_seen: DateTime<Utc>,
    pub confidence: f32,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum PatternType {
    CommandSequence(Vec<String>),
    TimeBasedUsage(String),
    DirectorySpecific(String, String),
    ErrorRecovery(String, String),
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct Workflow {
    pub id: uuid::Uuid,
    pub name: String,
    pub description: String,
    pub steps: Vec<WorkflowStep>,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub usage_count: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct WorkflowStep {
    pub order: u32,
    pub command: String,
    pub description: Option<String>,
    pub expected_outcome: Option<String>,
}

/// Summary information for an AI session with aggregate statistics
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct AiSessionSummary {
    pub session_id: String,
    pub ai_agent: String,
    pub ai_context: Option<String>,
    pub start_time: DateTime<Utc>,
    pub command_count: usize,
    pub duration_minutes: u64,
    pub success_rate: f32,
}

/// AI session analysis with patterns and insights
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AiSessionAnalysis {
    pub summary: AiSessionSummary,
    pub commands: Vec<Command>,
    pub patterns: Vec<String>,
    pub insights: Vec<String>,
    pub suggestions: Vec<String>,
}

#[cfg(test)]
mod tests;
