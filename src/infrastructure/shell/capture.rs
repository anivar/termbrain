use std::process::Command;
use std::env;
use anyhow::Result;

/// Captures command execution details from shell environment
pub struct CommandCapture {
    pub command: String,
    pub directory: String,
    pub exit_code: i32,
    pub duration_ms: u64,
}

impl CommandCapture {
    /// Called by shell hook before command execution
    pub fn before_command(command: &str) -> Result<()> {
        // Store command and start time
        env::set_var("TERMBRAIN_LAST_COMMAND", command);
        env::set_var("TERMBRAIN_COMMAND_START", 
            std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)?
                .as_millis()
                .to_string()
        );
        
        // Check for predictive mode
        if env::var("TERMBRAIN_PREDICTIVE").unwrap_or_default() == "on" {
            // Run predictive analysis
            if let Ok(output) = Command::new("tb")
                .args(&["_predict", command])
                .output()
            {
                if !output.stdout.is_empty() {
                    print!("{}", String::from_utf8_lossy(&output.stdout));
                }
            }
        }
        
        Ok(())
    }
    
    /// Called by shell hook after command execution
    pub fn after_command(exit_code: i32) -> Result<()> {
        // Get command details
        let command = env::var("TERMBRAIN_LAST_COMMAND").unwrap_or_default();
        let directory = env::current_dir()?.to_string_lossy().to_string();
        
        // Calculate duration
        let start = env::var("TERMBRAIN_COMMAND_START")
            .unwrap_or_default()
            .parse::<u128>()
            .unwrap_or(0);
        
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)?
            .as_millis();
        
        let duration_ms = (now - start) as u64;
        
        // Record command asynchronously
        Command::new("tb")
            .args(&[
                "_record",
                &command,
                &directory,
                &exit_code.to_string(),
                &duration_ms.to_string(),
            ])
            .spawn()?;
        
        // Clean up environment
        env::remove_var("TERMBRAIN_LAST_COMMAND");
        env::remove_var("TERMBRAIN_COMMAND_START");
        
        Ok(())
    }
}

/// Shell hook generator
pub struct ShellHooks;

impl ShellHooks {
    pub fn bash_hooks() -> &'static str {
        r#"
# Termbrain bash hooks
__termbrain_preexec() {
    tb _before_command "$1"
}

__termbrain_precmd() {
    local exit_code=$?
    tb _after_command $exit_code
}

# Set up hooks
if [[ -n "${BASH_VERSION}" ]]; then
    # Bash preexec/precmd setup
    trap '__termbrain_preexec "$BASH_COMMAND"' DEBUG
    PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND; }__termbrain_precmd"
fi
"#
    }
    
    pub fn zsh_hooks() -> &'static str {
        r#"
# Termbrain zsh hooks
autoload -Uz add-zsh-hook

__termbrain_preexec() {
    tb _before_command "$1"
}

__termbrain_precmd() {
    local exit_code=$?
    tb _after_command $exit_code
}

add-zsh-hook preexec __termbrain_preexec
add-zsh-hook precmd __termbrain_precmd
"#
    }
    
    pub fn fish_hooks() -> &'static str {
        r#"
# Termbrain fish hooks
function __termbrain_preexec --on-event fish_preexec
    tb _before_command "$argv"
end

function __termbrain_postexec --on-event fish_postexec
    tb _after_command $status
end
"#
    }
}