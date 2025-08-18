pub mod domain;
pub mod application;
pub mod infrastructure;
pub mod presentation;

use anyhow::Result;
use std::sync::Arc;
use chrono::Timelike;

use crate::infrastructure::persistence::{
    SqliteCommandRepository, SqliteWorkflowRepository, 
    SqliteIntentionRepository, SqlitePatternRepository
};
use crate::infrastructure::config::Config;

/// Main application struct that wires together all layers
pub struct TermbrainApp {
    // Repositories (infrastructure layer)
    command_repo: Arc<SqliteCommandRepository>,
    workflow_repo: Arc<SqliteWorkflowRepository>,
    intention_repo: Arc<SqliteIntentionRepository>,
    pattern_repo: Arc<SqlitePatternRepository>,
    
    // Configuration
    config: Config,
}

impl TermbrainApp {
    pub async fn new() -> Result<Self> {
        // Load configuration from infrastructure layer
        let config = Config::load().await?;
        
        // Initialize repositories
        let db_path = config.data_dir().join("termbrain.db");
        let command_repo = Arc::new(SqliteCommandRepository::new(&db_path).await?);
        let workflow_repo = Arc::new(SqliteWorkflowRepository::new(&db_path).await?);
        
        // Create a shared pool for intention and pattern repositories
        let db_url = format!("sqlite://{}?mode=rwc", db_path.display());
        let pool = sqlx::SqlitePoolOptions::new()
            .max_connections(5)
            .connect(&db_url)
            .await?;
            
        let intention_repo = Arc::new(SqliteIntentionRepository::new(pool.clone()).await?);
        let pattern_repo = Arc::new(SqlitePatternRepository::new(pool).await?);
        
        Ok(Self {
            command_repo,
            workflow_repo,
            intention_repo,
            pattern_repo,
            config,
        })
    }
    
    // Command recording (called by shell hooks)
    pub async fn record_command(
        &self,
        command: &str,
        directory: &str,
        exit_code: i32,
        duration_ms: u64,
    ) -> Result<()> {
        let use_case = application::use_cases::RecordCommand::new(&*self.command_repo);
        use_case.execute(command, directory, exit_code, duration_ms).await
    }
    
    // Search commands
    pub async fn search(&self, query: &str, limit: usize) -> Result<()> {
        let use_case = application::use_cases::SearchCommands::new(&*self.command_repo);
        let results = use_case.execute(query, limit).await?;
        presentation::cli::display_search_results(results);
        Ok(())
    }
    
    // Show statistics
    pub async fn show_stats(&self, range: &str) -> Result<()> {
        let use_case = application::use_cases::GenerateStats::new(&*self.command_repo);
        let stats = use_case.execute(range).await?;
        presentation::cli::display_stats(stats);
        Ok(())
    }
    
    // Show history
    pub async fn show_history(&self, semantic_type: Option<&str>, limit: usize) -> Result<()> {
        let use_case = application::use_cases::ShowHistory::new(&*self.command_repo);
        let results = use_case.execute(semantic_type, limit).await?;
        presentation::cli::display_search_results(results);
        Ok(())
    }
    
    // Workflow management
    pub async fn create_workflow(
        &self,
        name: &str,
        description: &str,
        commands: Vec<String>,
    ) -> Result<()> {
        let use_case = application::use_cases::CreateWorkflow::new(&*self.workflow_repo);
        use_case.execute(name, description, commands).await?;
        println!("✓ Workflow '{}' created successfully", name);
        Ok(())
    }
    
    pub async fn list_workflows(&self) -> Result<()> {
        let workflows = self.workflow_repo.list().await?;
        presentation::cli::display_workflows(workflows);
        Ok(())
    }
    
    pub async fn run_workflow(&self, name: &str) -> Result<()> {
        let use_case = application::use_cases::RunWorkflow::new(&*self.workflow_repo);
        use_case.execute(name).await
    }
    
    pub async fn delete_workflow(&self, name: &str) -> Result<()> {
        self.workflow_repo.delete(name).await?;
        println!("✓ Workflow '{}' deleted", name);
        Ok(())
    }
    
