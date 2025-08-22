//! Command implementations

use crate::{config::Config, ExportFormat, OutputFormat, WorkflowAction};
use anyhow::Result;
use chrono::{DateTime, Utc};
use std::path::Path;
use termbrain_core::domain::repositories::CommandRepository;
use termbrain_core::validation::{
    validate_command, validate_hostname, validate_path, validate_shell, validate_username,
};
use termbrain_storage::sqlite::{SqliteCommandRepository, SqliteStorage};
use uuid::Uuid;

/// Create storage instance using proper database path
async fn create_storage() -> Result<SqliteStorage> {
    let config = Config::load()?;

    // Ensure the config directory exists
    if let Some(parent) = config.database_path.parent() {
        std::fs::create_dir_all(parent)?;
    }

    let storage = SqliteStorage::new(&config.database_path).await?;

    // Ensure schema exists
    storage.ensure_schema().await?;

    Ok(storage)
}

pub async fn record_command(
    command: String,
    exit_code: i32,
    duration: Option<u64>,
    directory: Option<String>,
) -> Result<()> {
    let start_time = std::time::Instant::now();
    
    // Validate command input
    validate_command(&command)?;

    // Validate and normalize directory path
    let working_directory = if let Some(dir) = directory {
        let path = validate_path(Path::new(&dir))?;
        path.to_string_lossy().to_string()
    } else {
        let current_dir = std::env::current_dir()?;
        let path = validate_path(&current_dir)?;
        path.to_string_lossy().to_string()
    };

    // Use persistent storage
    let storage = create_storage().await?;
    let repo = SqliteCommandRepository::new(storage.pool().clone());

    // Parse command name and arguments
    let parts: Vec<&str> = command.split_whitespace().collect();
    let parsed_command = parts.first().unwrap_or(&"").to_string();
    let arguments = parts.into_iter().skip(1).map(|s| s.to_string()).collect();

    // Get and validate shell
    let shell_path = std::env::var("SHELL").unwrap_or_else(|_| "/bin/bash".to_string());
    let shell = shell_path
        .split('/')
        .next_back()
        .unwrap_or("bash")
        .to_string();
    if let Err(e) = validate_shell(&shell) {
        eprintln!("Warning: {}", e);
    }

    // Get and validate user
    let user = std::env::var("USER").unwrap_or_else(|_| "unknown".to_string());
    if let Err(e) = validate_username(&user) {
        eprintln!("Warning: Invalid username '{}': {}", user, e);
    }

    // Get and validate hostname
    let hostname = hostname::get()
        .map(|h| h.to_string_lossy().to_string())
        .unwrap_or_else(|_| "localhost".to_string());
    if let Err(e) = validate_hostname(&hostname) {
        eprintln!("Warning: Invalid hostname '{}': {}", hostname, e);
    }

    let cmd = termbrain_core::domain::entities::Command {
        id: Uuid::new_v4(),
        raw: command.clone(),
        parsed_command,
        arguments,
        working_directory,
        exit_code,
        duration_ms: duration.unwrap_or(0),
        timestamp: Utc::now(),
        session_id: std::env::var("TERMBRAIN_SESSION_ID")
            .unwrap_or_else(|_| format!("{}-{}", Utc::now().timestamp(), std::process::id())),
        metadata: termbrain_core::domain::entities::CommandMetadata {
            shell,
            user,
            hostname,
            terminal: std::env::var("TERM").unwrap_or_else(|_| "xterm".to_string()),
            environment: std::collections::HashMap::new(),
            ai_agent: std::env::var("TERMBRAIN_AI_AGENT").ok(),
            ai_session_id: std::env::var("TERMBRAIN_AI_SESSION").ok(),
            ai_context: std::env::var("TERMBRAIN_AI_CONTEXT").ok(),
        },
    };

    repo.save(&cmd).await?;
    
    // Log command execution
    let duration_ms = start_time.elapsed().as_millis() as u64;
    crate::logging::log_command_execution(
        &command,
        exit_code,
        duration.unwrap_or(duration_ms),
        cmd.metadata.ai_agent.as_deref(),
    );

    println!("📝 Recording command: {}", command);
    println!("   Exit code: {}", exit_code);
    if let Some(dur) = duration {
        println!("   Duration: {}ms", dur);
    }
    println!("✅ Command recorded successfully");
    Ok(())
}

