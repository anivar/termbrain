use crate::domain::entities::Command;
use crate::domain::entities::Workflow;
use crate::domain::value_objects::SemanticType;
use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SearchResult {
    pub command: String,
    pub timestamp: DateTime<Utc>,
    pub directory: String,
    pub exit_code: i32,
    pub semantic_type: SemanticType,
}

impl SearchResult {
    pub fn from_command(cmd: Command) -> Self {
        Self {
            command: cmd.command,
            timestamp: cmd.timestamp,
            directory: cmd.directory,
            exit_code: cmd.exit_code,
            semantic_type: cmd.semantic_type,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StatsResult {
    pub total_commands: usize,
    pub success_rate: f64,
    pub commands_by_type: HashMap<SemanticType, usize>,
    pub average_duration_ms: f64,
    pub time_range: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkflowDto {
    pub name: String,
    pub description: String,
    pub commands: Vec<String>,
    pub execution_count: u32,
    pub created_at: DateTime<Utc>,
}

impl From<Workflow> for WorkflowDto {
    fn from(workflow: Workflow) -> Self {
        Self {
            name: workflow.name,
            description: workflow.description,
            commands: workflow.commands,
            execution_count: workflow.execution_count,
            created_at: workflow.created_at,
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProjectAnalysis {
    pub project_type: ProjectType,
    pub primary_language: String,
    pub common_commands: Vec<(String, usize)>,
    pub workflow_suggestions: Vec<WorkflowSuggestion>,
    pub productivity_score: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ProjectType {
    JavaScript,
    Rust,
    Python,
    Go,
    Java,
    Generic,
    Unknown,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorkflowSuggestion {
    pub name: String,
    pub description: String,
    pub commands: Vec<String>,
    pub frequency: usize,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FlowState {
    pub in_flow: bool,
    pub duration_minutes: Option<u64>,
    pub productivity_score: Option<f64>,
    pub focus_area: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AIContext {
    pub project_info: ProjectAnalysis,
    pub recent_commands: Vec<SearchResult>,
    pub current_intention: Option<String>,
    pub workflow_patterns: Vec<WorkflowSuggestion>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GrowthAnalytics {
    pub skill_progression: HashMap<String, f64>,
    pub learning_velocity: f64,
    pub mastery_levels: HashMap<String, crate::application::use_cases::analyze_growth::MasteryLevel>,
    pub error_reduction_rate: f64,
    pub productivity_trends: Vec<(String, usize)>,
    pub new_commands_learned: usize,
    pub complex_command_ratio: f64,
    pub growth_score: f64,
}