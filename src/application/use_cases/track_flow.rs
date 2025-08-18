use crate::domain::repositories::CommandRepository;
use crate::application::dto::FlowState;
use anyhow::Result;
use std::env;
use std::path::PathBuf;
use tokio::fs;

pub struct TrackFlow<'a> {
    command_repository: &'a dyn CommandRepository,
}

impl<'a> TrackFlow<'a> {
    pub fn new(command_repository: &'a dyn CommandRepository) -> Self {
        Self { command_repository }
    }
    
    pub async fn start_flow(&self) -> Result<()> {
        let flow_file = self.flow_state_file();
        
        // Create flow state
        let state = FlowStateData {
            started_at: chrono::Utc::now(),
            session_id: std::process::id().to_string(),
        };
        
        // Save to file
        let content = serde_json::to_string(&state)?;
        fs::write(&flow_file, content).await?;
        
        // Set environment variable
        env::set_var("TERMBRAIN_IN_FLOW", "true");
        
        Ok(())
    }
    
    pub async fn end_flow(&self) -> Result<FlowState> {
        let flow_file = self.flow_state_file();
        
        if !flow_file.exists() {
            return Ok(FlowState {
                in_flow: false,
                duration_minutes: None,
                productivity_score: None,
                focus_area: None,
            });
        }
        
        // Read flow state
        let content = fs::read_to_string(&flow_file).await?;
        let state: FlowStateData = serde_json::from_str(&content)?;
        
        // Calculate duration
        let duration = chrono::Utc::now() - state.started_at;
        let duration_minutes = duration.num_minutes() as u64;
        
        // Analyze commands during flow
        let commands = self.command_repository
            .get_recent(1000)
            .await?;
        
        // Simple productivity score based on success rate
        let total = commands.len() as f64;
        let successful = commands.iter()
            .filter(|c| c.exit_code == 0)
            .count() as f64;
        
        let productivity_score = if total > 0.0 {
            (successful / total) * 10.0
        } else {
            5.0
        };
        
        // Detect focus area
        let focus_area = self.detect_focus_area(&commands);
        
        // Clean up
        fs::remove_file(&flow_file).await?;
        env::remove_var("TERMBRAIN_IN_FLOW");
        
        Ok(FlowState {
            in_flow: false,
            duration_minutes: Some(duration_minutes),
            productivity_score: Some(productivity_score),
            focus_area,
        })
    }
    
    pub async fn get_status(&self) -> Result<FlowState> {
        let flow_file = self.flow_state_file();
        
        if !flow_file.exists() {
            return Ok(FlowState {
                in_flow: false,
                duration_minutes: None,
                productivity_score: None,
                focus_area: None,
            });
        }
        
        // Read flow state
        let content = fs::read_to_string(&flow_file).await?;
        let state: FlowStateData = serde_json::from_str(&content)?;
        
        // Calculate current duration
        let duration = chrono::Utc::now() - state.started_at;
        let duration_minutes = duration.num_minutes() as u64;
        
        Ok(FlowState {
            in_flow: true,
            duration_minutes: Some(duration_minutes),
            productivity_score: None,
            focus_area: None,
        })
    }
    
    fn flow_state_file(&self) -> PathBuf {
        dirs::cache_dir()
            .unwrap_or_else(|| PathBuf::from("/tmp"))
            .join("termbrain_flow_state.json")
    }
    
    fn detect_focus_area(&self, commands: &[crate::domain::entities::Command]) -> Option<String> {
        use std::collections::HashMap;
        
        let mut type_counts = HashMap::new();
        
        for cmd in commands {
            *type_counts.entry(cmd.semantic_type).or_insert(0) += 1;
        }
        
        type_counts
            .into_iter()
            .max_by_key(|(_, count)| *count)
            .map(|(semantic_type, _)| format!("{:?}", semantic_type))
    }
}

#[derive(serde::Serialize, serde::Deserialize)]
struct FlowStateData {
    started_at: chrono::DateTime<chrono::Utc>,
    session_id: String,
}