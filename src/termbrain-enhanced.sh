#!/usr/bin/env bash
# 🧠 Termbrain V2 - Enhanced with High-Level Memory
# Inspired by Cipher's conceptual memory approach

# ============================================
# HIGH-LEVEL MEMORY SYSTEM
# ============================================

# New database tables for conceptual memory
tb::init_enhanced_db() {
    sqlite3 "$TERMBRAIN_DB" <<'EOF'
-- Concepts table: High-level understanding
CREATE TABLE IF NOT EXISTS concepts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    concept_type TEXT NOT NULL, -- 'architecture', 'decision', 'learning', 'goal'
    title TEXT NOT NULL,
    description TEXT,
    context TEXT,
    related_commands TEXT, -- JSON array of command IDs
    tags TEXT, -- JSON array
    importance INTEGER DEFAULT 5, -- 1-10 scale
    session_id TEXT
);

-- Reasoning table: Track why decisions were made
CREATE TABLE IF NOT EXISTS reasoning (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    decision TEXT NOT NULL,
    why TEXT NOT NULL,
    alternatives_considered TEXT,
    outcome TEXT,
    related_concept_id INTEGER,
    FOREIGN KEY (related_concept_id) REFERENCES concepts(id)
);

-- Projects table: Project-level memory
CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT,
    tech_stack TEXT, -- JSON array
    architecture_notes TEXT,
    business_logic TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_active DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Memory links: Connect commands to concepts
CREATE TABLE IF NOT EXISTS memory_links (
    command_id INTEGER,
    concept_id INTEGER,
    link_type TEXT, -- 'implements', 'explores', 'fixes', 'refactors'
    FOREIGN KEY (command_id) REFERENCES commands(id),
    FOREIGN KEY (concept_id) REFERENCES concepts(id)
);

CREATE INDEX IF NOT EXISTS idx_concepts_type ON concepts(concept_type);
CREATE INDEX IF NOT EXISTS idx_concepts_session ON concepts(session_id);
CREATE INDEX IF NOT EXISTS idx_reasoning_concept ON reasoning(related_concept_id);
EOF
}

# ============================================
# CONCEPTUAL MEMORY CAPTURE
# ============================================

