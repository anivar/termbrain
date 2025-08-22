//! Configuration management

use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};
use std::fs;

#[derive(Debug, Serialize, Deserialize)]
pub struct Config {
    pub database_path: PathBuf,
    pub shell_integration: bool,
    pub auto_record: bool,
    pub semantic_search: bool,
    pub max_history_size: usize,
    pub max_database_size_mb: u64,
    pub retention_days: Option<u32>,
    pub log_level: String,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            database_path: dirs::home_dir()
                .unwrap_or_default()
                .join(".termbrain")
                .join("termbrain.db"),
            shell_integration: true,
            auto_record: true,
            semantic_search: true,  // sqlite-vec is available
            max_history_size: 10000,
            max_database_size_mb: 1024, // 1GB default
            retention_days: Some(365),
            log_level: "info".to_string(),
        }
    }
}

impl Config {
    pub fn load() -> Result<Self> {
        let config_paths = Self::get_config_paths();
        
        // Try each config path in order
        for path in &config_paths {
            if path.exists() {
                match Self::load_from_file(path) {
                    Ok(mut config) => {
                        // Apply environment variable overrides
                        config.apply_env_overrides();
                        return Ok(config);
                    }
                    Err(e) => {
                        eprintln!("Warning: Failed to load config from {}: {}", path.display(), e);
                    }
                }
            }
        }
        
        // No config file found, use defaults
        let mut config = Self::default();
        config.apply_env_overrides();
        Ok(config)
    }
    
    fn get_config_paths() -> Vec<PathBuf> {
        let mut paths = Vec::new();
        
        // 1. Environment variable
        if let Ok(path) = std::env::var("TERMBRAIN_CONFIG") {
            paths.push(PathBuf::from(path));
        }
        
        // 2. User config directory
        if let Some(home) = dirs::home_dir() {
            paths.push(home.join(".termbrain/config.toml"));
            paths.push(home.join(".config/termbrain/config.toml"));
        }
        
        // 3. System config
        paths.push(PathBuf::from("/etc/termbrain/config.toml"));
        
        paths
    }
    
    fn load_from_file(path: &Path) -> Result<Self> {
        let contents = fs::read_to_string(path)?;
        let config: Config = toml::from_str(&contents)?;
        Ok(config)
    }
    
    fn apply_env_overrides(&mut self) {
        if let Ok(path) = std::env::var("TERMBRAIN_DATABASE_PATH") {
            self.database_path = PathBuf::from(path);
        }
        
        if let Ok(level) = std::env::var("TERMBRAIN_LOG_LEVEL") {
            self.log_level = level;
        }
        
        if let Ok(size) = std::env::var("TERMBRAIN_MAX_DB_SIZE_MB") {
            if let Ok(size_mb) = size.parse::<u64>() {
                self.max_database_size_mb = size_mb;
            }
        }
        
        if let Ok(enabled) = std::env::var("TERMBRAIN_AUTO_RECORD") {
            self.auto_record = enabled == "1" || enabled.to_lowercase() == "true";
        }
    }
    
    #[allow(dead_code)]
    pub fn save(&self, path: &Path) -> Result<()> {
        let contents = toml::to_string_pretty(self)?;
        
        // Create parent directory if needed
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)?;
        }
        
        fs::write(path, contents)?;
        Ok(())
    }
}
