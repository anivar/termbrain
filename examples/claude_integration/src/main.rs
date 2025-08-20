use anyhow::Result;
use clap::{Parser, Subcommand};
use dotenv::dotenv;
use std::env;
use tracing::{info, warn};

mod claude_client;
mod analyzer;
mod sanitizer;
mod cache;
mod config;

use claude_client::ClaudeClient;
use analyzer::CommandAnalyzer;
use sanitizer::CommandSanitizer;

#[derive(Parser)]
#[command(name = "claude-analyzer")]
#[command(about = "AI-powered command analysis using Claude")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
    
    /// Enable verbose logging
    #[arg(short, long)]
    verbose: bool,
    
    /// Configuration file path
    #[arg(short, long)]
    config: Option<String>,
}

#[derive(Subcommand)]
enum Commands {
    /// Analyze a specific command
    Analyze {
        /// The command to analyze
        command: String,
        
        /// Include execution context
        #[arg(long)]
        with_context: bool,
        
        /// Output format
        #[arg(long, default_value = "pretty")]
        format: String,
    },
    
    /// Get command suggestions based on history
    Suggest {
        /// Context for suggestions (e.g., "git workflow", "docker")
        #[arg(long)]
        context: Option<String>,
        
        /// Number of suggestions
        #[arg(short, long, default_value = "5")]
        limit: usize,
    },
    
    /// Diagnose failed commands
    Diagnose {
        /// The failed command
        #[arg(long)]
        command: String,
        
        /// Exit code of the failed command
        #[arg(long)]
        exit_code: i32,
        
        /// Error output (if available)
        #[arg(long)]
        error: Option<String>,
    },
    
    /// Learn about command categories or topics
    Learn {
        /// Topic to learn about
        #[arg(long)]
        topic: String,
        
        /// Skill level (beginner, intermediate, advanced)
        #[arg(long, default_value = "intermediate")]
        level: String,
    },
    
    /// Discover patterns in command history
    Patterns {
        /// Time period to analyze (days)
        #[arg(long, default_value = "7")]
        days: u32,
        
        /// Minimum confidence threshold
        #[arg(long, default_value = "0.7")]
        confidence: f32,
    },
    
    /// Generate daily summary report
    Summary {
        /// Date to summarize (YYYY-MM-DD, default: today)
        #[arg(long)]
        date: Option<String>,
        
        /// Include productivity insights
        #[arg(long)]
        productivity: bool,
    },
    
    /// Manage cache and configuration
    Cache {
        #[command(subcommand)]
        action: CacheAction,
    },
    
    /// Check system status
    Status,
}

#[derive(Subcommand)]
enum CacheAction {
    /// Clear analysis cache
    Clear,
    /// Show cache statistics
    Stats,
    /// Warm up cache with recent commands
    Warmup,
}

#[tokio::main]
async fn main() -> Result<()> {
    // Load environment variables
    dotenv().ok();
    
    let cli = Cli::parse();
    
    // Initialize logging
    let log_level = if cli.verbose { "debug" } else { "info" };
    tracing_subscriber::fmt()
        .with_env_filter(format!("claude_integration_example={}", log_level))
        .init();
    
    // Load configuration
    let config = config::load_config(cli.config.as_deref())?;
    
    // Initialize components
    let claude_client = ClaudeClient::new(&config).await?;
    let sanitizer = CommandSanitizer::new(&config);
    let analyzer = CommandAnalyzer::new(claude_client, sanitizer, config).await?;
    
    // Execute command
    match cli.command {
        Commands::Analyze { command, with_context, format } => {
            info!("Analyzing command: {}", command);
            let analysis = analyzer.analyze_command(&command, with_context).await?;
            display_analysis(&analysis, &format);
        }
        
        Commands::Suggest { context, limit } => {
            info!("Generating suggestions with context: {:?}", context);
            let suggestions = analyzer.get_suggestions(context.as_deref(), limit).await?;
            display_suggestions(&suggestions);
        }
        
        Commands::Diagnose { command, exit_code, error } => {
            info!("Diagnosing failed command: {} (exit code: {})", command, exit_code);
            let diagnosis = analyzer.diagnose_failure(&command, exit_code, error.as_deref()).await?;
            display_diagnosis(&diagnosis);
        }
        
        Commands::Learn { topic, level } => {
            info!("Learning about topic: {} (level: {})", topic, level);
            let learning_content = analyzer.learn_topic(&topic, &level).await?;
            display_learning_content(&learning_content);
        }
        
        Commands::Patterns { days, confidence } => {
            info!("Analyzing patterns for {} days with confidence >= {}", days, confidence);
            let patterns = analyzer.discover_patterns(days, confidence).await?;
            display_patterns(&patterns);
        }
        
        Commands::Summary { date, productivity } => {
            info!("Generating summary for date: {:?}", date);
            let summary = analyzer.generate_summary(date.as_deref(), productivity).await?;
            display_summary(&summary);
        }
        
        Commands::Cache { action } => {
            handle_cache_action(&analyzer, action).await?;
        }
        
        Commands::Status => {
            display_status(&analyzer).await?;
        }
    }
    
    Ok(())
}

