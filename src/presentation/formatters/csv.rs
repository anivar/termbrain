use crate::domain::entities::Command;
use anyhow::Result;
use std::io::Write;

pub fn format_commands<W: Write>(commands: &[Command], writer: &mut W) -> Result<()> {
    // Write header
    writeln!(writer, "timestamp,command,directory,exit_code,semantic_type,duration_ms")?;
    
    // Write data
    for cmd in commands {
        writeln!(
            writer,
            "{},{},{},{},{:?},{}",
            cmd.timestamp.to_rfc3339(),
            escape_csv(&cmd.command),
            escape_csv(&cmd.directory),
            cmd.exit_code,
            cmd.semantic_type,
            cmd.duration_ms
        )?;
    }
    
    Ok(())
}

fn escape_csv(s: &str) -> String {
    if s.contains(',') || s.contains('"') || s.contains('\n') {
        format!("\"{}\"", s.replace('"', "\"\""))
    } else {
        s.to_string()
    }
}