use crate::domain::entities::{Command, Pattern};
use crate::domain::repositories::{CommandRepository, PatternRepository};
use anyhow::Result;
use std::collections::HashMap;
use uuid::Uuid;

pub struct PatternDetector<'a> {
    command_repo: &'a dyn CommandRepository,
    pattern_repo: &'a dyn PatternRepository,
}

impl<'a> PatternDetector<'a> {
    pub fn new(
        command_repo: &'a dyn CommandRepository,
        pattern_repo: &'a dyn PatternRepository,
    ) -> Self {
        Self {
            command_repo,
            pattern_repo,
        }
    }
    
    pub async fn detect_patterns(&self, min_frequency: usize) -> Result<Vec<Pattern>> {
        // Get recent commands
        let commands = self.command_repo.get_recent(1000).await?;
        
        // Detect command sequences
        let mut sequence_map: HashMap<String, (usize, Vec<String>)> = HashMap::new();
        
        // Look for 2-3 command patterns
        for window_size in 2..=3 {
            for window in commands.windows(window_size) {
                // Check if commands are close in time (within 5 minutes)
                let time_diff = window.last().unwrap().timestamp - window.first().unwrap().timestamp;
                if time_diff.num_minutes() <= 5 {
                    let pattern = window
                        .iter()
                        .map(|c| c.command.split_whitespace().next().unwrap_or("").to_string())
                        .collect::<Vec<_>>()
                        .join(" → ");
                    
                    let contexts = window
                        .iter()
                        .map(|c| c.directory.clone())
                        .collect::<Vec<_>>();
                    
                    let entry = sequence_map.entry(pattern).or_insert((0, Vec::new()));
                    entry.0 += 1;
                    entry.1.extend(contexts);
                }
            }
        }
        
        // Create patterns from sequences
        let mut patterns = Vec::new();
        for (pattern_str, (frequency, contexts)) in sequence_map {
            if frequency >= min_frequency {
                let pattern = Pattern {
                    id: Uuid::new_v4(),
                    pattern: pattern_str.clone(),
                    frequency: frequency as u32,
                    contexts: contexts.into_iter().take(5).collect(), // Limit contexts
                    suggested_workflow: Some(self.suggest_workflow_name(&pattern_str)),
                };
                
                // Save to repository
                self.pattern_repo.save(&pattern).await?;
                patterns.push(pattern);
            }
        }
        
        patterns.sort_by_key(|p| std::cmp::Reverse(p.frequency));
        Ok(patterns)
    }
    
    pub async fn find_similar_patterns(&self, command: &str) -> Result<Vec<Pattern>> {
        let all_patterns = self.pattern_repo.find_patterns(1).await?;
        let cmd_base = command.split_whitespace().next().unwrap_or("");
        
        let mut similar = Vec::new();
        for pattern in all_patterns {
            if pattern.pattern.contains(cmd_base) {
                similar.push(pattern);
            }
        }
        
        similar.truncate(3);
        Ok(similar)
    }
    
    fn suggest_workflow_name(&self, pattern: &str) -> String {
        let parts: Vec<&str> = pattern.split(" → ").collect();
        
        match parts.as_slice() {
            ["git", "add", ..] => "Git commit workflow".to_string(),
            ["npm", "test", ..] => "Test and verify workflow".to_string(),
            ["cargo", "build", ..] => "Rust build workflow".to_string(),
            ["docker", ..] => "Container management workflow".to_string(),
            _ => format!("{} workflow", parts.join("-")),
        }
    }
}