    // Intention tracking
    pub async fn set_intention(&self, intention: &str) -> Result<()> {
        let use_case = application::use_cases::TrackIntention::new(&*self.intention_repo);
        use_case.execute(intention).await?;
        println!("✓ Intention set: {}", intention);
        Ok(())
    }
    
    pub async fn mark_intention_achieved(&self) -> Result<()> {
        let session_id = crate::domain::value_objects::generate_session_id();
        let use_case = application::use_cases::TrackIntention::new(&*self.intention_repo);
        use_case.mark_achieved(&session_id).await?;
        println!("✓ Intention marked as achieved");
        Ok(())
    }
    
    // Flow state management
    pub async fn flow_command(&self, action: &str) -> Result<()> {
        let use_case = application::use_cases::TrackFlow::new(&*self.command_repo);
        
        match action {
            "start" => {
                use_case.start_flow().await?;
                println!("🌊 Flow state started");
            }
            "end" => {
                let state = use_case.end_flow().await?;
                presentation::cli::display_flow_state(state);
            }
            "status" => {
                let state = use_case.get_status().await?;
                presentation::cli::display_flow_state(state);
            }
            _ => anyhow::bail!("Unknown flow action: {}", action),
        }
        
        Ok(())
    }
    
    // Export data
    pub async fn export(&self, format: &str, output: &str) -> Result<()> {
        let use_case = application::use_cases::ExportData::new(&*self.command_repo);
        use_case.execute(format, output).await?;
        println!("✓ Exported to {}", output);
        Ok(())
    }
    
    // Predictive mode
    pub async fn set_predictive_mode(&self, mode: &str) -> Result<()> {
        let use_case = application::use_cases::ManagePredictive::new(&self.config);
        use_case.execute(mode).await?;
        
        let status = if self.config.predictive_mode() {
            "enabled"
        } else {
            "disabled"
        };
        println!("✓ Predictive mode {}", status);
        Ok(())
    }
    
    // AI context generation
    pub async fn generate_ai_context(&self) -> Result<()> {
        let use_case = application::use_cases::GenerateAIContext::new(
            &*self.command_repo,
            &*self.pattern_repo,
            &*self.intention_repo
        );
        let context = use_case.execute().await?;
        
        // Save to file
        let output_path = std::env::current_dir()?.join(".termbrain-context.md");
        std::fs::write(&output_path, context)?;
        
        println!("✓ AI context generated: {}", output_path.display());
        Ok(())
    }
    
    // Project analysis
    pub async fn analyze_project(&self) -> Result<()> {
        let use_case = application::use_cases::AnalyzeProject::new(&*self.command_repo);
        let analysis = use_case.execute().await?;
        presentation::cli::display_project_analysis(analysis);
        Ok(())
    }
    
    // Shell integration
    pub async fn init_shell(&self, shell: Option<String>) -> Result<()> {
        use crate::infrastructure::shell::ShellHooks;
        
        let shell = shell.or_else(|| std::env::var("SHELL").ok())
            .ok_or_else(|| anyhow::anyhow!("Could not detect shell"))?;
        
        let hooks = if shell.contains("bash") {
            ShellHooks::bash_hooks()
        } else if shell.contains("zsh") {
            ShellHooks::zsh_hooks()
        } else if shell.contains("fish") {
            ShellHooks::fish_hooks()
        } else {
            anyhow::bail!("Unsupported shell: {}", shell);
        };
        
        println!("{}", hooks);
        Ok(())
    }
    
    // System status
    pub async fn show_status(&self) -> Result<()> {
        let count = self.command_repo.count().await?;
        let workflows = self.workflow_repo.list().await?.len();
        
        println!("🧠 Termbrain Status");
        println!("  Version: {}", env!("CARGO_PKG_VERSION"));
        println!("  Commands recorded: {}", count);
        println!("  Workflows: {}", workflows);
        println!("  Predictive mode: {}", 
            if self.config.predictive_mode() { "on" } else { "off" }
        );
        
        Ok(())
    }
    
    // Enable/disable recording
    pub async fn enable_recording(&self) -> Result<()> {
        std::env::remove_var("TERMBRAIN_DISABLED");
        println!("✓ Command recording enabled");
        Ok(())
    }
    
