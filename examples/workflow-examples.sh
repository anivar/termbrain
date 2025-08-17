#!/usr/bin/env bash
# Termbrain Workflow Examples

echo "🧠 Termbrain Workflow Examples"
echo "=============================="
echo ""

# Source termbrain (assumes already installed)
source ~/.termbrain/bin/termbrain

# Load workflow library
source ~/.termbrain/lib/workflows.sh

echo "📝 Creating example workflows..."
echo ""

# Example 1: Git commit workflow
echo "1. Git Commit Workflow"
tb::workflow_create "git-commit" \
    "Standard git commit workflow with checks" \
    "git status" \
    "git diff --staged" \
    "git commit -v"
echo ""

# Example 2: Docker development workflow
echo "2. Docker Development Workflow"
tb::workflow_create "docker-dev" \
    "Build and run Docker container for development" \
    "docker build -t myapp:dev ." \
    "docker stop myapp-dev || true" \
    "docker rm myapp-dev || true" \
    "docker run -d --name myapp-dev -p 3000:3000 -v \$(pwd):/app myapp:dev"
echo ""

# Example 3: Node.js test and lint workflow
echo "3. Node.js Quality Check Workflow"
tb::workflow_create "node-check" \
    "Run tests and linting for Node.js project" \
    "npm run lint" \
    "npm test" \
    "npm audit"
echo ""

# Example 4: Python virtual environment setup
echo "4. Python Environment Setup"
tb::workflow_create "python-env" \
    "Create and activate Python virtual environment" \
    "python -m venv .venv" \
    "echo 'Run: source .venv/bin/activate'" \
    "source .venv/bin/activate && pip install --upgrade pip" \
    "source .venv/bin/activate && pip install -r requirements.txt"
echo ""

# Example 5: Database backup workflow
echo "5. Database Backup Workflow"
tb::workflow_create "db-backup" \
    "Backup PostgreSQL database" \
    "mkdir -p backups" \
    "pg_dump -U postgres -d mydb > backups/mydb_\$(date +%Y%m%d_%H%M%S).sql" \
    "ls -la backups/" \
    "echo 'Backup complete!'"
echo ""

# Example 6: Deploy to staging
echo "6. Deploy to Staging Workflow"
tb::workflow_create "deploy-staging" \
    "Deploy application to staging environment" \
    "git checkout main" \
    "git pull origin main" \
    "npm install" \
    "npm run build" \
    "npm run test" \
    "rsync -avz --exclude='node_modules' --exclude='.env' ./ user@staging-server:/var/www/app/" \
    "ssh user@staging-server 'cd /var/www/app && npm install --production && pm2 restart app'"
echo ""

# Example 7: Clean development environment
echo "7. Clean Development Environment"
tb::workflow_create "clean-dev" \
    "Clean up development artifacts" \
    "find . -name '*.pyc' -delete" \
    "find . -name '__pycache__' -type d -exec rm -rf {} +" \
    "find . -name '.DS_Store' -delete" \
    "rm -rf node_modules" \
    "rm -rf .venv" \
    "docker system prune -f"
echo ""

# Example 8: Full stack startup
echo "8. Full Stack Development Startup"
tb::workflow_create "fullstack-start" \
    "Start all services for full stack development" \
    "docker-compose up -d postgres redis" \
    "cd backend && npm run dev &" \
    "cd frontend && npm run dev &" \
    "echo 'All services started! Backend: http://localhost:3001, Frontend: http://localhost:3000'"
echo ""

# Show all created workflows
echo "==============================================="
echo "✅ Example workflows created!"
echo ""
echo "📋 Available workflows:"
tb::workflow_list
echo ""
echo "💡 Usage examples:"
echo "  tb workflow show git-commit      # View workflow details"
echo "  tb workflow run git-commit       # Run the workflow"
echo "  tb workflow run docker-dev --dry-run  # Preview without executing"
echo ""
echo "🔍 Discover patterns in your own usage:"
echo "  tb learn                         # Find your command patterns"
echo "  tb workflow suggest              # Get workflow suggestions"
echo ""
echo "🚀 Create your own workflows:"
echo "  tb workflow create <name> <description> <cmd1> <cmd2> ..."
echo ""