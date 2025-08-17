pub mod domain;
pub mod application;
pub mod infrastructure;
pub mod presentation;

use anyhow::Result;
use std::path::PathBuf;

pub struct TermbrainApp {
    command_repo: Box<dyn domain::repositories::CommandRepository>,
    workflow_repo: Box<dyn domain::repositories::WorkflowRepository>,
    config: application::config::Config,
}

impl TermbrainApp {
    pub async fn new() -> Result<Self> {
        let config = application::config::Config::load()?;
        let db_path = config.data_dir().join("termbrain.db");
        
        // Initialize repositories
        let command_repo = Box::new(
            infrastructure::persistence::SqliteCommandRepository::new(&db_path).await?
        );
        let workflow_repo = Box::new(
            infrastructure::persistence::SqliteWorkflowRepository::new(&db_path).await?
        );
        
        Ok(Self {
            command_repo,
            workflow_repo,
            config,
        })
    }
    
    pub async fn search(&self, query: &str, limit: usize) -> Result<()> {
        let search_use_case = application::use_cases::SearchCommands::new(&*self.command_repo);
        let results = search_use_case.execute(query, limit).await?;
        presentation::cli::display_search_results(results);
        Ok(())
    }
    
    pub async fn show_stats(&self, range: &str) -> Result<()> {
        let stats_use_case = application::use_cases::GenerateStats::new(&*self.command_repo);
        let stats = stats_use_case.execute(range).await?;
        presentation::cli::display_stats(stats);
        Ok(())
    }
    
    pub async fn create_workflow(&self, name: &str, description: &str, commands: Vec<String>) -> Result<()> {
        let create_use_case = application::use_cases::CreateWorkflow::new(&*self.workflow_repo);
        create_use_case.execute(name, description, commands).await?;
        println!("✓ Workflow '{}' created successfully", name);
        Ok(())
    }
    
    pub async fn list_workflows(&self) -> Result<()> {
        let workflows = self.workflow_repo.list().await?;
        presentation::cli::display_workflows(workflows);
        Ok(())
    }
    
    pub async fn run_workflow(&self, name: &str) -> Result<()> {
        let run_use_case = application::use_cases::RunWorkflow::new(&*self.workflow_repo);
        run_use_case.execute(name).await?;
        Ok(())
    }
    
    pub async fn delete_workflow(&self, name: &str) -> Result<()> {
        self.workflow_repo.delete(name).await?;
        println!("✓ Workflow '{}' deleted", name);
        Ok(())
    }
    
    pub async fn set_intention(&self, intention: &str) -> Result<()> {
        let intention_use_case = application::use_cases::TrackIntention::new(&*self.command_repo);
        intention_use_case.execute(intention).await?;
        println!("✓ Intention set: {}", intention);
        Ok(())
    }
    
    pub async fn export(&self, format: &str, output: &str) -> Result<()> {
        let export_use_case = application::use_cases::ExportData::new(&*self.command_repo);
        export_use_case.execute(format, output).await?;
        println!("✓ Exported to {}", output);
        Ok(())
    }
    
    pub async fn set_predictive_mode(&self, mode: &str) -> Result<()> {
        match mode {
            "on" => self.config.set_predictive_mode(true)?,
            "off" => self.config.set_predictive_mode(false)?,
            "toggle" => {
                let current = self.config.predictive_mode();
                self.config.set_predictive_mode(!current)?;
            }
            _ => anyhow::bail!("Invalid mode: {}", mode),
        }
        
        let status = if self.config.predictive_mode() { "enabled" } else { "disabled" };
        println!("✓ Predictive mode {}", status);
        Ok(())
    }
    
    pub async fn generate_ai_context(&self) -> Result<()> {
        let ai_use_case = application::use_cases::GenerateAIContext::new(&*self.command_repo);
        let context = ai_use_case.execute().await?;
        
        let output_path = PathBuf::from(".termbrain-context.md");
        std::fs::write(&output_path, context)?;
        println!("✓ AI context generated: {}", output_path.display());
        Ok(())
    }
    
    pub async fn analyze_project(&self) -> Result<()> {
        let analyze_use_case = application::use_cases::AnalyzeProject::new(&*self.command_repo);
        let analysis = analyze_use_case.execute().await?;
        presentation::cli::display_project_analysis(analysis);
        Ok(())
    }
    
    pub async fn init_shell(&self, shell: Option<String>) -> Result<()> {
        let detected_shell = shell.or_else(|| std::env::var("SHELL").ok());
        
        match detected_shell {
            Some(s) if s.contains("bash") => {
                println!("{}", include_str!("../shell/bash/init.sh"));
            }
            Some(s) if s.contains("zsh") => {
                println!("{}", include_str!("../shell/zsh/init.sh"));
            }
            Some(s) if s.contains("fish") => {
                println!("{}", include_str!("../shell/fish/init.fish"));
            }
            _ => {
                anyhow::bail!("Could not detect shell. Please specify with --shell");
            }
        }
        
        Ok(())
    }
    
    pub async fn show_help(&self) -> Result<()> {
        // This is handled by clap automatically
        Ok(())
    }
}