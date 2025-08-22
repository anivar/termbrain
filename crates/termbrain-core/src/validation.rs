//! Input validation utilities for TermBrain
//!
//! This module provides comprehensive input validation to prevent
//! security vulnerabilities and ensure data integrity.

use anyhow::{anyhow, Result};
use std::path::{Path, PathBuf};

/// Maximum allowed command length (10KB)
const MAX_COMMAND_LENGTH: usize = 10_240;

/// Maximum allowed path length
const MAX_PATH_LENGTH: usize = 4_096;

/// Maximum allowed environment variable value length
const MAX_ENV_VALUE_LENGTH: usize = 32_768;

/// Validates a command string
pub fn validate_command(command: &str) -> Result<()> {
    // Check length
    if command.is_empty() {
        return Err(anyhow!("Command cannot be empty"));
    }

    if command.len() > MAX_COMMAND_LENGTH {
        return Err(anyhow!(
            "Command too long: {} bytes (max: {} bytes)",
            command.len(),
            MAX_COMMAND_LENGTH
        ));
    }

    // Check for null bytes
    if command.contains('\0') {
        return Err(anyhow!("Command cannot contain null bytes"));
    }

    // Check for control characters (except newline, tab)
    for (i, ch) in command.chars().enumerate() {
        if ch.is_control() && ch != '\n' && ch != '\t' && ch != '\r' {
            return Err(anyhow!(
                "Command contains invalid control character at position {}: {:?}",
                i,
                ch
            ));
        }
    }

    Ok(())
}

/// Validates a file path
pub fn validate_path(path: &Path) -> Result<PathBuf> {
    // Convert to string to check length
    let path_str = path
        .to_str()
        .ok_or_else(|| anyhow!("Path contains invalid UTF-8"))?;

    if path_str.is_empty() {
        return Err(anyhow!("Path cannot be empty"));
    }

    if path_str.len() > MAX_PATH_LENGTH {
        return Err(anyhow!(
            "Path too long: {} bytes (max: {} bytes)",
            path_str.len(),
            MAX_PATH_LENGTH
        ));
    }

    // Check for null bytes
    if path_str.contains('\0') {
        return Err(anyhow!("Path cannot contain null bytes"));
    }

    // Attempt to canonicalize the path (resolves symlinks and ..)
    // This helps prevent path traversal attacks
    match path.canonicalize() {
        Ok(canonical) => Ok(canonical),
        Err(_) => {
            // If path doesn't exist yet, at least resolve relative components
            let absolute = if path.is_absolute() {
                path.to_path_buf()
            } else {
                std::env::current_dir()?.join(path)
            };

            // Simple path traversal check
            let normalized = normalize_path(&absolute);
            Ok(normalized)
        }
    }
}

/// Normalize a path by resolving . and .. components
fn normalize_path(path: &Path) -> PathBuf {
    use std::path::Component;

    let mut components = Vec::new();

    for component in path.components() {
        match component {
            Component::ParentDir => {
                components.pop();
            }
            Component::CurDir => {
                // Skip
            }
            c => {
                components.push(c);
            }
        }
    }

    components.iter().collect()
}

/// Validates an environment variable name
pub fn validate_env_name(name: &str) -> Result<()> {
    if name.is_empty() {
        return Err(anyhow!("Environment variable name cannot be empty"));
    }

    // Check first character (must be letter or underscore)
    let first = name.chars().next().ok_or_else(|| anyhow!("Empty name after validation"))?;
    if !first.is_alphabetic() && first != '_' {
        return Err(anyhow!(
            "Environment variable name must start with a letter or underscore"
        ));
    }

    // Check remaining characters
    for ch in name.chars() {
        if !ch.is_alphanumeric() && ch != '_' {
            return Err(anyhow!(
                "Environment variable name can only contain letters, numbers, and underscores"
            ));
        }
    }

    Ok(())
}

/// Validates an environment variable value
pub fn validate_env_value(value: &str) -> Result<()> {
    if value.len() > MAX_ENV_VALUE_LENGTH {
        return Err(anyhow!(
            "Environment variable value too long: {} bytes (max: {} bytes)",
            value.len(),
            MAX_ENV_VALUE_LENGTH
        ));
    }

    // Check for null bytes
    if value.contains('\0') {
        return Err(anyhow!(
            "Environment variable value cannot contain null bytes"
        ));
    }

    Ok(())
}

/// Validates a shell name
pub fn validate_shell(shell: &str) -> Result<()> {
    const VALID_SHELLS: &[&str] = &[
        "bash", "zsh", "fish", "sh", "dash", "ksh", "tcsh", "csh", "nu", "elvish", "xonsh",
    ];

    if !VALID_SHELLS.contains(&shell) {
        return Err(anyhow!(
            "Invalid shell '{}'. Valid shells are: {}",
            shell,
            VALID_SHELLS.join(", ")
        ));
    }

    Ok(())
}

