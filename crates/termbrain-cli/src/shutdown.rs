//! Graceful shutdown handling

use anyhow::Result;
use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use tokio::sync::broadcast;
use tokio::time::{timeout, Duration};

/// Shutdown signal manager
pub struct ShutdownManager {
    shutdown_tx: broadcast::Sender<()>,
    is_shutting_down: Arc<AtomicBool>,
}

impl ShutdownManager {
    pub fn new() -> Self {
        let (shutdown_tx, _) = broadcast::channel(16);
        Self {
            shutdown_tx,
            is_shutting_down: Arc::new(AtomicBool::new(false)),
        }
    }
    
    /// Get a receiver for shutdown signals
    #[allow(dead_code)]
    pub fn subscribe(&self) -> broadcast::Receiver<()> {
        self.shutdown_tx.subscribe()
    }
    
    /// Check if shutdown is in progress
    #[allow(dead_code)]
    pub fn is_shutting_down(&self) -> bool {
        self.is_shutting_down.load(Ordering::Relaxed)
    }
    
    /// Start listening for shutdown signals
    pub async fn listen_for_shutdown(&self) -> Result<()> {
        let shutdown_tx = self.shutdown_tx.clone();
        let is_shutting_down = self.is_shutting_down.clone();
        
        tokio::spawn(async move {
            #[cfg(unix)]
            {
                // Listen for SIGTERM and SIGINT on Unix systems
                let mut sigterm = tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
                    .expect("Failed to install SIGTERM handler");
                let mut sigint = tokio::signal::unix::signal(tokio::signal::unix::SignalKind::interrupt())
                    .expect("Failed to install SIGINT handler");
                
                tokio::select! {
                    _ = sigterm.recv() => {
                        tracing::info!("Received SIGTERM, initiating graceful shutdown");
                    }
                    _ = sigint.recv() => {
                        tracing::info!("Received SIGINT (Ctrl+C), initiating graceful shutdown");
                    }
                }
            }
            
            #[cfg(not(unix))]
            {
                // On non-Unix systems, just listen for Ctrl+C
                signal::ctrl_c().await.expect("Failed to listen for Ctrl+C");
                tracing::info!("Received Ctrl+C, initiating graceful shutdown");
            }
            
            // Mark shutdown as in progress
            is_shutting_down.store(true, Ordering::Relaxed);
            
            // Notify all tasks
            let _ = shutdown_tx.send(());
        });
        
        Ok(())
    }
    
    /// Wait for graceful shutdown with timeout
    #[allow(dead_code)]
    pub async fn wait_for_shutdown(&self, tasks: Vec<tokio::task::JoinHandle<()>>) -> Result<()> {
        tracing::info!("Waiting for {} tasks to complete", tasks.len());
        
        // Give tasks 30 seconds to complete
        match timeout(Duration::from_secs(30), Self::wait_for_tasks(tasks)).await {
            Ok(_) => {
                tracing::info!("All tasks completed gracefully");
            }
            Err(_) => {
                tracing::warn!("Some tasks did not complete within timeout, forcing shutdown");
            }
        }
        
        Ok(())
    }
    
    #[allow(dead_code)]
    async fn wait_for_tasks(tasks: Vec<tokio::task::JoinHandle<()>>) {
        for task in tasks {
            let _ = task.await;
        }
    }
}

/// Shutdown guard that ensures cleanup on drop
#[allow(dead_code)]
pub struct ShutdownGuard {
    name: String,
    cleanup: Option<Box<dyn FnOnce() + Send>>,
}

impl ShutdownGuard {
    #[allow(dead_code)]
    pub fn new(name: String, cleanup: Box<dyn FnOnce() + Send>) -> Self {
        tracing::debug!(guard = %name, "Created shutdown guard");
        Self {
            name,
            cleanup: Some(cleanup),
        }
    }
}

impl Drop for ShutdownGuard {
    fn drop(&mut self) {
        if let Some(cleanup) = self.cleanup.take() {
            tracing::debug!(guard = %self.name, "Running shutdown cleanup");
            cleanup();
        }
    }
}

/// Macro to handle graceful shutdown in async contexts
#[macro_export]
macro_rules! select_with_shutdown {
    ($shutdown:expr, $($future:expr),+) => {
        tokio::select! {
            _ = $shutdown => {
                tracing::debug!("Received shutdown signal");
                break;
            }
            $($future),+
        }
    };
}