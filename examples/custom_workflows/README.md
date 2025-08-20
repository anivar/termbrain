# Custom Workflows Example

This example demonstrates how to create intelligent, AI-powered workflows that learn from your command patterns and automate complex sequences of terminal operations.

## Features

- **Pattern-Based Workflows**: Automatically detect and suggest workflows from your command history
- **AI-Generated Scripts**: Use Claude/Gemini to generate custom automation scripts
- **Conditional Logic**: Smart workflows that adapt based on context and environment
- **Error Handling**: Robust workflows with proper error detection and recovery
- **Integration Hooks**: Connect workflows with external tools and services

## Quick Start

```bash
cd examples/custom_workflows

# Detect workflows from your history
./workflow-manager detect --days 30

# Generate a deployment workflow
./workflow-manager generate --type deployment --tech "docker,kubernetes"

# Run an existing workflow
./workflow-manager run git-deploy-flow

# Interactive workflow creation
./workflow-manager create --interactive
```

## Example Workflows

### 1. Intelligent Git Deployment Workflow

```yaml
# workflows/git-deploy-flow.yml
name: "Smart Git Deployment"
description: "AI-enhanced deployment workflow with safety checks"
version: "1.0"

triggers:
  - pattern: "git push origin main"
  - manual: true
  - schedule: "0 9 * * 1-5"  # Weekdays at 9 AM

variables:
  - name: BRANCH
    default: "main"
    description: "Target branch for deployment"
  - name: ENVIRONMENT
    required: true
    options: ["staging", "production"]
  - name: SKIP_TESTS
    default: false
    type: boolean

pre_conditions:
  - command: "git status --porcelain"
    expect_empty: true
    error_message: "Working directory must be clean"
  
  - command: "git branch --show-current"
    expect: "${BRANCH}"
    error_message: "Must be on ${BRANCH} branch"

steps:
  - name: "AI Pre-deployment Analysis"
    type: ai_analysis
    provider: claude
    prompt: |
      Analyze the following git diff for deployment readiness:
      
      Changes: {{ git_diff }}
      Target: {{ ENVIRONMENT }}
      
      Check for:
      1. Breaking changes
      2. Database migrations
      3. Configuration changes
      4. Security issues
      
      Provide deployment risk assessment and recommendations.
    
    outputs:
      - risk_level
      - recommendations
      - migration_required
    
    conditions:
      - if: "risk_level == 'high'"
        action: pause
        message: "High risk deployment detected. Manual approval required."

  - name: "Run Tests"
    condition: "!SKIP_TESTS"
    commands:
      - "cargo test --all"
      - "cargo clippy -- -D warnings"
      - "cargo fmt --check"
    
    on_failure:
      - notify: "slack"
        message: "Tests failed for deployment to ${ENVIRONMENT}"
      - exit_code: 1

  - name: "Build Docker Image"
    commands:
      - "docker build -t myapp:${COMMIT_SHA} ."
      - "docker tag myapp:${COMMIT_SHA} myapp:${ENVIRONMENT}-latest"
    
    retry:
      attempts: 3
      delay: 30s
    
    outputs:
      - image_id: "{{ docker_image_id }}"

  - name: "AI Security Scan"
    type: ai_analysis
    provider: gemini
    prompt: |
      Analyze this Docker image for security vulnerabilities:
      
      Image: myapp:${COMMIT_SHA}
      Dockerfile: {{ dockerfile_content }}
      
      Scan for:
      1. Known vulnerabilities in base image
      2. Exposed secrets or credentials
      3. Insecure configurations
      4. Privilege escalation risks
      
      Provide security assessment and remediation steps.
    
    parallel: true  # Run while next step executes

  - name: "Deploy to Kubernetes"
    condition: "ENVIRONMENT == 'production'"
    commands:
      - "kubectl set image deployment/myapp myapp=myapp:${COMMIT_SHA}"
      - "kubectl rollout status deployment/myapp --timeout=300s"
    
    on_failure:
      - "kubectl rollout undo deployment/myapp"
      - notify: "pagerduty"
        severity: "high"

  - name: "Verify Deployment"
    type: ai_verification
    provider: claude
    commands:
      - "kubectl get pods -l app=myapp"
      - "curl -f http://myapp.${ENVIRONMENT}.com/health"
    
    ai_prompt: |
      Analyze these deployment verification results:
      
      Pod Status: {{ pod_status }}
      Health Check: {{ health_response }}
      
      Determine if deployment was successful and identify any issues.
    
    expect_ai_confirmation: true

post_steps:
  - name: "Generate Deployment Report"
    type: ai_report
    provider: claude
    template: |
      # Deployment Report
      
      **Environment**: ${ENVIRONMENT}
      **Commit**: ${COMMIT_SHA}
      **Status**: {{ deployment_status }}
      
      ## AI Analysis Summary
      
      **Pre-deployment Risk**: {{ risk_level }}
      **Security Scan**: {{ security_status }}
      **Verification**: {{ verification_result }}
      
      ## Recommendations
      
      {{ ai_recommendations }}
    
    outputs:
      - file: "reports/deployment-${TIMESTAMP}.md"
      - slack: "#deployments"

notifications:
  on_success:
    - slack: "#deployments"
      message: "✅ Successfully deployed ${COMMIT_SHA} to ${ENVIRONMENT}"
  
  on_failure:
    - slack: "#alerts"
      message: "❌ Deployment failed for ${COMMIT_SHA} to ${ENVIRONMENT}"
    - email: "team@company.com"

cleanup:
  - "docker image prune -f"
  - "kubectl delete pods --field-selector=status.phase=Succeeded"
```

