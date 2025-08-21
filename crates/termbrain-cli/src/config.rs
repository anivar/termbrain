//! Configuration management

use anyhow::Result;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

#[derive(Debug, Serialize, Deserialize)]
pub struct Config {
    pub database_path: PathBuf,
    pub shell_integration: bool,
    pub auto_record: bool,
    pub semantic_search: bool,
    pub max_history_size: usize,
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
            semantic_search: false,
            max_history_size: 10000,
        }
    }
}

impl Config {
    pub fn load() -> Result<Self> {
        // For now, return default config
        // In a full implementation, this would read from config file
        Ok(Self::default())
    }
    
}