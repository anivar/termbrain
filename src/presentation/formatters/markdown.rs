use crate::domain::entities::Command;
use crate::application::dto::{StatsResult, ProjectAnalysis};
use chrono::Local;
use anyhow::Result;
use std::io::Write;

pub fn format_commands<W: Write>(commands: &[Command], writer: &mut W) -> Result<()> {
    writeln!(writer, "# Termbrain Command History Export")?;
    writeln!(writer)?;
    writeln!(writer, "Generated: {}", Local::now().format("%Y-%m-%d %H:%M:%S"))?;
    writeln!(writer)?;
    
    writeln!(writer, "## Commands")?;
    writeln!(writer)?;
    writeln!(writer, "| Time | Command | Directory | Status | Type |")?;
    writeln!(writer, "|------|---------|-----------|--------|------|")?;
    
    for cmd in commands {
        let status = if cmd.exit_code == 0 { "✓" } else { "✗" };
        let local_time = Local.from_utc_datetime(&cmd.timestamp.naive_utc());
        
        writeln!(
            writer,
            "| {} | `{}` | {} | {} | {} |",
            local_time.format("%H:%M:%S"),
            cmd.command.replace('|', "\\|"),
            cmd.directory.replace('|', "\\|"),
            status,
            format!("{:?}", cmd.semantic_type)
        )?;
    }
    
    Ok(())
}

pub fn format_stats<W: Write>(stats: &StatsResult, writer: &mut W) -> Result<()> {
    writeln!(writer, "# Termbrain Statistics Report")?;
    writeln!(writer)?;
    
    writeln!(writer, "## Overview")?;
    writeln!(writer, "- Total Commands: {}", stats.total_commands)?;
    writeln!(writer, "- Success Rate: {:.1}%", stats.success_rate * 100.0)?;
    writeln!(writer, "- Average Duration: {:.0}ms", stats.average_duration_ms)?;
    writeln!(writer)?;
    
    writeln!(writer, "## Command Types")?;
    for (cmd_type, count) in &stats.commands_by_type {
        writeln!(writer, "- {:?}: {}", cmd_type, count)?;
    }
    
    Ok(())
}

pub fn format_project_analysis<W: Write>(analysis: &ProjectAnalysis, writer: &mut W) -> Result<()> {
    writeln!(writer, "# Project Analysis")?;
    writeln!(writer)?;
    
    writeln!(writer, "## Project Information")?;
    writeln!(writer, "- Type: {:?}", analysis.project_type)?;
    writeln!(writer, "- Primary Language: {}", analysis.primary_language)?;
    writeln!(writer, "- Productivity Score: {:.1}/10", analysis.productivity_score)?;
    writeln!(writer)?;
    
    if !analysis.common_commands.is_empty() {
        writeln!(writer, "## Common Commands")?;
        for (cmd, count) in &analysis.common_commands {
            writeln!(writer, "- `{}` ({}x)", cmd, count)?;
        }
        writeln!(writer)?;
    }
    
    if !analysis.workflow_suggestions.is_empty() {
        writeln!(writer, "## Suggested Workflows")?;
        for suggestion in &analysis.workflow_suggestions {
            writeln!(writer, "### {}", suggestion.name)?;
            writeln!(writer, "Frequency: {} times", suggestion.frequency)?;
            writeln!(writer, "Commands:")?;
            for cmd in &suggestion.commands {
                writeln!(writer, "- `{}`", cmd)?;
            }
            writeln!(writer)?;
        }
    }
    
    Ok(())
}