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
    Context,
    
    /// Analyze current project
    Project,
    
    /// Initialize shell integration
    Init {
        /// Shell type (bash, zsh, fish)
        #[arg(long)]
        shell: Option<String>,
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
}

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt::init();
    
    let cli = Cli::parse();
    let mut app = TermbrainApp::new().await?;
    
    match cli.command {
        Some(Commands::Search { query, limit }) => {
            app.search(&query, limit).await?;
        }
        Some(Commands::Stats { range }) => {
            app.show_stats(&range).await?;
        }
        Some(Commands::Workflow { action }) => {
            match action {
                WorkflowCommands::Create { name, description, commands } => {
                    app.create_workflow(&name, &description, commands).await?;
                }
                WorkflowCommands::List => {
                    app.list_workflows().await?;
                }
                WorkflowCommands::Run { name } => {
                    app.run_workflow(&name).await?;
                }
                WorkflowCommands::Delete { name } => {
                    app.delete_workflow(&name).await?;
                }
            }
        }
        Some(Commands::Intend { intention }) => {
            let intention_text = intention.join(" ");
            app.set_intention(&intention_text).await?;
        }
        Some(Commands::Export { format, output }) => {
            app.export(&format, &output).await?;
        }
        Some(Commands::Predictive { mode }) => {
            app.set_predictive_mode(&mode).await?;
        }
        Some(Commands::Context) => {
            app.generate_ai_context().await?;
        }
        Some(Commands::Project) => {
            app.analyze_project().await?;
        }
        Some(Commands::Init { shell }) => {
            app.init_shell(shell).await?;
        }
        None => {
            // No command provided, show help
            app.show_help().await?;
        }
    }
    
    Ok(())
}