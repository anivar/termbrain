use crate::application::config::Config;
use anyhow::Result;

pub struct ManagePredictive<'a> {
    config: &'a Config,
}

impl<'a> ManagePredictive<'a> {
    pub fn new(config: &'a Config) -> Self {
        Self { config }
    }
    
    pub async fn execute(&self, mode: &str) -> Result<()> {
        match mode {
            "on" => {
                self.config.set_predictive_mode(true).await?;
            }
            "off" => {
                self.config.set_predictive_mode(false).await?;
            }
            "toggle" => {
                let current = self.config.predictive_mode();
                self.config.set_predictive_mode(!current).await?;
            }
            _ => anyhow::bail!("Invalid mode: {}. Use 'on', 'off', or 'toggle'", mode),
        }
        
        Ok(())
    }
}