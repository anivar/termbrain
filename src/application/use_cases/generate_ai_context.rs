use crate::domain::repositories::{CommandRepository, PatternRepository, IntentionRepository};
use crate::domain::services::PatternDetector;
use anyhow::Result;
use std::collections::HashMap;

pub struct GenerateAIContext<'a> {
    command_repository: &'a dyn CommandRepository,
    pattern_repository: &'a dyn PatternRepository,
    intention_repository: &'a dyn IntentionRepository,
}

impl<'a> GenerateAIContext<'a> {
    pub fn new(
        command_repository: &'a dyn CommandRepository,
        pattern_repository: &'a dyn PatternRepository,
        intention_repository: &'a dyn IntentionRepository,
    ) -> Self {
        Self {
            command_repository,
            pattern_repository,
            intention_repository,
        }
    }
    
    pub async fn execute(&self) -> Result<String> {
        let current_dir = std::env::current_dir()?;
        let session_id = crate::domain::value_objects::generate_session_id();
        
        // Get recent commands
        let commands = self.command_repository
            .get_by_directory(&current_dir.to_string_lossy(), 200)
            .await?;
        
        // Get patterns
        let patterns = self.pattern_repository.find_patterns(3).await?;
        
        // Get current intention
        let current_intention = self.intention_repository.get_current(&session_id).await?;
        
        let mut context = String::new();
        
        // Header
        context.push_str("# Termbrain AI Context\n\n");
        context.push_str(&format!("Generated for: {}\n", current_dir.display()));
        context.push_str(&format!("Generated at: {}\n\n", chrono::Utc::now()));
        
        // Project overview
        context.push_str("## Project Overview\n\n");
        
        // Detect project characteristics
        if current_dir.join("package.json").exists() {
            context.push_str("- **Type**: Node.js/JavaScript project\n");
        }
        if current_dir.join("Cargo.toml").exists() {
            context.push_str("- **Type**: Rust project\n");
        }
        if current_dir.join(".git").exists() {
            context.push_str("- **Version Control**: Git repository\n");
        }
        
        context.push_str("\n");
        
        // Current intention if any
        if let Some(intention) = current_intention {
            context.push_str("## Current Development Intention\n\n");
            context.push_str(&format!("**Goal**: {}\n\n", intention.intention));
        }
        
        // Recent activity summary
        context.push_str("## Recent Development Activity\n\n");
        
        // Group commands by semantic type
        let mut by_type: HashMap<_, Vec<_>> = HashMap::new();
        for cmd in &commands {
            by_type.entry(cmd.semantic_type).or_default().push(cmd);
        }
        
        // Sort by frequency
        let mut type_list: Vec<_> = by_type.into_iter().collect();
        type_list.sort_by_key(|(_, cmds)| std::cmp::Reverse(cmds.len()));
        
        for (sem_type, cmds) in type_list.iter().take(5) {
            context.push_str(&format!("### {:?} Commands ({})\n\n", sem_type, cmds.len()));
            
            // Show most recent examples
            for cmd in cmds.iter().take(5) {
                context.push_str(&format!("- `{}`", cmd.command));
                if cmd.exit_code != 0 {
                    context.push_str(" ❌ (failed)");
                }
                context.push_str("\n");
            }
            context.push_str("\n");
        }
        
        // Common patterns
        context.push_str("## Common Command Patterns\n\n");
        
        let mut cmd_counts = HashMap::new();
        for cmd in &commands {
            let base = cmd.command.split_whitespace().next().unwrap_or("");
            *cmd_counts.entry(base).or_insert(0) += 1;
        }
        
        let mut sorted_cmds: Vec<_> = cmd_counts.into_iter().collect();
        sorted_cmds.sort_by_key(|(_, count)| std::cmp::Reverse(*count));
        
        for (cmd, count) in sorted_cmds.iter().take(10) {
            context.push_str(&format!("- `{}` (used {} times)\n", cmd, count));
        }
        
        context.push_str("\n");
        
        // Detected patterns and workflows
        if !patterns.is_empty() {
            context.push_str("## Detected Workflow Patterns\n\n");
            context.push_str("Based on your command history, here are frequently used patterns:\n\n");
            
            for pattern in patterns.iter().take(5) {
                context.push_str(&format!("### {} ({}x)\n", 
                    pattern.suggested_workflow.as_ref().unwrap_or(&pattern.pattern),
                    pattern.frequency
                ));
                context.push_str(&format!("Pattern: `{}`\n", pattern.pattern));
                
                if !pattern.contexts.is_empty() {
                    context.push_str("Used in: ");
                    let unique_contexts: std::collections::HashSet<_> = pattern.contexts.iter().collect();
                    let contexts_str = unique_contexts.into_iter()
                        .take(3)
                        .map(|c| c.as_str())
                        .collect::<Vec<_>>()
                        .join(", ");
                    context.push_str(&contexts_str);
                    context.push_str("\n");
                }
                context.push_str("\n");
            }
        }
        
        context.push_str("\n");
        
        // Error patterns
        let failed_commands: Vec<_> = commands.iter()
            .filter(|c| c.exit_code != 0)
            .take(10)
            .collect();
        
        if !failed_commands.is_empty() {
            context.push_str("## Recent Errors to Address\n\n");
            for cmd in failed_commands.iter().take(5) {
                context.push_str(&format!("- `{}` (exit code: {})\n", cmd.command, cmd.exit_code));
            }
            context.push_str("\n");
        }
        
        // Development environment and statistics
        context.push_str("## Development Environment\n\n");
        context.push_str(&format!("- **Working Directory**: {}\n", current_dir.display()));
        context.push_str(&format!("- **Total Commands Analyzed**: {}\n", commands.len()));
        
        // Calculate more detailed statistics
        let success_rate = if !commands.is_empty() {
            let successful = commands.iter().filter(|c| c.exit_code == 0).count();
            (successful as f64 / commands.len() as f64) * 100.0
        } else {
            0.0
        };
        
        context.push_str(&format!("- **Success Rate**: {:.1}%\n", success_rate));
        
        // Most active directories
        let mut dir_counts: HashMap<&str, usize> = HashMap::new();
        for cmd in &commands {
            *dir_counts.entry(&cmd.directory).or_insert(0) += 1;
        }
        
        let mut dirs: Vec<_> = dir_counts.into_iter().collect();
        dirs.sort_by_key(|(_, count)| std::cmp::Reverse(*count));
        
        if !dirs.is_empty() {
            context.push_str("- **Most Active Directories**:\n");
            for (dir, count) in dirs.iter().take(3) {
                context.push_str(&format!("  - {} ({}x)\n", dir, count));
            }
        }
        
        // Git branch information
        let branches: std::collections::HashSet<_> = commands.iter()
            .filter_map(|c| c.git_branch.as_ref())
            .collect();
        
        if !branches.is_empty() {
            context.push_str(&format!("- **Git Branches Used**: {}\n", 
                branches.into_iter().take(5).cloned().collect::<Vec<_>>().join(", ")
            ));
        }
        
        context.push_str("\n---\n\n");
        context.push_str("*This context was automatically generated by Termbrain to help AI assistants better understand your project and development patterns.*\n");
        
        Ok(context)
    }
}