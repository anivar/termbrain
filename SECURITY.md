# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 2.0.x   | :white_check_mark: |
| 1.x     | :x:                |

## Reporting a Vulnerability

We take the security of TermBrain seriously. If you discover a security vulnerability, please follow these steps:

1. **DO NOT** disclose the vulnerability publicly until it has been addressed
2. Create a private security advisory on GitHub or contact the maintainers
3. Include the following information:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)

### Response Timeline

- **Initial Response**: Within 48 hours
- **Status Update**: Within 7 days
- **Fix Timeline**: Depends on severity
  - Critical: 1-7 days
  - High: 1-2 weeks
  - Medium: 2-4 weeks
  - Low: Next release

## Security Features

TermBrain implements multiple security measures:

### Input Validation
- All user inputs are validated before processing
- Path traversal prevention
- Command injection protection
- SQL injection prevention through parameterized queries

### Data Protection
- All data stored locally (no cloud sync)
- No telemetry or analytics
- Commands stored as-is (no automatic filtering yet)

### Shell Integration Security
- Secure command capture
- Proper escaping of shell arguments
- No execution of user commands
- Read-only access to command history

### Code Security
- Memory safety through Rust
- No unsafe blocks in critical paths
- Comprehensive error handling
- Regular dependency audits

## Security Best Practices

When using TermBrain:

1. **Regular Updates**: Keep TermBrain updated to the latest version
2. **File Permissions**: Ensure `~/.termbrain/` has appropriate permissions (700)
3. **Database Security**: The SQLite database should be readable only by the user
4. **Environment Variables**: Be cautious about recording sensitive environment variables
5. **AI Integration**: Review commands before sharing with AI services

## Known Security Considerations

1. **Command History**: TermBrain records all commands, including those with sensitive data
   - Use `TERMBRAIN_ENABLED=0` to temporarily disable recording
   - Manually remove sensitive entries from the database if needed

2. **AI Agent Detection**: Process tree scanning requires reading process information
   - This is read-only and doesn't execute any processes
   - Can be disabled by not loading shell integration

3. **Shell Integration**: Hooks into shell command execution
   - All hooks are passive (monitoring only)
   - No command modification or injection

## Security Practices

Recommended security practices:

- Run `cargo audit` regularly for dependency scanning
- Review code changes for security implications
- Test input validation thoroughly

## Disclosure Policy

After a security vulnerability is fixed:

1. We will publish a security advisory
2. Update the CHANGELOG with security fixes
3. Credit the reporter (unless they prefer to remain anonymous)
4. Provide migration instructions if needed

## Contact

For security concerns:
- GitHub Security Advisories: [Create private advisory](https://github.com/anivar/termbrain/security/advisories/new)
- Or contact maintainers directly through GitHub

For general issues, use the public issue tracker.