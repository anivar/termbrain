use crate::domain::repositories::CommandRepository;
use crate::application::dto::{ProjectAnalysis, ProjectType, WorkflowSuggestion};
use anyhow::Result;
use std::collections::HashMap;
use std::path::Path;

pub struct AnalyzeProject<'a> {
    command_repository: &'a dyn CommandRepository,
}

impl<'a> AnalyzeProject<'a> {
    pub fn new(command_repository: &'a dyn CommandRepository) -> Self {
        Self { command_repository }
    }
    
    pub async fn execute(&self) -> Result<ProjectAnalysis> {
        let current_dir = std::env::current_dir()?;
        
        // Detect project type
        let project_type = self.detect_project_type(&current_dir);
        
        // Get recent commands in this directory
        let commands = self.command_repository
            .get_by_directory(&current_dir.to_string_lossy(), 1000)
            .await?;
        
        // Analyze language usage
        let primary_language = self.detect_primary_language(&commands);
        
        // Calculate productivity score
        let total = commands.len() as f64;
        let successful = commands.iter().filter(|c| c.exit_code == 0).count() as f64;
        let productivity_score = if total > 0.0 {
            (successful / total) * 10.0
        } else {
            5.0
        };
        
        // Find common commands
        let mut command_counts = HashMap::new();
        for cmd in &commands {
            let base_cmd = cmd.command.split_whitespace().next().unwrap_or("");
            *command_counts.entry(base_cmd.to_string()).or_insert(0) += 1;
        }
        
        let mut common_commands: Vec<_> = command_counts.into_iter().collect();
        common_commands.sort_by_key(|(_, count)| std::cmp::Reverse(*count));
        common_commands.truncate(10);
        
        // Detect workflow patterns
        let workflow_suggestions = self.detect_workflow_patterns(&commands);
        
        Ok(ProjectAnalysis {
            project_type,
            primary_language,
            productivity_score,
            common_commands,
            workflow_suggestions,
        })
    }
    
    fn detect_project_type(&self, path: &Path) -> ProjectType {
        if path.join("package.json").exists() {
            ProjectType::JavaScript
        } else if path.join("Cargo.toml").exists() {
            ProjectType::Rust
        } else if path.join("requirements.txt").exists() || path.join("setup.py").exists() {
            ProjectType::Python
        } else if path.join("go.mod").exists() {
            ProjectType::Go
        } else if path.join("pom.xml").exists() || path.join("build.gradle").exists() {
            ProjectType::Java
        } else if path.join(".git").exists() {
            ProjectType::Generic
        } else {
            ProjectType::Unknown
        }
    }
    
    fn detect_primary_language(&self, commands: &[crate::domain::entities::Command]) -> String {
        let mut lang_counts = HashMap::new();
        
        for cmd in commands {
            let base_cmd = cmd.command.split_whitespace().next().unwrap_or("");
            let lang = match base_cmd {
                "npm" | "node" | "yarn" | "pnpm" => "JavaScript",
                "cargo" | "rustc" | "rustup" => "Rust",
                "python" | "pip" | "poetry" | "pipenv" => "Python",
                "go" | "gofmt" => "Go",
                "java" | "javac" | "mvn" | "gradle" => "Java",
                _ => continue,
            };
            *lang_counts.entry(lang).or_insert(0) += 1;
        }
        
        lang_counts.into_iter()
            .max_by_key(|(_, count)| *count)
            .map(|(lang, _)| lang.to_string())
            .unwrap_or_else(|| "Unknown".to_string())
    }
    
    fn detect_workflow_patterns(&self, commands: &[crate::domain::entities::Command]) -> Vec<WorkflowSuggestion> {
        let mut patterns = Vec::new();
        
        // Simple pattern detection: look for sequences of commands that appear multiple times
        let mut sequence_counts: HashMap<Vec<String>, usize> = HashMap::new();
        
        // Look for 2-3 command sequences
        for window_size in 2..=3 {
            for window in commands.windows(window_size) {
                let sequence: Vec<String> = window.iter()
                    .map(|c| c.command.split_whitespace().next().unwrap_or("").to_string())
                    .collect();
                
                *sequence_counts.entry(sequence).or_insert(0) += 1;
            }
        }
        
        // Convert frequent sequences to workflow suggestions
        for (sequence, count) in sequence_counts {
            if count >= 3 {
                patterns.push(WorkflowSuggestion {
                    name: format!("{} workflow", sequence.join(" → ")),
                    description: format!("Frequently used sequence: {}", sequence.join(", ")),
                    commands: sequence,
                    frequency: count,
                });
            }
        }
        
        patterns.sort_by_key(|p| std::cmp::Reverse(p.frequency));
        patterns.truncate(5);
        
        patterns
    }
}