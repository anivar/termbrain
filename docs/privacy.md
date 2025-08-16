# Privacy Guide

Termbrain is designed with privacy as a core principle. This guide explains how your data is handled and how to control it.

## Privacy Principles

1. **Local-Only Storage** - All data stays on your machine
2. **No Telemetry** - Zero network requests or tracking
3. **User Control** - You decide what to record and keep
4. **Automatic Protection** - Sensitive data detection and redaction

## Data Storage

### What is Stored

- Command text
- Directory where command was run
- Exit codes and duration
- Git branch (if applicable)
- Timestamp
- Session ID

### What is NOT Stored

- Command output
- Environment variables (except for project detection)
- File contents
- Network traffic
- Personal information

### Storage Location

All data is stored in: `~/.termbrain/data/termbrain.db`

This is a SQLite database that you can:
- Inspect with any SQLite tool
- Export to other formats
- Delete at any time

## Privacy Controls

### Pause Recording

```bash
# Temporarily pause recording
export TERMBRAIN_PAUSED=1

# Resume recording
unset TERMBRAIN_PAUSED
```

### Sensitive Command Detection

Termbrain automatically detects and marks sensitive commands:
- Password-related commands
- API keys and tokens
- SSH and GPG operations
- Environment variable exports

### Manual Privacy Management

```bash
# Access privacy controls
tb privacy
```

Options:
1. **Redact sensitive data** - Replace sensitive commands with [REDACTED]
2. **Export your data** - Get a JSON export of all data
3. **Clear all data** - Complete deletion
4. **Pause recording** - Temporarily stop capturing

## Sensitive Directories

Termbrain automatically skips recording in:
- `~/.ssh/`
- `~/.gnupg/`
- Any directory with `/private/` in the path

## Data Redaction

### Automatic Redaction

Commands containing these patterns are automatically marked sensitive:
- `password`, `token`, `secret`, `api_key`
- Base64 encoded strings
- Long hexadecimal strings
- Environment variable assignments

### Manual Redaction

```bash
# Redact all sensitive commands
sqlite3 ~/.termbrain/data/termbrain.db "
    UPDATE commands 
    SET command = '[REDACTED]' 
    WHERE is_sensitive = 1;
"
```

## Data Export

### Export Everything

```bash
tb privacy
# Choose "Export my data"
```

### Export Specific Data

```bash
# Export last 30 days
sqlite3 ~/.termbrain/data/termbrain.db "
    SELECT * FROM commands 
    WHERE timestamp > datetime('now', '-30 days')
" > my-export.json
```

## Data Deletion

### Delete Everything

```bash
tb privacy
# Choose "Clear all data"
# Confirm with "DELETE"
```

### Delete Specific Time Range

```bash
# Delete commands older than 90 days
sqlite3 ~/.termbrain/data/termbrain.db "
    DELETE FROM commands 
    WHERE timestamp < datetime('now', '-90 days');
"
```

## Security Considerations

### File Permissions

The database is created with user-only permissions:
```bash
ls -la ~/.termbrain/data/termbrain.db
# -rw------- (600)
```

### SQL Injection Protection

All user input is properly escaped using `tb::escape_sql`

### No Network Access

Termbrain never makes network requests. You can verify this:
```bash
# Check for network code
grep -r "curl\|wget\|fetch" ~/.termbrain/
```

## Best Practices

1. **Regular Reviews** - Periodically check what's being recorded
2. **Use Privacy Mode** - Pause recording for sensitive work
3. **Export Before Sharing** - Review exports before sharing contexts
4. **Clean Old Data** - Remove old commands you no longer need

## FAQ

**Q: Can others access my Termbrain data?**
A: Only if they have access to your user account. The database is protected by filesystem permissions.

**Q: Is data encrypted?**
A: Not by default. Use full-disk encryption for additional security.

**Q: Can I move my data to another machine?**
A: Yes, just copy `~/.termbrain/data/termbrain.db`

**Q: How do I completely uninstall?**
A: Run `./uninstall.sh` - it will ask about keeping or deleting your data.

## Contact

For privacy concerns or questions, please open an issue on GitHub.