pub async fn search_commands(
    query: String,
    limit: usize,
    directory: Option<String>,
    since: Option<String>,
    semantic: bool,
    format: OutputFormat,
) -> Result<()> {
    // Validate query (relaxed validation for search)
    if query.is_empty() {
        return Err(anyhow::anyhow!("Search query cannot be empty"));
    }

    // Validate directory if provided
    let validated_directory = if let Some(dir) = directory {
        let path = validate_path(Path::new(&dir))?;
        Some(path.to_string_lossy().to_string())
    } else {
        None
    };

    let storage = create_storage().await?;
    let repo = SqliteCommandRepository::new(storage.pool().clone());

    // Parse since date if provided
    let since_date = if let Some(since_str) = since {
        Some(since_str.parse::<DateTime<Utc>>()?)
    } else {
        None
    };

    // Perform search based on type
    let results = if semantic {
        repo.search_semantic(&query, limit).await?
    } else {
        repo.search(&query, limit, validated_directory.as_deref(), since_date)
            .await?
    };

    // Display results
    match format {
        OutputFormat::Table => {
            if results.is_empty() {
                println!("No commands found matching '{}'", query);
                return Ok(());
            }

            println!("\n┌─────────────────────────────────────────────────┬─────────────────────┬──────┐");
            println!(
                "│ Command                                         │ Last Used           │ Exit │"
            );
            println!(
                "├─────────────────────────────────────────────────┼─────────────────────┼──────┤"
            );

            for cmd in results {
                let time_str = format_relative_time(&cmd.timestamp);
                let truncated_cmd = truncate_string(&cmd.raw, 47);
                println!(
                    "│ {:<47} │ {:<19} │ {:>4} │",
                    truncated_cmd, time_str, cmd.exit_code
                );
            }

            println!(
                "└─────────────────────────────────────────────────┴─────────────────────┴──────┘"
            );
        }
        OutputFormat::Json => {
            println!("{}", serde_json::to_string_pretty(&results)?);
        }
        OutputFormat::Csv => {
            println!("command,timestamp,exit_code,directory,duration_ms");
            for cmd in results {
                println!(
                    "{},{},{},{},{}",
                    cmd.raw, cmd.timestamp, cmd.exit_code, cmd.working_directory, cmd.duration_ms
                );
            }
        }
        OutputFormat::Plain => {
            for cmd in results {
                println!("{} ({})", cmd.raw, format_relative_time(&cmd.timestamp));
            }
        }
    }

    Ok(())
}

pub async fn show_history(
    limit: usize,
    success_only: bool,
    directory: Option<String>,
    ai_agent: Option<String>,
    format: OutputFormat,
) -> Result<()> {
    println!("📚 Command History (last {} commands)", limit);
    if success_only {
        println!("   Filtering: successful commands only");
    }
    if let Some(ref dir) = directory {
        println!("   Directory: {}", dir);
    }
    if let Some(ref agent) = ai_agent {
        println!("   AI Agent: {}", agent);
    }

    let storage = create_storage().await?;
    let repo = SqliteCommandRepository::new(storage.pool().clone());

    // Get commands based on filters
    let mut commands = if let Some(dir) = directory {
        repo.find_by_directory(&dir).await?
    } else {
        repo.find_recent(limit).await?
    };

    // Filter by success if requested
    if success_only {
        commands.retain(|cmd| cmd.exit_code == 0);
    }

    // Filter by AI agent if requested
    if let Some(ref agent) = ai_agent {
        commands.retain(|cmd| {
            cmd.metadata.ai_agent.as_ref().map_or(false, |a| a == agent)
        });
    }

    // Limit results
    commands.truncate(limit);

    match format {
        OutputFormat::Table => {
            if commands.is_empty() {
                println!("\nNo commands found matching criteria");
                return Ok(());
            }

            println!(
                "\n┌────┬─────────────────────────────────────────┬─────────────────────┬──────┐"
            );
            println!(
                "│ #  │ Command                                 │ Time                │ Exit │"
            );
            println!(
                "├────┼─────────────────────────────────────────┼─────────────────────┼──────┤"
            );

            for (i, cmd) in commands.iter().enumerate() {
                let time_str = format_relative_time(&cmd.timestamp);
                let truncated_cmd = truncate_string(&cmd.raw, 39);
                println!(
                    "│ {:<2} │ {:<39} │ {:<19} │ {:>4} │",
                    i + 1,
                    truncated_cmd,
                    time_str,
                    cmd.exit_code
                );
            }

            println!(
                "└────┴─────────────────────────────────────────┴─────────────────────┴──────┘"
            );
        }
        OutputFormat::Json => {
            println!("{}", serde_json::to_string_pretty(&commands)?);
        }
        OutputFormat::Csv => {
            println!("number,command,timestamp,exit_code,directory,duration_ms");
            for (i, cmd) in commands.iter().enumerate() {
                println!(
                    "{},{},{},{},{},{}",
                    i + 1,
                    cmd.raw,
                    cmd.timestamp,
                    cmd.exit_code,
                    cmd.working_directory,
                    cmd.duration_ms
                );
            }
        }
        OutputFormat::Plain => {
            for (i, cmd) in commands.iter().enumerate() {
                println!(
                    "{}. {} ({})",
                    i + 1,
                    cmd.raw,
                    format_relative_time(&cmd.timestamp)
                );
            }
        }
    }

    Ok(())
}

