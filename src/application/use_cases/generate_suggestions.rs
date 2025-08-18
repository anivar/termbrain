use crate::domain::repositories::{CommandRepository, PatternRepository};
use crate::domain::services::{PredictionEngine, PatternDetector};
use anyhow::Result;
use std::collections::HashMap;

pub struct GenerateSuggestions<'a> {
    command_repository: &'a dyn CommandRepository,
    pattern_repository: &'a dyn PatternRepository,
}

impl<'a> GenerateSuggestions<'a> {
    pub fn new(
        command_repository: &'a dyn CommandRepository,
        pattern_repository: &'a dyn PatternRepository,
    ) -> Self {
        Self {
            command_repository,
            pattern_repository,
        }
    }
    
    pub async fn execute(&self) -> Result<Suggestions> {
        let recent_commands = self.command_repository.get_recent(500).await?;
        let current_dir = std::env::current_dir()?.to_string_lossy().to_string();
        
        // Analyze patterns
        let pattern_detector = PatternDetector::new(self.command_repository, self.pattern_repository);
        let patterns = pattern_detector.detect_patterns(3).await?;
        
        // Get predictions
        let prediction_engine = PredictionEngine::new();
        let next_commands = prediction_engine.predict_next_command(&recent_commands, &current_dir).await;
        
        // Analyze workflow opportunities
        let workflow_opportunities = self.find_workflow_opportunities(&recent_commands);
        
        // Find learning recommendations
        let learning_recommendations = self.generate_learning_recommendations(&recent_commands);
        
        // Productivity tips
        let productivity_tips = self.generate_productivity_tips(&recent_commands);
        
        // Tool recommendations
        let tool_recommendations = self.recommend_tools(&recent_commands);
        
        Ok(Suggestions {
            next_commands: next_commands.into_iter()
                .map(|p| NextCommand {
                    command: p.command,
                    confidence: p.confidence,
                    reason: p.reason,
                })
                .collect(),
            workflow_opportunities,
            learning_recommendations,
            productivity_tips,
            tool_recommendations,
        })
    }
    
    fn find_workflow_opportunities(&self, commands: &[crate::domain::entities::Command]) -> Vec<WorkflowOpportunity> {
        let mut opportunities = Vec::new();
        let mut sequence_counts: HashMap<Vec<String>, usize> = HashMap::new();
        
        // Look for repeated sequences
        for window in commands.windows(3) {
            let sequence: Vec<String> = window
                .iter()
                .map(|c| c.command.split_whitespace().next().unwrap_or("").to_string())
                .collect();
            
            *sequence_counts.entry(sequence).or_insert(0) += 1;
        }
        
        for (sequence, count) in sequence_counts {
            if count >= 5 {
                opportunities.push(WorkflowOpportunity {
                    name: format!("{} workflow", sequence.join("-")),
                    description: format!("You've run this sequence {} times", count),
                    commands: sequence,
                    frequency: count,
                    estimated_time_saved: count * 5, // Assume 5 seconds saved per workflow
                });
            }
        }
        
        opportunities.sort_by_key(|o| std::cmp::Reverse(o.estimated_time_saved));
        opportunities.truncate(3);
        opportunities
    }
    
    fn generate_learning_recommendations(&self, commands: &[crate::domain::entities::Command]) -> Vec<LearningRecommendation> {
        let mut recommendations = Vec::new();
        
        // Count command usage
        let mut tool_errors: HashMap<String, usize> = HashMap::new();
        for cmd in commands.iter().filter(|c| c.exit_code != 0) {
            let tool = cmd.command.split_whitespace().next().unwrap_or("").to_string();
            *tool_errors.entry(tool).or_insert(0) += 1;
        }
        
        // Recommend learning for tools with high error rates
        for (tool, error_count) in tool_errors {
            if error_count >= 3 {
                recommendations.push(LearningRecommendation {
                    topic: format!("{} advanced usage", tool),
                    reason: format!("You've had {} errors with this tool", error_count),
                    resources: vec![
                        format!("man {}", tool),
                        format!("tldr {}", tool),
                        format!("{} --help", tool),
                    ],
                    priority: if error_count >= 10 { Priority::High } else { Priority::Medium },
                });
            }
        }
        
        // Add recommendations based on complexity
        let complex_commands = commands.iter().filter(|c| c.complexity >= 4).count();
        if complex_commands > 20 {
            recommendations.push(LearningRecommendation {
                topic: "Shell scripting and automation".to_string(),
                reason: "You're using many complex command combinations".to_string(),
                resources: vec![
                    "Bash scripting guide".to_string(),
                    "Learn about shell functions".to_string(),
                ],
                priority: Priority::High,
            });
        }
        
        recommendations
    }
    
