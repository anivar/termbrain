use crate::application::use_cases::generate_suggestions::{
    Suggestions, Priority, ImpactLevel
};
use colored::*;

pub fn display_suggestions(suggestions: Suggestions) {
    println!("{}", "💡 Personalized Suggestions".bold());
    println!();
    
    // Next command predictions
    if !suggestions.next_commands.is_empty() {
        println!("{}", "🔮 Predicted Next Commands:".bright_white());
        for (idx, cmd) in suggestions.next_commands.iter().enumerate() {
            println!("  {}. {} (confidence: {:.0}%)",
                idx + 1,
                cmd.command.cyan(),
                cmd.confidence * 100.0
            );
            println!("     {}", cmd.reason.dimmed());
        }
        println!();
    }
    
    // Workflow opportunities
    if !suggestions.workflow_opportunities.is_empty() {
        println!("{}", "⚡ Workflow Opportunities:".bright_white());
        for opp in &suggestions.workflow_opportunities {
            println!("  {} {}", "•".cyan(), opp.name.bold());
            println!("    {}", opp.description);
            println!("    Commands: {}", opp.commands.join(" → ").cyan());
            println!("    Potential time saved: ~{} seconds/month", 
                opp.estimated_time_saved.to_string().green()
            );
            println!();
        }
    }
    
    // Learning recommendations
    if !suggestions.learning_recommendations.is_empty() {
        println!("{}", "📚 Learning Recommendations:".bright_white());
        for rec in &suggestions.learning_recommendations {
            let priority_color = match rec.priority {
                Priority::High => "red",
                Priority::Medium => "yellow",
                Priority::Low => "green",
            };
            
            println!("  {} {} [{}]",
                "•".cyan(),
                rec.topic.bold(),
                format!("{:?}", rec.priority).color(priority_color)
            );
            println!("    {}", rec.reason.dimmed());
            println!("    Resources: {}", rec.resources.join(", ").green());
            println!();
        }
    }
    
    // Productivity tips
    if !suggestions.productivity_tips.is_empty() {
        println!("{}", "🚀 Productivity Tips:".bright_white());
        for tip in &suggestions.productivity_tips {
            let impact_icon = match tip.impact {
                ImpactLevel::High => "🔥",
                ImpactLevel::Medium => "⭐",
                ImpactLevel::Low => "💫",
            };
            
            println!("  {} {} {}", impact_icon, tip.title.bold(), format!("[{:?} impact]", tip.impact).dimmed());
            println!("    {}", tip.description);
            println!("    {}: {}", "Action".green(), tip.action.cyan());
            println!();
        }
    }
    
    // Tool recommendations
    if !suggestions.tool_recommendations.is_empty() {
        println!("{}", "🛠️  Tool Recommendations:".bright_white());
        for tool in &suggestions.tool_recommendations {
            println!("  {} {}", "•".cyan(), tool.tool.bold());
            println!("    {}", tool.reason);
            println!("    Benefits:");
            for benefit in &tool.benefits {
                println!("      - {}", benefit.green());
            }
            println!("    Install: {}", tool.installation.cyan());
            println!();
        }
    }
    
    if suggestions.next_commands.is_empty() 
        && suggestions.workflow_opportunities.is_empty()
        && suggestions.learning_recommendations.is_empty()
        && suggestions.productivity_tips.is_empty()
        && suggestions.tool_recommendations.is_empty() {
        println!("No specific suggestions at this time. Keep exploring! 🌟");
    }
}