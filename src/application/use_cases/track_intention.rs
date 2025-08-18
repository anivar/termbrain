use crate::domain::repositories::IntentionRepository;
use crate::domain::entities::Intention;
use crate::domain::value_objects::SessionId;
use anyhow::Result;
use std::env;

pub struct TrackIntention<'a> {
    intention_repository: &'a dyn IntentionRepository,
}

impl<'a> TrackIntention<'a> {
    pub fn new(intention_repository: &'a dyn IntentionRepository) -> Self {
        Self { intention_repository }
    }
    
    pub async fn execute(&self, intention_text: &str) -> Result<()> {
        let session_id = SessionId::new();
        
        // Create intention entity
        let intention = Intention {
            id: uuid::Uuid::new_v4(),
            session_id: session_id.to_string(),
            intention: intention_text.to_string(),
            created_at: chrono::Utc::now(),
            achieved: false,
            commands_count: 0,
        };
        
        // Save to repository
        self.intention_repository.save(&intention).await?;
        
        // Set environment variable for shell hooks
        env::set_var("TERMBRAIN_INTENTION", intention_text);
        env::set_var("TERMBRAIN_INTENTION_ID", intention.id.to_string());
        
        Ok(())
    }
    
    pub async fn mark_achieved(&self, session_id: &str) -> Result<()> {
        if let Some(intention) = self.intention_repository.get_current(session_id).await? {
            self.intention_repository.mark_achieved(&intention.id.to_string()).await?;
            
            // Clear environment variables
            env::remove_var("TERMBRAIN_INTENTION");
            env::remove_var("TERMBRAIN_INTENTION_ID");
        }
        
        Ok(())
    }
}