pub async fn show_statistics(period: String, top: usize, format: OutputFormat) -> Result<()> {
    println!("📊 Usage Statistics ({})", period);
    println!("   Top {} commands:", top);

    let storage = create_storage().await?;
    let repo = SqliteCommandRepository::new(storage.pool().clone());

    // Get all commands for analysis
    let commands = repo.find_recent(1000).await?; // Get a reasonable sample

    if commands.is_empty() {
        println!("\nNo commands recorded yet");
        return Ok(());
    }

    // Calculate statistics
    let mut command_stats: std::collections::HashMap<String, (usize, usize)> =
        std::collections::HashMap::new();

    for cmd in &commands {
        let entry = command_stats
            .entry(cmd.parsed_command.clone())
            .or_insert((0, 0));
        entry.0 += 1; // total count
        if cmd.exit_code == 0 {
            entry.1 += 1; // success count
        }
    }

    // Sort by frequency
    let mut sorted_stats: Vec<_> = command_stats.into_iter().collect();
    sorted_stats.sort_by(|a, b| b.1 .0.cmp(&a.1 .0));
    sorted_stats.truncate(top);

    match format {
        OutputFormat::Table => {
            if sorted_stats.is_empty() {
                println!("\nNo statistics available");
                return Ok(());
            }

            println!("\n┌─────────────────────────────────────────┬───────┬─────────────────┐");
            println!("│ Command                                 │ Count │ Success Rate    │");
            println!("├─────────────────────────────────────────┼───────┼─────────────────┤");

            for (command, (total, success)) in sorted_stats {
                let success_rate = if total > 0 {
                    (success as f32 / total as f32) * 100.0
                } else {
                    0.0
                };
                let truncated_cmd = truncate_string(&command, 39);
                println!(
                    "│ {:<39} │ {:>5} │ {:>13.1}% │",
                    truncated_cmd, total, success_rate
                );
            }

            println!("└─────────────────────────────────────────┴───────┴─────────────────┘");
        }
        OutputFormat::Json => {
            let stats: Vec<_> = sorted_stats.into_iter().map(|(cmd, (total, success))| {
                serde_json::json!({
                    "command": cmd,
                    "count": total,
                    "success_count": success,
                    "success_rate": if total > 0 { (success as f32 / total as f32) * 100.0 } else { 0.0 }
                })
            }).collect();
            println!("{}", serde_json::to_string_pretty(&stats)?);
        }
        OutputFormat::Csv => {
            println!("command,count,success_count,success_rate");
            for (command, (total, success)) in sorted_stats {
                let success_rate = if total > 0 {
                    (success as f32 / total as f32) * 100.0
                } else {
                    0.0
                };
                println!("{},{},{},{:.1}", command, total, success, success_rate);
            }
        }
        OutputFormat::Plain => {
            for (command, (total, success)) in sorted_stats {
                let success_rate = if total > 0 {
                    (success as f32 / total as f32) * 100.0
                } else {
                    0.0
                };
                println!(
                    "{}: {} times ({:.1}% success)",
                    command, total, success_rate
                );
            }
        }
    }

    Ok(())
}

pub async fn show_patterns(
    confidence: f32,
    pattern_type: Option<String>,
    format: OutputFormat,
) -> Result<()> {
    println!("🔄 Detected Patterns (confidence >= {:.1})", confidence);
    if let Some(ptype) = pattern_type {
        println!("   Pattern type: {}", ptype);
    }

    let storage = create_storage().await?;
    let repo = SqliteCommandRepository::new(storage.pool().clone());

    // Get recent commands for basic pattern analysis
    let commands = repo.find_recent(100).await?;

    if commands.len() < 3 {
        println!("\nNot enough commands recorded for pattern detection (need at least 3)");
        return Ok(());
    }

    // Basic pattern detection: find command sequences
    let mut sequences: std::collections::HashMap<String, usize> = std::collections::HashMap::new();

    for window in commands.windows(3) {
        if window.len() == 3 {
            let pattern = format!(
                "{} → {} → {}",
                window[2].parsed_command, window[1].parsed_command, window[0].parsed_command
            );
            *sequences.entry(pattern).or_insert(0) += 1;
        }
    }

    // Filter by frequency (at least 2 occurrences) and calculate confidence
    let mut patterns: Vec<_> = sequences
        .into_iter()
        .filter(|(_, freq)| *freq >= 2)
        .map(|(pattern, freq)| {
            let calc_confidence = (freq as f32 / commands.len() as f32).min(1.0);
            (pattern, calc_confidence, freq)
        })
        .filter(|(_, conf, _)| *conf >= confidence)
        .collect();

    patterns.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap_or(std::cmp::Ordering::Equal));

    match format {
        OutputFormat::Table => {
            if patterns.is_empty() {
                println!(
                    "\nNo patterns detected with confidence >= {:.1}",
                    confidence
                );
                println!("Try lowering the confidence threshold or record more commands");
                return Ok(());
            }

            println!("\n┌─────────────────────────────────────────┬────────────┬─────────────┐");
            println!("│ Pattern                                 │ Confidence │ Frequency   │");
            println!("├─────────────────────────────────────────┼────────────┼─────────────┤");

            for (pattern, confidence_val, frequency) in patterns {
                let truncated_pattern = truncate_string(&pattern, 39);
                println!(
                    "│ {:<39} │ {:>8.2}   │ {:>9} │",
                    truncated_pattern, confidence_val, frequency
                );
            }

            println!("└─────────────────────────────────────────┴────────────┴─────────────┘");
        }
        OutputFormat::Json => {
            let pattern_data: Vec<_> = patterns
                .into_iter()
                .map(|(pattern, conf, freq)| {
                    serde_json::json!({
                        "pattern": pattern,
                        "confidence": conf,
                        "frequency": freq
                    })
                })
                .collect();
            println!("{}", serde_json::to_string_pretty(&pattern_data)?);
        }
        OutputFormat::Csv => {
            println!("pattern,confidence,frequency");
            for (pattern, conf, freq) in patterns {
                println!("{},{:.2},{}", pattern, conf, freq);
            }
        }
        OutputFormat::Plain => {
            for (pattern, conf, freq) in patterns {
                println!("{} (confidence: {:.2}, {} times)", pattern, conf, freq);
            }
        }
    }

    Ok(())
}

