//! Logging and observability infrastructure

use anyhow::Result;
use std::path::PathBuf;
use tracing_appender::rolling::{RollingFileAppender, Rotation};
use tracing_subscriber::{
    fmt::{self, format::FmtSpan},
    layer::SubscriberExt,
    util::SubscriberInitExt,
    EnvFilter, Layer,
};

/// Initialize logging with file rotation and structured output
pub fn init_logging(config: &crate::config::Config) -> Result<()> {
    // Determine log directory
    let log_dir = dirs::home_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join(".termbrain")
        .join("logs");
    
    // Create log directory if it doesn't exist
    std::fs::create_dir_all(&log_dir)?;
    
    // Create rolling file appender (daily rotation)
    let file_appender = RollingFileAppender::new(
        Rotation::DAILY,
        &log_dir,
        "termbrain.log",
    );
    
    // File layer for structured JSON logs
    let file_layer = fmt::layer()
        .json()
        .with_target(true)
        .with_thread_ids(true)
        .with_thread_names(true)
        .with_span_events(FmtSpan::CLOSE)
        .with_writer(file_appender)
        .with_filter(EnvFilter::new(&config.log_level));
    
    // Console layer for human-readable output
    let console_layer = fmt::layer()
        .with_target(false)
        .with_thread_ids(false)
        .with_writer(std::io::stderr)
        .with_filter(EnvFilter::new("termbrain=warn,error"));
    
    // Combine layers
    tracing_subscriber::registry()
        .with(file_layer)
        .with(console_layer)
        .init();
    
    tracing::info!(
        version = env!("CARGO_PKG_VERSION"),
        log_dir = %log_dir.display(),
        "TermBrain logging initialized"
    );
    
    Ok(())
}

/// Log command execution with context
pub fn log_command_execution(
    command: &str,
    exit_code: i32,
    duration_ms: u64,
    ai_agent: Option<&str>,
) {
    tracing::info!(
        command = %command,
        exit_code = exit_code,
        duration_ms = duration_ms,
        ai_agent = ai_agent,
        "Command recorded"
    );
}

/// Log search operation
#[allow(dead_code)]
pub fn log_search(query: &str, result_count: usize, duration_ms: u64) {
    tracing::info!(
        query = %query,
        result_count = result_count,
        duration_ms = duration_ms,
        "Search performed"
    );
}

/// Log database operation
#[allow(dead_code)]
pub fn log_database_operation(operation: &str, success: bool, duration_ms: u64) {
    if success {
        tracing::debug!(
            operation = %operation,
            duration_ms = duration_ms,
            "Database operation completed"
        );
    } else {
        tracing::error!(
            operation = %operation,
            duration_ms = duration_ms,
            "Database operation failed"
        );
    }
}

/// Log security event
#[allow(dead_code)]
pub fn log_security_event(event_type: &str, details: &str) {
    tracing::warn!(
        event_type = %event_type,
        details = %details,
        "Security event"
    );
}


/// Log garbage collection
pub fn log_garbage_collection(deleted_count: usize, duration_ms: u64) {
    tracing::info!(
        deleted_count = deleted_count,
        duration_ms = duration_ms,
        "Garbage collection completed"
    );
}