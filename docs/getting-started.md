# Getting Started with Termbrain

Welcome to Termbrain! This guide will help you install and start using Termbrain in minutes.

## Table of Contents

- [Installation](#installation)
- [First Steps](#first-steps)
- [Basic Usage](#basic-usage)
- [AI Integration](#ai-integration)
- [Next Steps](#next-steps)

## Installation

### Prerequisites

- **Operating System**: macOS or Linux
- **Shell**: Bash 4.0+ or Zsh 5.0+
- **Dependencies**: SQLite 3, jq (installed automatically)

### Install via Git

```bash
git clone https://github.com/anivar/termbrain.git
cd termbrain
./install.sh
```

### Install via curl

```bash
curl -sSL https://raw.githubusercontent.com/anivar/termbrain/main/install.sh | bash
```

### Manual Installation

```bash
git clone https://github.com/anivar/termbrain.git
cd termbrain
./install.sh
```

### Verify Installation

After installation, restart your terminal or run:

```bash
source ~/.bashrc  # or ~/.zshrc for Zsh
```

You should see:
```
🧠 Termbrain active | 'tb help' for commands
```

## First Steps

### 1. Check Installation

```bash
tb help
```

This shows all available commands.

### 2. View Your Stats

```bash
tb stats
```

See analytics about your command usage (will be empty initially).

### 3. Generate Your First AI Context

```bash
tb ai "help me with git"
```

This creates a context file with your Git-related commands and patterns.

## Basic Usage

### Command Memory

Termbrain automatically captures every command you run. No setup needed!

```bash
# Run any command
git status
npm install
docker ps

# Termbrain remembers everything
```

### Search Your History

```bash
tb search
```

Use the interactive search to find any command you've run.

### Track Your Mistakes and Solutions

When you encounter an error:

```bash
$ npm start
Error: Cannot find module 'express'

$ npm install express  # This fixes it
$ npm start           # Works now!
```

Termbrain automatically learns that `npm install express` fixed the error.

### Learn Your Patterns

```bash
tb learn
```

Discover repeated command sequences and workflow patterns.

## AI Integration

### Generate Context for AI Assistants

```bash
# For general help
tb ai

# For specific topics
tb ai "docker optimization"
tb ai "database queries"
```

### Provider-Specific Files

Termbrain creates context files for different AI tools:

```bash
# For Claude
tb ai "help" claude
# Creates .claude.md

# For Cursor
tb ai "help" cursor  
# Creates .cursorrules

# For GitHub Copilot
tb ai "help" copilot
# Creates .github/copilot-instructions.md
```

### What's Included in Context?

- Recent relevant commands
- Error-solution pairs
- Your workflow patterns
- Project information
- Current directory structure

## Privacy Controls

### Pause Recording

```bash
export TERMBRAIN_PAUSED=1
# Commands won't be recorded

unset TERMBRAIN_PAUSED
# Recording resumes
```

### Manage Your Data

```bash
tb privacy
```

Options:
- Redact sensitive data
- Export your data
- Clear all data
- Pause recording

## Common Workflows

### Daily Development

```bash
# Start your day
tb stats  # See yesterday's patterns

# Work on a feature
tb-intend "add user profiles"
git checkout -b feature/user-profiles
# ... code ...
tb-achieved

# Get AI help with context
tb ai "help with React components"
```

### Debugging

```bash
# When you hit an error
npm test
# Error occurs...

# Try solutions
# Termbrain tracks what works

# Later, same error?
# Termbrain suggests: "Last time, you fixed this with..."
```

### Learning New Tools

```bash
# Exploring a new framework
tb-intend "learn Next.js"

# Try commands
npx create-next-app
npm run dev

# Track your learning
tb-achieved
# "I learned how to set up Next.js projects"
```

## Next Steps


### Customize Termbrain

- Edit `~/.termbrain/config` (if you create it) for custom settings
- Add to `.bashrc`/`.zshrc` for custom aliases
- Contribute to the project on GitHub

### Get Help

- Run `tb help` for command reference
- Check [Troubleshooting](troubleshooting.md) for common issues
- Join [GitHub Discussions](https://github.com/anivar/termbrain/discussions)

## Tips

1. **Let it run** - Termbrain learns over time, so keep it active
2. **Use intentions** - Track what you're trying to achieve
3. **Review patterns** - Check `tb stats` weekly to spot improvements
4. **Privacy first** - Use `tb privacy` to control your data

Welcome to a smarter terminal experience! 🧠✨