    pub async fn disable_recording(&self) -> Result<()> {
        std::env::set_var("TERMBRAIN_DISABLED", "1");
        println!("✓ Command recording disabled");
        Ok(())
    }
    
    // Show help
    pub async fn show_help(&self) -> Result<()> {
        presentation::cli::display_help();
        Ok(())
    }
    
    // Predictive analysis
    pub async fn predict_command(&self, command: &str) -> Result<()> {
        use crate::domain::services::PredictionEngine;
        
        let engine = PredictionEngine::new();
        
        // Check for safety warnings
        if let Some(warning) = engine.check_dangerous_command(command).await {
            use colored::*;
            println!("{}", "⚠️  Safety Warning".red().bold());
            println!("{}", warning.message.red());
            println!("Suggestion: {}", warning.suggestion.yellow());
        }
        
        // Get predictions if predictive mode is enabled
        if self.config.predictive_mode() {
            let recent_commands = self.command_repo.get_recent(100).await?;
            let current_dir = std::env::current_dir()?.to_string_lossy().to_string();
            
            let predictions = engine.predict_next_command(&recent_commands, &current_dir).await;
            
            if !predictions.is_empty() {
                println!("\n🔮 Predicted next commands:");
                for (idx, pred) in predictions.iter().enumerate() {
                    println!("  {}. {} (confidence: {:.0}%)",
                        idx + 1,
                        pred.command,
                        pred.confidence * 100.0
                    );
                    println!("     {}", pred.reason);
                }
            }
        }
        
        Ok(())
    }
    
    // Growth analytics
    pub async fn show_growth_analytics(&self) -> Result<()> {
        let use_case = application::use_cases::AnalyzeGrowth::new(&*self.command_repo);
        let analytics = use_case.execute().await?;
        presentation::cli::display_growth_analytics(analytics);
        Ok(())
    }
    
    // Explain recent commands
    pub async fn explain_recent_commands(&self, limit: usize) -> Result<()> {
        let use_case = application::use_cases::ExplainCommands::new(&*self.command_repo);
        let explanations = use_case.execute(limit).await?;
        presentation::cli::display_command_explanations(explanations);
        Ok(())
    }
    
    // Show suggestions
    pub async fn show_suggestions(&self) -> Result<()> {
        let use_case = application::use_cases::GenerateSuggestions::new(
            &*self.command_repo,
            &*self.pattern_repo
        );
        let suggestions = use_case.execute().await?;
        presentation::cli::display_suggestions(suggestions);
        Ok(())
    }
    
    // Show workflow details
    pub async fn show_workflow(&self, name: &str) -> Result<()> {
        let workflow = self.workflow_repo
            .get_by_name(name)
            .await?
            .ok_or_else(|| anyhow::anyhow!("Workflow '{}' not found", name))?;
        
        println!("🔧 Workflow: {}", workflow.name);
        println!("📝 Description: {}", workflow.description);
        println!("🔢 Executed: {} times", workflow.execution_count);
        println!("\n📋 Commands:");
        for (idx, cmd) in workflow.commands.iter().enumerate() {
            println!("  {}. {}", idx + 1, cmd);
        }
        Ok(())
    }
    
    // Detect workflow patterns
    pub async fn detect_workflow_patterns(&self) -> Result<()> {
        use crate::domain::services::PatternDetector;
        
        let detector = PatternDetector::new(&*self.command_repo, &*self.pattern_repo);
        let patterns = detector.detect_patterns(3).await?;
        
        if patterns.is_empty() {
            println!("No recurring patterns found yet. Keep using termbrain!");
        } else {
            println!("🔍 Detected Workflow Patterns:\n");
            for pattern in patterns {
                println!("Pattern: {}", pattern.pattern);
                println!("Frequency: {} times", pattern.frequency);
                if let Some(workflow) = &pattern.suggested_workflow {
                    println!("Suggested name: {}", workflow);
                }
                println!();
            }
        }
        Ok(())
    }
    
