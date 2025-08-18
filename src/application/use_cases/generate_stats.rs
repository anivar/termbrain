use crate::domain::repositories::CommandRepository;
use crate::application::dto::StatsResult;
use anyhow::Result;
use chrono::{Utc, Duration};
use std::collections::HashMap;

pub struct GenerateStats<'a> {
    command_repository: &'a dyn CommandRepository,
}

impl<'a> GenerateStats<'a> {
    pub fn new(command_repository: &'a dyn CommandRepository) -> Self {
        Self { command_repository }
    }
    
    pub async fn execute(&self, range: &str) -> Result<StatsResult> {
        // Calculate time range
        let since = match range {
            "today" => Utc::now() - Duration::days(1),
            "week" => Utc::now() - Duration::weeks(1),
            "month" => Utc::now() - Duration::days(30),
            _ => chrono::DateTime::<Utc>::MIN_UTC,
        };
        
        // Get commands in range
        let commands = self.command_repository.get_since(since).await?;
        
        // Calculate statistics
        let total_commands = commands.len();
        let successful_commands = commands.iter().filter(|c| c.exit_code == 0).count();
        let success_rate = if total_commands > 0 {
            successful_commands as f64 / total_commands as f64
        } else {
            0.0
        };
        
        // Average duration
        let total_duration: u64 = commands.iter().map(|c| c.duration_ms).sum();
        let average_duration_ms = if total_commands > 0 {
            total_duration as f64 / total_commands as f64
        } else {
            0.0
        };
        
        // Commands by type
        let mut commands_by_type = HashMap::new();
        for cmd in &commands {
            *commands_by_type.entry(cmd.semantic_type).or_insert(0) += 1;
        }
        
        Ok(StatsResult {
            total_commands,
            success_rate,
            average_duration_ms,
            commands_by_type,
            time_range: range.to_string(),
        })
    }
}