# Capture high-level concepts automatically
tb::capture_concept() {
    local concept_type="$1"
    local title="$2"
    local description="$3"
    
    # Get related commands from recent history
    local related_cmds=$(sqlite3 "$TERMBRAIN_DB" "
        SELECT json_group_array(id) 
        FROM (
            SELECT id FROM commands 
            WHERE session_id = '$TERMBRAIN_SESSION_ID' 
            ORDER BY timestamp DESC 
            LIMIT 5
        );
    ")
    
    # Auto-generate tags based on context
    local tags=$(tb::generate_tags "$title $description")
    
    sqlite3 "$TERMBRAIN_DB" "
        INSERT INTO concepts (
            concept_type, title, description, 
            context, related_commands, tags, session_id
        ) VALUES (
            '$concept_type',
            '$(tb::escape_sql "$title")',
            '$(tb::escape_sql "$description")',
            '$(tb::get_current_context)',
            '$related_cmds',
            '$tags',
            '$TERMBRAIN_SESSION_ID'
        );
    "
    
    echo "🧠 Concept captured: $title"
}

# Interactive concept capture
tb::why() {
    local last_cmd=$(sqlite3 "$TERMBRAIN_DB" "
        SELECT command FROM commands 
        ORDER BY timestamp DESC LIMIT 1;
    ")
    
    echo "📝 Why did you run: $last_cmd"
    echo -n "Reason: "
    read -r reason
    
    if [[ -n "$reason" ]]; then
        tb::capture_concept "decision" "$last_cmd" "$reason"
        
        # Also capture as reasoning
        sqlite3 "$TERMBRAIN_DB" "
            INSERT INTO reasoning (decision, why)
            VALUES ('$(tb::escape_sql "$last_cmd")', '$(tb::escape_sql "$reason")');
        "
    fi
}

# Capture architectural decisions
tb::arch() {
    local title="$1"
    local description="$2"
    
    if [[ -z "$title" ]]; then
        echo "📐 Capture architectural decision"
        echo -n "Title: "
        read -r title
        echo -n "Description: "
        read -r description
    fi
    
    tb::capture_concept "architecture" "$title" "$description"
    
    # Update project architecture
    local project=$(tb::detect_project)
    sqlite3 "$TERMBRAIN_DB" "
        UPDATE projects 
        SET architecture_notes = architecture_notes || '\n- ' || '$(tb::escape_sql "$title: $description")'
        WHERE name = '$project';
    "
}

# ============================================
# INTELLIGENT MEMORY SYNTHESIS
# ============================================

# Generate context with both commands AND concepts
tb::ai_enhanced() {
    local query="${1:-general}"
    local context_file="$TERMBRAIN_HOME/cache/enhanced-context-$(date +%s).md"
    
    {
        echo "# Termbrain Enhanced Context"
        echo "Generated: $(date)"
        echo "Query: $query"
        echo ""
        
        # High-level concepts related to query
        echo "## Relevant Concepts & Decisions"
        sqlite3 "$TERMBRAIN_DB" "
            SELECT printf('### %s\n%s\n*Type: %s | Importance: %d*\n', 
                   title, description, concept_type, importance)
            FROM concepts 
            WHERE title LIKE '%$query%' 
               OR description LIKE '%$query%'
               OR tags LIKE '%$query%'
            ORDER BY importance DESC, timestamp DESC
            LIMIT 5;
        "
        echo ""
        
        # Reasoning history
        echo "## Decision History"
        sqlite3 "$TERMBRAIN_DB" "
            SELECT printf('**Decision:** %s\n**Why:** %s\n', 
                   decision, why)
            FROM reasoning 
            WHERE decision LIKE '%$query%' 
               OR why LIKE '%$query%'
            ORDER BY timestamp DESC
            LIMIT 5;
        "
        echo ""
        
        # Project context
        echo "## Project Context"
        local current_project=$(tb::detect_project)
        sqlite3 "$TERMBRAIN_DB" "
            SELECT printf('**Project:** %s\n**Stack:** %s\n**Architecture:**\n%s\n**Business Logic:**\n%s', 
                   name, tech_stack, architecture_notes, business_logic)
            FROM projects 
            WHERE name = '$current_project';
        "
        echo ""
        
        # Command history with conceptual links
        echo "## Command History with Context"
        sqlite3 "$TERMBRAIN_DB" "
            SELECT printf('%s\n   Context: %s\n   Concept: %s', 
                   c.command,
                   c.semantic_type,
                   COALESCE(con.title, 'No linked concept'))
            FROM commands c
            LEFT JOIN memory_links ml ON c.id = ml.command_id
            LEFT JOIN concepts con ON ml.concept_id = con.id
            WHERE c.command LIKE '%$query%'
            ORDER BY c.timestamp DESC
            LIMIT 10;
        "
        echo ""
        
        # Learned patterns with explanations
        echo "## Your Patterns & Workflows"
        tb::explain_patterns "$query"
        
    } > "$context_file"
    
    # Copy to providers
    tb::copy_to_providers "$context_file"
    
    echo "🧠 Enhanced context generated with high-level understanding!"
}

# ============================================
# MEMORY EXPLORATION UI
# ============================================

# Interactive memory browser (inspired by Cipher's Web UI)
tb::explore() {
    while true; do
        clear
        echo "🧠 Termbrain Memory Explorer"
        echo "============================"
        echo ""
        echo "1. 📚 Browse Concepts & Decisions"
        echo "2. 🔍 Search Everything" 
        echo "3. 📊 View Analytics"
        echo "4. 🏗️  Architecture Overview"
        echo "5. 💡 Learning Insights"
        echo "6. 🤖 Generate AI Context"
        echo "7. 📤 Export Memory"
        echo "8. ❌ Exit"
        echo ""
        echo -n "Choose [1-8]: "
        read -r choice
        
        case $choice in
            1) tb::browse_concepts ;;
            2) tb::search_enhanced ;;
            3) tb::analytics_dashboard ;;
            4) tb::architecture_view ;;
            5) tb::learning_insights ;;
            6) tb::ai_enhanced ;;
            7) tb::export_memory ;;
            8) break ;;
        esac
        
        echo -e "\nPress Enter to continue..."
        read -r
    done
}