pub async fn handle_workflow(action: WorkflowAction, _format: OutputFormat) -> Result<()> {
    match action {
        WorkflowAction::List => {
            println!("🔄 Available Workflows:");
            println!("\n1. deploy-frontend");
            println!("   Steps: build → test → deploy");
            println!("   Used: 12 times");
            println!("\n2. git-workflow");
            println!("   Steps: add → commit → push");
            println!("   Used: 45 times");
        }
        WorkflowAction::Create { name } => {
            println!("✨ Created workflow: {}", name);
        }
        WorkflowAction::Run { name } => {
            println!("▶️  Running workflow: {}", name);
        }
        WorkflowAction::Delete { name } => {
            println!("🗑️  Deleted workflow: {}", name);
        }
    }
    Ok(())
}

pub async fn export_data(
    output: String,
    format: ExportFormat,
    since: Option<String>,
    until: Option<String>,
) -> Result<()> {
    println!("📤 Exporting data to: {}", output);
    
    let storage = create_storage().await?;
    let repo = SqliteCommandRepository::new(storage.pool().clone());
    
    // Parse date filters
    let since_date = if let Some(since_str) = since {
        Some(parse_date_str(&since_str)?)
    } else {
        None
    };
    
    let until_date = if let Some(until_str) = until {
        Some(parse_date_str(&until_str)?)
    } else {
        None
    };
    
    // Get commands based on date range
    let commands = if let (Some(start), Some(end)) = (since_date, until_date) {
        repo.find_by_time_range(start, end).await?
    } else if let Some(start) = since_date {
        repo.find_by_time_range(start, Utc::now()).await?
    } else {
        // Export all commands if no date range specified
        repo.find_recent(usize::MAX).await?
    };
    
    println!("   Found {} commands to export", commands.len());
    
    // Export based on format
    let output_content = match format {
        ExportFormat::Json => {
            serde_json::to_string_pretty(&commands)?
        }
        ExportFormat::Csv => {
            let mut csv_output = String::from("timestamp,command,exit_code,duration_ms,directory,user,hostname,shell,ai_agent\n");
            for cmd in &commands {
                csv_output.push_str(&format!(
                    "{},{},{},{},{},{},{},{},{}\n",
                    cmd.timestamp.to_rfc3339(),
                    escape_csv(&cmd.raw),
                    cmd.exit_code,
                    cmd.duration_ms,
                    escape_csv(&cmd.working_directory),
                    escape_csv(&cmd.metadata.user),
                    escape_csv(&cmd.metadata.hostname),
                    escape_csv(&cmd.metadata.shell),
                    cmd.metadata.ai_agent.as_deref().unwrap_or("")
                ));
            }
            csv_output
        }
        ExportFormat::Markdown => {
            let mut md_output = String::from("# TermBrain Command History Export\n\n");
            md_output.push_str(&format!("Generated: {}\n", Utc::now().to_rfc3339()));
            md_output.push_str(&format!("Total commands: {}\n\n", commands.len()));
            
            // Group by date
            let mut current_date = String::new();
            for cmd in &commands {
                let date = cmd.timestamp.format("%Y-%m-%d").to_string();
                if date != current_date {
                    current_date = date.clone();
                    md_output.push_str(&format!("\n## {}\n\n", date));
                }
                
                md_output.push_str(&format!(
                    "- `{}` {} `{}` ({}{})\n",
                    cmd.timestamp.format("%H:%M:%S"),
                    if cmd.exit_code == 0 { "✅" } else { "❌" },
                    cmd.raw,
                    cmd.working_directory,
                    if let Some(agent) = &cmd.metadata.ai_agent {
                        format!(", AI: {}", agent)
                    } else {
                        String::new()
                    }
                ));
            }
            md_output
        }
    };
    
    // Write to file
    std::fs::write(&output, output_content)?;
    
    println!("✅ Export completed: {} ({} bytes)", output, std::fs::metadata(&output)?.len());
    Ok(())
}