    fn generate_productivity_tips(&self, commands: &[crate::domain::entities::Command]) -> Vec<ProductivityTip> {
        let mut tips = Vec::new();
        
        // Check for repetitive commands
        let mut command_counts: HashMap<String, usize> = HashMap::new();
        for cmd in commands {
            *command_counts.entry(cmd.command.clone()).or_insert(0) += 1;
        }
        
        for (cmd, count) in command_counts {
            if count >= 10 && cmd.len() > 20 {
                tips.push(ProductivityTip {
                    title: "Create an alias".to_string(),
                    description: format!("You've typed '{}' {} times", 
                        if cmd.len() > 50 { &cmd[..50] } else { &cmd }, 
                        count
                    ),
                    action: format!("alias short='{}'\n", cmd),
                    impact: ImpactLevel::High,
                });
            }
        }
        
        // Check for directory navigation patterns
        let cd_count = commands.iter().filter(|c| c.command.starts_with("cd ")).count();
        if cd_count > 50 {
            tips.push(ProductivityTip {
                title: "Use a directory jumper".to_string(),
                description: format!("You've navigated directories {} times", cd_count),
                action: "Consider using 'z' or 'autojump' for faster navigation".to_string(),
                impact: ImpactLevel::Medium,
            });
        }
        
        tips
    }
    
    fn recommend_tools(&self, commands: &[crate::domain::entities::Command]) -> Vec<ToolRecommendation> {
        let mut recommendations = Vec::new();
        
        // Check for patterns that could benefit from specific tools
        let grep_count = commands.iter().filter(|c| c.command.contains("grep")).count();
        let find_count = commands.iter().filter(|c| c.command.contains("find")).count();
        
        if grep_count > 10 {
            recommendations.push(ToolRecommendation {
                tool: "ripgrep (rg)".to_string(),
                reason: format!("You use grep frequently ({} times). ripgrep is faster.", grep_count),
                benefits: vec![
                    "5-10x faster than grep".to_string(),
                    "Respects .gitignore by default".to_string(),
                    "Better Unicode support".to_string(),
                ],
                installation: "brew install ripgrep".to_string(),
            });
        }
        
        if find_count > 5 {
            recommendations.push(ToolRecommendation {
                tool: "fd".to_string(),
                reason: format!("You use find {} times. fd is more intuitive.", find_count),
                benefits: vec![
                    "Simpler syntax than find".to_string(),
                    "Faster performance".to_string(),
                    "Colorized output".to_string(),
                ],
                installation: "brew install fd".to_string(),
            });
        }
        
        recommendations
    }
}

#[derive(Debug, Clone)]
pub struct Suggestions {
    pub next_commands: Vec<NextCommand>,
    pub workflow_opportunities: Vec<WorkflowOpportunity>,
    pub learning_recommendations: Vec<LearningRecommendation>,
    pub productivity_tips: Vec<ProductivityTip>,
    pub tool_recommendations: Vec<ToolRecommendation>,
}

#[derive(Debug, Clone)]
pub struct NextCommand {
    pub command: String,
    pub confidence: f64,
    pub reason: String,
}

#[derive(Debug, Clone)]
pub struct WorkflowOpportunity {
    pub name: String,
    pub description: String,
    pub commands: Vec<String>,
    pub frequency: usize,
    pub estimated_time_saved: usize,
}

#[derive(Debug, Clone)]
pub struct LearningRecommendation {
    pub topic: String,
    pub reason: String,
    pub resources: Vec<String>,
    pub priority: Priority,
}

#[derive(Debug, Clone)]
pub struct ProductivityTip {
    pub title: String,
    pub description: String,
    pub action: String,
    pub impact: ImpactLevel,
}

#[derive(Debug, Clone)]
pub struct ToolRecommendation {
    pub tool: String,
    pub reason: String,
    pub benefits: Vec<String>,
    pub installation: String,
}

#[derive(Debug, Clone, Copy)]
pub enum Priority {
    Low,
    Medium,
    High,
}

#[derive(Debug, Clone, Copy)]
pub enum ImpactLevel {
    Low,
    Medium,
    High,
}