# TermBrain Deployment Guide

> ⚠️ **WARNING**: TermBrain v2.0.0-alpha.1 is NOT production-ready. This guide describes the target deployment setup, but many features are not yet implemented. See [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md) for current status.

This guide covers deployment considerations for TermBrain in production environments.

## System Requirements

### Minimum Requirements
- **OS**: Linux, macOS, or BSD
- **CPU**: 1 core
- **RAM**: 512 MB
- **Storage**: 100 MB + space for command history
- **Rust**: 1.70+ (for building)
- **SQLite**: 3.35+

### Recommended Requirements
- **CPU**: 2+ cores
- **RAM**: 1 GB
- **Storage**: SSD with 1 GB+ free space
- **Shell**: Bash 4.0+, Zsh 5.0+, or Fish 3.0+

## Installation Methods

### 1. From Source (Recommended)

```bash
# Clone repository
git clone https://github.com/anivar/termbrain.git
cd termbrain

# Build release binary
cargo build --release

# Install binary
sudo cp target/release/tb /usr/local/bin/
sudo chmod +x /usr/local/bin/tb

# Install shell integration for all users
sudo tb install --shell bash --system
```

### 2. Using Cargo

```bash
# Install from crates.io (when published)
cargo install termbrain-cli

# Or from git
cargo install --git https://github.com/anivar/termbrain.git termbrain-cli
```

### 3. Pre-built Binaries

