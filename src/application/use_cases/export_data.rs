use crate::domain::repositories::CommandRepository;
use crate::presentation::formatters;
use anyhow::Result;
use std::fs::File;
use std::io::BufWriter;

pub struct ExportData<'a> {
    command_repository: &'a dyn CommandRepository,
}

impl<'a> ExportData<'a> {
    pub fn new(command_repository: &'a dyn CommandRepository) -> Self {
        Self { command_repository }
    }
    
    pub async fn execute(&self, format: &str, output: &str) -> Result<()> {
        // Get all commands
        let commands = self.command_repository.get_all().await?;
        
        // Create output file
        let file = File::create(output)?;
        let mut writer = BufWriter::new(file);
        
        // Export based on format
        match format {
            "json" => {
                let json = formatters::json::format(&commands)?;
                std::io::Write::write_all(&mut writer, json.as_bytes())?;
            }
            "csv" => {
                formatters::csv::format_commands(&commands, &mut writer)?;
            }
            "md" | "markdown" => {
                formatters::markdown::format_commands(&commands, &mut writer)?;
            }
            "sql" => {
                // Generate SQL insert statements
                writeln!(&mut writer, "-- Termbrain command export")?;
                writeln!(&mut writer, "-- Generated at: {}", chrono::Utc::now())?;
                writeln!(&mut writer)?;
                
                for cmd in &commands {
                    writeln!(
                        &mut writer,
                        "INSERT INTO commands (id, timestamp, command, directory, exit_code, duration_ms, session_id, command_type, semantic_type) VALUES ('{}', '{}', '{}', '{}', {}, {}, '{}', {:?}, {:?});",
                        cmd.id,
                        cmd.timestamp.to_rfc3339(),
                        cmd.command.replace('\'', "''"),
                        cmd.directory.replace('\'', "''"),
                        cmd.exit_code,
                        cmd.duration_ms,
                        cmd.session_id,
                        cmd.command_type,
                        cmd.semantic_type
                    )?;
                }
            }
            _ => anyhow::bail!("Unsupported format: {}", format),
        }
        
        Ok(())
    }
}

use std::io::writeln;