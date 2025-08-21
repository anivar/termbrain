use anyhow::{anyhow, Result};
use reqwest::Client;
use serde::{Deserialize, Serialize};
use std::time::Duration;
use tracing::{debug, warn};

use crate::config::Config;

#[derive(Debug, Clone)]
pub struct ClaudeClient {
    client: Client,
    api_key: String,
    base_url: String,
    model: String,
    max_tokens: u32,
    temperature: f32,
}

#[derive(Debug, Serialize)]
struct ClaudeRequest {
    model: String,
    max_tokens: u32,
    temperature: f32,
    messages: Vec<Message>,
}

#[derive(Debug, Serialize)]
struct Message {
    role: String,
    content: String,
}

#[derive(Debug, Deserialize)]
struct ClaudeResponse {
    content: Vec<Content>,
    usage: Option<Usage>,
}

#[derive(Debug, Deserialize)]
struct Content {
    #[serde(rename = "type")]
    content_type: String,
    text: String,
}

#[derive(Debug, Deserialize)]
struct Usage {
    input_tokens: u32,
    output_tokens: u32,
}

impl ClaudeClient {
    pub async fn new(config: &Config) -> Result<Self> {
        let client = Client::builder()
            .timeout(Duration::from_secs(config.claude.timeout_seconds))
            .build()?;

        Ok(Self {
            client,
            api_key: config.claude.api_key.clone(),
            base_url: config.claude.base_url.clone(),
            model: config.claude.model.clone(),
            max_tokens: config.claude.max_tokens,
            temperature: config.claude.temperature,
        })
    }

    pub async fn send_message(&self, prompt: &str) -> Result<String> {
        debug!("Sending message to Claude: {}", prompt);

        let request = ClaudeRequest {
            model: self.model.clone(),
            max_tokens: self.max_tokens,
            temperature: self.temperature,
            messages: vec![Message {
                role: "user".to_string(),
                content: prompt.to_string(),
            }],
        };

        let response = self
            .client
            .post(&format!("{}/v1/messages", self.base_url))
            .header("x-api-key", &self.api_key)
            .header("anthropic-version", "2023-06-01")
            .header("Content-Type", "application/json")
            .json(&request)
            .send()
            .await?;

        if !response.status().is_success() {
            let error_text = response.text().await?;
            warn!("Claude API error: {}", error_text);
            return Err(anyhow!("Claude API error: {}", error_text));
        }

        let claude_response: ClaudeResponse = response.json().await?;
        
        if let Some(usage) = &claude_response.usage {
            debug!("Token usage - Input: {}, Output: {}", usage.input_tokens, usage.output_tokens);
        }

        // Extract text from the first content block
        claude_response
            .content
            .first()
            .map(|content| content.text.clone())
            .ok_or_else(|| anyhow!("No content in Claude response"))
    }

    pub async fn analyze_command(&self, command: &str) -> Result<String> {
        let prompt = format!(
            r#"Please analyze this command and provide insights:

Command: `{}`

Provide a comprehensive analysis including:
1. What this command does (step by step breakdown)
2. Potential issues or risks
3. Suggested improvements or alternatives
4. Security considerations (if any)
5. Performance tips
6. Common use cases

Format your response in clear, concise markdown."#,
            command
        );

        self.send_message(&prompt).await
    }

    pub async fn suggest_commands(&self, context: Option<&str>, history: &[String]) -> Result<String> {
        let context_part = context
            .map(|c| format!("Context: {}\n", c))
            .unwrap_or_default();

        let history_part = if history.is_empty() {
            "No recent command history available.".to_string()
        } else {
            format!(
                "Recent command history:\n{}",
                history
                    .iter()
                    .take(20)
                    .enumerate()
                    .map(|(i, cmd)| format!("{}. {}", i + 1, cmd))
                    .collect::<Vec<_>>()
                    .join("\n")
            )
        };

        let prompt = format!(
            r#"Based on the user's command history and context, suggest relevant commands they might want to use next.

{}
{}

Please provide:
1. 3-5 specific command suggestions with explanations
2. Any workflow optimizations you notice
3. Patterns in their usage that could be improved
4. Helpful aliases or shortcuts they could create

Focus on practical, actionable suggestions based on their apparent workflow."#,
            context_part, history_part
        );

        self.send_message(&prompt).await
    }

