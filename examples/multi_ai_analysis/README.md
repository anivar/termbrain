# Multi-AI Analysis Example

This example demonstrates how to leverage multiple AI providers (Claude, Gemini, OpenAI, etc.) simultaneously to get comprehensive command analysis, cross-validation of suggestions, and diverse perspectives on terminal workflows.

## Features

- **Cross-Provider Analysis**: Compare insights from multiple AI models
- **Consensus Building**: Identify areas where all models agree
- **Diverse Perspectives**: Leverage each model's strengths
- **Confidence Scoring**: Weight suggestions based on model agreement
- **Ensemble Learning**: Combine outputs for better accuracy
- **A/B Testing**: Compare model performance over time

## Setup

### 1. Install Dependencies

```bash
cd examples/multi_ai_analysis
cargo build
```

### 2. Configure Multiple Providers

Create a `.env` file:

```bash
# Primary AI Providers
ANTHROPIC_API_KEY=your_claude_api_key
GOOGLE_API_KEY=your_gemini_api_key
OPENAI_API_KEY=your_openai_api_key

# Optional: Additional providers
COHERE_API_KEY=your_cohere_api_key
MISTRAL_API_KEY=your_mistral_api_key

# Provider preferences
PRIMARY_PROVIDER=claude
FALLBACK_PROVIDER=gemini
CONSENSUS_THRESHOLD=0.7

# Analysis settings
ENABLE_CROSS_VALIDATION=true
ENABLE_PERFORMANCE_TRACKING=true
MAX_CONCURRENT_REQUESTS=3

# TermBrain Integration
TERMBRAIN_DATA_DIR=/path/to/your/termbrain/data
```

### 3. Provider Configuration

```toml
# multi_ai_config.toml
[providers.claude]
model = "claude-3-5-sonnet-20241022"
strengths = ["code_analysis", "security_review", "explanations"]
max_tokens = 4096
temperature = 0.1
enabled = true

[providers.gemini]
model = "gemini-1.5-pro-latest"
strengths = ["vision_analysis", "code_generation", "performance"]
max_tokens = 8192
temperature = 0.2
enabled = true

[providers.openai]
model = "gpt-4-turbo"
strengths = ["general_analysis", "pattern_recognition", "creativity"]
max_tokens = 4096
temperature = 0.3
enabled = true

[providers.cohere]
model = "command-r-plus"
strengths = ["summarization", "classification", "search"]
max_tokens = 4096
temperature = 0.2
enabled = false

[analysis]
# Route different types of analysis to best-suited providers
routing_rules = [
    { pattern = "security", primary = "claude", secondary = "gemini" },
    { pattern = "vision", primary = "gemini", secondary = "openai" },
    { pattern = "code_generation", primary = "gemini", secondary = "claude" },
    { pattern = "explanation", primary = "claude", secondary = "openai" },
    { pattern = "performance", primary = "gemini", secondary = "claude" },
]

# Consensus requirements
consensus_threshold = 0.7
min_providers = 2
max_providers = 3

# Quality controls
cross_validation = true
confidence_scoring = true
bias_detection = true
```

## Usage Examples

### Multi-Provider Command Analysis