/// Validates a hostname
pub fn validate_hostname(hostname: &str) -> Result<()> {
    if hostname.is_empty() {
        return Err(anyhow!("Hostname cannot be empty"));
    }

    if hostname.len() > 255 {
        return Err(anyhow!("Hostname too long (max 255 characters)"));
    }

    // Check each label
    for label in hostname.split('.') {
        if label.is_empty() {
            return Err(anyhow!("Hostname contains empty label"));
        }

        if label.len() > 63 {
            return Err(anyhow!("Hostname label too long (max 63 characters)"));
        }

        // Must start and end with alphanumeric
        if let Some(first) = label.chars().next() {
            if !first.is_alphanumeric() {
                return Err(anyhow!(
                    "Hostname label must start with alphanumeric character"
                ));
            }
        }

        if let Some(last) = label.chars().last() {
            if !last.is_alphanumeric() {
                return Err(anyhow!(
                    "Hostname label must end with alphanumeric character"
                ));
            }
        }

        // Check all characters
        for ch in label.chars() {
            if !ch.is_alphanumeric() && ch != '-' {
                return Err(anyhow!(
                    "Hostname can only contain letters, numbers, and hyphens"
                ));
            }
        }
    }

    Ok(())
}

/// Validates a username
pub fn validate_username(username: &str) -> Result<()> {
    if username.is_empty() {
        return Err(anyhow!("Username cannot be empty"));
    }

    if username.len() > 32 {
        return Err(anyhow!("Username too long (max 32 characters)"));
    }

    // Check first character
    let first = username.chars().next().ok_or_else(|| anyhow!("Empty username after validation"))?;
    if !first.is_alphabetic() && first != '_' {
        return Err(anyhow!("Username must start with a letter or underscore"));
    }

    // Check all characters
    for ch in username.chars() {
        if !ch.is_alphanumeric() && ch != '_' && ch != '-' && ch != '$' {
            return Err(anyhow!(
                "Username can only contain letters, numbers, underscore, hyphen, and dollar sign"
            ));
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_validate_command() {
        // Valid commands
        assert!(validate_command("ls -la").is_ok());
        assert!(validate_command("echo 'hello world'").is_ok());
        assert!(validate_command("git commit -m 'test'").is_ok());

        // Invalid commands
        assert!(validate_command("").is_err());
        assert!(validate_command("cmd\0with\0null").is_err());
        assert!(validate_command(&"a".repeat(20_000)).is_err());
    }

    #[test]
    fn test_validate_path() {
        // Valid paths
        assert!(validate_path(Path::new("/home/user")).is_ok());
        assert!(validate_path(Path::new("./relative/path")).is_ok());

        // Invalid paths
        assert!(validate_path(Path::new("")).is_err());
        assert!(validate_path(Path::new("/path\0with\0null")).is_err());
    }

    #[test]
    fn test_validate_env_name() {
        // Valid names
        assert!(validate_env_name("PATH").is_ok());
        assert!(validate_env_name("_PRIVATE").is_ok());
        assert!(validate_env_name("MY_VAR_123").is_ok());

        // Invalid names
        assert!(validate_env_name("").is_err());
        assert!(validate_env_name("123_START").is_err());
        assert!(validate_env_name("MY-VAR").is_err());
    }

    #[test]
    fn test_validate_shell() {
        // Valid shells
        assert!(validate_shell("bash").is_ok());
        assert!(validate_shell("zsh").is_ok());
        assert!(validate_shell("fish").is_ok());

        // Invalid shells
        assert!(validate_shell("").is_err());
        assert!(validate_shell("fakeshell").is_err());
    }

    #[test]
    fn test_validate_hostname() {
        // Valid hostnames
        assert!(validate_hostname("localhost").is_ok());
        assert!(validate_hostname("example.com").is_ok());
        assert!(validate_hostname("my-server-01").is_ok());

        // Invalid hostnames
        assert!(validate_hostname("").is_err());
        assert!(validate_hostname("-invalid").is_err());
        assert!(validate_hostname("invalid-").is_err());
        assert!(validate_hostname("invalid..com").is_err());
    }

    #[test]
    fn test_validate_username() {
        // Valid usernames
        assert!(validate_username("john").is_ok());
        assert!(validate_username("_admin").is_ok());
        assert!(validate_username("user-123").is_ok());

        // Invalid usernames
        assert!(validate_username("").is_err());
        assert!(validate_username("123user").is_err());
        assert!(validate_username("user@domain").is_err());
    }
}
