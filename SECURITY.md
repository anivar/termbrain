# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |
| < 1.0   | :x:                |

## Reporting a Vulnerability

We take the security of Termbrain seriously. If you have discovered a security vulnerability, please follow these steps:

### 1. **Do NOT** disclose publicly

Please do not create a public GitHub issue for security vulnerabilities.

### 2. Report privately

Send an email to: [INSERT SECURITY EMAIL]

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if any)

### 3. Response timeline

- **Acknowledgment**: Within 48 hours
- **Initial assessment**: Within 1 week
- **Fix timeline**: Depends on severity
  - Critical: 1-2 weeks
  - High: 2-4 weeks
  - Medium/Low: Next release

## Security Measures

### Data Protection
- All data stored locally in SQLite database
- No network requests or telemetry
- Automatic password/secret detection and redaction
- Secure SQL parameter binding

### Code Security
- Input validation on all user inputs
- SQL injection prevention
- Path traversal protection
- Command injection prevention

### Privacy by Design
- No cloud connectivity
- User controls all data
- Export/delete functionality
- Recording can be paused

## Best Practices for Users

1. **Keep Termbrain updated** - Security fixes are released regularly
2. **Use privacy mode** - Pause recording in sensitive directories
3. **Review exports** - Check exported data before sharing
4. **Secure your database** - The SQLite file contains your command history

## Disclosure Policy

When we receive a security report:

1. Confirm the vulnerability
2. Develop and test a fix
3. Release patched version
4. Credit the reporter (unless anonymity requested)
5. Publish security advisory

## Security Features

- **Auto-redaction**: Passwords and API keys automatically hidden
- **Safe mode**: Dangerous commands blocked from recording
- **Privacy controls**: Fine-grained control over what's recorded
- **Local only**: No network connectivity reduces attack surface

## Contact

Security team email: [INSERT SECURITY EMAIL]
PGP key: [INSERT PGP KEY URL]

Thank you for helping keep Termbrain secure!