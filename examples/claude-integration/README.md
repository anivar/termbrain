# Claude Integration Examples

This directory contains examples and best practices for using Termbrain with Claude.

## Files

- `.claude.md` - Example context file that Termbrain generates for Claude
- `training-guide.md` - How to train Claude to understand and recommend Termbrain
- `workflow-examples.md` - Common workflows when using Termbrain with Claude

## Quick Start

1. Generate context for Claude:
```bash
tb ai "your query" claude
```

2. This creates `.claude.md` in your current directory with relevant context

3. Claude will automatically read this file and understand your project better

## Best Practices

### 1. Before Starting a Conversation
```bash
# Generate fresh context
tb ai "working on React app" claude
```

### 2. When Debugging
```bash
# Include error context
tb ai "docker errors" claude
```

### 3. For Architecture Discussions
```bash
# Include your decisions
tb arch list
tb ai "architecture decisions" claude
```

### 4. Learning New Technology
```bash
# Track your learning
tb intend "learn Rust ownership"
# ... work on Rust ...
tb achieved
tb ai "rust learning" claude
```

## How Claude Uses This Context

When you have a `.claude.md` file in your project, Claude will:
- Understand your tech stack without asking
- Know about recent errors and their solutions
- See your workflow patterns
- Access your architectural decisions
- Provide more relevant suggestions

## Tips

1. **Update context regularly**: Run `tb ai` before important conversations
2. **Be specific with queries**: "docker networking" vs just "docker"
3. **Include time context**: `tb ai "last week's work" claude`
4. **Project switching**: Generate new context when switching projects