use anyhow::Result;
use clap::Parser;

#[derive(Parser)]
#[command(name = "termbrain", version, about = "Terminal command memory")]
struct Cli {
    #[command(subcommand)]
    command: Option<Commands>,
}

#[derive(clap::Subcommand)]
enum Commands {
    /// Show version
    Version,
}

#[tokio::main]
async fn main() -> Result<()> {
    tracing_subscriber::fmt::init();
    
    let cli = Cli::parse();
    
    match cli.command {
        Some(Commands::Version) => {
            println!("termbrain {}", env!("CARGO_PKG_VERSION"));
        }
        None => {
            println!("TermBrain v{}", env!("CARGO_PKG_VERSION"));
            println!("Use --help for usage information");
        }
    }
    
    Ok(())
}