# Browse concepts interactively
tb::browse_concepts() {
    local concept=$(sqlite3 "$TERMBRAIN_DB" "
        SELECT printf('%s | %s | %s', concept_type, title, substr(description, 1, 50))
        FROM concepts
        ORDER BY timestamp DESC;
    " | fzf --header="Select a concept to view details")
    
    if [[ -n "$concept" ]]; then
        local title=$(echo "$concept" | cut -d'|' -f2 | xargs)
        
        clear
        echo "📚 Concept Details"
        echo "=================="
        
        sqlite3 "$TERMBRAIN_DB" -column -header "
            SELECT 
                concept_type as Type,
                title as Title,
                description as Description,
                datetime(timestamp, 'localtime') as Created,
                importance as Importance
            FROM concepts 
            WHERE title = '$title';
        "
        
        echo -e "\n📎 Related Commands:"
        sqlite3 "$TERMBRAIN_DB" "
            SELECT c.command
            FROM commands c
            JOIN json_each((SELECT related_commands FROM concepts WHERE title = '$title')) j
            ON c.id = j.value
            LIMIT 5;
        "
    fi
}

# ============================================
# PROJECT MEMORY MANAGEMENT
# ============================================

# Initialize or switch project context
tb::project() {
    local action="${1:-list}"
    local project_name="${2:-$(basename "$PWD")}"
    
    case "$action" in
        init)
            echo "🚀 Initializing project: $project_name"
            echo -n "Description: "
            read -r description
            echo -n "Tech stack (comma-separated): "
            read -r tech_stack
            
            sqlite3 "$TERMBRAIN_DB" "
                INSERT OR REPLACE INTO projects (name, description, tech_stack)
                VALUES (
                    '$project_name',
                    '$(tb::escape_sql "$description")',
                    json_array($(echo "$tech_stack" | sed "s/,/','/g" | sed "s/^/'/" | sed "s/$/'/"))
                );
            "
            
            echo "✅ Project initialized!"
            ;;
            
        switch)
            # List projects and switch
            local selected=$(sqlite3 "$TERMBRAIN_DB" "
                SELECT name || ' - ' || substr(description, 1, 50)
                FROM projects
                ORDER BY last_active DESC;
            " | fzf --header="Select project")
            
            if [[ -n "$selected" ]]; then
                project_name=$(echo "$selected" | cut -d' ' -f1)
                export TERMBRAIN_ACTIVE_PROJECT="$project_name"
                echo "📁 Switched to project: $project_name"
            fi
            ;;
            
        list)
            echo "📁 Your Projects"
            echo "==============="
            sqlite3 "$TERMBRAIN_DB" -column -header "
                SELECT 
                    name as Project,
                    substr(description, 1, 40) as Description,
                    date(last_active) as 'Last Active'
                FROM projects
                ORDER BY last_active DESC;
            "
            ;;
    esac
}

# ============================================
# AGENT MEMORY MODE
# ============================================

# MCP-compatible server mode (inspired by Cipher)
tb::mcp_server() {
    local port="${1:-3000}"
    
    echo "🤖 Starting Termbrain MCP Server on port $port"
    echo "Compatible with Cursor, Claude Desktop, VS Code"
    
    # Simple HTTP server that responds to MCP requests
    while true; do
        {
            read -r request
            
            case "$request" in
                *"GET /context"*)
                    tb::ai_enhanced > /tmp/tb-context.md
                    echo -e "HTTP/1.1 200 OK\r\nContent-Type: text/markdown\r\n\r\n"
                    cat /tmp/tb-context.md
                    ;;
                    
                *"POST /capture"*)
                    # Read concept from request body
                    read -r body
                    tb::capture_concept "agent" "AI Decision" "$body"
                    echo -e "HTTP/1.1 200 OK\r\n\r\n{\"status\":\"captured\"}"
                    ;;
                    
                *"GET /search"*)
                    query=$(echo "$request" | grep -oP 'q=\K[^&]+')
                    tb::search_api "$query"
                    ;;
            esac
        } | nc -l -p "$port" -q 1
    done
}

# ============================================
# LEARNING & INSIGHTS
# ============================================