    pub async fn diagnose_error(&self, command: &str, exit_code: i32, error_output: Option<&str>) -> Result<String> {
        let error_part = error_output
            .map(|e| format!("Error output:\n{}\n", e))
            .unwrap_or_default();

        let prompt = format!(
            r#"Help diagnose this failed command:

Command: `{}`
Exit code: {}
{}

Please provide:
1. Likely causes for this failure
2. Step-by-step troubleshooting steps
3. Common solutions for this type of error
4. How to prevent this error in the future
5. Alternative approaches if the original command can't be fixed

Be specific and actionable in your recommendations."#,
            command, exit_code, error_part
        );

        self.send_message(&prompt).await
    }

    pub async fn generate_learning_content(&self, topic: &str, skill_level: &str) -> Result<String> {
        let prompt = format!(
            r#"Create a comprehensive learning guide for the topic: "{}"
Target skill level: {}

Please provide:
1. Brief overview of the topic
2. Key concepts and terminology
3. Essential commands with examples
4. Common patterns and best practices
5. Practical exercises to try
6. Common pitfalls to avoid
7. Next steps for advancing skills

Make it practical and hands-on, focusing on real-world usage."#,
            topic, skill_level
        );

        self.send_message(&prompt).await
    }

    pub async fn analyze_patterns(&self, commands: &[String], timeframe_days: u32) -> Result<String> {
        let command_list = commands
            .iter()
            .take(100) // Limit to prevent token overflow
            .enumerate()
            .map(|(i, cmd)| format!("{}. {}", i + 1, cmd))
            .collect::<Vec<_>>()
            .join("\n");

        let prompt = format!(
            r#"Analyze these commands from the last {} days to identify patterns and workflows:

Commands:
{}

Please identify:
1. Common command sequences or workflows
2. Repeated patterns with confidence scores
3. Time-based patterns (if any temporal data is apparent)
4. Optimization opportunities
5. Potential automation candidates
6. Areas where aliases or scripts would help

Focus on actionable insights that could improve productivity."#,
            timeframe_days, command_list
        );

        self.send_message(&prompt).await
    }

    pub async fn generate_summary(&self, commands: &[String], date: &str) -> Result<String> {
        let summary_data = if commands.is_empty() {
            "No commands executed on this date.".to_string()
        } else {
            // Group commands by category for better analysis
            let command_text = commands
                .iter()
                .take(50) // Limit for token efficiency
                .collect::<Vec<_>>()
                .join("\n");

            format!("Commands executed ({} total):\n{}", commands.len(), command_text)
        };

        let prompt = format!(
            r#"Generate a daily summary report for command usage on {}.

{}

Please provide:
1. Overview of activity level and focus areas
2. Top command categories and their frequency
3. Notable patterns or workflows
4. Productivity insights and observations
5. Suggestions for tomorrow
6. Learning opportunities based on usage
7. A productivity score (1-10) with brief reasoning

Make it engaging and actionable, like a personal AI assistant reviewing the day."#,
            date, summary_data
        );

        self.send_message(&prompt).await
    }

    pub async fn test_connection(&self) -> Result<()> {
        debug!("Testing Claude API connection");
        
        let test_message = "Hello! Please respond with 'Connection successful' to confirm the API is working.";
        let response = self.send_message(test_message).await?;
        
        if response.to_lowercase().contains("connection successful") || response.to_lowercase().contains("working") {
            debug!("Claude API connection test successful");
            Ok(())
        } else {
            warn!("Unexpected response from Claude API: {}", response);
            Err(anyhow!("Unexpected response from Claude API"))
        }
    }

    pub fn get_model_info(&self) -> ClaudeModelInfo {
        ClaudeModelInfo {
            model: self.model.clone(),
            max_tokens: self.max_tokens,
            temperature: self.temperature,
        }
    }
}

#[derive(Debug)]
pub struct ClaudeModelInfo {
    pub model: String,
    pub max_tokens: u32,
    pub temperature: f32,
}