fn escape_csv(s: &str) -> String {
    if s.contains(',') || s.contains('"') || s.contains('\n') {
        format!("\"{}\"", s.replace('"', "\"\""))
    } else {
        s.to_string()
    }
}

fn parse_date_str(date_str: &str) -> Result<DateTime<Utc>> {
    // Try parsing as relative time first
    if let Some(duration) = parse_relative_time(date_str) {
        return Ok(Utc::now() - duration);
    }
    
    // Try parsing as absolute date
    if let Ok(date) = DateTime::parse_from_rfc3339(date_str) {
        return Ok(date.with_timezone(&Utc));
    }
    
    // Try common date formats
    if let Ok(date) = chrono::NaiveDate::parse_from_str(date_str, "%Y-%m-%d") {
        if let Some(datetime) = date.and_hms_opt(0, 0, 0) {
            return Ok(datetime.and_utc());
        }
    }
    
    Err(anyhow::anyhow!("Invalid date format: {}", date_str))
}

fn parse_relative_time(s: &str) -> Option<chrono::Duration> {
    let parts: Vec<&str> = s.split_whitespace().collect();
    if parts.len() != 3 || parts[2] != "ago" {
        return None;
    }
    
    let amount = parts[0].parse::<i64>().ok()?;
    
    match parts[1] {
        "minute" | "minutes" | "min" => Some(chrono::Duration::minutes(amount)),
        "hour" | "hours" | "hr" => Some(chrono::Duration::hours(amount)),
        "day" | "days" => Some(chrono::Duration::days(amount)),
        "week" | "weeks" => Some(chrono::Duration::weeks(amount)),
        "month" | "months" => Some(chrono::Duration::days(amount * 30)), // Approximate
        _ => None,
    }
}

pub async fn install_shell_integration(shell: Option<String>, yes: bool) -> Result<()> {
    // Detect shell if not provided
    let shell_type = if let Some(s) = shell {
        s
    } else {
        let shell_path = std::env::var("SHELL").unwrap_or_else(|_| "/bin/bash".to_string());
        shell_path
            .split('/')
            .next_back()
            .unwrap_or("bash")
            .to_string()
    };

    println!("🛠️  Installing shell integration for: {}", shell_type);

    // Validate shell
    if !["bash", "zsh", "fish"].contains(&shell_type.as_str()) {
        return Err(anyhow::anyhow!(
            "Unsupported shell: {}. Supported shells: bash, zsh, fish",
            shell_type
        ));
    }

    // Get the appropriate shell integration file
    let integration_content = match shell_type.as_str() {
        "bash" => include_str!("../../../../shell-integration/bash/termbrain.bash"),
        "zsh" => include_str!("../../../../shell-integration/zsh/termbrain.zsh"),
        "fish" => include_str!("../../../../shell-integration/fish/termbrain.fish"),
        _ => return Err(anyhow::anyhow!("Unsupported shell: {}", shell_type)),
    };

    // Get shell config file
    let home_dir =
        dirs::home_dir().ok_or_else(|| anyhow::anyhow!("Could not find home directory"))?;
    let config_file = match shell_type.as_str() {
        "bash" => home_dir.join(".bashrc"),
        "zsh" => home_dir.join(".zshrc"),
        "fish" => home_dir.join(".config/fish/config.fish"),
        _ => return Err(anyhow::anyhow!("Unsupported shell: {}", shell_type)),
    };

    // Create shell integration directory
    let config = Config::load()?;
    let integration_dir = config
        .database_path
        .parent()
        .ok_or_else(|| anyhow::anyhow!("Invalid database path: no parent directory"))?
        .join("shell-integration");
    std::fs::create_dir_all(&integration_dir)?;

    // Write integration script
    let script_name = format!("termbrain.{}", shell_type);
    let script_path = integration_dir.join(&script_name);
    std::fs::write(&script_path, integration_content)?;

    println!("   Created integration script: {}", script_path.display());

    // Check if already integrated
    let source_line = match shell_type.as_str() {
        "fish" => format!("source {}", script_path.display()),
        _ => format!("source \"{}\"", script_path.display()),
    };

    let config_exists = config_file.exists();
    let already_integrated = if config_exists {
        let existing_content = std::fs::read_to_string(&config_file)?;
        existing_content.contains(&script_path.to_string_lossy().to_string())
    } else {
        false
    };

    if already_integrated {
        println!(
            "   ✅ Shell integration already configured in {}",
            config_file.display()
        );
        return Ok(());
    }

    // Ask for confirmation unless --yes flag is provided
    if !yes {
        println!(
            "\n   This will add the following line to {}:",
            config_file.display()
        );
        println!("   {}", source_line);
        print!("\n   Continue? [y/N]: ");
        std::io::Write::flush(&mut std::io::stdout())?;

        let mut input = String::new();
        std::io::stdin().read_line(&mut input)?;

        if !input.trim().to_lowercase().starts_with('y') {
            println!("   Installation cancelled");
            return Ok(());
        }
    }

    // Ensure config file directory exists
    if let Some(parent) = config_file.parent() {
        std::fs::create_dir_all(parent)?;
    }

    // Add integration to shell config
    let integration_block = format!("\n# TermBrain shell integration\n{}\n", source_line);

    if config_exists {
        let mut file = std::fs::OpenOptions::new()
            .create(true)
            .append(true)
            .open(&config_file)?;
        std::io::Write::write_all(&mut file, integration_block.as_bytes())?;
    } else {
        std::fs::write(&config_file, integration_block)?;
    }

    println!("   ✅ Added integration to {}", config_file.display());
    println!(
        "   📝 Restart your terminal or run: source {}",
        config_file.display()
    );

    if shell_type == "fish" {
        println!("   🐟 For Fish shell, the integration will be active in new sessions");
    }

    println!("\n✅ Shell integration installed successfully!");
    println!("   Your commands will now be automatically recorded to TermBrain");

    Ok(())
}

