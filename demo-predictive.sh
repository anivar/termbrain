#!/usr/bin/env bash
# Demo script for predictive features

echo "🤖 Termbrain Predictive DevOps Demo"
echo "==================================="
echo ""

# Add some sample data to the database
TERMBRAIN_DB="${TERMBRAIN_HOME:-$HOME/.termbrain}/data/termbrain.db"

echo "Setting up demo data..."

# Add historical commands
sqlite3 "$TERMBRAIN_DB" <<EOF
-- Clear demo data
DELETE FROM commands WHERE session_id = 'demo';

-- Add /var/log patterns
INSERT INTO commands (command, directory, semantic_type, exit_code, session_id)
VALUES 
  ('tail -f nginx/error.log | grep 500', '/var/log', 'monitoring', 0, 'demo'),
  ('tail -f nginx/error.log | grep 500', '/var/log', 'monitoring', 0, 'demo'),
  ('less +F nginx/access.log', '/var/log', 'monitoring', 0, 'demo'),
  ('grep ERROR *.log', '/var/log', 'searching', 0, 'demo'),
  ('systemctl status nginx', '/var/log', 'monitoring', 0, 'demo');

-- Add git push patterns with failures
INSERT INTO commands (command, directory, semantic_type, exit_code, session_id, timestamp)
VALUES 
  ('git push origin main', '$PWD', 'version_control', 1, 'demo', datetime('now', '-2 days')),
  ('npm test', '$PWD', 'testing', 0, 'demo', datetime('now', '-2 days', '+1 minute')),
  ('git push origin main', '$PWD', 'version_control', 0, 'demo', datetime('now', '-2 days', '+2 minutes'));
EOF

echo ""
echo "Demo 1: Directory-based suggestions"
echo "-----------------------------------"
echo "When you cd to /var/log, termbrain suggests:"
echo ""

# Simulate the prediction output
echo "🤖 TB: Entering log"
echo "     Common commands here:"
echo "     • tail -f nginx/error.log | grep 500 (2 times)"
echo "     • less +F nginx/access.log (1 times)"
echo "     • grep ERROR *.log (1 times)"
echo "     Suggestions:"
echo "     → tail -f error.log"
echo "     → less +F access.log"
echo "     → grep ERROR *.log"

echo ""
echo "Demo 2: Pre-push warnings"
echo "-------------------------"
echo "When you run 'git push', termbrain warns:"
echo ""

echo "⚠️  TB: No tests run in this session. Consider running tests first!"
echo "📊 TB: 1 failed pushes in the last week from this repo."
echo "     Last time, this helped: npm test"

echo ""
echo "Demo 3: Dangerous command detection"
echo "-----------------------------------"
echo "When you type 'rm -rf /', termbrain warns:"
echo ""

echo "🚨 TB: EXTREMELY DANGEROUS COMMAND DETECTED!"
echo "     This could delete everything. Are you SURE?"
echo "     Press Ctrl+C to cancel."

echo ""
echo "Demo 4: Next command suggestions"
echo "--------------------------------"
echo "After running 'npm install', termbrain suggests:"
echo ""

echo "💡 TB: Next, you might want to:"
echo "     → npm test (45 times before)"
echo "     → npm run dev (23 times before)"
echo "     → git status (12 times before)"

echo ""
echo "To enable predictive mode in your shell:"
echo "  tb predictive on"
echo ""
echo "To see it in action:"
echo "  1. Enable predictive mode"
echo "  2. cd to different directories"
echo "  3. Try commands like 'git push' or 'npm publish'"
echo ""