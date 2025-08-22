# Contributing to TermBrain

Thank you for your interest in contributing to TermBrain! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:
- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive criticism
- Respect differing viewpoints and experiences

## How to Contribute

### Reporting Issues

1. Check existing issues to avoid duplicates
2. Use issue templates when available
3. Include:
   - Clear description of the problem
   - Steps to reproduce
   - Expected vs actual behavior
   - System information (OS, shell, Rust version)
   - Error messages or logs

### Suggesting Features

1. Check the roadmap and existing feature requests
2. Describe the use case and benefits
3. Consider implementation complexity
4. Be open to discussion and alternatives

### Submitting Changes

1. **Fork and Clone**
   ```bash
   git clone https://github.com/your-username/termbrain.git
   cd termbrain
   ```

2. **Create a Branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

3. **Make Changes**
   - Follow the coding standards
   - Add tests for new functionality
   - Update documentation as needed
   - Keep commits focused and atomic

4. **Test Your Changes**
   ```bash
   # Run all tests
   cargo test --workspace

   # Run clippy
   cargo clippy --workspace --all-targets

   # Format code
   cargo fmt --all

   # Check for security issues
   cargo audit
   ```

5. **Submit Pull Request**
   - Use a clear, descriptive title
   - Reference related issues
   - Describe what changes you made and why
   - Include screenshots for UI changes
   - Ensure CI passes

## Development Setup

### Prerequisites

- Rust 1.70+ (via [rustup](https://rustup.rs/))
- SQLite 3.35+
- Git

### Building

```bash
# Clone the repository
git clone https://github.com/anivar/termbrain.git
cd termbrain

# Build debug version
cargo build

# Build release version
cargo build --release

# Run tests
cargo test --workspace

# Run with debug logging
RUST_LOG=debug cargo run -- search test
```

### Project Structure

```
termbrain/
├── crates/
│   ├── termbrain-core/      # Domain logic
│   ├── termbrain-storage/   # Database layer
│   └── termbrain-cli/       # CLI interface
├── shell-integration/       # Shell hooks
├── migrations/             # Database migrations
└── tests/                  # Integration tests
```

## Coding Standards

### Rust Guidelines

1. **Follow Rust idioms**
   - Use `Result<T, E>` for error handling
   - Prefer `?` operator over `unwrap()`
   - Use meaningful variable names
   - Document public APIs

2. **Error Handling**
   ```rust
   // Good
   let file = File::open(path)?;
   
   // Bad
   let file = File::open(path).unwrap();
   ```

3. **Code Organization**
   - Keep modules focused and cohesive
   - Use the type system effectively
   - Minimize `unsafe` code
   - Add tests alongside implementation

### Documentation

1. **Code Comments**
   - Document "why" not "what"
   - Use `///` for public API docs
   - Include examples in doc comments

2. **Commit Messages**
   - Use present tense ("Add feature" not "Added feature")
   - Keep first line under 50 characters
   - Reference issues: "Fix #123: Description"
   - Use conventional commits when possible:
     - `feat:` New features
     - `fix:` Bug fixes
     - `docs:` Documentation changes
     - `test:` Test additions/changes
     - `refactor:` Code refactoring
     - `chore:` Maintenance tasks

### Testing

1. **Unit Tests**
   - Test edge cases
   - Use descriptive test names
   - Keep tests focused and independent

2. **Integration Tests**
   - Test real workflows
   - Verify shell integration
   - Test error scenarios

Example:
```rust
#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_command_validation_rejects_empty() {
        let result = validate_command("");
        assert!(result.is_err());
    }
}
```

## Pull Request Process

1. **Before Submitting**
   - Rebase on latest main branch
   - Ensure all tests pass
   - Run formatter and linter
   - Update documentation

2. **PR Guidelines**
   - One feature/fix per PR
   - Keep changes focused
   - Respond to review feedback
   - Be patient with the review process

3. **Review Process**
   - At least one maintainer approval required
   - CI must pass
   - No merge conflicts
   - Documentation updated

## Architecture Decisions

When making significant changes:

1. Discuss in an issue first
2. Consider backward compatibility
3. Document design decisions
4. Follow existing patterns
5. Prioritize security and performance

## Release Process

1. Update version in `Cargo.toml`
2. Update `CHANGELOG.md`
3. Create release PR
4. Tag release after merge
5. Publish to crates.io

## Getting Help

- Check documentation first
- Ask in GitHub Discussions
- Join our community chat (if available)
- Tag maintainers for guidance

## Recognition

Contributors are recognized in:
- Release notes
- README acknowledgments
- GitHub contributors page

Thank you for contributing to TermBrain! 🧠