### 2. AI-Driven Development Environment Setup

```yaml
# workflows/dev-setup.yml
name: "Intelligent Dev Environment Setup"
description: "AI-powered development environment configuration"

triggers:
  - command_pattern: "git clone"
  - manual: true

inputs:
  - name: PROJECT_PATH
    from_context: true
    description: "Detected from git clone command"

steps:
  - name: "Analyze Project Structure"
    type: ai_analysis
    provider: gemini
    commands:
      - "find ${PROJECT_PATH} -type f -name '*.json' -o -name '*.toml' -o -name '*.yml' | head -20"
      - "ls -la ${PROJECT_PATH}"
    
    prompt: |
      Analyze this project structure and identify:
      
      Files found: {{ command_outputs }}
      
      1. Programming languages used
      2. Framework/technology stack
      3. Build system requirements
      4. Development tool recommendations
      5. Container/Docker requirements
      6. IDE/editor recommendations
      
      Provide a setup plan for optimal development experience.
    
    outputs:
      - languages
      - frameworks
      - build_tools
      - dev_tools
      - setup_recommendations

  - name: "Setup Language Environment"
    type: conditional_multi
    cases:
      - condition: "languages contains 'rust'"
        commands:
          - "rustup update"
          - "rustup component add clippy rust-src"
          - "cargo install cargo-watch cargo-edit"
      
      - condition: "languages contains 'javascript' || languages contains 'typescript'"
        commands:
          - "nvm install --lts"
          - "npm install -g typescript @types/node"
          - "npm install -g eslint prettier"
      
      - condition: "languages contains 'python'"
        commands:
          - "pyenv install 3.11.0"
          - "pip install poetry black isort mypy"

  - name: "Configure Development Tools"
    type: ai_script_generation
    provider: claude
    prompt: |
      Generate setup scripts for this development environment:
      
      Project: ${PROJECT_PATH}
      Languages: {{ languages }}
      Frameworks: {{ frameworks }}
      Build tools: {{ build_tools }}
      
      Create scripts for:
      1. IDE/editor configuration
      2. Git hooks setup
      3. Environment variables
      4. Docker development setup (if applicable)
      5. CI/CD configuration templates
    
    execute_generated: true
    safety_check: true

  - name: "AI-Generated Project README"
    type: ai_content_generation
    provider: claude
    condition: "!file_exists('${PROJECT_PATH}/README.md')"
    
    prompt: |
      Create a comprehensive README.md for this project:
      
      Project path: ${PROJECT_PATH}
      Technologies: {{ frameworks }}
      Structure: {{ project_structure }}
      
      Include:
      1. Project description and purpose
      2. Installation instructions
      3. Development setup
      4. Usage examples
      5. Contributing guidelines
      6. Project structure explanation
    
    output_file: "${PROJECT_PATH}/README.md"

notifications:
  on_completion:
    - terminal_notification: "🚀 Development environment ready for ${PROJECT_PATH}"
```