```bash
# Analyze with all available providers
./multi-ai-analyzer analyze "docker run --rm -it -v \$(pwd):/workspace ubuntu:20.04 bash" --providers all

# Output:
# 🔍 Multi-AI Command Analysis
# 
# **Command**: `docker run --rm -it -v $(pwd):/workspace ubuntu:20.04 bash`
# **Analysis Time**: 2.3s | **Providers**: 3/3 responded
# 
# ## 🤖 Claude Analysis (Confidence: 95%)
# This Docker command creates an interactive Ubuntu container with volume mounting:
# 
# **Breakdown**:
# - `--rm`: Auto-removes container when it exits (excellent for cleanup)
# - `-it`: Interactive terminal with pseudo-TTY allocation
# - `-v $(pwd):/workspace`: Mounts current directory to /workspace in container
# - `ubuntu:20.04`: Uses Ubuntu 20.04 LTS base image
# 
# **Security Notes**:
# - Volume mounting gives container access to host files
# - Consider using `--user $(id -u):$(id -g)` to avoid root permissions
# 
# ## 🔮 Gemini Analysis (Confidence: 92%)
# Excellent development container setup with proper cleanup mechanisms:
# 
# **Strengths**:
# - Ephemeral container (--rm) prevents accumulation
# - Interactive mode perfect for development/debugging
# - Smart volume mounting for file access
# 
# **Optimizations**:
# ```bash
# # Consider adding:
# docker run --rm -it \
#   --user $(id -u):$(id -g) \
#   --workdir /workspace \
#   -v $(pwd):/workspace \
#   ubuntu:20.04 bash
# ```
# 
# ## 🧠 OpenAI Analysis (Confidence: 89%)
# Standard containerized development environment pattern:
# 
# **Use Cases**:
# - Testing code in clean Ubuntu environment
# - Running tools not available on host system
# - Isolating development dependencies
# 
# **Alternatives**:
# - Use `docker-compose` for complex setups
# - Consider `devcontainers` for IDE integration
# - Try `podman` for rootless containers
# 
# ## 📊 Consensus Summary
# 
# **Agreement Level**: 94% 🟢
# **Key Consensus Points**:
# ✅ Excellent container hygiene with --rm flag
# ✅ Proper interactive setup for development
# ✅ Volume mounting is correctly implemented
# ⚠️ All providers suggest adding user mapping for security
# 
# **Recommended Action**:
# ```bash
# # Enhanced version based on all AI feedback:
# docker run --rm -it \
#   --user $(id -u):$(id -g) \
#   --workdir /workspace \
#   -v $(pwd):/workspace:Z \
#   ubuntu:20.04 bash
# ```
# 
# **Why This Command Scored High**:
# - Follows Docker best practices
# - Includes proper cleanup mechanisms
# - Safe volume mounting approach
# - Clear intent and structure
```

### Cross-Validated Suggestions

```bash
# Get suggestions with cross-validation
./multi-ai-analyzer suggest --context "kubernetes debugging" --validate

# Output:
# 🤖 Cross-Validated AI Suggestions
# 
# **Context**: Kubernetes debugging workflow
# **Validation**: 3 providers cross-checked each suggestion
# 
# ## High Confidence Suggestions (Agreement: 90%+)
# 
# ### 1. Pod Status Investigation 🔍
# **Confidence**: 97% | **All providers agree**
# ```bash
# kubectl get pods -o wide --show-labels
# kubectl describe pod <pod-name>
# kubectl logs <pod-name> --previous
# ```
# **Why Recommended**:
# - Claude: "Essential first steps for pod debugging"
# - Gemini: "Provides comprehensive pod state information"
# - OpenAI: "Standard troubleshooting workflow in K8s"
# 
# ### 2. Resource Usage Analysis 📊
# **Confidence**: 94% | **Strong consensus**
# ```bash
# kubectl top pods
# kubectl top nodes
# kubectl describe nodes | grep -A 5 "Allocated resources"
# ```
# **Cross-Validation Notes**:
# - All models recommend checking resource constraints first
# - Gemini specifically highlights CPU/memory bottlenecks
# - Claude emphasizes node-level resource analysis
# 
# ### 3. Event Timeline Review 📅
# **Confidence**: 91% | **Unanimous recommendation**
# ```bash
# kubectl get events --sort-by='.lastTimestamp'
# kubectl get events --field-selector involvedObject.name=<pod-name>
# ```
# 
# ## Medium Confidence Suggestions (Agreement: 70-89%)
# 
# ### 4. Network Connectivity Testing 🌐
# **Confidence**: 83% | **2/3 providers strongly recommend**
# ```bash
# kubectl exec -it <pod-name> -- nslookup kubernetes.default
# kubectl exec -it <pod-name> -- wget -qO- http://service-name:port/health
# ```
# **Dissenting Opinion** (OpenAI): Suggests using `curl` instead of `wget`
# **Consensus**: Network testing is crucial, tool choice is preference
# 
# ### 5. Configuration Validation 🔧
# **Confidence**: 78% | **Mixed approaches suggested**
# ```bash
# kubectl get configmap <name> -o yaml
# kubectl get secret <name> -o yaml
# kubectl explain pod.spec.containers.env
# ```
# **Model Variations**:
# - Claude: Focus on RBAC and security configs
# - Gemini: Emphasize environment variable validation
# - OpenAI: Suggest configuration diff analysis
# 
# ## Low Confidence / Conflicting Suggestions (Agreement: <70%)
# 
# ### 6. Advanced Debugging Tools 🛠️
# **Confidence**: 65% | **Significant disagreement**
# 
# **Claude's Approach**:
# ```bash
# kubectl debug <pod-name> -it --image=nicolaka/netshoot
# kubectl auth can-i --list --as=system:serviceaccount:default:default
# ```
# 
# **Gemini's Approach**:
# ```bash
# kubectl exec -it <pod-name> -- /bin/bash
# kubectl port-forward <pod-name> 8080:8080
# ```
# 
# **OpenAI's Approach**:
# ```bash
# kubectl logs -f deployment/<name> --all-containers
# kubectl rollout history deployment/<name>
# ```
# 
# **Analysis**: Each model has valid but different debugging philosophies
# - Claude: Security-focused, proper debugging tools
# - Gemini: Direct access, port forwarding for testing
# - OpenAI: Deployment-level analysis, rollout tracking
# 
# ## 📈 Confidence Metrics
# 
# - **High Confidence Commands**: 3 (ready to use immediately)
# - **Medium Confidence Commands**: 2 (verify with your specific environment)
# - **Conflicting Approaches**: 1 (choose based on your debugging style)
# 
# **Recommendation**: Start with high-confidence suggestions, then choose from medium-confidence based on your specific debugging needs.
```

### Ensemble Error Diagnosis

```bash
# Diagnose with ensemble approach
./multi-ai-analyzer diagnose --command "terraform apply" --exit-code 1 --error-file terraform_error.log --ensemble

