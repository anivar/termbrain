use crate::application::use_cases::explain_commands::{CommandExplanation, CommandContext};
use chrono::{Local, TimeZone};
use colored::*;

pub fn display_command_explanations(explanations: Vec<CommandExplanation>) {
    println!("{}", "🤔 Command Explanations".bold());
    println!();
    
    for (idx, exp) in explanations.iter().enumerate() {
        let local_time = Local.from_utc_datetime(&exp.timestamp.naive_utc());
        let status_icon = if exp.success { "✓".green() } else { "✗".red() };
        
        println!("{} {} {}",
            format!("{}.", idx + 1).dimmed(),
            status_icon,
            exp.command.bright_white()
        );
        
        println!("   {} {}", "Time:".dimmed(), local_time.format("%Y-%m-%d %H:%M:%S").to_string().dimmed());
        println!("   {} {}", "Purpose:".cyan(), exp.purpose);
        println!("   {} {}", "Impact:".yellow(), exp.impact);
        
        if !exp.alternatives.is_empty() {
            println!("   {} {}", "Alternatives:".green(), exp.alternatives.join(", "));
        }
        
        if let Some(branch) = &exp.context.git_branch {
            println!("   {} {}", "Git branch:".dimmed(), branch.dimmed());
        }
        
        if let Some(intention) = &exp.context.intention {
            println!("   {} {}", "Intention:".magenta(), intention);
        }
        
        println!();
    }
}