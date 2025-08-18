use anyhow::Result;
use clap::{Parser, Subcommand};
use termbrain::TermbrainApp;

#[derive(Parser)]
#[command(
    name = "termbrain",
    about = "The Terminal That Never Forgets",
    version,
    author,
    long_about = "Your AI-powered command-line memory that learns from your terminal usage"
)]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(Subcommand)]
enum Commands {
    /// Search through command history
    Search {
        /// Search query
        query: String,
        /// Maximum number of results
        #[arg(short, long, default_value = "50")]
        limit: usize,
    },
    
    /// Show statistics about command usage
    Stats {
        /// Time range (today, week, month, all)
        #[arg(short, long, default_value = "week")]
        range: String,
    },
    
    /// Show command history
    History {
        /// Filter by semantic type
        #[arg(short = 't', long)]
        semantic_type: Option<String>,
        /// Maximum number of results
        #[arg(short, long, default_value = "50")]
        limit: usize,
    },
    
    /// Show commands by semantic type
    Type {
        /// Semantic type to filter by
        semantic_type: String,
        /// Maximum number of results
        #[arg(short, long, default_value = "50")]
        limit: usize,
    },
    
    /// Manage workflows
    Workflow {
        #[command(subcommand)]
        action: WorkflowCommands,
    },
    
    /// Track intention for current session
    Intend {
        /// What you intend to accomplish
        intention: Vec<String>,
    },
    
    /// Mark current intention as achieved
    Achieved,
    
    /// Manage flow state
    Flow {
        /// Action (start, end, status)
        #[arg(default_value = "status")]
        action: String,
    },
    
    /// View learning and growth analytics
    Growth,
    
    /// Get personalized suggestions
    Suggest,
    
    /// Export command history
    Export {
        /// Export format (json, csv, md, sql)
        format: String,
        /// Output file path
        output: String,
    },
    
    /// Enable/disable predictive mode
    Predictive {
        /// on/off/toggle
        #[arg(default_value = "toggle")]
        mode: String,
    },
    
    /// Generate AI context for current project
    #[command(alias = "ai")]
    Context {
        /// Optional query for context
        query: Option<String>,
    },
    
    /// Analyze current project
    Project,
    
    /// Explain recent commands
    Why {
        /// Number of commands to explain
        #[arg(default_value = "5")]
        limit: usize,
    },
    
    /// Analyze project architecture
    Arch,
    
    /// Explore command patterns
    Explore {
        /// Pattern to explore
        pattern: Option<String>,
    },
    
    /// Show productivity metrics
    Productivity,
    
    /// Show termbrain status
    Status,
    
    /// Enable command recording
    Enable,
    
    /// Disable command recording
    Disable,
    
    /// Initialize shell integration
    Init {
        /// Shell type (bash, zsh, fish)
        #[arg(long)]
        shell: Option<String>,
    },
    
    // Internal commands (not shown in help)
    #[command(hide = true)]
    BeforeCommand {
        command: String,
    },
    
    #[command(hide = true)]
    AfterCommand {
        exit_code: i32,
    },
    
    #[command(hide = true)]
    Record {
        command: String,
        directory: String,
        exit_code: i32,
        duration_ms: u64,
    },
    
    #[command(hide = true)]
    Predict {
        command: String,
    },
}

#[derive(Subcommand)]
enum WorkflowCommands {
    /// Create a new workflow
    Create {
        /// Workflow name
        name: String,
        /// Workflow description
        description: String,
        /// Commands to execute
        commands: Vec<String>,
    },
    
    /// List all workflows
    List,
    
    /// Show workflow details
    Show {
        /// Workflow name
        name: String,
    },
    
    /// Run a workflow
    Run {
        /// Workflow name
        name: String,
    },
    
    /// Delete a workflow
    Delete {
        /// Workflow name
        name: String,
    },
    
    /// Find workflow patterns
    Patterns,
}

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::from_default_env()
                .add_directive(tracing::Level::WARN.into())
        )
        .init();
    
    let cli = Cli::parse();
    let mut app = TermbrainApp::new().await?;
    
    match cli.command {
        Some(Commands::Search { query, limit }) => {
            app.search(&query, limit).await?;
        }
        
        Some(Commands::Stats { range }) => {
            app.show_stats(&range).await?;
        }
        
        Some(Commands::History { semantic_type, limit }) => {
            app.show_history(semantic_type.as_deref(), limit).await?;
        }
        
        Some(Commands::Type { semantic_type, limit }) => {
            app.show_history(Some(&semantic_type), limit).await?;
        }
        
        Some(Commands::Workflow { action }) => {
            match action {
                WorkflowCommands::Create { name, description, commands } => {
                    app.create_workflow(&name, &description, commands).await?;
                }
                WorkflowCommands::List => {
                    app.list_workflows().await?;
                }
                WorkflowCommands::Show { name } => {
                    app.show_workflow(&name).await?;
                }
                WorkflowCommands::Run { name } => {
                    app.run_workflow(&name).await?;
                }
                WorkflowCommands::Delete { name } => {
                    app.delete_workflow(&name).await?;
                }
                WorkflowCommands::Patterns => {
                    app.detect_workflow_patterns().await?;
                }
            }
        }
        
        Some(Commands::Intend { intention }) => {
            let intention_text = intention.join(" ");
            app.set_intention(&intention_text).await?;
        }
        
        Some(Commands::Achieved) => {
            app.mark_intention_achieved().await?;
        }
        
        Some(Commands::Flow { action }) => {
            app.flow_command(&action).await?;
        }
        
        Some(Commands::Growth) => {
            app.show_growth_analytics().await?;
        }
        
        Some(Commands::Suggest) => {
            app.show_suggestions().await?;
        }
        
        Some(Commands::Export { format, output }) => {
            app.export(&format, &output).await?;
        }
        
        Some(Commands::Predictive { mode }) => {
            app.set_predictive_mode(&mode).await?;
        }
        
        Some(Commands::Context { query }) => {
            if let Some(q) = query {
                println!("Generating AI context for: {}", q);
            }
            app.generate_ai_context().await?;
        }
        
        Some(Commands::Project) => {
            app.analyze_project().await?;
        }
        
        Some(Commands::Why { limit }) => {
            app.explain_recent_commands(limit).await?;
        }
        
        Some(Commands::Arch) => {
            app.analyze_architecture().await?;
        }
        
        Some(Commands::Explore { pattern }) => {
            app.explore_patterns(pattern.as_deref()).await?;
        }
        
        Some(Commands::Productivity) => {
            app.show_productivity_metrics().await?;
        }
        
        Some(Commands::Status) => {
            app.show_status().await?;
        }
        
        Some(Commands::Enable) => {
            app.enable_recording().await?;
        }
        
        Some(Commands::Disable) => {
            app.disable_recording().await?;
        }
        
        Some(Commands::Init { shell }) => {
            app.init_shell(shell).await?;
        }
        
        // Internal commands for shell hooks
        Some(Commands::BeforeCommand { command }) => {
            use termbrain::infrastructure::shell::CommandCapture;
            CommandCapture::before_command(&command)?;
        }
        
        Some(Commands::AfterCommand { exit_code }) => {
            use termbrain::infrastructure::shell::CommandCapture;
            CommandCapture::after_command(exit_code)?;
        }
        
        Some(Commands::Record { command, directory, exit_code, duration_ms }) => {
            app.record_command(&command, &directory, exit_code, duration_ms).await?;
        }
        
        Some(Commands::Predict { command }) => {
            app.predict_command(&command).await?;
        }
        
        None => {
            app.show_help().await?;
        }
    }
    
    Ok(())
}