Download from [releases page](https://github.com/anivar/termbrain/releases):

```bash
# Download binary
wget https://github.com/anivar/termbrain/releases/download/v2.0.0/tb-linux-amd64
chmod +x tb-linux-amd64
sudo mv tb-linux-amd64 /usr/local/bin/tb

# Verify installation
tb --version
```

## Configuration

### Environment Variables

Create `/etc/termbrain/env`:

```bash
# Core settings
TERMBRAIN_DATABASE_PATH=/var/lib/termbrain/termbrain.db
TERMBRAIN_LOG_LEVEL=info
TERMBRAIN_LOG_DIR=/var/log/termbrain

# Feature flags
TERMBRAIN_ENABLED=1
TERMBRAIN_AUTO_RECORD=1
TERMBRAIN_AI_DETECTION=1

# Performance tuning
TERMBRAIN_POOL_SIZE=10
TERMBRAIN_COMMAND_TIMEOUT=5000
```

### System-wide Configuration

Create `/etc/termbrain/config.toml`:

```toml
[core]
database_path = "/var/lib/termbrain/termbrain.db"
log_level = "info"

# Note: Configuration file loading is not yet implemented
# These are planned configuration options:
#
# [storage]
# max_database_size = "10GB"
# retention_days = 365
# 
# [security]
# allowed_users = ["*"]
# 
# [performance]
# connection_pool_size = 10
```

## Directory Structure

```
/etc/termbrain/              # Configuration
├── config.toml             # Main config
├── env                     # Environment variables
└── hooks/                  # Custom hooks

/var/lib/termbrain/         # Data
├── termbrain.db           # Main database
├── backups/               # Database backups
└── migrations/            # Applied migrations

/var/log/termbrain/         # Logs
├── termbrain.log          # Application logs
└── audit.log              # Security audit log

/usr/local/bin/            # Binaries
└── tb                     # Main executable

/etc/profile.d/            # Shell integration
└── termbrain.sh          # System-wide shell hooks
```

## Shell Integration

### System-wide Setup

For all users:

```bash
# Bash
echo 'source /usr/share/termbrain/shell-integration/termbrain.bash' >> /etc/bash.bashrc

# Zsh
echo 'source /usr/share/termbrain/shell-integration/termbrain.zsh' >> /etc/zsh/zshrc

# Fish
cp /usr/share/termbrain/shell-integration/termbrain.fish /etc/fish/conf.d/
```

### Per-user Setup

```bash
# Install for current user
tb install --shell $(basename $SHELL)

# Verify installation
tb status
```

## Database Management

### Initial Setup

```bash
# Create data directory
sudo mkdir -p /var/lib/termbrain
sudo chown termbrain:termbrain /var/lib/termbrain

# Database will be created automatically on first use
# No init command exists yet
```

### Backup Strategy

Create `/etc/cron.daily/termbrain-backup`:

```bash
#!/bin/bash
BACKUP_DIR="/var/lib/termbrain/backups"
DB_PATH="/var/lib/termbrain/termbrain.db"
DATE=$(date +%Y%m%d)

mkdir -p "$BACKUP_DIR"
sqlite3 "$DB_PATH" ".backup $BACKUP_DIR/termbrain-$DATE.db"

# Keep only last 7 days
find "$BACKUP_DIR" -name "termbrain-*.db" -mtime +7 -delete
```

### Database Maintenance

```bash
# Optimize database (monthly)
sqlite3 /var/lib/termbrain/termbrain.db "VACUUM;"
sqlite3 /var/lib/termbrain/termbrain.db "ANALYZE;"

# Check integrity
sqlite3 /var/lib/termbrain/termbrain.db "PRAGMA integrity_check;"
```

## Security Hardening

### File Permissions

```bash
# Set proper permissions
sudo chown -R termbrain:termbrain /var/lib/termbrain
sudo chmod 750 /var/lib/termbrain
sudo chmod 640 /var/lib/termbrain/termbrain.db

# Config permissions
sudo chown -R root:termbrain /etc/termbrain
sudo chmod 750 /etc/termbrain
sudo chmod 640 /etc/termbrain/config.toml
```

### User Isolation

Create dedicated user:

```bash
# Create system user
sudo useradd -r -s /bin/false -d /var/lib/termbrain termbrain

# Add users to termbrain group for access
sudo usermod -a -G termbrain username
```

### SELinux Policy

```bash
# Create custom policy
cat > termbrain.te << EOF
module termbrain 1.0;

require {
    type user_t;
    type termbrain_t;
    type termbrain_db_t;
}

# Allow termbrain to read/write its database
allow termbrain_t termbrain_db_t:file { read write create unlink };
EOF

# Compile and install
checkmodule -M -m -o termbrain.mod termbrain.te
semodule_package -o termbrain.pp -m termbrain.mod
sudo semodule -i termbrain.pp
```

## Monitoring

### Health Checks

Create `/usr/local/bin/termbrain-health`:

```bash
#!/bin/bash
# Check if service is responsive
if ! tb status >/dev/null 2>&1; then
    echo "CRITICAL: TermBrain not responding"
    exit 2
fi

# Check database size
DB_SIZE=$(stat -f%z /var/lib/termbrain/termbrain.db 2>/dev/null || stat -c%s /var/lib/termbrain/termbrain.db)
if [ $DB_SIZE -gt 10737418240 ]; then  # 10GB
    echo "WARNING: Database size exceeds 10GB"
    exit 1
fi

echo "OK: TermBrain healthy"
exit 0
```

### Logging

Configure rsyslog `/etc/rsyslog.d/termbrain.conf`:

```
# TermBrain logging
if $programname == 'termbrain' then /var/log/termbrain/termbrain.log
& stop
```

### Metrics

Export metrics for monitoring:

```bash
# Metrics export is not yet implemented

# Custom metrics script
#!/bin/bash
# Note: JSON output for status command may not include all fields yet
echo "termbrain_database_size_bytes $(stat -c%s /var/lib/termbrain/termbrain.db)"
```

## Performance Tuning

### SQLite Optimization

```sql
-- Set pragmas for performance
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA cache_size = -64000;  -- 64MB cache
PRAGMA temp_store = MEMORY;
PRAGMA mmap_size = 268435456;  -- 256MB mmap
```

### System Limits

Edit `/etc/security/limits.d/termbrain.conf`:

```
termbrain soft nofile 65536
termbrain hard nofile 65536
termbrain soft nproc 4096
termbrain hard nproc 4096
```

## Troubleshooting

### Common Issues

1. **Permission Denied**
   ```bash
   # Fix permissions
   sudo chown -R termbrain:termbrain /var/lib/termbrain
   sudo chmod -R u+rw,g+r,o-rwx /var/lib/termbrain
   ```

2. **Database Locked**
   ```bash
   # Check for stale locks
   lsof /var/lib/termbrain/termbrain.db
   
   # Force unlock (use with caution)
   sqlite3 /var/lib/termbrain/termbrain.db "PRAGMA journal_mode=DELETE;"
   ```

3. **High Memory Usage**
   ```bash
   # Reduce cache size
   export TERMBRAIN_CACHE_SIZE=1000
   
   # Limit connection pool
   export TERMBRAIN_POOL_SIZE=5
   ```

### Debug Mode

```bash
# Enable debug logging
export RUST_LOG=termbrain=debug
export TERMBRAIN_LOG_LEVEL=debug

# Run with verbose output
tb --verbose search test

# Trace SQL queries
export TERMBRAIN_SQL_LOG=1
```

## Uninstallation

```bash
# Stop recording
tb disable

# Remove shell integration
tb uninstall --purge

# Remove system files
sudo rm -rf /etc/termbrain
sudo rm -rf /var/lib/termbrain
sudo rm -rf /var/log/termbrain
sudo rm /usr/local/bin/tb

# Remove user
sudo userdel termbrain
```

## Best Practices

1. **Regular Backups**: Automate daily backups of the database
2. **Log Rotation**: Configure logrotate for TermBrain logs
3. **Monitoring**: Set up alerts for database size and errors
4. **Updates**: Subscribe to security advisories
5. **Access Control**: Limit who can read command history
6. **Retention**: Implement data retention policies
7. **Audit**: Review access logs regularly

## Support

- Documentation: https://termbrain.dev/docs
- Issues: https://github.com/anivar/termbrain/issues
- Security: security@termbrain.dev