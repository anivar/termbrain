use crate::domain::repositories::CommandRepository;
use crate::domain::entities::{Command, SemanticType};
use anyhow::Result;

pub struct ExplainCommands<'a> {
    command_repository: &'a dyn CommandRepository,
}

impl<'a> ExplainCommands<'a> {
    pub fn new(command_repository: &'a dyn CommandRepository) -> Self {
        Self { command_repository }
    }
    
    pub async fn execute(&self, limit: usize) -> Result<Vec<CommandExplanation>> {
        let recent_commands = self.command_repository.get_recent(limit).await?;
        
        let mut explanations = Vec::new();
        for cmd in recent_commands {
            let explanation = self.explain_command(&cmd);
            explanations.push(explanation);
        }
        
        Ok(explanations)
    }
    
    fn explain_command(&self, command: &Command) -> CommandExplanation {
        let base_cmd = command.command.split_whitespace().next().unwrap_or("");
        let args: Vec<&str> = command.command.split_whitespace().skip(1).collect();
        
        let (purpose, impact, alternatives) = match (base_cmd, command.semantic_type) {
            ("git", SemanticType::VersionControl) => {
                self.explain_git_command(&command.command, &args)
            }
            ("npm", SemanticType::PackageManagement) | ("yarn", SemanticType::PackageManagement) => {
                self.explain_npm_command(&command.command, &args)
            }
            ("docker", SemanticType::Container) => {
                self.explain_docker_command(&command.command, &args)
            }
            ("cd", SemanticType::Navigation) => {
                (
                    format!("Navigate to directory: {}", args.first().unwrap_or(&"home")),
                    "Changes current working directory".to_string(),
                    vec!["pushd (to save current directory)", "z (smart directory jumping)"],
                )
            }
            ("rm", SemanticType::FileOperation) => {
                let force = args.contains(&"-f") || args.contains(&"-rf");
                let recursive = args.contains(&"-r") || args.contains(&"-rf");
                (
                    format!("Remove files/directories{}{}", 
                        if recursive { " recursively" } else { "" },
                        if force { " forcefully" } else { "" }
                    ),
                    if force { "⚠️ Permanent deletion without confirmation" } else { "Deletes files (asks for confirmation)" }.to_string(),
                    vec!["trash (moves to trash instead)", "rm -i (interactive mode)"],
                )
            }
            _ => self.generic_explanation(base_cmd, &args),
        };
        
        CommandExplanation {
            command: command.command.clone(),
            timestamp: command.timestamp,
            purpose,
            impact,
            alternatives,
            success: command.exit_code == 0,
            context: self.analyze_context(command),
        }
    }
    
    fn explain_git_command(&self, cmd: &str, args: &[&str]) -> (String, String, Vec<&'static str>) {
        if args.is_empty() {
            return ("Show git help".to_string(), "No impact".to_string(), vec![]);
        }
        
        match args[0] {
            "add" => (
                "Stage files for commit".to_string(),
                "Prepares changes to be committed".to_string(),
                vec!["git add -p (interactive staging)", "git add -u (stage only tracked files)"],
            ),
            "commit" => (
                "Save changes to repository".to_string(),
                "Creates a new commit with staged changes".to_string(),
                vec!["git commit --amend (modify last commit)", "git commit -a (commit all tracked changes)"],
            ),
            "push" => (
                "Upload commits to remote repository".to_string(),
                "Shares your changes with team".to_string(),
                vec!["git push --force-with-lease (safer force push)", "git push -u (set upstream)"],
            ),
            "pull" => (
                "Download and merge remote changes".to_string(),
                "Updates local branch with remote changes".to_string(),
                vec!["git fetch && git merge (explicit two-step)", "git pull --rebase (linear history)"],
            ),
            "status" => (
                "Check repository state".to_string(),
                "No impact - read only".to_string(),
                vec!["git status -sb (short format)", "git diff (see actual changes)"],
            ),
            _ => self.generic_explanation("git", args),
        }
    }
    
    fn explain_npm_command(&self, cmd: &str, args: &[&str]) -> (String, String, Vec<&'static str>) {
        if args.is_empty() {
            return ("Show npm help".to_string(), "No impact".to_string(), vec![]);
        }
        
        match args[0] {
            "install" | "i" => (
                "Install project dependencies".to_string(),
                "Downloads packages to node_modules".to_string(),
                vec!["yarn install", "pnpm install (faster alternative)"],
            ),
            "run" => (
                format!("Execute script: {}", args.get(1).unwrap_or(&"<script>")),
                "Runs defined npm script".to_string(),
                vec!["yarn run", "npx (run without installing)"],
            ),
            "test" => (
                "Run test suite".to_string(),
                "Executes project tests".to_string(),
                vec!["npm run test:watch", "jest --coverage"],
            ),
            _ => self.generic_explanation("npm", args),
        }
    }
    
    fn explain_docker_command(&self, cmd: &str, args: &[&str]) -> (String, String, Vec<&'static str>) {
        if args.is_empty() {
            return ("Show docker help".to_string(), "No impact".to_string(), vec![]);
        }
        
        match args[0] {
            "run" => (
                "Create and start new container".to_string(),
                "Launches container from image".to_string(),
                vec!["docker-compose up", "podman run"],
            ),
            "build" => (
                "Build image from Dockerfile".to_string(),
                "Creates new Docker image".to_string(),
                vec!["docker buildx (multi-platform)", "buildah"],
            ),
            "ps" => (
                "List running containers".to_string(),
                "No impact - read only".to_string(),
                vec!["docker ps -a (all containers)", "docker container ls"],
            ),
            _ => self.generic_explanation("docker", args),
        }
    }
    
    fn generic_explanation(&self, cmd: &str, args: &[&str]) -> (String, String, Vec<&'static str>) {
        (
            format!("Execute '{}' with {} arguments", cmd, args.len()),
            "Check command documentation for details".to_string(),
            vec!["man page", "tldr", "--help flag"],
        )
    }
    
    fn analyze_context(&self, command: &Command) -> CommandContext {
        CommandContext {
            working_directory: command.directory.clone(),
            git_branch: command.git_branch.clone(),
            intention: command.intent.clone(),
            complexity_score: command.complexity,
        }
    }
}

#[derive(Debug, Clone)]
pub struct CommandExplanation {
    pub command: String,
    pub timestamp: chrono::DateTime<chrono::Utc>,
    pub purpose: String,
    pub impact: String,
    pub alternatives: Vec<&'static str>,
    pub success: bool,
    pub context: CommandContext,
}

#[derive(Debug, Clone)]
pub struct CommandContext {
    pub working_directory: String,
    pub git_branch: Option<String>,
    pub intention: Option<String>,
    pub complexity_score: u8,
}