    // Analyze architecture
    pub async fn analyze_architecture(&self) -> Result<()> {
        let project_analysis = {
            let use_case = application::use_cases::AnalyzeProject::new(&*self.command_repo);
            use_case.execute().await?
        };
        
        println!("🏗️  Architecture Analysis\n");
        println!("Project Type: {:?}", project_analysis.project_type);
        println!("Primary Language: {}", project_analysis.primary_language);
        
        // Analyze command patterns for architecture insights
        let recent_commands = self.command_repo.get_recent(500).await?;
        let mut architecture_hints = Vec::new();
        
        // Check for microservices patterns
        let docker_commands = recent_commands.iter()
            .filter(|c| c.command.contains("docker"))
            .count();
        if docker_commands > 10 {
            architecture_hints.push("Containerized/Microservices architecture detected");
        }
        
        // Check for monorepo patterns
        let distinct_dirs: std::collections::HashSet<_> = recent_commands.iter()
            .map(|c| &c.directory)
            .collect();
        if distinct_dirs.len() > 20 {
            architecture_hints.push("Monorepo or multi-project structure");
        }
        
        // Check for CI/CD patterns
        let ci_commands = recent_commands.iter()
            .filter(|c| c.command.contains("test") || c.command.contains("build") || c.command.contains("deploy"))
            .count();
        if ci_commands > 20 {
            architecture_hints.push("Active CI/CD pipeline usage");
        }
        
        if !architecture_hints.is_empty() {
            println!("\nArchitecture Patterns:");
            for hint in architecture_hints {
                println!("• {}", hint);
            }
        }
        
        Ok(())
    }
    
    // Explore patterns
    pub async fn explore_patterns(&self, pattern: Option<&str>) -> Result<()> {
        use crate::domain::services::PatternDetector;
        
        let detector = PatternDetector::new(&*self.command_repo, &*self.pattern_repo);
        
        if let Some(p) = pattern {
            println!("🔍 Exploring pattern: {}\n", p);
            let similar = detector.find_similar_patterns(p).await?;
            
            if similar.is_empty() {
                println!("No similar patterns found.");
            } else {
                for pattern in similar {
                    println!("Pattern: {}", pattern.pattern);
                    println!("Frequency: {} times", pattern.frequency);
                    println!();
                }
            }
        } else {
            println!("🔍 All Command Patterns:\n");
            let patterns = detector.detect_patterns(2).await?;
            
            for pattern in patterns.iter().take(10) {
                println!("• {} ({}x)", pattern.pattern, pattern.frequency);
            }
        }
        
        Ok(())
    }
    
    // Show productivity metrics
    pub async fn show_productivity_metrics(&self) -> Result<()> {
        let stats = {
            let use_case = application::use_cases::GenerateStats::new(&*self.command_repo);
            use_case.execute("week").await?
        };
        
        let recent_commands = self.command_repo.get_recent(1000).await?;
        
        println!("📊 Productivity Metrics\n");
        
        // Commands per day
        let days = 7;
        let commands_per_day = stats.total_commands as f64 / days as f64;
        println!("📈 Commands per day: {:.1}", commands_per_day);
        
        // Success rate trend
        println!("✅ Success rate: {:.1}%", stats.success_rate * 100.0);
        
        // Time efficiency
        println!("⏱️  Average command duration: {:.0}ms", stats.average_duration_ms);
        
        // Peak hours
        let mut hourly_activity: std::collections::HashMap<u8, usize> = std::collections::HashMap::new();
        for cmd in &recent_commands {
            let hour = cmd.timestamp.hour() as u8;
            *hourly_activity.entry(hour).or_insert(0) += 1;
        }
        
        let mut hours: Vec<_> = hourly_activity.into_iter().collect();
        hours.sort_by_key(|(_, count)| std::cmp::Reverse(*count));
        
        println!("\n🕐 Most productive hours:");
        for (hour, count) in hours.iter().take(3) {
            println!("  {}:00 - {}:00: {} commands", hour, hour + 1, count);
        }
        
        // Complexity trend
        let complex_commands = recent_commands.iter()
            .filter(|c| c.complexity >= 3)
            .count();
        let complexity_ratio = complex_commands as f64 / recent_commands.len() as f64;
        
        println!("\n🧩 Command complexity: {:.1}% complex commands", complexity_ratio * 100.0);
        
        Ok(())
    }
}