fn display_analysis(analysis: &analyzer::CommandAnalysis, format: &str) {
    match format {
        "json" => {
            println!("{}", serde_json::to_string_pretty(analysis).unwrap());
        }
        "pretty" | _ => {
            println!("🔍 Command Analysis\n");
            println!("📝 **Command**: `{}`\n", analysis.command);
            
            if let Some(explanation) = &analysis.explanation {
                println!("📖 **Explanation**:");
                println!("{}\n", explanation);
            }
            
            if !analysis.suggestions.is_empty() {
                println!("💡 **Suggestions**:");
                for (i, suggestion) in analysis.suggestions.iter().enumerate() {
                    println!("{}. {}", i + 1, suggestion);
                }
                println!();
            }
            
            if let Some(complexity) = &analysis.complexity {
                println!("⚡ **Complexity**: {}", complexity);
            }
            
            if !analysis.alternatives.is_empty() {
                println!("🔄 **Alternatives**:");
                for alt in &analysis.alternatives {
                    println!("• `{}`", alt);
                }
                println!();
            }
            
            if let Some(security_notes) = &analysis.security_notes {
                println!("🔐 **Security Notes**:");
                println!("{}\n", security_notes);
            }
        }
    }
}

fn display_suggestions(suggestions: &[analyzer::CommandSuggestion]) {
    println!("🤖 AI Suggestions\n");
    
    for (i, suggestion) in suggestions.iter().enumerate() {
        println!("{}. **{}**", i + 1, suggestion.title);
        println!("   `{}`", suggestion.command);
        if let Some(description) = &suggestion.description {
            println!("   {}", description);
        }
        println!();
    }
}

fn display_diagnosis(diagnosis: &analyzer::CommandDiagnosis) {
    println!("❌ Error Diagnosis\n");
    println!("🔍 **Command**: `{}`", diagnosis.command);
    println!("📊 **Exit Code**: {}\n", diagnosis.exit_code);
    
    if !diagnosis.likely_causes.is_empty() {
        println!("🔍 **Likely Causes**:");
        for (i, cause) in diagnosis.likely_causes.iter().enumerate() {
            println!("{}. {}", i + 1, cause);
        }
        println!();
    }
    
    if !diagnosis.suggested_fixes.is_empty() {
        println!("🛠️ **Suggested Fixes**:");
        for (i, fix) in diagnosis.suggested_fixes.iter().enumerate() {
            println!("{}. {}", i + 1, fix);
        }
        println!();
    }
    
    if !diagnosis.prevention_tips.is_empty() {
        println!("🛡️ **Prevention Tips**:");
        for tip in &diagnosis.prevention_tips {
            println!("• {}", tip);
        }
        println!();
    }
}

fn display_learning_content(content: &analyzer::LearningContent) {
    println!("📚 Learning: {}\n", content.topic);
    
    if let Some(overview) = &content.overview {
        println!("📖 **Overview**:");
        println!("{}\n", overview);
    }
    
    if !content.key_concepts.is_empty() {
        println!("🔑 **Key Concepts**:");
        for concept in &content.key_concepts {
            println!("• {}", concept);
        }
        println!();
    }
    
    if !content.examples.is_empty() {
        println!("💡 **Examples**:");
        for example in &content.examples {
            println!("```");
            println!("{}", example.command);
            println!("```");
            if let Some(explanation) = &example.explanation {
                println!("{}\n", explanation);
            }
        }
    }
    
    if !content.next_steps.is_empty() {
        println!("🚀 **Next Steps**:");
        for (i, step) in content.next_steps.iter().enumerate() {
            println!("{}. {}", i + 1, step);
        }
        println!();
    }
}