# Output:
# 🔍 Ensemble Error Diagnosis
# 
# **Failed Command**: `terraform apply`
# **Exit Code**: 1 | **Error Analysis**: 3 AI models consulted
# 
# ## 🧠 Individual AI Analyses
# 
# ### Claude's Diagnosis 🔍
# **Primary Issue**: State lock conflict
# **Confidence**: 92%
# 
# **Analysis**:
# ```
# Error indicates another terraform process has acquired the state lock.
# This commonly happens when:
# 1. Previous terraform process didn't complete cleanly
# 2. CI/CD pipeline is running terraform simultaneously
# 3. Another team member is applying changes
# ```
# 
# **Recommended Fix**:
# ```bash
# # Check for running processes
# ps aux | grep terraform
# 
# # Force unlock if safe (BE VERY CAREFUL)
# terraform force-unlock <lock-id>
# 
# # Better: Wait and retry
# sleep 30 && terraform apply
# ```
# 
# ### Gemini's Diagnosis 🔮
# **Primary Issue**: Resource dependency conflict
# **Confidence**: 87%
# 
# **Analysis**:
# ```
# The error suggests a circular dependency or resource constraint issue.
# Looking at the stack trace, it appears related to AWS IAM role creation
# where the role policy references a resource that doesn't exist yet.
# ```
# 
# **Recommended Fix**:
# ```bash
# # Check terraform plan for dependencies
# terraform plan -out=tfplan
# terraform show -json tfplan | jq '.planned_values'
# 
# # Apply in smaller chunks
# terraform apply -target=aws_iam_role.main
# terraform apply -target=aws_iam_policy.main
# terraform apply  # Apply remaining resources
# ```
# 
# ### OpenAI's Diagnosis 🧠
# **Primary Issue**: Provider authentication failure
# **Confidence**: 79%
# 
# **Analysis**:
# ```
# The underlying issue appears to be AWS credentials. The terraform
# apply succeeded partially but failed when trying to create certain
# AWS resources, suggesting temporary credential issues or insufficient
# permissions.
# ```
# 
# **Recommended Fix**:
# ```bash
# # Verify AWS credentials
# aws sts get-caller-identity
# aws iam list-attached-user-policies --user-name $USER
# 
# # Refresh credentials if using SSO
# aws sso login --profile default
# 
# # Retry with explicit provider config
# terraform apply -var-file=env/production.tfvars
# ```
# 
# ## 🎯 Ensemble Conclusion
# 
# **Consensus Analysis** (Weighted by confidence):
# 1. **State Management Issue** (40% weight) - Claude's analysis
# 2. **Resource Dependencies** (35% weight) - Gemini's analysis  
# 3. **Authentication Problem** (25% weight) - OpenAI's analysis
# 
# **Most Likely Root Cause**: State lock + dependency issues
# **Confidence Level**: 88%
# 
# ## 🛠️ Recommended Action Plan
# 
# **Step 1: Immediate Checks**
# ```bash
# # Check for lock files and running processes
# ls -la .terraform/
# ps aux | grep terraform
# aws sts get-caller-identity
# ```
# 
# **Step 2: Safe Resolution**
# ```bash
# # If no other terraform processes found:
# terraform force-unlock <lock-id>  # Use lock ID from error
# 
# # Verify plan before applying
# terraform plan -detailed-exitcode
# 
# # Apply with targeted approach
# terraform apply -auto-approve=false
# ```
# 
# **Step 3: Prevention**
# ```bash
# # Set up remote state locking
# terraform {
#   backend "s3" {
#     bucket         = "your-terraform-state"
#     key            = "terraform.tfstate"
#     region         = "us-west-2"
#     dynamodb_table = "terraform-locks"
#     encrypt        = true
#   }
# }
# ```
# 
# ## 📊 Diagnostic Confidence Breakdown
# 
# | Issue Type | Claude | Gemini | OpenAI | Consensus |
# |------------|--------|--------|--------|-----------|
# | State Lock | 92% ✅ | 60% ⚠️ | 45% ❌ | **High** |
# | Dependencies | 70% ⚠️ | 87% ✅ | 55% ⚠️ | **Medium** |
# | Authentication | 40% ❌ | 50% ⚠️ | 79% ✅ | **Low** |
# 
# **Final Recommendation**: Follow the action plan in order, as it addresses the most likely causes first while being safe and reversible.
```

### Performance Comparison Dashboard

```bash
# Compare AI provider performance
./multi-ai-analyzer benchmark --days 7 --detailed