### 3. Smart Monitoring and Alerting Workflow

```yaml
# workflows/smart-monitoring.yml
name: "AI-Enhanced System Monitoring"
description: "Intelligent monitoring with AI-powered analysis"

schedule: "*/5 * * * *"  # Every 5 minutes

variables:
  - name: ALERT_THRESHOLD
    default: 0.8
    type: float
  - name: AI_ANALYSIS_INTERVAL
    default: 15  # minutes

steps:
  - name: "Collect System Metrics"
    type: parallel
    commands:
      - name: "cpu_usage"
        command: "top -bn1 | grep 'Cpu(s)' | awk '{print $2}' | cut -d'%' -f1"
      - name: "memory_usage"
        command: "free | grep Mem | awk '{printf \"%.2f\", $3/$2 * 100.0}'"
      - name: "disk_usage"
        command: "df -h / | awk 'NR==2{print $5}' | cut -d'%' -f1"
      - name: "docker_status"
        command: "docker ps --format 'table {{.Names}}\\t{{.Status}}\\t{{.Ports}}'"
      - name: "k8s_pods"
        command: "kubectl get pods -o wide"
        optional: true

  - name: "AI Anomaly Detection"
    type: ai_analysis
    provider: claude
    condition: "elapsed_since_last_ai_analysis > AI_ANALYSIS_INTERVAL"
    
    prompt: |
      Analyze these system metrics for anomalies:
      
      CPU Usage: {{ cpu_usage }}%
      Memory Usage: {{ memory_usage }}%
      Disk Usage: {{ disk_usage }}%
      
      Docker Containers:
      {{ docker_status }}
      
      Kubernetes Pods:
      {{ k8s_pods }}
      
      Historical context (last 24h):
      {{ historical_metrics }}
      
      Identify:
      1. Performance anomalies
      2. Resource exhaustion risks
      3. Container/pod health issues
      4. Trending problems
      5. Recommended actions
    
    outputs:
      - anomaly_score
      - risk_areas
      - recommendations
      - urgency_level

  - name: "Intelligent Alerting"
    type: conditional
    condition: "anomaly_score > ALERT_THRESHOLD || urgency_level == 'high'"
    
    actions:
      - name: "Generate Alert Context"
        type: ai_analysis
        provider: gemini
        prompt: |
          Create a detailed alert report:
          
          Anomalies detected: {{ risk_areas }}
          Urgency: {{ urgency_level }}
          Recommendations: {{ recommendations }}
          
          Generate:
          1. Executive summary
          2. Technical details
          3. Immediate action items
          4. Long-term recommendations
        
        outputs:
          - alert_summary
          - technical_details
          - action_items

      - name: "Smart Notification Routing"
        type: conditional_multi
        cases:
          - condition: "urgency_level == 'critical'"
            actions:
              - pagerduty_alert: "{{ alert_summary }}"
              - slack: "#alerts"
              - email: "oncall@company.com"
          
          - condition: "urgency_level == 'high'"
            actions:
              - slack: "#monitoring"
              - create_ticket: "{{ technical_details }}"
          
          - condition: "urgency_level == 'medium'"
            actions:
              - slack: "#monitoring"
              - log: "monitoring.log"

  - name: "Auto-Remediation"
    type: ai_decision
    provider: claude
    condition: "urgency_level in ['high', 'critical']"
    
    prompt: |
      Based on these system issues, recommend automatic remediation:
      
      Issues: {{ risk_areas }}
      Current state: {{ system_metrics }}
      
      For each issue, determine:
      1. Can it be safely auto-remediated?
      2. What commands should be executed?
      3. What are the risks?
      4. What monitoring is needed after remediation?
      
      Only recommend actions that are:
      - Safe to execute automatically
      - Reversible if they cause issues
      - Low risk of data loss
    
    auto_execute_if_safe: true
    max_risk_score: 0.3

data_retention:
  metrics_history: "7 days"
  ai_analysis_results: "30 days"
  alert_reports: "90 days"
```

## Advanced Workflow Features

### 1. AI-Powered Workflow Generation

```bash
# Generate workflows from natural language
./workflow-manager generate-from-prompt "I want to automate my daily standup process by analyzing my git commits, checking JIRA tickets, and generating a summary"

# Output: Generated workflow with AI-driven analysis steps
```