# Generate learning insights from patterns
tb::learning_insights() {
    echo "💡 Learning Insights"
    echo "==================="
    echo ""
    
    # Most important concepts
    echo "🎯 Key Concepts You've Captured:"
    sqlite3 "$TERMBRAIN_DB" -column -header "
        SELECT 
            title as Concept,
            concept_type as Type,
            importance as Priority
        FROM concepts
        WHERE importance >= 7
        ORDER BY importance DESC
        LIMIT 5;
    "
    echo ""
    
    # Learning patterns
    echo "📈 Your Learning Journey:"
    sqlite3 "$TERMBRAIN_DB" "
        SELECT printf('- %s: Explored %d times, last on %s',
               pattern_type,
               frequency,
               date(last_seen))
        FROM patterns
        WHERE pattern_type IN ('learning', 'exploring', 'debugging')
        ORDER BY frequency DESC;
    "
    echo ""
    
    # Growth metrics
    echo "🌱 Growth Metrics:"
    local total_concepts=$(sqlite3 "$TERMBRAIN_DB" "SELECT COUNT(*) FROM concepts;")
    local total_decisions=$(sqlite3 "$TERMBRAIN_DB" "SELECT COUNT(*) FROM reasoning;")
    local error_resolution_rate=$(sqlite3 "$TERMBRAIN_DB" "
        SELECT printf('%.1f%%', 100.0 * SUM(CASE WHEN solved THEN 1 ELSE 0 END) / COUNT(*))
        FROM errors;
    ")
    
    echo "  Concepts captured: $total_concepts"
    echo "  Decisions documented: $total_decisions"
    echo "  Error resolution rate: $error_resolution_rate"
}

# ============================================
# MEMORY EXPORT & SHARING
# ============================================

# Export memory in various formats
tb::export_memory() {
    local format="${1:-markdown}"
    local output_file="$TERMBRAIN_HOME/exports/termbrain-export-$(date +%Y%m%d-%H%M%S)"
    
    case "$format" in
        markdown)
            {
                echo "# Termbrain Memory Export"
                echo "Exported: $(date)"
                echo ""
                
                echo "## Concepts & Architecture"
                sqlite3 "$TERMBRAIN_DB" "
                    SELECT printf('### %s\n\n%s\n\nTags: %s\n\n---\n',
                           title, description, tags)
                    FROM concepts
                    WHERE concept_type = 'architecture'
                    ORDER BY importance DESC;
                "
                
                echo "## Key Decisions"
                sqlite3 "$TERMBRAIN_DB" "
                    SELECT printf('**What:** %s\n**Why:** %s\n\n',
                           decision, why)
                    FROM reasoning
                    ORDER BY timestamp DESC;
                "
                
                echo "## Learned Solutions"
                sqlite3 "$TERMBRAIN_DB" "
                    SELECT printf('**Problem:** %s\n**Solution:** %s\n\n',
                           c.command, e.solution_commands)
                    FROM errors e
                    JOIN commands c ON e.command_id = c.id
                    WHERE e.solved = TRUE;
                "
            } > "${output_file}.md"
            echo "📤 Exported to: ${output_file}.md"
            ;;
            
        json)
            sqlite3 "$TERMBRAIN_DB" "
                SELECT json_object(
                    'export_date', datetime('now'),
                    'concepts', (SELECT json_group_array(json_object(
                        'type', concept_type,
                        'title', title,
                        'description', description,
                        'tags', tags
                    )) FROM concepts),
                    'decisions', (SELECT json_group_array(json_object(
                        'what', decision,
                        'why', why
                    )) FROM reasoning),
                    'patterns', (SELECT json_group_array(json_object(
                        'type', pattern_type,
                        'frequency', frequency
                    )) FROM patterns)
                );
            " > "${output_file}.json"
            echo "📤 Exported to: ${output_file}.json"
            ;;
    esac
}

# ============================================
# ENHANCED SHELL INTEGRATION
# ============================================

# Smarter command capture with concept detection
tb::preexec_enhanced() {
    tb::preexec "$1"  # Original capture
    
    # Detect conceptual patterns
    case "$1" in
        *"mkdir"*|*"touch"*|*"scaffold"*|*"create-react-app"*)
            export TB_CONCEPT_HINT="creating"
            ;;
        *"refactor"*|*"rename"*|*"mv"*)
            export TB_CONCEPT_HINT="refactoring"
            ;;
        *"TODO"*|*"FIXME"*|*"XXX"*)
            export TB_CONCEPT_HINT="planning"
            ;;
        *"git checkout -b"*)
            export TB_CONCEPT_HINT="feature_start"
            ;;
    esac
}

# Enhanced post-command with auto-concept capture
tb::precmd_enhanced() {
    tb::precmd  # Original capture
    
    # Auto-capture concepts based on hints
    if [[ -n "$TB_CONCEPT_HINT" ]]; then
        case "$TB_CONCEPT_HINT" in
            creating)
                tb::capture_concept "creation" "New component" "Created via: $TB_LAST_COMMAND"
                ;;
            feature_start)
                local branch=$(git branch --show-current 2>/dev/null)
                tb::capture_concept "feature" "Started: $branch" "New feature branch"
                ;;
        esac
        unset TB_CONCEPT_HINT
    fi
}

# ============================================
# QUICK ALIASES
# ============================================

alias tb-why='tb::why'              # Explain last command
alias tb-arch='tb::arch'            # Capture architecture decision
alias tb-project='tb::project'      # Project management
alias tb-explore='tb::explore'      # Memory explorer
alias tb-insights='tb::learning_insights'  # View insights
alias tb-export='tb::export_memory' # Export memory

# ============================================
# INITIALIZATION
# ============================================

# Initialize enhanced features
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Set up enhanced hooks
    if [[ -n "$BASH_VERSION" ]]; then
        trap 'tb::preexec_enhanced "$BASH_COMMAND"' DEBUG
        PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}tb::precmd_enhanced"
    elif [[ -n "$ZSH_VERSION" ]]; then
        autoload -U add-zsh-hook
        add-zsh-hook preexec tb::preexec_enhanced
        add-zsh-hook precmd tb::precmd_enhanced
    fi
    
    # Initialize enhanced database
    tb::init_enhanced_db
    
    echo "🧠✨ Termbrain Enhanced Mode Active"
    echo "New commands: tb-why, tb-arch, tb-explore"
fi