# Output:
# 📊 AI Provider Performance Dashboard (Last 7 Days)
# 
# ## ⚡ Response Time Analysis
# 
# | Provider | Avg Response | 95th Percentile | Fastest | Slowest |
# |----------|--------------|-----------------|---------|---------|
# | Claude   | 1.2s ⭐      | 2.1s           | 0.8s    | 4.2s    |
# | Gemini   | 0.9s 🏆      | 1.8s           | 0.5s    | 3.1s    |
# | OpenAI   | 1.8s         | 3.2s           | 1.1s    | 7.4s    |
# 
# ## 🎯 Accuracy Metrics
# 
# **Based on 142 user feedback ratings**
# 
# | Provider | Accuracy | User Satisfaction | Helpfulness |
# |----------|----------|-------------------|-------------|
# | Claude   | 94% 🏆   | 4.6/5 ⭐         | 4.7/5 🏆    |
# | Gemini   | 91%      | 4.4/5            | 4.5/5       |
# | OpenAI   | 88%      | 4.2/5            | 4.3/5       |
# 
# ## 📈 Specialization Performance
# 
# ### Security Analysis
# ```
# Claude:  ████████████████████████████████████ 96% 🏆
# Gemini:  ████████████████████████████████     89%
# OpenAI:  ████████████████████████████         83%
# ```
# 
# ### Code Generation
# ```
# Gemini:  ████████████████████████████████████ 94% 🏆
# Claude:  ████████████████████████████████     87%
# OpenAI:  ████████████████████████████████     88%
# ```
# 
# ### Command Explanation
# ```
# Claude:  ████████████████████████████████████ 97% 🏆
# OpenAI:  ████████████████████████████████     91%
# Gemini:  ████████████████████████████████     90%
# ```
# 
# ### Error Diagnosis
# ```
# Claude:  ████████████████████████████████████ 93% 🏆
# Gemini:  ████████████████████████████████     89%
# OpenAI:  ████████████████████████████████     88%
# ```
# 
# ## 💰 Cost Analysis
# 
# **Total API Costs (7 days): $23.47**
# 
# | Provider | Requests | Cost/Request | Total Cost | Cost Efficiency |
# |----------|----------|--------------|------------|-----------------|
# | Claude   | 89       | $0.12        | $10.68     | High ⭐         |
# | Gemini   | 94       | $0.08        | $7.52      | Excellent 🏆    |
# | OpenAI   | 67       | $0.08        | $5.36      | Good            |
# 
# ## 🔄 Consensus Analysis
# 
# **Agreement Patterns**:
# - All 3 providers agree: 67% of analyses 🎯
# - 2 providers agree: 28% of analyses ⚠️
# - Complete disagreement: 5% of analyses ⚡
# 
# **Most Reliable Consensus Areas**:
# 1. Basic command explanation (94% agreement)
# 2. Security vulnerability detection (89% agreement)
# 3. Performance optimization suggestions (87% agreement)
# 
# **Areas of Frequent Disagreement**:
# 1. Advanced debugging approaches (62% agreement)
# 2. Tool/framework preferences (58% agreement)
# 3. Architectural recommendations (54% agreement)
# 
# ## 🚀 Recommendations
# 
# ### Optimal Provider Routing
# ```toml
# [smart_routing]
# security_analysis = "claude"       # 96% accuracy, excellent explanations
# code_generation = "gemini"        # 94% accuracy, fast responses
# basic_explanations = "claude"     # 97% accuracy, most helpful
# cost_sensitive = "gemini"         # Best cost efficiency
# speed_critical = "gemini"         # Fastest average response
# ```
# 
# ### Cost Optimization
# - **Switch to Gemini for routine analyses**: Save ~33% on costs
# - **Use Claude for complex security reviews**: Worth the premium
# - **Batch requests during off-peak hours**: Some providers offer discounts
# 
# ### Quality Improvements
# - **Enable consensus mode for critical analyses**: 94% accuracy when 2+ providers agree
# - **Use ensemble approach for unfamiliar commands**: Reduces error rate by 23%
# - **Implement user feedback loop**: Continuously improve routing decisions
# 
# ## 📊 Weekly Trends
# 
# **This Week vs Last Week**:
# - Total requests: +23% 📈 (increased usage)
# - Average accuracy: +2.1% 📈 (model improvements)
# - Response time: -0.3s 📈 (better infrastructure)
# - User satisfaction: +0.2 points 📈 (better routing)
# - Total costs: +18% 📊 (reasonable given usage increase)
# 
# **Anomalies Detected**:
# - OpenAI response times spiked on March 12 (likely service issues)
# - Claude accuracy dropped 3% on March 14 (model update?)
# - Gemini showed improved code generation accuracy (+5% this week)
```

## Advanced Features

### 1. AI Model Orchestration

```rust
// examples/multi_ai_analysis/src/orchestrator.rs
use std::time::Duration;
use tokio::time::timeout;