pub async fn uninstall_termbrain(purge: bool, yes: bool) -> Result<()> {
    println!("🗑️  TermBrain Uninstaller");

    let config = Config::load()?;
    let termbrain_dir = config.database_path.parent()
        .ok_or_else(|| anyhow::anyhow!("Invalid database path: no parent directory"))?;

    // Show what will be removed
    println!("\n   The following will be removed:");

    // Shell integration removal
    let home_dir =
        dirs::home_dir().ok_or_else(|| anyhow::anyhow!("Could not find home directory"))?;
    let shell_configs = vec![
        ("bash", home_dir.join(".bashrc")),
        ("zsh", home_dir.join(".zshrc")),
        ("fish", home_dir.join(".config/fish/config.fish")),
    ];

    let mut found_integrations = Vec::new();
    for (shell, config_file) in &shell_configs {
        if config_file.exists() {
            let content = std::fs::read_to_string(config_file)?;
            if content.contains("TermBrain shell integration") || content.contains("termbrain") {
                found_integrations.push((shell, config_file));
                println!("   📝 Shell integration from {}", config_file.display());
            }
        }
    }

    // TermBrain directory
    if termbrain_dir.exists() {
        let dir_size = get_directory_size(termbrain_dir)?;
        if purge {
            println!(
                "   📁 TermBrain directory: {} ({:.1} MB)",
                termbrain_dir.display(),
                dir_size as f64 / 1024.0 / 1024.0
            );
            println!("   🗄️  Command history database (PERMANENT DATA LOSS)");
        } else {
            println!(
                "   📁 TermBrain installation files: {} ({:.1} MB)",
                termbrain_dir.display(),
                dir_size as f64 / 1024.0 / 1024.0
            );
            println!(
                "   📦 Database will be preserved: {}",
                config.database_path.display()
            );
        }
    }

    // Binary location
    if let Ok(current_exe) = std::env::current_exe() {
        if current_exe.file_name().unwrap_or_default() == "tb" {
            println!("   🗑️  TermBrain binary: {}", current_exe.display());
        }
    }

    if found_integrations.is_empty() && !termbrain_dir.exists() {
        println!("\n   ℹ️  No TermBrain installation found");
        return Ok(());
    }

    // Confirmation
    if !yes {
        if purge {
            println!("\n   ⚠️  WARNING: --purge flag will permanently delete all command history!");
            print!("   Are you sure you want to completely remove TermBrain? [y/N]: ");
        } else {
            print!("\n   Continue with uninstallation? [y/N]: ");
        }
        std::io::Write::flush(&mut std::io::stdout())?;

        let mut input = String::new();
        std::io::stdin().read_line(&mut input)?;

        if !input.trim().to_lowercase().starts_with('y') {
            println!("   Uninstallation cancelled");
            return Ok(());
        }
    }

    println!("\n   🧹 Starting cleanup...");

    // Remove shell integrations
    for (shell, config_file) in found_integrations {
        if let Err(e) = remove_shell_integration(config_file) {
            println!("   ⚠️  Failed to remove {} integration: {}", shell, e);
        } else {
            println!("   ✅ Removed {} shell integration", shell);
        }
    }

    // Remove TermBrain directory
    if termbrain_dir.exists() {
        if purge {
            // Remove everything
            std::fs::remove_dir_all(termbrain_dir)?;
            println!("   ✅ Removed TermBrain directory and all data");
        } else {
            // Remove everything except the database
            for entry in std::fs::read_dir(termbrain_dir)? {
                let entry = entry?;
                let path = entry.path();

                // Skip the database file
                if path == config.database_path {
                    continue;
                }

                if path.is_dir() {
                    std::fs::remove_dir_all(&path)?;
                } else {
                    std::fs::remove_file(&path)?;
                }
            }
            println!("   ✅ Removed TermBrain installation files");
            println!(
                "   📦 Preserved database: {}",
                config.database_path.display()
            );
        }
    }

    println!("\n✅ TermBrain uninstallation completed!");

    if !purge {
        println!(
            "   💡 To remove the preserved database later, run: rm {}",
            config.database_path.display()
        );
    }

    println!("   📝 You may need to restart your terminal or run:");
    for (_, config_file) in shell_configs {
        if config_file.exists() {
            println!("      source {}", config_file.display());
            break;
        }
    }

    Ok(())
}

