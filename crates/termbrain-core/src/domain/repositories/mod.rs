//! Repository trait definitions

use super::entities::{Command, Pattern, Session, Workflow};
use anyhow::Result;
use async_trait::async_trait;
use chrono::{DateTime, Utc};

#[async_trait]
pub trait CommandRepository: Send + Sync {
    async fn save(&self, command: &Command) -> Result<()>;
    async fn find_by_id(&self, id: &uuid::Uuid) -> Result<Option<Command>>;
    async fn find_by_session(&self, session_id: &str) -> Result<Vec<Command>>;
    async fn find_recent(&self, limit: usize) -> Result<Vec<Command>>;
    async fn find_by_pattern(&self, pattern: &str) -> Result<Vec<Command>>;
    async fn find_by_directory(&self, directory: &str) -> Result<Vec<Command>>;
    async fn find_by_time_range(
        &self,
        start: DateTime<Utc>,
        end: DateTime<Utc>,
    ) -> Result<Vec<Command>>;
    async fn search(
        &self,
        query: &str,
        limit: usize,
        directory: Option<&str>,
        since: Option<DateTime<Utc>>,
    ) -> Result<Vec<Command>>;
    async fn search_semantic(&self, query: &str, limit: usize) -> Result<Vec<Command>>;
    async fn delete_by_id(&self, id: &uuid::Uuid) -> Result<()>;
    async fn count(&self) -> Result<usize>;
}

#[async_trait]
pub trait SessionRepository: Send + Sync {
    async fn create(&self, session: &Session) -> Result<()>;
    async fn update(&self, session: &Session) -> Result<()>;
    async fn find_by_id(&self, id: &str) -> Result<Option<Session>>;
    async fn find_active(&self) -> Result<Option<Session>>;
    async fn find_recent(&self, limit: usize) -> Result<Vec<Session>>;
    async fn close(&self, id: &str) -> Result<()>;
}

#[async_trait]
pub trait PatternRepository: Send + Sync {
    async fn save(&self, pattern: &Pattern) -> Result<()>;
    async fn find_by_id(&self, id: &uuid::Uuid) -> Result<Option<Pattern>>;
    async fn find_all(&self) -> Result<Vec<Pattern>>;
    async fn find_by_confidence(&self, min_confidence: f32) -> Result<Vec<Pattern>>;
    async fn update_frequency(&self, id: &uuid::Uuid, frequency: u32) -> Result<()>;
    async fn delete_by_id(&self, id: &uuid::Uuid) -> Result<()>;
}

#[async_trait]
pub trait WorkflowRepository: Send + Sync {
    async fn save(&self, workflow: &Workflow) -> Result<()>;
    async fn update(&self, workflow: &Workflow) -> Result<()>;
    async fn find_by_id(&self, id: &uuid::Uuid) -> Result<Option<Workflow>>;
    async fn find_by_name(&self, name: &str) -> Result<Option<Workflow>>;
    async fn find_all(&self) -> Result<Vec<Workflow>>;
    async fn increment_usage(&self, id: &uuid::Uuid) -> Result<()>;
    async fn delete_by_id(&self, id: &uuid::Uuid) -> Result<()>;
}

#[derive(Clone)]
pub struct SearchOptions {
    pub query: Option<String>,
    pub directory: Option<String>,
    pub start_time: Option<DateTime<Utc>>,
    pub end_time: Option<DateTime<Utc>>,
    pub exit_code: Option<i32>,
    pub limit: Option<usize>,
    pub offset: Option<usize>,
}

impl Default for SearchOptions {
    fn default() -> Self {
        Self {
            query: None,
            directory: None,
            start_time: None,
            end_time: None,
            exit_code: None,
            limit: Some(100),
            offset: None,
        }
    }
}

#[async_trait]
pub trait SearchRepository: Send + Sync {
    async fn search(&self, options: SearchOptions) -> Result<Vec<Command>>;
    async fn count_results(&self, options: SearchOptions) -> Result<usize>;
}
