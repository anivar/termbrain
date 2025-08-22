use anyhow::Result;
use clap::{Parser, Subcommand};

mod commands;
mod config;
mod logging;
mod garbage_collector;
mod shutdown;

use commands::*;
use shutdown::ShutdownManager;

#[derive(Parser)]
#[command(
    name = "termbrain",
    version,
    about = "The Terminal That Never Forgets - Your AI-powered command-line memory"
)]
#[command(long_about = r#"
TermBrain is an intelligent terminal command memory system that:
• Records and analyzes your command history
• Provides semantic search across commands
• Detects usage patterns and suggests workflows
• Integrates seamlessly with your shell

Use 'tb <command>' as shorthand for 'termbrain <command>'"#)]
struct Cli {
    /// Enable verbose output
    #[arg(short, long, global = true)]
    verbose: bool,

    /// Output format
    #[arg(long, value_enum, default_value = "table", global = true)]
    format: OutputFormat,

    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Record a command execution
    #[command(alias = "r")]
    Record {
        /// The command that was executed
        #[arg(required = true)]
        command: Vec<String>,

        /// Exit code of the command
        #[arg(short, long, default_value = "0")]
        exit_code: i32,

        /// Duration in milliseconds
        #[arg(long)]
        duration: Option<u64>,

        /// Working directory
        #[arg(short, long)]
        directory: Option<String>,
    },

    /// Search command history
    #[command(alias = "s")]
    Search {
        /// Search query
        query: String,

        /// Limit number of results
        #[arg(short, long, default_value = "10")]
        limit: usize,

        /// Search in specific directory
        #[arg(short, long)]
        directory: Option<String>,

        /// Search from specific date
        #[arg(long)]
        since: Option<String>,

        /// Use semantic search
        #[arg(long)]
        semantic: bool,
    },

    /// Show recent command history
    #[command(alias = "h")]
    History {
        /// Number of commands to show
        #[arg(short, long, default_value = "20")]
        limit: usize,

        /// Show only successful commands
        #[arg(long)]
        success_only: bool,

        /// Filter by directory
        #[arg(short, long)]
        directory: Option<String>,
        
        /// Filter by AI agent
        #[arg(long)]
        ai_agent: Option<String>,
    },

    /// Show usage statistics
    #[command(alias = "stats")]
    Statistics {
        /// Time period (day, week, month, year)
        #[arg(short, long, default_value = "week")]
        period: String,

        /// Show top N commands
        #[arg(short, long, default_value = "10")]
        top: usize,
    },

    /// Detect and show usage patterns
    #[command(alias = "p")]
    Patterns {
        /// Minimum confidence threshold (0.0-1.0)
        #[arg(short, long, default_value = "0.5")]
        confidence: f32,

        /// Show only specific pattern type
        #[arg(short, long)]
        pattern_type: Option<String>,
    },

    /// Manage workflows
    #[command(alias = "w")]
    Workflow {
        #[command(subcommand)]
        action: WorkflowAction,
    },

    /// Export command data
    Export {
        /// Output file path
        #[arg(short, long)]
        output: String,

        /// Export format (json, csv, markdown)
        #[arg(long = "export-format", value_enum, default_value = "json")]
        export_format: ExportFormat,

        /// Date range
        #[arg(long)]
        since: Option<String>,
        #[arg(long)]
        until: Option<String>,
    },

    /// Setup shell integration
    #[command(alias = "setup")]
    Install {
        /// Shell type (bash, zsh, fish)
        #[arg(short, long)]
        shell: Option<String>,

        /// Skip confirmation prompts
        #[arg(short, long)]
        yes: bool,
    },

    /// Remove TermBrain and clean up files
    Uninstall {
        /// Remove all data including command history
        #[arg(long)]
        purge: bool,

        /// Skip confirmation prompts
        #[arg(short, long)]
        yes: bool,
    },
    
    /// Wrap and monitor AI agent execution
    Wrap {
        /// AI agent name (e.g., aider, continue, cursor)
        #[arg(long)]
        ai_agent: String,
        
        /// Context description for this session
        #[arg(long)]
        context: Option<String>,
        
        /// Command to execute with monitoring
        #[arg(last = true)]
        command: Vec<String>,
    },

    /// Start interactive session
    #[command(alias = "i")]
    Interactive,

    /// Show system status
    Status,
}

#[derive(Subcommand)]
enum WorkflowAction {
    /// List all workflows
    List,
    /// Create a new workflow
    Create { name: String },
    /// Run a workflow
    Run { name: String },
    /// Delete a workflow
    Delete { name: String },
}

#[derive(clap::ValueEnum, Clone, Debug)]
enum OutputFormat {
    Table,
    Json,
    Csv,
    Plain,
}

#[derive(clap::ValueEnum, Clone, Debug)]
enum ExportFormat {
    Json,
    Csv,
    Markdown,
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();

    // Load configuration
    let config = match config::Config::load() {
        Ok(cfg) => cfg,
        Err(e) => {
            eprintln!("Warning: Failed to load config: {}", e);
            config::Config::default()
        }
    };

    // Initialize logging with rotation
    logging::init_logging(&config)?;
    
    // Initialize shutdown manager
    let shutdown_manager = ShutdownManager::new();
    shutdown_manager.listen_for_shutdown().await?;
    
    // Start background tasks
    let mut background_tasks = vec![];
    
    
    // Start garbage collector if not in one-shot commands
    if !matches!(cli.command, Some(Commands::Status) | Some(Commands::Export { .. }) | None) {
        let storage = termbrain_storage::SqliteStorage::new(&config.database_path).await?;
        let gc = garbage_collector::GarbageCollector::new(
            storage,
            config.max_database_size_mb,
            config.retention_days,
        );
        
        let gc_handle = tokio::spawn(async move {
            gc.start().await;
        });
        background_tasks.push(gc_handle);
    }

    // Handle commands
    match cli.command {
        Some(Commands::Record {
            command,
            exit_code,
            duration,
            directory,
        }) => {
            record_command(command.join(" "), exit_code, duration, directory).await?;
        }

        Some(Commands::Search {
            query,
            limit,
            directory,
            since,
            semantic,
        }) => {
            search_commands(query, limit, directory, since, semantic, cli.format).await?;
        }

        Some(Commands::History {
            limit,
            success_only,
            directory,
            ai_agent,
        }) => {
            show_history(limit, success_only, directory, ai_agent, cli.format).await?;
        }

        Some(Commands::Statistics { period, top }) => {
            show_statistics(period, top, cli.format).await?;
        }

        Some(Commands::Patterns {
            confidence,
            pattern_type,
        }) => {
            show_patterns(confidence, pattern_type, cli.format).await?;
        }

        Some(Commands::Workflow { action }) => {
            handle_workflow(action, cli.format).await?;
        }

        Some(Commands::Export {
            output,
            export_format,
            since,
            until,
        }) => {
            export_data(output, export_format, since, until).await?;
        }

        Some(Commands::Install { shell, yes }) => {
            install_shell_integration(shell, yes).await?;
        }

        Some(Commands::Uninstall { purge, yes }) => {
            uninstall_termbrain(purge, yes).await?;
        }
        
        Some(Commands::Wrap { ai_agent, context, command }) => {
            wrap_ai_agent(ai_agent, context, command).await?;
        }

        Some(Commands::Interactive) => {
            start_interactive_session().await?;
        }

        Some(Commands::Status) => {
            show_status(cli.format).await?;
        }

        None => {
            show_welcome().await?;
        }
    }

    Ok(())
}
