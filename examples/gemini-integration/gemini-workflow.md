# Using Termbrain with Gemini CLI

## Setup

1. Install both tools:
```bash
# Install Termbrain
git clone https://github.com/anivar/termbrain.git
cd termbrain && ./install.sh

# Install Gemini CLI
npm install -g @google/gemini-cli
```

2. Configure Termbrain for Gemini:
```bash
# Use the Gemini provider
tb ai "your context" gemini
```

## Workflow Examples

### Example 1: Debug with Full Context

```bash
# 1. Generate debugging context
tb ai "python TypeError" gemini

# 2. Start Gemini with context
gemini

# 3. In Gemini, include the context
> @.gemini-context.md I'm getting a TypeError in my Python app

# Gemini now has:
# - Your recent Python commands
# - Previous TypeErrors and solutions
# - Your project structure
```

### Example 2: Architecture Review

```bash
# 1. Document your decisions in Termbrain
tb arch "API Design" "REST with JWT tokens"
tb arch "Database" "PostgreSQL with Redis cache"

# 2. Generate architecture context
tb ai "architecture decisions" gemini

# 3. In Gemini
gemini
> @.gemini-context.md review my architecture decisions and suggest improvements
```

### Example 3: Learning Session

```bash
# 1. Track your learning
tb intend "learn Kubernetes"

# ... work with k8s ...

# 2. Generate learning context
tb ai "kubernetes learning" gemini

# 3. Ask Gemini for help
gemini
> @.gemini-context.md based on my k8s attempts, what should I learn next?
```

### Example 4: Error Pattern Analysis

```bash
# 1. After multiple errors, generate context
tb ai "recurring errors" gemini

# 2. Let Gemini analyze patterns
gemini
> @.gemini-context.md analyze my error patterns and suggest preventive measures
```

## Advanced Integration

### Custom Command for Gemini

Create `.gemini/commands/termbrain.toml`:
```toml
[termbrain-context]
description = "Include Termbrain context for current issue"
prompt = """
@.gemini-context.md

Analyze my terminal history and current context to help with: {{args}}
"""
```

Then use in Gemini:
```bash
gemini
> /termbrain-context debugging docker compose
```

### Shell Integration

```bash
# In Gemini, use shell mode to run tb commands
gemini
> !tb ai "current errors" gemini
> @.gemini-context.md help me fix these errors
```

### Automated Context Updates

Create an alias:
```bash
alias gemini-tb='tb ai "recent work" gemini && gemini'

# Now just run
gemini-tb
# Automatically generates fresh context before starting Gemini
```

## Best Practices

1. **Update context before complex queries**
   ```bash
   tb ai "specific topic" gemini && gemini
   ```

2. **Use descriptive queries for context**
   ```bash
   tb ai "react hooks useState errors" gemini
   # Better than: tb ai "errors" gemini
   ```

3. **Combine with intentions**
   ```bash
   tb intend "refactor auth system"
   # ... work ...
   tb ai "auth refactoring" gemini
   ```

4. **Document Gemini's solutions**
   ```bash
   # After Gemini helps
   tb arch "Gemini Solution" "Used middleware pattern for auth"
   ```

## Why This Works Well

1. **Gemini gets full context** without you explaining
2. **Your terminal history** provides real examples
3. **Error patterns** help Gemini give better solutions
4. **Project understanding** from Termbrain's analysis
5. **Learning tracking** shows your progress

The combination of Termbrain's memory and Gemini's intelligence creates a powerful development assistant!