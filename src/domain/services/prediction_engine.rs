use crate::domain::entities::{Command, SemanticType};
use crate::domain::repositories::CommandRepository;
use anyhow::Result;
use std::collections::HashMap;

pub struct PredictionEngine;

impl PredictionEngine {
    pub fn new() -> Self {
        Self
    }
    
    pub async fn predict_next_command(
        &self,
        recent_commands: &[Command],
        current_directory: &str,
    ) -> Vec<PredictedCommand> {
        let mut predictions = Vec::new();
        
        // Simple prediction based on command frequency in current directory
        let mut command_freq: HashMap<String, usize> = HashMap::new();
        
        for cmd in recent_commands.iter().filter(|c| c.directory == current_directory) {
            let base_cmd = cmd.command.split_whitespace().next().unwrap_or("");
            *command_freq.entry(base_cmd.to_string()).or_insert(0) += 1;
        }
        
        // Get semantic context
        let recent_types: Vec<SemanticType> = recent_commands
            .iter()
            .take(5)
            .map(|c| c.semantic_type)
            .collect();
        
        // Generate predictions based on patterns
        if recent_types.contains(&SemanticType::Testing) {
            predictions.push(PredictedCommand {
                command: "npm test".to_string(),
                confidence: 0.8,
                reason: "Recent testing activity detected".to_string(),
            });
        }
        
        if recent_types.contains(&SemanticType::VersionControl) {
            predictions.push(PredictedCommand {
                command: "git status".to_string(),
                confidence: 0.7,
                reason: "Git workflow in progress".to_string(),
            });
            
            predictions.push(PredictedCommand {
                command: "git commit -m \"\"".to_string(),
                confidence: 0.6,
                reason: "Ready to commit changes".to_string(),
            });
        }
        
        // Add frequency-based predictions
        let mut freq_sorted: Vec<_> = command_freq.into_iter().collect();
        freq_sorted.sort_by_key(|(_, count)| std::cmp::Reverse(*count));
        
        for (cmd, count) in freq_sorted.iter().take(3) {
            let confidence = (*count as f64 / recent_commands.len() as f64).min(0.9);
            predictions.push(PredictedCommand {
                command: cmd.clone(),
                confidence,
                reason: format!("Frequently used in this directory ({} times)", count),
            });
        }
        
        // Sort by confidence and limit
        predictions.sort_by(|a, b| b.confidence.partial_cmp(&a.confidence).unwrap());
        predictions.truncate(5);
        
        predictions
    }
    
    pub async fn check_dangerous_command(&self, command: &str) -> Option<SafetyWarning> {
        let cmd_lower = command.to_lowercase();
        
        // Check for dangerous patterns
        if cmd_lower.contains("rm -rf /") || cmd_lower.contains("rm -fr /") {
            return Some(SafetyWarning {
                level: WarningLevel::Critical,
                message: "This command could delete system files!".to_string(),
                suggestion: "Use with extreme caution or add specific path".to_string(),
            });
        }
        
        if cmd_lower.starts_with("sudo rm") || cmd_lower.starts_with("sudo dd") {
            return Some(SafetyWarning {
                level: WarningLevel::High,
                message: "Destructive command with sudo privileges".to_string(),
                suggestion: "Double-check the command before executing".to_string(),
            });
        }
        
        if cmd_lower.contains("force") || cmd_lower.contains("--force") {
            return Some(SafetyWarning {
                level: WarningLevel::Medium,
                message: "Force flag detected".to_string(),
                suggestion: "Consider if forcing is necessary".to_string(),
            });
        }
        
        None
    }
}

#[derive(Debug, Clone)]
pub struct PredictedCommand {
    pub command: String,
    pub confidence: f64,
    pub reason: String,
}

#[derive(Debug, Clone)]
pub struct SafetyWarning {
    pub level: WarningLevel,
    pub message: String,
    pub suggestion: String,
}

#[derive(Debug, Clone, Copy)]
pub enum WarningLevel {
    Low,
    Medium,
    High,
    Critical,
}