### 2. Learning from Command Patterns

```bash
# Analyze command history for workflow opportunities
./workflow-manager analyze-patterns --intelligence-level high

# Output:
# 🤖 AI-Detected Workflow Opportunities
# 
# **Pattern 1**: Git Feature Branch Workflow (Confidence: 94%)
# Detected sequence: branch creation → development → testing → merge
# Suggestion: Automate with PR creation and code review integration
# 
# **Pattern 2**: Docker Development Cycle (Confidence: 89%)
# Detected sequence: code change → docker build → docker run → test → debug
# Suggestion: Create watch-mode workflow with automatic rebuilding
```

### 3. Context-Aware Workflow Execution

```rust
// Smart workflow engine that adapts to context
pub struct ContextAwareWorkflowEngine {
    ai_client: Box<dyn AIProvider>,
    context_analyzer: ContextAnalyzer,
    workflow_repository: WorkflowRepository,
}

impl ContextAwareWorkflowEngine {
    pub async fn suggest_workflow(&self, current_context: &ExecutionContext) -> Result<Vec<WorkflowSuggestion>> {
        // Analyze current context
        let context_analysis = self.context_analyzer.analyze(current_context).await?;
        
        // Get AI recommendations
        let ai_suggestions = self.ai_client.suggest_workflows(&context_analysis).await?;
        
        // Find matching workflows
        let matching_workflows = self.workflow_repository
            .find_by_context(&context_analysis)
            .await?;
        
        // Combine and rank suggestions
        Ok(self.rank_suggestions(ai_suggestions, matching_workflows))
    }
}
```

### 4. Workflow Testing and Validation

```yaml
# workflows/test-deployment.yml
name: "Workflow Testing Framework"

test_environments:
  - name: "sandbox"
    description: "Safe testing environment"
    constraints:
      - no_production_access: true
      - max_resource_usage: "10%"
  
  - name: "staging"
    description: "Pre-production testing"
    constraints:
      - require_approval: true
      - rollback_required: true

validation_steps:
  - name: "AI Safety Analysis"
    type: ai_analysis
    provider: claude
    prompt: |
      Analyze this workflow for safety and correctness:
      
      Workflow: {{ workflow_definition }}
      Target Environment: {{ target_environment }}
      
      Check for:
      1. Potentially destructive operations
      2. Security vulnerabilities
      3. Resource exhaustion risks
      4. Missing error handling
      5. Insufficient rollback procedures
    
    safety_score_required: 0.8

  - name: "Dry Run Execution"
    type: simulation
    execute_commands: false
    validate_conditions: true
    check_dependencies: true

  - name: "Gradual Rollout"
    type: canary_deployment
    rollout_strategy:
      - stage: "1%"
        duration: "5m"
        success_criteria: "error_rate < 0.1%"
      - stage: "10%"
        duration: "15m"
        success_criteria: "latency_p95 < 200ms"
      - stage: "100%"
        success_criteria: "all_green"
```

## Best Practices

### 1. Workflow Security

```yaml
security:
  ai_approval_required:
    - command_patterns: ["rm -rf", "DROP TABLE", "kubectl delete"]
    - environment: "production"
    - cost_threshold: "$100"
  
  secret_management:
    - never_log: ["password", "token", "key"]
    - encrypt_outputs: true
    - rotate_secrets: "30d"
  
  access_control:
    - role_based: true
    - require_mfa: ["production", "security"]
    - audit_trail: true
```

### 2. Error Handling and Recovery

```yaml
error_handling:
  global_strategies:
    - retry_on_transient: 3
    - circuit_breaker: true
    - graceful_degradation: true
  
  ai_assisted_recovery:
    - analyze_failures: true
    - suggest_fixes: true
    - auto_rollback_threshold: 0.9
```

### 3. Performance Optimization

```yaml
performance:
  parallelization:
    - max_concurrent: 5
    - dependency_aware: true
    - resource_limits: true
  
  caching:
    - ai_analysis_results: "1h"
    - command_outputs: "15m"
    - workflow_templates: "24h"
  
  resource_management:
    - cpu_limit: "80%"
    - memory_limit: "2GB"
    - timeout: "30m"
```

This workflow system combines the power of AI analysis with robust automation, creating intelligent workflows that learn and adapt to your development patterns.