pub struct AIOrchestrator {
    providers: HashMap<String, Box<dyn AIProvider>>,
    routing_rules: Vec<RoutingRule>,
    consensus_engine: ConsensusEngine,
}

impl AIOrchestrator {
    pub async fn analyze_with_ensemble(&self, request: &AnalysisRequest) -> Result<EnsembleResult> {
        // Determine which providers to use
        let selected_providers = self.select_providers(request);
        
        // Execute analysis in parallel
        let mut tasks = Vec::new();
        for provider in selected_providers {
            let req = request.clone();
            let prov = provider.clone();
            
            tasks.push(tokio::spawn(async move {
                timeout(Duration::from_secs(30), prov.analyze(&req)).await
            }));
        }
        
        // Collect results
        let results = futures::future::join_all(tasks).await;
        
        // Build consensus
        let consensus = self.consensus_engine.build_consensus(&results)?;
        
        Ok(EnsembleResult {
            individual_results: results,
            consensus,
            confidence_score: self.calculate_confidence(&results),
            execution_time: start_time.elapsed(),
        })
    }
}
```

### 2. Bias Detection and Mitigation

```rust
// examples/multi_ai_analysis/src/bias_detector.rs
pub struct BiasDetector {
    known_biases: Vec<BiasPattern>,
    mitigation_strategies: HashMap<BiasType, MitigationStrategy>,
}

