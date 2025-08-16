# Termbrain + Claude Workflow Examples

## Example 1: Debugging with Context

### Without Termbrain
```
You: "My Docker container keeps failing"
Claude: "What error are you getting?"
You: "Port 5432 already in use"
Claude: "What have you tried?"
You: "I don't remember exactly..."
```

### With Termbrain
```bash
# First, generate context
tb ai "docker port errors" claude

# Now Claude knows:
# - You had this error 3 times before
# - You fixed it with: lsof -i :5432 && kill -9 PID
# - It's related to your PostgreSQL setup
```

## Example 2: Architecture Discussion

### Setup
```bash
# Document your decision
tb arch "API Design" "Using REST with JWT tokens for security"

# Generate context
tb ai "api architecture" claude
```

### Result
Claude now has context about:
- Your API design decisions
- Related commands you've run
- Your tech stack
- Previous similar implementations

## Example 3: Learning Journey

### Track Your Learning
```bash
# Set intention
tb intend "implement user authentication"

# Work on it...
npm install bcrypt jsonwebtoken
# ... coding ...

# Document completion
tb achieved
# Prompt: "Learned about JWT refresh tokens and secure storage"

# Generate context for help
tb ai "authentication implementation" claude
```

### Claude's Enhanced Response
With this context, Claude can:
- See you're learning authentication
- Know you chose JWT approach
- Understand what packages you're using
- Provide guidance specific to your implementation

## Example 4: Project Onboarding

### When joining a new project
```bash
cd new-project

# Let Termbrain analyze your history
tb ai "new project setup" claude

# Claude now knows:
# - This is a TypeScript/React project
# - You use pnpm as package manager
# - Your common testing patterns
# - Your git workflow
```

## Example 5: Error Pattern Recognition

```bash
# After multiple similar errors
tb learn

# Termbrain shows:
# Pattern detected: npm install → npm test (fails 40% of time)
# Suggestion: Run 'npm run build' first

# Share with Claude
tb ai "testing workflow" claude
```

## Real-World Scenario: Full Development Session

```bash
# 1. Start your day
tb intend "add user profile feature"

# 2. Work on the feature
git checkout -b feature/user-profile
npm install react-avatar
# ... coding ...

# 3. Hit an error
npm test
# ERROR: Cannot find module

# 4. Fix it
npm run build
npm test
# Success!

# 5. Get help from Claude
tb ai "user profile implementation" claude

# 6. Complete the task
tb achieved
# "Implemented user profile with avatar upload"

# Claude now has complete context of:
# - Your intention
# - Commands you ran
# - Errors you encountered
# - How you fixed them
# - What you learned
```

## Pro Tips

1. **Before asking Claude for help**:
   ```bash
   tb ai "current problem" claude
   ```

2. **For code reviews**:
   ```bash
   tb ai "recent changes" claude
   ```

3. **For debugging sessions**:
   ```bash
   tb ai "last hour errors" claude
   ```

4. **For learning documentation**:
   ```bash
   tb growth  # See your learning journey
   tb ai "learning progress" claude
   ```