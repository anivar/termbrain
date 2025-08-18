use anyhow::Result;
use directories::ProjectDirs;
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use tokio::fs;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Config {
    #[serde(default)]
    pub predictive_mode: bool,
    
    #[serde(default)]
    pub data_dir: Option<PathBuf>,
    
    #[serde(default)]
    pub export_dir: Option<PathBuf>,
    
    #[serde(default = "default_history_limit")]
    pub history_limit: usize,
    
    #[serde(default)]
    pub disabled_directories: Vec<String>,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            predictive_mode: false,
            data_dir: None,
            export_dir: None,
            history_limit: default_history_limit(),
            disabled_directories: vec![],
        }
    }
}

fn default_history_limit() -> usize {
    10000
}

impl Config {
    pub async fn load() -> Result<Self> {
        let config_path = Self::config_path()?;
        
        if config_path.exists() {
            let content = fs::read_to_string(&config_path).await?;
            let config: Config = toml::from_str(&content)?;
            Ok(config)
        } else {
            let config = Config::default();
            config.save().await?;
            Ok(config)
        }
    }
    
    pub async fn save(&self) -> Result<()> {
        let config_path = Self::config_path()?;
        
        // Ensure parent directory exists
        if let Some(parent) = config_path.parent() {
            fs::create_dir_all(parent).await?;
        }
        
        let content = toml::to_string_pretty(self)?;
        fs::write(&config_path, content).await?;
        
        Ok(())
    }
    
    pub fn data_dir(&self) -> PathBuf {
        self.data_dir.clone().unwrap_or_else(|| {
            Self::project_dirs()
                .map(|dirs| dirs.data_dir().to_path_buf())
                .unwrap_or_else(|| {
                    dirs::home_dir()
                        .unwrap_or_else(|| PathBuf::from("."))
                        .join(".termbrain/data")
                })
        })
    }
    
    pub fn export_dir(&self) -> PathBuf {
        self.export_dir.clone().unwrap_or_else(|| {
            self.data_dir().parent()
                .unwrap_or(&PathBuf::from("."))
                .join("exports")
        })
    }
    
    pub fn predictive_mode(&self) -> bool {
        self.predictive_mode
    }
    
    pub async fn set_predictive_mode(&self, enabled: bool) -> Result<()> {
        let mut config = self.clone();
        config.predictive_mode = enabled;
        config.save().await?;
        Ok(())
    }
    
    fn config_path() -> Result<PathBuf> {
        Ok(Self::project_dirs()
            .map(|dirs| dirs.config_dir().join("config.toml"))
            .unwrap_or_else(|| {
                dirs::home_dir()
                    .unwrap_or_else(|| PathBuf::from("."))
                    .join(".termbrain/config.toml")
            }))
    }
    
    fn project_dirs() -> Option<ProjectDirs> {
        ProjectDirs::from("com", "termbrain", "termbrain")
    }
}

// Re-export for infrastructure use
pub use self::Config as Settings;