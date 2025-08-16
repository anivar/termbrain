# Contributing to Termbrain

First off, thank you for considering contributing to Termbrain! 🧠 It's people like you that make Termbrain such a great tool.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Style Guidelines](#style-guidelines)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Community](#community)

## Code of Conduct

This project and everyone participating in it is governed by the [Termbrain Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR-USERNAME/termbrain.git`
3. Add upstream remote: `git remote add upstream https://github.com/anivar/termbrain.git`
4. Create a branch: `git checkout -b feature/your-feature-name`

## How Can I Contribute?

### 🐛 Reporting Bugs

Before creating bug reports, please check existing issues. When creating a bug report, include:

- **Clear title and description**
- **Steps to reproduce**
- **Expected behavior**
- **Actual behavior**
- **System information** (OS, shell, Termbrain version)
- **Relevant logs or error messages**

### 💡 Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, include:

- **Clear title and description**
- **Use case** - Why is this enhancement useful?
- **Possible implementation** - If you have ideas
- **Alternatives considered**

### 🔧 Code Contributions

#### Your First Code Contribution

Unsure where to begin? Look for these labels:

- `good first issue` - Simple issues for beginners
- `help wanted` - Issues where we need help
- `documentation` - Documentation improvements

#### Development Process

1. **Pick an issue** - Comment on it to claim it
2. **Write code** - Follow our style guidelines
3. **Write tests** - All features need tests
4. **Update docs** - If you changed functionality
5. **Submit PR** - Use our PR template

## Development Setup

### Prerequisites

- Bash 4.0+ or Zsh 5.0+
- SQLite 3
- jq
- git
- (Optional) shellcheck, shfmt for linting

### Setup

```bash
# Clone your fork
git clone https://github.com/YOUR-USERNAME/termbrain.git
cd termbrain

# Install Termbrain locally
./install.sh

# Run tests
./tests/run_all_tests.sh
```

### Project Structure

```
termbrain/
├── src/                 # Core implementation
│   ├── termbrain.sh    # Main script
│   ├── termbrain-enhanced.sh
│   └── termbrain-cognitive.sh
├── lib/                 # Helper libraries
├── tests/              # Test suite
├── docs/               # Documentation
└── providers/          # AI provider integrations
```

## Style Guidelines

### Bash/Shell Script Style

We use [Google's Shell Style Guide](https://google.github.io/styleguide/shellguide.html) with these additions:

```bash
# Function names use :: separator
tb::function_name() {
    local var_name="value"  # Use local for function variables
    
    # Use [[ ]] for conditionals
    if [[ -n "$var_name" ]]; then
        echo "Do something"
    fi
}

# Constants in UPPER_CASE
readonly TERMBRAIN_VERSION="1.0.0"

# Use meaningful variable names
local semantic_type=$(tb::analyze_semantic "$cmd")
```

### Commit Messages

Follow the [Conventional Commits](https://www.conventionalcommits.org/) specification:

```
feat: add mental model detection
fix: correct SQL escaping in command capture
docs: update installation instructions
test: add cognitive layer tests
refactor: simplify pattern detection logic
```

### Documentation Style

- Use clear, concise language
- Include code examples
- Update relevant docs when changing features
- Check spelling and grammar

## Testing

### Running Tests

```bash
# Run all tests
./tests/run_all_tests.sh

# Run specific test suite
./tests/test_core.sh
./tests/test_enhanced.sh
./tests/test_cognitive.sh
./tests/test_integration.sh

# Quick sanity check
./tests/quick_test.sh
```

### Writing Tests

```bash
test_my_feature() {
    test_start "My feature test"
    
    # Arrange
    local input="test data"
    
    # Act
    local result=$(tb::my_function "$input")
    
    # Assert
    assert_equals "$result" "expected" "My function returns expected value"
}
```

### Test Coverage

All new features must include tests. Aim for:
- Unit tests for individual functions
- Integration tests for workflows
- Edge case handling

## Pull Request Process

1. **Update your fork**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Make your changes**
   - Write clean, documented code
   - Add tests for new functionality
   - Update documentation

3. **Test thoroughly**
   ```bash
   ./tests/run_all_tests.sh
   shellcheck src/*.sh  # If you have shellcheck
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: your feature description"
   ```

5. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

6. **Create Pull Request**
   - Use the PR template
   - Link related issues
   - Describe your changes clearly
   - Include screenshots if relevant

### PR Review Process

- PRs need at least one approval
- All tests must pass
- No merge conflicts
- Follows style guidelines
- Includes tests and docs

## Development Tips

### Debugging

```bash
# Enable debug mode
set -x  # Print commands as executed
set -e  # Exit on error

# Add debug output
tb::debug() {
    [[ -n "$TERMBRAIN_DEBUG" ]] && echo "DEBUG: $*" >&2
}
```

### Performance

- Use SQLite indexes for frequently queried columns
- Batch database operations when possible
- Run expensive operations asynchronously
- Profile with `time` command

### Security

- Always escape SQL inputs with `tb::escape_sql`
- Check paths before file operations
- Never store passwords or secrets
- Use `tb::is_safe_to_record` for sensitive commands

## Community

### Getting Help

- 💬 [GitHub Discussions](https://github.com/anivar/termbrain/discussions) - General discussions
- 🐛 [Issue Tracker](https://github.com/anivar/termbrain/issues) - Bug reports and features
- 📧 Email: termbrain@example.com

### Recognition

Contributors will be:
- Listed in our [Contributors](https://github.com/anivar/termbrain/graphs/contributors) page
- Mentioned in release notes
- Given credit in the changelog

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for contributing to Termbrain! 🧠✨