use crate::domain::repositories::CommandRepository;
use crate::application::dto::GrowthAnalytics;
use anyhow::Result;
use chrono::{Duration, Utc};
use std::collections::HashMap;

pub struct AnalyzeGrowth<'a> {
    command_repository: &'a dyn CommandRepository,
}

impl<'a> AnalyzeGrowth<'a> {
    pub fn new(command_repository: &'a dyn CommandRepository) -> Self {
        Self { command_repository }
    }
    
    pub async fn execute(&self) -> Result<GrowthAnalytics> {
        // Get commands from different time periods
        let now = Utc::now();
        let week_ago = now - Duration::weeks(1);
        let month_ago = now - Duration::days(30);
        let three_months_ago = now - Duration::days(90);
        
        let recent_commands = self.command_repository.get_since(week_ago).await?;
        let month_commands = self.command_repository.get_since(month_ago).await?;
        let quarter_commands = self.command_repository.get_since(three_months_ago).await?;
        
        // Calculate skill progression
        let skill_progression = self.calculate_skill_progression(&quarter_commands);
        
        // Calculate learning velocity
        let new_commands_week = self.count_unique_commands(&recent_commands);
        let new_commands_month = self.count_unique_commands(&month_commands);
        let learning_velocity = new_commands_week as f64 / 7.0; // New commands per day
        
        // Calculate mastery levels
        let mastery_levels = self.calculate_mastery_levels(&month_commands);
        
        // Error reduction rate
        let week_success_rate = self.calculate_success_rate(&recent_commands);
        let month_success_rate = self.calculate_success_rate(&month_commands);
        let error_reduction = week_success_rate - month_success_rate;
        
        // Productivity trends
        let daily_averages = self.calculate_daily_averages(&recent_commands);
        
        // Complex command usage
        let complex_command_ratio = self.calculate_complexity_ratio(&recent_commands);
        
        Ok(GrowthAnalytics {
            skill_progression,
            learning_velocity,
            mastery_levels,
            error_reduction_rate: error_reduction,
            productivity_trends: daily_averages,
            new_commands_learned: new_commands_week,
            complex_command_ratio,
            growth_score: self.calculate_growth_score(
                learning_velocity,
                error_reduction,
                complex_command_ratio
            ),
        })
    }
    
    fn calculate_skill_progression(&self, commands: &[crate::domain::entities::Command]) -> HashMap<String, f64> {
        let mut progression = HashMap::new();
        let total = commands.len() as f64;
        
        if total == 0.0 {
            return progression;
        }
        
        // Group by semantic type and calculate progression
        let mut type_counts: HashMap<_, usize> = HashMap::new();
        for cmd in commands {
            *type_counts.entry(cmd.semantic_type).or_insert(0) += 1;
        }
        
        for (sem_type, count) in type_counts {
            let percentage = (count as f64 / total) * 100.0;
            progression.insert(format!("{:?}", sem_type), percentage);
        }
        
        progression
    }
    
    fn count_unique_commands(&self, commands: &[crate::domain::entities::Command]) -> usize {
        let unique: std::collections::HashSet<_> = commands
            .iter()
            .map(|c| c.command.split_whitespace().next().unwrap_or(""))
            .collect();
        unique.len()
    }
    
    fn calculate_mastery_levels(&self, commands: &[crate::domain::entities::Command]) -> HashMap<String, MasteryLevel> {
        let mut mastery = HashMap::new();
        let mut tool_usage: HashMap<String, (usize, usize)> = HashMap::new(); // (total, successful)
        
        for cmd in commands {
            let tool = cmd.command.split_whitespace().next().unwrap_or("").to_string();
            let entry = tool_usage.entry(tool).or_insert((0, 0));
            entry.0 += 1;
            if cmd.exit_code == 0 {
                entry.1 += 1;
            }
        }
        
        for (tool, (total, successful)) in tool_usage {
            let success_rate = successful as f64 / total as f64;
            let level = match (total, success_rate) {
                (t, s) if t >= 50 && s >= 0.95 => MasteryLevel::Expert,
                (t, s) if t >= 20 && s >= 0.85 => MasteryLevel::Advanced,
                (t, s) if t >= 10 && s >= 0.75 => MasteryLevel::Intermediate,
                _ => MasteryLevel::Beginner,
            };
            mastery.insert(tool, level);
        }
        
        mastery
    }
    
    fn calculate_success_rate(&self, commands: &[crate::domain::entities::Command]) -> f64 {
        if commands.is_empty() {
            return 0.0;
        }
        
        let successful = commands.iter().filter(|c| c.exit_code == 0).count();
        successful as f64 / commands.len() as f64
    }
    
    fn calculate_daily_averages(&self, commands: &[crate::domain::entities::Command]) -> Vec<(String, usize)> {
        let mut daily_counts: HashMap<String, usize> = HashMap::new();
        
        for cmd in commands {
            let date = cmd.timestamp.format("%Y-%m-%d").to_string();
            *daily_counts.entry(date).or_insert(0) += 1;
        }
        
        let mut averages: Vec<_> = daily_counts.into_iter().collect();
        averages.sort_by_key(|(date, _)| date.clone());
        averages
    }
    
    fn calculate_complexity_ratio(&self, commands: &[crate::domain::entities::Command]) -> f64 {
        if commands.is_empty() {
            return 0.0;
        }
        
        let complex = commands.iter().filter(|c| c.complexity >= 3).count();
        complex as f64 / commands.len() as f64
    }
    
    fn calculate_growth_score(&self, learning_velocity: f64, error_reduction: f64, complexity: f64) -> f64 {
        // Weighted score calculation
        let learning_weight = 0.4;
        let error_weight = 0.3;
        let complexity_weight = 0.3;
        
        let score = (learning_velocity.min(5.0) / 5.0) * learning_weight
            + (error_reduction.max(-0.2) + 0.2) * error_weight * 5.0
            + complexity * complexity_weight * 10.0;
        
        (score * 10.0).min(10.0).max(0.0) // Scale to 0-10
    }
}

#[derive(Debug, Clone, Copy, serde::Serialize, serde::Deserialize)]
pub enum MasteryLevel {
    Beginner,
    Intermediate,
    Advanced,
    Expert,
}