// Mock implementation for testing/demo purposes
impl ClaudeClient {
    pub fn new_mock() -> Self {
        Self {
            client: Client::new(),
            api_key: "mock-key".to_string(),
            base_url: "https://api.anthropic.com".to_string(),
            model: "claude-3-5-sonnet-20241022".to_string(),
            max_tokens: 4096,
            temperature: 0.1,
        }
    }

    pub async fn send_message_mock(&self, prompt: &str) -> Result<String> {
        // Simulate API delay
        tokio::time::sleep(Duration::from_millis(500)).await;

        // Return mock responses based on prompt content
        if prompt.contains("analyze this command") {
            Ok(self.mock_command_analysis())
        } else if prompt.contains("suggest commands") {
            Ok(self.mock_command_suggestions())
        } else if prompt.contains("diagnose") {
            Ok(self.mock_error_diagnosis())
        } else if prompt.contains("learning guide") {
            Ok(self.mock_learning_content())
        } else if prompt.contains("analyze patterns") {
            Ok(self.mock_pattern_analysis())
        } else if prompt.contains("daily summary") {
            Ok(self.mock_daily_summary())
        } else {
            Ok("This is a mock response from Claude. In a real implementation, this would connect to the Anthropic API.".to_string())
        }
    }

    fn mock_command_analysis(&self) -> String {
        r#"## Command Analysis

This command demonstrates a complex find and grep operation:

### Breakdown:
1. `find . -name '*.rs'` - Searches recursively for Rust files
2. `-exec grep -l 'async fn' {} \;` - Executes grep on each file to find async functions

### Suggestions:
- Use `ripgrep` for better performance: `rg -l "async fn" --type rust`
- Add `--exclude-dir target` to skip build artifacts
- Consider using `fd` instead of find for modern file searching

### Security Notes:
- Be cautious with `-exec` as it can execute commands on found files
- Always validate file paths in scripts

### Performance Tips:
- The `\;` syntax runs grep once per file (slower)
- Use `\+` to batch multiple files per grep call"#.to_string()
    }

    fn mock_command_suggestions(&self) -> String {
        r#"## Command Suggestions

Based on your command history, here are some helpful suggestions:

### Git Workflow Optimizations:
1. `git commit -am "message"` - Combine add and commit for tracked files
2. `git log --oneline -10` - Concise commit history
3. `git push -u origin main` - Set upstream while pushing

### Development Shortcuts:
1. `cargo watch -x test` - Automatically run tests on file changes
2. `cargo check` - Fast syntax checking without building
3. `cargo clippy` - Lint suggestions for better code

### Productivity Aliases:
```bash
alias gst="git status"
alias gaa="git add ."
alias gcm="git commit -m"
```

Your usage patterns suggest you'd benefit from setting up git hooks for automated testing!"#.to_string()
    }

    fn mock_error_diagnosis(&self) -> String {
        r#"## Error Diagnosis

Exit code 125 typically indicates Docker daemon issues or port conflicts.

### Likely Causes:
1. **Port 8080 already in use** - Another service is bound to this port
2. **Docker daemon not running** - Docker service needs to be started
3. **Insufficient permissions** - User lacks Docker privileges

### Troubleshooting Steps:
1. Check port usage: `lsof -i :8080` or `netstat -tulpn | grep 8080`
2. Start Docker daemon: `sudo systemctl start docker`
3. Verify Docker status: `docker info`
4. Check user groups: `groups $USER` (should include 'docker')

### Solutions:
1. **Use different port**: `docker run -p 8081:80 nginx`
2. **Stop conflicting service**: `sudo kill $(lsof -t -i:8080)`
3. **Add user to docker group**: `sudo usermod -aG docker $USER`

### Prevention:
- Always check port availability before binding
- Use `docker ps` to see running containers
- Set up port ranges for development environments"#.to_string()
    }

