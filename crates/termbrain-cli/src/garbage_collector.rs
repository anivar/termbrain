//! Database and log garbage collection and cleanup

use anyhow::Result;
use chrono::{DateTime, Duration, Utc};
use std::path::{Path, PathBuf};
use termbrain_storage::SqliteStorage;
use tokio::time::{interval, Duration as TokioDuration};

/// Garbage collector for database maintenance
pub struct GarbageCollector {
    storage: SqliteStorage,
    max_database_size_mb: u64,
    retention_days: Option<u32>,
}

impl GarbageCollector {
    pub fn new(storage: SqliteStorage, max_database_size_mb: u64, retention_days: Option<u32>) -> Self {
        Self {
            storage,
            max_database_size_mb,
            retention_days,
        }
    }
    
    /// Start the garbage collector background task
    pub async fn start(self) {
        let mut interval = interval(TokioDuration::from_secs(3600)); // Run every hour
        
        loop {
            interval.tick().await;
            
            let start = std::time::Instant::now();
            match self.run_cleanup().await {
                Ok(deleted) => {
                    let duration = start.elapsed().as_millis() as u64;
                    crate::logging::log_garbage_collection(deleted, duration);
                }
                Err(e) => {
                    tracing::error!(error = %e, "Garbage collection failed");
                }
            }
        }
    }
    
    /// Run cleanup operations
    async fn run_cleanup(&self) -> Result<usize> {
        let mut total_deleted = 0;
        
        // 1. Clean up logs first
        match self.cleanup_old_logs().await {
            Ok(deleted) => {
                if deleted > 0 {
                    tracing::info!(deleted_logs = deleted, "Cleaned up old log files");
                }
            }
            Err(e) => {
                tracing::warn!(error = %e, "Failed to clean up logs");
            }
        }
        
        // 2. Check database size
        let db_size_mb = self.get_database_size_mb().await?;
        tracing::debug!(size_mb = db_size_mb, limit_mb = self.max_database_size_mb, "Checking database size");
        
        if db_size_mb > self.max_database_size_mb {
            // Delete oldest commands until we're under the limit
            let to_delete = self.calculate_records_to_delete(db_size_mb).await?;
            total_deleted += self.delete_oldest_commands(to_delete).await?;
            
            tracing::info!(
                deleted = total_deleted,
                "Deleted commands due to size limit"
            );
        }
        
        // 3. Apply retention policy if configured
        if let Some(days) = self.retention_days {
            let cutoff = Utc::now() - Duration::days(days as i64);
            let deleted = self.delete_commands_before(cutoff).await?;
            total_deleted += deleted;
            
            if deleted > 0 {
                tracing::info!(
                    deleted = deleted,
                    retention_days = days,
                    "Deleted commands due to retention policy"
                );
            }
        }
        
        // 4. Vacuum database to reclaim space
        if total_deleted > 0 {
            self.vacuum_database().await?;
        }
        
        // 5. Check and clean temporary files
        self.cleanup_temp_files().await?;
        
        Ok(total_deleted)
    }
    
    /// Get current database size in MB
    async fn get_database_size_mb(&self) -> Result<u64> {
        let size_bytes = self.storage.get_database_size().await?;
        Ok(size_bytes / (1024 * 1024))
    }
    
    /// Calculate how many records to delete based on size
    async fn calculate_records_to_delete(&self, current_size_mb: u64) -> Result<usize> {
        // Aim to reduce to 80% of max size
        let target_size_mb = (self.max_database_size_mb as f64 * 0.8) as u64;
        let size_to_reduce_mb = current_size_mb - target_size_mb;
        
        // Estimate: assume average command record is ~1KB
        let records_to_delete = (size_to_reduce_mb * 1024) as usize;
        
        Ok(records_to_delete)
    }
    
    /// Delete oldest commands
    async fn delete_oldest_commands(&self, count: usize) -> Result<usize> {
        self.storage.delete_oldest_commands(count).await
    }
    
    /// Delete commands before a certain date
    async fn delete_commands_before(&self, cutoff: DateTime<Utc>) -> Result<usize> {
        self.storage.delete_commands_before(cutoff).await
    }
    
