<div align="center">
  
# 🧠 Termbrain

### The Terminal That Never Forgets

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![GitHub stars](https://img.shields.io/github/stars/anivar/termbrain)](https://github.com/anivar/termbrain/stargazers)
[![Tests](https://github.com/anivar/termbrain/actions/workflows/test.yml/badge.svg)](https://github.com/anivar/termbrain/actions/workflows/test.yml)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

[**Features**](#features) • [**Quick Start**](#quick-start) • [**Demo**](#demo) • [**Docs**](docs/) • [**Contributing**](#contributing)

</div>

---

## What is Termbrain?

**Your terminal has amnesia.** Every time you close it, all context is lost. When you ask AI for help, you have to explain your entire setup. Again. And again.

**Termbrain gives your terminal a photographic memory.** It remembers every command, learns from your mistakes, and automatically provides context to AI assistants. No more explaining your project setup every time you need help.

<!-- Demo GIF coming soon -->

## ✨ Features

🧠 **Living Memory** - Automatically captures and indexes every command with smart categorization  
🔍 **Smart Search** - Find that command you ran last month in seconds using fuzzy search  
🤖 **AI Context** - One command generates perfect context for Claude, Cursor, or Copilot  
📊 **Analytics** - Understand your development patterns and productivity metrics  
🔒 **Privacy First** - Everything stays local on your machine, you own your data  
⚡ **Easy Setup** - Simple installation for bash and zsh  
🎯 **Smart Patterns** - Detects your workflow patterns and common sequences  

## 🚀 Quick Start

### Install via Git
```bash
git clone https://github.com/anivar/termbrain.git
cd termbrain
./install.sh
```

### Prerequisites
- SQLite3 and jq (installed automatically on most systems)
- fzf (optional but recommended for search functionality)

<!-- NPM and Homebrew support coming soon -->

### Manual Installation
```bash
git clone https://github.com/anivar/termbrain.git
cd termbrain
./install.sh
```

## 🎯 Usage

### Generate AI Context
```bash
tb ai "help me optimize database queries"
# Automatically includes your recent DB commands, errors, and solutions
```

### Search Your Memory
```bash
tb search
# Interactive search through all your commands with FZF
```

### View Analytics
```bash
tb stats
# See command usage patterns, error rates, and productivity metrics
```

<!-- Advanced features coming in v2.0 -->

## 🤯 Real-World Examples

### Never Explain Your Setup Again

**Without Termbrain:**
```
You: "I need help with my API"
AI: "What framework are you using?"
You: "Express with TypeScript"
AI: "What database?"
You: "PostgreSQL with Prisma"
AI: "What's your testing setup?"
You: *sighs* "Jest with supertest..."
```

**With Termbrain:**
```bash
tb ai "optimize my API endpoints"
# AI instantly knows: Express, TypeScript, PostgreSQL, Prisma, Jest
# Plus your recent queries, errors, and solutions!
```

### Learn from Your Mistakes

```bash
# Monday: You struggle with a Docker error
docker-compose up
# ERROR: port already in use

# After fixing it:
lsof -i :5432
kill -9 <PID>
docker-compose up
# Success!

# Friday: Same error occurs
# Termbrain automatically suggests: "Try: lsof -i :5432 (worked last time)"
```

### Discover Your Patterns

```bash
tb stats

📊 Your Development Analytics
============================

📈 Command Usage:
   git operations      2,847 times
   npm commands       1,923 times
   docker commands      892 times

⏱️ Time Analysis:
   npm install     avg 45.2 seconds
   docker build    avg 92.1 seconds

🔄 Top Workflows:
   git add → commit → push    (312 times)
   npm test → npm run build   (143 times)

💡 Suggestions:
   - Create alias 'gcp' for your git workflow
   - Consider npm ci instead of npm install
```

## 🏗️ Architecture

Termbrain uses a simple yet powerful architecture:

- **Shell Hooks** - Captures commands using preexec/precmd
- **SQLite Database** - Fast, reliable local storage
- **Semantic Analysis** - Understands command types and context
- **AI Integration** - Generates context files for various AI tools

[Read more about the architecture →](docs/architecture.md)

## 🛡️ Privacy & Security

- ✅ **100% Local** - No cloud, no telemetry, no tracking
- ✅ **Auto-Redaction** - Passwords and secrets automatically detected and hidden
- ✅ **You Control Everything** - Export, delete, or pause recording anytime
- ✅ **Secure by Design** - Follows security best practices

[Read our security policy →](SECURITY.md)

## 📖 Documentation

- [Getting Started](docs/getting-started.md)
- [Architecture](docs/architecture.md)
- [Contributing Guide](CONTRIBUTING.md)

## 🤝 Contributing

We love contributions! Whether it's:

- 🐛 Bug reports
- 💡 Feature requests
- 📖 Documentation improvements
- 🔧 Code contributions

Please read our [Contributing Guide](CONTRIBUTING.md) and [Code of Conduct](CODE_OF_CONDUCT.md).

## 📊 Project Status

- ✅ Core memory system
- ✅ Command capture and analysis
- ✅ Error tracking and learning
- ✅ AI context generation
- ✅ Multi-shell support (bash, zsh)
- 📋 Enhanced memory features (planned for v2.0)
- 📋 NPM/Homebrew packages (coming soon)
- 📋 Fish shell support (planned)
- 📋 Windows support (planned)

## 🙏 Acknowledgments

Termbrain is inspired by:
- The concept of "memory palaces" and cognitive enhancement
- Tools like `history`, `fzf`, and `ripgrep`
- The amazing developer community

## 📄 License

MIT © [Anivar Aravind](https://github.com/anivar)

---

<div align="center">

**Built with 🧠 by developers who forget things**

[Report Bug](https://github.com/anivar/termbrain/issues) • [Request Feature](https://github.com/anivar/termbrain/issues) • [Join Discussion](https://github.com/anivar/termbrain/discussions)

⭐ Star us on GitHub — it helps!

</div>