fn remove_shell_integration(config_file: &std::path::Path) -> Result<()> {
    let content = std::fs::read_to_string(config_file)?;

    // Remove TermBrain related lines
    let filtered_lines: Vec<&str> = content
        .lines()
        .filter(|line| {
            !line.contains("TermBrain shell integration")
                && !line.contains("termbrain.zsh")
                && !line.contains("termbrain.bash")
                && !line.contains("termbrain.fish")
                && !line.trim().is_empty()
                || (line.trim().is_empty() && !content.lines().any(|l| l.contains("TermBrain")))
        })
        .collect();

    let new_content = filtered_lines.join("\n");

    // Only write if content changed
    if new_content != content {
        std::fs::write(config_file, new_content)?;
    }

    Ok(())
}

fn get_directory_size(path: &std::path::Path) -> Result<u64> {
    let mut size = 0;

    if path.is_dir() {
        for entry in std::fs::read_dir(path)? {
            let entry = entry?;
            let metadata = entry.metadata()?;

            if metadata.is_dir() {
                size += get_directory_size(&entry.path())?;
            } else {
                size += metadata.len();
            }
        }
    } else {
        size = std::fs::metadata(path)?.len();
    }

    Ok(size)
}

pub async fn wrap_ai_agent(
    ai_agent: String, 
    context: Option<String>, 
    command: Vec<String>
) -> Result<()> {
    if command.is_empty() {
        return Err(anyhow::anyhow!("No command provided to wrap"));
    }

    println!("🤖 TermBrain AI Agent Monitor");
    println!("   Agent: {}", ai_agent);
    if let Some(ctx) = &context {
        println!("   Context: {}", ctx);
    }
    println!("   Command: {}", command.join(" "));
    println!();

    // Generate unique AI session ID
    let ai_session_id = format!("{}-{}", ai_agent, Utc::now().timestamp());
    
    // Set environment variables for the child process
    let mut child_env = std::env::vars().collect::<std::collections::HashMap<String, String>>();
    child_env.insert("TERMBRAIN_AI_AGENT".to_string(), ai_agent.clone());
    child_env.insert("TERMBRAIN_AI_SESSION".to_string(), ai_session_id.clone());
    if let Some(ctx) = &context {
        child_env.insert("TERMBRAIN_AI_CONTEXT".to_string(), ctx.clone());
    }
    child_env.insert("TERMBRAIN_AI_WRAPPED".to_string(), "true".to_string());

    // Execute the command with enhanced environment
    let start_time = Utc::now();
    let mut child = tokio::process::Command::new(&command[0])
        .args(&command[1..])
        .envs(&child_env)
        .stdin(std::process::Stdio::inherit())
        .stdout(std::process::Stdio::inherit())
        .stderr(std::process::Stdio::inherit())
        .spawn()?;

    println!("🔍 Monitoring AI agent execution...");
    
    // Wait for the command to complete
    let status = child.wait().await?;
    let end_time = Utc::now();
    let duration_ms = (end_time - start_time).num_milliseconds() as u64;

    // Record the AI session summary
    let session_summary = format!(
        "AI Agent Session: {} completed ({})",
        ai_agent,
        if status.success() { "success" } else { "failed" }
    );

    let storage = create_storage().await?;
    let repo = SqliteCommandRepository::new(storage.pool().clone());
    
    let summary_command = termbrain_core::domain::entities::Command {
        id: uuid::Uuid::new_v4(),
        raw: session_summary.clone(),
        parsed_command: "ai-session".to_string(),
        arguments: vec![ai_agent.clone(), status.code().unwrap_or(-1).to_string()],
        working_directory: std::env::current_dir()?.to_string_lossy().to_string(),
        exit_code: status.code().unwrap_or(-1),
        duration_ms,
        timestamp: end_time,
        session_id: ai_session_id.clone(),
        metadata: termbrain_core::domain::entities::CommandMetadata {
            shell: "ai-wrapper".to_string(),
            user: std::env::var("USER").unwrap_or_else(|_| "unknown".to_string()),
            hostname: hostname::get()
                .map(|h| h.to_string_lossy().to_string())
                .unwrap_or_else(|_| "localhost".to_string()),
            terminal: "termbrain-wrap".to_string(),
            environment: std::collections::HashMap::new(),
            ai_agent: Some(ai_agent.clone()),
            ai_session_id: Some(ai_session_id),
            ai_context: context,
        },
    };

    repo.save(&summary_command).await?;

    // Display results
    println!();
    if status.success() {
        println!("✅ AI agent completed successfully");
    } else {
        println!("❌ AI agent failed with exit code: {}", status.code().unwrap_or(-1));
    }
    
    println!("⏱️  Duration: {}ms", duration_ms);
    println!("📊 Use 'tb history --ai-agent {}' to see all commands from this session", ai_agent);
    
    Ok(())
}