fn display_patterns(patterns: &[analyzer::CommandPattern]) {
    println!("🔄 Discovered Patterns\n");
    
    for pattern in patterns {
        println!("**{}** (Confidence: {:.1}%)", pattern.name, pattern.confidence * 100.0);
        println!("📋 Description: {}", pattern.description);
        
        if !pattern.commands.is_empty() {
            println!("🔗 Command sequence:");
            for (i, cmd) in pattern.commands.iter().enumerate() {
                if i == pattern.commands.len() - 1 {
                    println!("   └─ `{}`", cmd);
                } else {
                    println!("   ├─ `{}`", cmd);
                }
            }
        }
        
        println!("📊 Frequency: {} times", pattern.frequency);
        
        if let Some(suggestion) = &pattern.optimization_suggestion {
            println!("💡 Optimization: {}", suggestion);
        }
        
        println!();
    }
}

fn display_summary(summary: &analyzer::DailySummary) {
    println!("📊 Daily Command Summary - Powered by Claude\n");
    println!("🕒 **Date**: {} ({} commands executed)\n", summary.date, summary.total_commands);
    
    if !summary.top_activities.is_empty() {
        println!("🏆 **Top Activities**:");
        for activity in &summary.top_activities {
            println!("• {} ({}%) - {}", activity.category, activity.percentage, activity.description);
        }
        println!();
    }
    
    if let Some(insights) = &summary.ai_insights {
        println!("💡 **AI Insights**:");
        println!("{}\n", insights);
    }
    
    if !summary.suggestions.is_empty() {
        println!("🎯 **Suggestions for Tomorrow**:");
        for suggestion in &summary.suggestions {
            println!("• {}", suggestion);
        }
        println!();
    }
    
    if let Some(learning_opportunity) = &summary.learning_opportunity {
        println!("🚀 **Learning Opportunity**:");
        println!("{}\n", learning_opportunity);
    }
    
    if let Some(productivity) = &summary.productivity_score {
        println!("📈 **Productivity Score**: {:.1}/10", productivity);
    }
}

async fn handle_cache_action(analyzer: &CommandAnalyzer, action: CacheAction) -> Result<()> {
    match action {
        CacheAction::Clear => {
            analyzer.clear_cache().await?;
            println!("✅ Cache cleared successfully");
        }
        CacheAction::Stats => {
            let stats = analyzer.get_cache_stats().await?;
            println!("📊 Cache Statistics:");
            println!("• Entries: {}", stats.entry_count);
            println!("• Hit rate: {:.1}%", stats.hit_rate * 100.0);
            println!("• Size: {}", stats.size_mb);
        }
        CacheAction::Warmup => {
            println!("🔥 Warming up cache...");
            let warmed = analyzer.warmup_cache().await?;
            println!("✅ Warmed up {} entries", warmed);
        }
    }
    Ok(())
}

async fn display_status(analyzer: &CommandAnalyzer) -> Result<()> {
    println!("🔍 Claude Integration Status\n");
    
    // Check API connectivity
    match analyzer.test_api_connection().await {
        Ok(_) => println!("✅ Claude API: Connected"),
        Err(e) => {
            println!("❌ Claude API: Failed - {}", e);
            warn!("API connection failed: {}", e);
        }
    }
    
    // Check TermBrain data access
    match analyzer.test_termbrain_access().await {
        Ok(command_count) => println!("✅ TermBrain Data: {} commands available", command_count),
        Err(e) => {
            println!("❌ TermBrain Data: Failed - {}", e);
            warn!("TermBrain access failed: {}", e);
        }
    }
    
    // Check cache status
    let cache_stats = analyzer.get_cache_stats().await?;
    println!("📊 Cache: {} entries, {:.1}% hit rate", cache_stats.entry_count, cache_stats.hit_rate * 100.0);
    
    // Check configuration
    let config_status = analyzer.get_config_status();
    println!("⚙️ Configuration: {}", if config_status.is_valid { "Valid" } else { "Issues found" });
    
    if !config_status.warnings.is_empty() {
        println!("\n⚠️ Configuration Warnings:");
        for warning in &config_status.warnings {
            println!("• {}", warning);
        }
    }
    
    Ok(())
}