impl BiasDetector {
    pub fn analyze_for_bias(&self, results: &[AIResult]) -> BiasAnalysis {
        let mut detected_biases = Vec::new();
        
        // Check for provider-specific biases
        for bias_pattern in &self.known_biases {
            if bias_pattern.matches(results) {
                detected_biases.push(DetectedBias {
                    bias_type: bias_pattern.bias_type.clone(),
                    confidence: bias_pattern.calculate_confidence(results),
                    affected_providers: bias_pattern.identify_affected_providers(results),
                    mitigation: self.mitigation_strategies.get(&bias_pattern.bias_type).cloned(),
                });
            }
        }
        
        BiasAnalysis {
            detected_biases,
            overall_bias_score: self.calculate_overall_bias_score(&detected_biases),
            recommendations: self.generate_mitigation_recommendations(&detected_biases),
        }
    }
}

#[derive(Debug)]
pub enum BiasType {
    ToolPreference,        // Preferring specific tools/frameworks
    PlatformBias,          // Favoring certain operating systems
    ComplexityBias,        // Over/under-estimating command complexity
    SecurityParanoia,      // Being overly cautious about security
    Recency,              // Favoring newer tools over established ones
}
```

### 3. Real-time Quality Monitoring

```rust
// examples/multi_ai_analysis/src/quality_monitor.rs
pub struct QualityMonitor {
    metrics_collector: MetricsCollector,
    alert_thresholds: AlertThresholds,
    feedback_analyzer: FeedbackAnalyzer,
}

impl QualityMonitor {
    pub async fn monitor_analysis_quality(&self, result: &EnsembleResult) -> QualityReport {
        let metrics = QualityMetrics {
            response_time: result.execution_time,
            consensus_level: result.consensus.agreement_score,
            confidence_distribution: self.analyze_confidence_distribution(&result.individual_results),
            user_satisfaction: self.feedback_analyzer.get_recent_satisfaction().await,
        };
        
        // Check for quality degradation
        let alerts = self.check_quality_alerts(&metrics);
        
        // Generate recommendations
        let recommendations = self.generate_quality_recommendations(&metrics);
        
        QualityReport {
            metrics,
            alerts,
            recommendations,
            overall_quality_score: self.calculate_overall_quality(&metrics),
        }
    }
}
```

### 4. Cost Optimization Engine

```rust
// examples/multi_ai_analysis/src/cost_optimizer.rs
pub struct CostOptimizer {
    provider_pricing: HashMap<String, PricingModel>,
    usage_patterns: UsageAnalytics,
    budget_constraints: BudgetConstraints,
}

impl CostOptimizer {
    pub fn optimize_provider_selection(&self, request: &AnalysisRequest) -> ProviderSelection {
        // Calculate cost-benefit for each provider
        let mut scores = Vec::new();
        
        for (provider_name, provider) in &self.providers {
            let cost = self.estimate_cost(provider_name, request);
            let quality = self.estimate_quality(provider_name, request);
            let speed = self.estimate_speed(provider_name, request);
            
            // Weighted scoring based on user preferences
            let score = self.calculate_weighted_score(cost, quality, speed, &request.preferences);
            
            scores.push(ProviderScore {
                provider: provider_name.clone(),
                score,
                estimated_cost: cost,
                estimated_quality: quality,
                estimated_speed: speed,
            });
        }
        
        // Sort by score and apply budget constraints
        scores.sort_by(|a, b| b.score.partial_cmp(&a.score).unwrap());
        
        ProviderSelection {
            primary: scores[0].provider.clone(),
            fallback: scores.get(1).map(|s| s.provider.clone()),
            estimated_total_cost: scores[0].estimated_cost,
            confidence: self.calculate_selection_confidence(&scores),
        }
    }
}
```

## Configuration Examples

### Smart Routing Configuration

```toml
# smart_routing.toml
[routing_rules]

[[rules]]
name = "security_analysis"
conditions = { keywords = ["security", "vulnerability", "exploit", "malware"] }
primary_provider = "claude"
secondary_provider = "gemini"
confidence_threshold = 0.85

[[rules]]
name = "code_generation"
conditions = { keywords = ["generate", "create", "script", "dockerfile"] }
primary_provider = "gemini"
secondary_provider = "claude"
confidence_threshold = 0.80

[[rules]]
name = "error_diagnosis"
conditions = { has_error_code = true, has_error_output = true }
providers = ["claude", "gemini", "openai"]
consensus_required = true
confidence_threshold = 0.75

[[rules]]
name = "performance_analysis"
conditions = { keywords = ["slow", "optimize", "performance", "speed"] }
primary_provider = "gemini"
secondary_provider = "claude"
include_benchmarks = true

