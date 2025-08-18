use crate::application::dto::{
    SearchResult, StatsResult, WorkflowDto, ProjectAnalysis, FlowState, AIContext, GrowthAnalytics
};
use crate::domain::entities::Workflow;
use chrono::{Local, TimeZone};
use colored::*;

// Re-export from cli module
pub use crate::presentation::cli::{display_command_explanations, display_suggestions};

pub fn display_search_results(results: Vec<SearchResult>) {
    if results.is_empty() {
        println!("No commands found");
        return;
    }
    
    println!("{}", "Search Results:".bold());
    println!();
    
    for result in results {
        let status = if result.exit_code == 0 {
            "✓".green()
        } else {
            "✗".red()
        };
        
        let local_time = Local.from_utc_datetime(&result.timestamp.naive_utc());
        
        println!("{} {} {}",
            status,
            result.command.bright_white(),
            format!("[{}]", result.semantic_type).dimmed()
        );
        println!("  {} • {}",
            local_time.format("%Y-%m-%d %H:%M:%S").to_string().dimmed(),
            result.directory.dimmed()
        );
        println!();
    }
}

pub fn display_stats(stats: StatsResult) {
    println!("{}", "Command Statistics:".bold());
    println!();
    
    // Overall stats
    println!("📊 {} Overview", "Overall".bright_white());
    println!("  Total commands: {}", stats.total_commands.to_string().cyan());
    println!("  Success rate: {:.1}%", 
        (stats.success_rate * 100.0).to_string().green()
    );
    println!("  Average duration: {:.0}ms", stats.average_duration_ms);
    println!();
    
    // By type
    if !stats.commands_by_type.is_empty() {
        println!("📂 {} Usage", "By Type".bright_white());
        for (semantic_type, count) in stats.commands_by_type.iter().take(5) {
            let percentage = (*count as f64 / stats.total_commands as f64) * 100.0;
            println!("  {:20} {:>6} ({:.1}%)", 
                format!("{:?}", semantic_type).dimmed(),
                count.to_string().cyan(),
                percentage
            );
        }
        println!();
    }
    
    // By hour
    println!("🕐 {} Activity", "By Hour".bright_white());
    let max_hour_count = stats.commands_by_hour.iter()
        .map(|(_, count)| *count)
        .max()
        .unwrap_or(1);
    
    for (hour, count) in &stats.commands_by_hour {
        let bar_width = ((*count as f64 / max_hour_count as f64) * 20.0) as usize;
        let bar = "█".repeat(bar_width);
        println!("  {:02}:00 {} {}", 
            hour,
            bar.green(),
            count.to_string().dimmed()
        );
    }
    println!();
    
    // Most used directories
    if !stats.most_used_directories.is_empty() {
        println!("📁 {} Directories", "Most Used".bright_white());
        for (dir, count) in stats.most_used_directories.iter().take(5) {
            println!("  {:40} {}", 
                dir.dimmed(),
                count.to_string().cyan()
            );
        }
    }
}

pub fn display_workflows(workflows: Vec<Workflow>) {
    if workflows.is_empty() {
        println!("No workflows found");
        println!("\nCreate a workflow with: tb workflow create <name> <description> <cmd1> <cmd2>...");
        return;
    }
    
    println!("{}", "Workflows:".bold());
    println!();
    
    for workflow in workflows {
        println!("📋 {} - {}",
            workflow.name.bright_white(),
            workflow.description.dimmed()
        );
        println!("   Commands: {} | Runs: {}",
            workflow.commands.len().to_string().cyan(),
            workflow.execution_count.to_string().green()
        );
        println!();
    }
}

pub fn display_project_analysis(analysis: ProjectAnalysis) {
    println!("{}", "Project Analysis:".bold());
    println!();
    
    println!("🔍 Project Type: {}", 
        format!("{:?}", analysis.project_type).bright_white()
    );
    println!("🔤 Primary Language: {}", 
        analysis.primary_language.cyan()
    );
    println!("📊 Productivity Score: {:.1}/10", 
        analysis.productivity_score.to_string().green()
    );
    println!();
    
    if !analysis.common_commands.is_empty() {
        println!("🔧 {} Commands:", "Common".bright_white());
        for (cmd, count) in analysis.common_commands.iter().take(5) {
            println!("  {} ({}x)", cmd.dimmed(), count);
        }
        println!();
    }
    
    if !analysis.workflow_suggestions.is_empty() {
        println!("💡 {} Workflows:", "Suggested".bright_white());
        for suggestion in &analysis.workflow_suggestions {
            println!("  {} - {} commands", 
                suggestion.name.cyan(),
                suggestion.commands.len()
            );
        }
    }
}