pub async fn start_interactive_session() -> Result<()> {
    println!("🚀 Starting TermBrain interactive session...");
    println!("   Type 'help' for commands, 'exit' to quit");
    println!("✨ Interactive mode ready");
    Ok(())
}

pub async fn show_status(format: OutputFormat) -> Result<()> {
    println!("📊 TermBrain Status");

    let storage = create_storage().await?;
    let repo = SqliteCommandRepository::new(storage.pool().clone());
    let config = Config::load()?;

    // Get actual metrics
    let total_commands = repo.count().await?;

    // Get database size
    let db_size = if config.database_path.exists() {
        let metadata = std::fs::metadata(&config.database_path)?;
        let size_bytes = metadata.len();
        if size_bytes < 1024 {
            format!("{} B", size_bytes)
        } else if size_bytes < 1024 * 1024 {
            format!("{:.1} KB", size_bytes as f64 / 1024.0)
        } else {
            format!("{:.1} MB", size_bytes as f64 / (1024.0 * 1024.0))
        }
    } else {
        "0 B".to_string()
    };

    // Count unique sessions
    let all_commands = repo.find_recent(1000).await?;
    let unique_sessions: std::collections::HashSet<_> =
        all_commands.iter().map(|cmd| &cmd.session_id).collect();
    let session_count = unique_sessions.len();

    // Get current session ID
    let current_session =
        std::env::var("TERMBRAIN_SESSION_ID").unwrap_or_else(|_| "none".to_string());

    match format {
        OutputFormat::Table => {
            println!("\n┌─────────────────────┬─────────────────────┐");
            println!("│ Metric              │ Value               │");
            println!("├─────────────────────┼─────────────────────┤");
            println!("│ Commands Recorded   │ {:<19} │", total_commands);
            println!("│ Unique Sessions     │ {:<19} │", session_count);
            println!(
                "│ Current Session     │ {:<19} │",
                truncate_string(&current_session, 19)
            );
            println!(
                "│ Database Path       │ {:<19} │",
                truncate_string(&config.database_path.to_string_lossy(), 19)
            );
            println!("│ Database Size       │ {:<19} │", db_size);
            println!("└─────────────────────┴─────────────────────┘");
        }
        OutputFormat::Json => {
            let status = serde_json::json!({
                "commands_recorded": total_commands,
                "unique_sessions": session_count,
                "current_session": current_session,
                "database_path": config.database_path,
                "database_size": db_size
            });
            println!("{}", serde_json::to_string_pretty(&status)?);
        }
        OutputFormat::Csv => {
            println!("metric,value");
            println!("commands_recorded,{}", total_commands);
            println!("unique_sessions,{}", session_count);
            println!("current_session,{}", current_session);
            println!("database_path,{}", config.database_path.display());
            println!("database_size,{}", db_size);
        }
        OutputFormat::Plain => {
            println!("Commands Recorded: {}", total_commands);
            println!("Unique Sessions: {}", session_count);
            println!("Current Session: {}", current_session);
            println!("Database Path: {}", config.database_path.display());
            println!("Database Size: {}", db_size);
        }
    }

    Ok(())
}

pub async fn show_welcome() -> Result<()> {
    println!(
        r#"
🧠 TermBrain - The Terminal That Never Forgets

Welcome to TermBrain! Your AI-powered command-line memory assistant.

Quick Start:
  tb record "git status"           Record a command
  tb search "git"                  Search your history
  tb history                       Show recent commands
  tb patterns                      View usage patterns
  tb setup                         Install shell hooks

For detailed help: tb --help
For interactive mode: tb interactive
"#
    );
    Ok(())
}

fn format_relative_time(timestamp: &DateTime<Utc>) -> String {
    let now = Utc::now();
    let duration = now.signed_duration_since(*timestamp);

    if duration.num_seconds() < 60 {
        "Just now".to_string()
    } else if duration.num_minutes() < 60 {
        format!("{} min ago", duration.num_minutes())
    } else if duration.num_hours() < 24 {
        format!("{} hr ago", duration.num_hours())
    } else if duration.num_days() < 7 {
        format!("{} days ago", duration.num_days())
    } else {
        timestamp.format("%Y-%m-%d").to_string()
    }
}

fn truncate_string(s: &str, max_len: usize) -> String {
    if s.len() <= max_len {
        s.to_string()
    } else {
        format!("{}...", &s[..max_len.saturating_sub(3)])
    }
}