    /// Vacuum database to reclaim space
    async fn vacuum_database(&self) -> Result<()> {
        tracing::debug!("Vacuuming database");
        self.storage.vacuum().await
    }
    
    /// Clean up old log files
    async fn cleanup_old_logs(&self) -> Result<usize> {
        let log_dir = dirs::home_dir()
            .unwrap_or_default()
            .join(".termbrain")
            .join("logs");
            
        if !log_dir.exists() {
            return Ok(0);
        }
        
        let mut deleted = 0;
        let cutoff = Utc::now() - Duration::days(7); // Keep 7 days of logs
        
        let mut entries = tokio::fs::read_dir(&log_dir).await?;
        while let Some(entry) = entries.next_entry().await? {
            let path = entry.path();
            if path.extension().and_then(|s| s.to_str()) == Some("log") {
                if let Ok(metadata) = entry.metadata().await {
                    if let Ok(modified) = metadata.modified() {
                        let modified_time: DateTime<Utc> = modified.into();
                        if modified_time < cutoff {
                            if tokio::fs::remove_file(&path).await.is_ok() {
                                deleted += 1;
                                tracing::debug!(?path, "Deleted old log file");
                            }
                        }
                    }
                }
            }
        }
        
        // Also check total log directory size
        self.enforce_log_size_limit(&log_dir).await?;
        
        Ok(deleted)
    }
    
    /// Enforce maximum log directory size
    async fn enforce_log_size_limit(&self, log_dir: &Path) -> Result<()> {
        const MAX_LOG_SIZE_MB: u64 = 100; // 100MB max for logs
        
        let total_size = self.calculate_directory_size(log_dir).await?;
        let size_mb = total_size / (1024 * 1024);
        
        if size_mb > MAX_LOG_SIZE_MB {
            // Delete oldest logs until under limit
            let mut files = self.get_files_sorted_by_age(log_dir).await?;
            
            while size_mb > MAX_LOG_SIZE_MB && !files.is_empty() {
                if let Some((path, _)) = files.pop() {
                    if tokio::fs::remove_file(&path).await.is_ok() {
                        tracing::debug!(?path, "Deleted log file due to size limit");
                    }
                }
            }
        }
        
        Ok(())
    }
    
    /// Calculate total size of a directory
    async fn calculate_directory_size(&self, dir: &Path) -> Result<u64> {
        let mut total_size = 0;
        let mut entries = tokio::fs::read_dir(dir).await?;
        
        while let Some(entry) = entries.next_entry().await? {
            if let Ok(metadata) = entry.metadata().await {
                total_size += metadata.len();
            }
        }
        
        Ok(total_size)
    }
    
    /// Get files sorted by modification time (oldest first)
    async fn get_files_sorted_by_age(&self, dir: &Path) -> Result<Vec<(PathBuf, DateTime<Utc>)>> {
        let mut files = Vec::new();
        let mut entries = tokio::fs::read_dir(dir).await?;
        
        while let Some(entry) = entries.next_entry().await? {
            let path = entry.path();
            if path.is_file() {
                if let Ok(metadata) = entry.metadata().await {
                    if let Ok(modified) = metadata.modified() {
                        let modified_time: DateTime<Utc> = modified.into();
                        files.push((path, modified_time));
                    }
                }
            }
        }
        
        files.sort_by(|a, b| a.1.cmp(&b.1));
        Ok(files)
    }
    
    /// Clean up temporary files
    async fn cleanup_temp_files(&self) -> Result<()> {
        let temp_dir = dirs::home_dir()
            .unwrap_or_default()
            .join(".termbrain")
            .join("tmp");
            
        if temp_dir.exists() {
            // Remove temp files older than 1 hour
            let cutoff = Utc::now() - Duration::hours(1);
            let mut entries = tokio::fs::read_dir(&temp_dir).await?;
            
            while let Some(entry) = entries.next_entry().await? {
                if let Ok(metadata) = entry.metadata().await {
                    if let Ok(modified) = metadata.modified() {
                        let modified_time: DateTime<Utc> = modified.into();
                        if modified_time < cutoff {
                            let _ = tokio::fs::remove_file(entry.path()).await;
                        }
                    }
                }
            }
        }
        
        Ok(())
    }
}