[fallback_strategy]
max_retries = 2
retry_delay_seconds = 5
fallback_to_local = true
emergency_providers = ["claude", "gemini"]

[quality_controls]
min_consensus_score = 0.7
max_response_time_seconds = 30
enable_bias_detection = true
require_explanation = true
```

### Cost Management

```toml
# cost_management.toml
[budget]
daily_limit_usd = 10.0
monthly_limit_usd = 200.0
alert_thresholds = [0.5, 0.8, 0.95]

[provider_limits]
claude_daily_requests = 100
gemini_daily_requests = 150
openai_daily_requests = 75

[cost_optimization]
enable_smart_routing = true
prefer_cheaper_for_simple = true
batch_similar_requests = true
cache_expensive_results = true

[pricing_models]
[pricing_models.claude]
cost_per_1k_input_tokens = 0.003
cost_per_1k_output_tokens = 0.015

[pricing_models.gemini]
cost_per_1k_input_tokens = 0.00125
cost_per_1k_output_tokens = 0.00375

[pricing_models.openai]
cost_per_1k_input_tokens = 0.01
cost_per_1k_output_tokens = 0.03
```

## Best Practices

### 1. Provider Selection Strategy

```python
# Provider selection flowchart
def select_optimal_providers(request):
    if request.type == "security_analysis":
        return ["claude", "gemini"]  # Claude excels, Gemini validates
    elif request.type == "code_generation":
        return ["gemini", "claude"]  # Gemini leads, Claude reviews
    elif request.type == "cost_sensitive":
        return ["gemini"]  # Best cost efficiency
    elif request.type == "speed_critical":
        return ["gemini"]  # Fastest responses
    elif request.type == "high_stakes":
        return ["claude", "gemini", "openai"]  # Full consensus
    else:
        return ["claude", "gemini"]  # Default balanced approach
```

### 2. Consensus Building

```rust
impl ConsensusEngine {
    pub fn build_consensus(&self, results: &[AIResult]) -> Consensus {
        // Weight results by provider reputation and confidence
        let weighted_results = self.apply_weights(results);
        
        // Find areas of agreement
        let agreements = self.find_agreements(&weighted_results);
        
        // Identify and resolve conflicts
        let conflicts = self.identify_conflicts(&weighted_results);
        let resolved_conflicts = self.resolve_conflicts(&conflicts);
        
        // Build final consensus
        Consensus {
            primary_recommendation: self.extract_primary_recommendation(&agreements),
            alternative_approaches: self.extract_alternatives(&resolved_conflicts),
            confidence_score: self.calculate_consensus_confidence(&agreements),
            dissenting_opinions: self.extract_dissenting_opinions(&conflicts),
        }
    }
}
```

### 3. Continuous Learning

```rust
impl LearningSystem {
    pub async fn update_from_feedback(&mut self, feedback: UserFeedback) -> Result<()> {
        // Update provider performance metrics
        self.update_provider_scores(&feedback).await?;
        
        // Adjust routing rules based on outcomes
        self.optimize_routing_rules(&feedback).await?;
        
        // Update consensus thresholds
        self.calibrate_consensus_thresholds(&feedback).await?;
        
        // Train local models on successful patterns
        self.train_local_predictors(&feedback).await?;
        
        Ok(())
    }
}
```

## Troubleshooting

### Common Issues

1. **Conflicting Recommendations**
   ```bash
   # Enable bias detection
   ./multi-ai-analyzer config set bias_detection true
   
   # Increase consensus threshold
   ./multi-ai-analyzer config set consensus_threshold 0.8
   ```

2. **High Costs**
   ```bash
   # Enable cost optimization
   ./multi-ai-analyzer config set cost_optimization true
   
   # Set daily budget limits
   ./multi-ai-analyzer budget set --daily 15 --monthly 300
   ```

3. **Slow Response Times**
   ```bash
   # Enable parallel processing
   ./multi-ai-analyzer config set max_concurrent_requests 5
   
   # Implement request batching
   ./multi-ai-analyzer config set batch_requests true
   ```

This multi-AI approach gives you the best of all worlds - leveraging each model's strengths while cross-validating results for maximum confidence and accuracy.