pub fn display_flow_state(state: FlowState) {
    if state.in_flow {
        println!("🌊 {} Flow State", "In".green().bold());
        
        if let Some(duration) = state.duration_minutes {
            println!("  Duration: {} minutes", duration);
        }
        
        if let Some(score) = state.productivity_score {
            println!("  Productivity: {:.1}/10", score);
        }
        
        if let Some(area) = &state.focus_area {
            println!("  Focus: {}", area.bright_white());
        }
    } else {
        println!("💤 {} in flow state", "Not".dimmed());
        println!("\nStart a flow session with: tb flow start");
    }
}

pub fn display_help() {
    println!("{}", "Termbrain - The Terminal That Never Forgets".bold());
    println!();
    println!("{}", "USAGE:".yellow());
    println!("    tb <COMMAND> [OPTIONS]");
    println!();
    println!("{}", "COMMANDS:".yellow());
    println!("    {}  Search command history", "search".cyan());
    println!("    {}   Show command statistics", "stats".cyan());
    println!("    {} View command history", "history".cyan());
    println!("    {}    Manage workflows", "workflow".cyan());
    println!("    {}  Set your current intention", "intend".cyan());
    println!("    {}   Export command history", "export".cyan());
    println!("    {} Analyze current project", "project".cyan());
    println!("    {}      Generate AI context", "ai".cyan());
    println!("    {}    Track flow state", "flow".cyan());
    println!();
    println!("Run 'tb <COMMAND> --help' for more information on a command.");
}

pub fn display_growth_analytics(analytics: GrowthAnalytics) {
    use crate::application::use_cases::analyze_growth::MasteryLevel;
    
    println!("{}", "📈 Growth Analytics".bold());
    println!();
    
    // Growth Score
    let score_color = if analytics.growth_score >= 8.0 {
        "green"
    } else if analytics.growth_score >= 5.0 {
        "yellow"
    } else {
        "red"
    };
    
    println!("🎯 {} {}/10",
        "Growth Score:".bright_white(),
        format!("{:.1}", analytics.growth_score).color(score_color).bold()
    );
    println!();
    
    // Learning Velocity
    println!("📚 {} {:.1} new commands/day",
        "Learning Velocity:".bright_white(),
        analytics.learning_velocity
    );
    println!("   {} new commands learned this week", analytics.new_commands_learned);
    println!();
    
    // Skill Progression
    println!("{}", "🔧 Skill Progression:".bright_white());
    let mut skills: Vec<_> = analytics.skill_progression.into_iter().collect();
    skills.sort_by(|a, b| b.1.partial_cmp(&a.1).unwrap());
    
    for (skill, percentage) in skills.iter().take(5) {
        let bar_length = (percentage / 2.0) as usize;
        let bar = "█".repeat(bar_length);
        let empty = "░".repeat(50 - bar_length);
        println!("   {:>15}: {}{} {:.1}%",
            skill,
            bar.green(),
            empty.dimmed(),
            percentage
        );
    }
    println!();
    
    // Mastery Levels
    println!("{}", "🏆 Tool Mastery:".bright_white());
    let mut mastery: Vec<_> = analytics.mastery_levels.into_iter()
        .filter(|(_, level)| !matches!(level, MasteryLevel::Beginner))
        .collect();
    mastery.sort_by_key(|(_, level)| match level {
        MasteryLevel::Expert => 0,
        MasteryLevel::Advanced => 1,
        MasteryLevel::Intermediate => 2,
        MasteryLevel::Beginner => 3,
    });
    
    for (tool, level) in mastery.iter().take(10) {
        let (icon, color) = match level {
            MasteryLevel::Expert => ("⭐⭐⭐", "bright_green"),
            MasteryLevel::Advanced => ("⭐⭐", "green"),
            MasteryLevel::Intermediate => ("⭐", "yellow"),
            MasteryLevel::Beginner => ("○", "dimmed"),
        };
        println!("   {} {} - {:?}", icon, tool.color(color), level);
    }
    println!();
    
    // Productivity Metrics
    println!("{}", "📊 Productivity Metrics:".bright_white());
    let error_icon = if analytics.error_reduction_rate > 0.0 { "↑" } else { "↓" };
    let error_color = if analytics.error_reduction_rate > 0.0 { "green" } else { "red" };
    
    println!("   Error reduction: {} {:.1}%",
        error_icon.color(error_color),
        (analytics.error_reduction_rate * 100.0).abs()
    );
    println!("   Complex command usage: {:.1}%",
        analytics.complex_command_ratio * 100.0
    );
    println!();
    
    // Activity Trend
    if !analytics.productivity_trends.is_empty() {
        println!("{}", "📅 Recent Activity:".bright_white());
        for (date, count) in analytics.productivity_trends.iter().take(7) {
            let bar = "▪".repeat((count / 10).max(1).min(20));
            println!("   {}: {} {}",
                date,
                bar.cyan(),
                count
            );
        }
    }
}