    fn mock_learning_content(&self) -> String {
        r#"## Learning: Kubernetes Commands

### Overview
Kubernetes (k8s) is a container orchestration platform. kubectl is the command-line tool for interacting with Kubernetes clusters.

### Essential Commands

#### Cluster Information:
- `kubectl cluster-info` - Display cluster information
- `kubectl get nodes` - List cluster nodes
- `kubectl get namespaces` - List all namespaces

#### Pod Management:
- `kubectl get pods` - List pods in current namespace
- `kubectl get pods -A` - List pods in all namespaces
- `kubectl describe pod <name>` - Detailed pod information
- `kubectl logs <pod-name>` - View pod logs
- `kubectl exec -it <pod> -- /bin/bash` - Access pod shell

#### Deployments:
- `kubectl get deployments` - List deployments
- `kubectl apply -f deployment.yaml` - Apply configuration
- `kubectl scale deployment <name> --replicas=3` - Scale deployment
- `kubectl rollout status deployment/<name>` - Check rollout status

### Best Practices:
1. Always specify namespace: `kubectl get pods -n production`
2. Use labels for filtering: `kubectl get pods -l app=nginx`
3. Save configurations in version control
4. Use `--dry-run=client -o yaml` to preview changes

### Next Steps:
1. Practice with minikube locally
2. Learn about services and ingress
3. Explore helm for package management
4. Study monitoring with kubectl top"#.to_string()
    }

    fn mock_pattern_analysis(&self) -> String {
        r#"## Discovered Command Patterns

### Pattern 1: Development Cycle (Confidence: 92%)
**Sequence**: `git status` → `git add .` → `git commit -m` → `git push`
- Occurs 15 times in the analyzed period
- Average cycle time: 3.2 minutes
- **Optimization**: Create alias `gcp` for "git commit and push"

### Pattern 2: Testing Workflow (Confidence: 87%)
**Sequence**: `cargo build` → `cargo test` → `cargo run`
- Often followed by git commands when tests pass
- **Suggestion**: Use `cargo watch` for automatic rebuilds
- **Alias suggestion**: `alias ctr="cargo test && cargo run"`

### Pattern 3: Docker Development (Confidence: 78%)
**Sequence**: `docker build` → `docker run` → `docker logs`
- Frequent container debugging cycle
- **Optimization**: Use docker-compose for development environments
- **Tip**: Add `--rm` flag to automatically remove containers

### Pattern 4: Directory Navigation (Confidence: 71%)
**Sequence**: `cd projects/termbrain` → `code .` → `cargo watch`
- Project switching and development setup
- **Suggestion**: Use direnv for automatic environment setup
- **Script opportunity**: Create project launcher script

### Productivity Insights:
- You show good git hygiene with frequent small commits
- Consider batching similar operations
- Your workflow suggests microservices development - excellent!
- Automation opportunities identified in testing and deployment phases"#.to_string()
    }

    fn mock_daily_summary(&self) -> String {
        r#"## Daily Command Summary - March 15, 2024

### Activity Overview
**142 commands executed** - High productivity day with focused development work

### Top Activities:
1. **Git operations (31%)** - Heavy development day with 44 git commands
2. **Rust development (24%)** - Cargo build/test/run cycles dominating
3. **Docker commands (18%)** - Container management and debugging
4. **File operations (12%)** - Find, grep, and file manipulation
5. **Other (15%)** - System commands, navigation, etc.

### AI Insights:
- Excellent git hygiene with frequent, small commits
- Strong testing discipline - you run tests before commits
- Docker usage suggests microservices architecture work
- Your error rate is low (94% successful commands)

### Patterns Observed:
- Morning: Heavy git activity (code review/merging?)
- Midday: Focused Rust development with test cycles
- Afternoon: Docker debugging and deployment work
- You often forget to add `.dockerignore` files (noticed 3 times today)

### Suggestions for Tomorrow:
1. Try `git commit --amend` for quick fixes instead of new commits
2. Use `cargo watch -x test` to automate testing
3. Consider `docker-compose` for your multi-container setups
4. Set up pre-commit hooks to catch formatting issues

### Learning Opportunity:
I noticed you're working with Kubernetes deployments. Would you like me to suggest a learning path for advanced kubectl commands based on your current workflow?

### Productivity Score: 8.7/10
High score due to consistent workflow, good practices, and efficient tool usage. Minor deductions for some repeated command patterns that could be automated."#.to_string()
    }
}