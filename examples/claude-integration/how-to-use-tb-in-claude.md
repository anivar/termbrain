# How to Use tb Commands Within Claude

## Understanding the Context

When you're chatting with Claude about your code, you **cannot run tb commands directly inside Claude**. However, you can use Termbrain to enhance your Claude conversations.

## The Workflow

### 1. Run tb Commands in Your Terminal

```bash
# In your terminal (not in Claude)
tb ai "docker debugging" claude
```

This creates `.claude.md` in your current directory.

### 2. Claude Automatically Reads the Context

When you start a conversation in Claude, it will automatically detect and read `.claude.md` files in your project, giving it context about:
- Your recent commands
- Errors and solutions
- Project structure
- Your workflow patterns

### 3. Example Conversation Flow

**In Terminal:**
```bash
# You're working on a React app and getting errors
npm run build
# Error: Module not found

# Generate context for Claude
tb ai "react build errors" claude
```

**In Claude:**
```
You: "I'm getting module not found errors in my React build"

Claude: "I can see from your terminal history that you're getting this error 
after running `npm run build`. Based on your previous solutions to similar 
errors, you've successfully fixed this before by:
1. Checking your import paths
2. Running `npm install` to ensure dependencies are installed
3. In one case, you had to clear the npm cache with `npm cache clean --force`

Looking at your project structure, you're using TypeScript with absolute 
imports. Let me help you debug this specific case..."
```

## Best Practices

### Before Starting a Claude Session

1. **Generate Fresh Context**
   ```bash
   # Terminal
   tb ai "working on [topic]" claude
   ```

2. **Update After Major Changes**
   ```bash
   # After fixing a complex bug
   tb ai "bug fixes" claude
   ```

3. **Include Learning Context**
   ```bash
   # If you're learning something new
   tb intend "learn AWS Lambda"
   # ... work on Lambda ...
   tb achieved
   tb ai "lambda learning" claude
   ```

### During Your Claude Session

You can reference Termbrain's insights:
- "Based on my terminal history..."
- "I've tried these commands before..."
- "My usual workflow for this is..."

Claude will understand because it has your context.

### Common Patterns

**Pattern 1: Debugging Session**
```bash
# Terminal: Capture the error context
tb ai "authentication errors" claude

# Claude: Now ask about the specific error
# Claude will know your auth setup, recent errors, and past solutions
```

**Pattern 2: Architecture Discussion**
```bash
# Terminal: Include your decisions
tb arch list
tb ai "architecture review" claude

# Claude: Discuss architecture
# Claude will know your decisions and reasoning
```

**Pattern 3: Learning Session**
```bash
# Terminal: Track what you're learning
tb intend "implement GraphQL"
# ... try things ...
tb ai "graphql progress" claude

# Claude: Ask for guidance
# Claude will know what you've tried and where you're stuck
```

## What Doesn't Work

❌ **Cannot run in Claude:**
```
You: "Run tb stats for me"
Claude: "I cannot execute terminal commands..."
```

✅ **Do this instead:**
```bash
# In your terminal
tb stats > stats.txt

# Then share the output with Claude or generate context
tb ai "productivity analysis" claude
```

## Advanced Usage

### Creating Custom Context

```bash
# Combine multiple aspects
tb ai "docker postgresql testing" claude

# This will include:
# - Docker commands
# - PostgreSQL queries
# - Testing commands
# - Related errors and solutions
```

### Project-Specific Context

```bash
# When switching projects
cd ~/projects/api-server
tb ai "api server context" claude

cd ~/projects/frontend
tb ai "frontend context" claude
```

### Time-Based Context

```bash
# Recent work
tb ai "today's work" claude

# Specific problem solving
tb ai "last hour debugging" claude
```

## Summary

1. **tb commands run in your terminal**, not in Claude
2. **Generate context** with `tb ai [query] claude`
3. **Claude reads** the generated `.claude.md` automatically
4. **Update context** as you work for better assistance
5. **Be specific** with your queries for focused context

This workflow gives Claude perfect context about your work without needing to explain your setup every time!