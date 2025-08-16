#!/usr/bin/env bash
# 🧠 Termbrain Cognitive Layer - Deep Understanding for Your Terminal

# ============================================
# COGNITIVE MEMORY ARCHITECTURE
# ============================================

# Initialize cognitive database schema
tb::init_cognitive() {
    sqlite3 "$TERMBRAIN_DB" <<'EOF'
-- Intentions: What were you trying to achieve?
CREATE TABLE IF NOT EXISTS intentions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    goal TEXT NOT NULL,
    context TEXT,
    success BOOLEAN,
    learnings TEXT,
    time_spent INTEGER, -- seconds
    complexity INTEGER DEFAULT 5 -- 1-10
);

-- Knowledge: What you've learned
CREATE TABLE IF NOT EXISTS knowledge (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    topic TEXT NOT NULL,
    insight TEXT NOT NULL,
    confidence INTEGER DEFAULT 5, -- 1-10
    source TEXT, -- 'experience', 'documentation', 'error', 'success'
    verified BOOLEAN DEFAULT FALSE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_used DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Connections: How things relate
CREATE TABLE IF NOT EXISTS connections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    from_type TEXT NOT NULL, -- 'command', 'error', 'pattern', 'knowledge'
    from_id INTEGER NOT NULL,
    to_type TEXT NOT NULL,
    to_id INTEGER NOT NULL,
    relationship TEXT NOT NULL, -- 'causes', 'fixes', 'requires', 'blocks', 'enhances'
    strength INTEGER DEFAULT 5 -- 1-10
);

-- Mental Models: Your understanding patterns
CREATE TABLE IF NOT EXISTS mental_models (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    description TEXT,
    pattern TEXT, -- JSON of command sequences
    context_triggers TEXT, -- When to apply this model
    effectiveness REAL DEFAULT 0.5, -- 0-1 success rate
    usage_count INTEGER DEFAULT 0
);

-- Cognitive State: Track your focus and flow
CREATE TABLE IF NOT EXISTS cognitive_state (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    focus_area TEXT,
    productivity_score INTEGER, -- 1-10
    interruption_count INTEGER DEFAULT 0,
    flow_duration INTEGER, -- seconds in flow state
    energy_level INTEGER DEFAULT 5 -- 1-10
);

CREATE INDEX idx_intentions_goal ON intentions(goal);
CREATE INDEX idx_knowledge_topic ON knowledge(topic);
CREATE INDEX idx_connections_from ON connections(from_type, from_id);
CREATE INDEX idx_mental_models_name ON mental_models(name);
EOF
}

# ============================================
# INTENTION TRACKING
# ============================================

# Start tracking an intention
tb::intend() {
    local goal="$1"
    
    if [[ -z "$goal" ]]; then
        echo "🎯 What are you trying to accomplish?"
        read -r goal
    fi
    
    # Store intention
    local intention_id=$(sqlite3 "$TERMBRAIN_DB" "
        INSERT INTO intentions (goal, context)
        VALUES (
            '$(tb::escape_sql "$goal")',
            '$(tb::get_context_summary)'
        );
        SELECT last_insert_rowid();
    ")
    
    export TB_ACTIVE_INTENTION_ID=$intention_id
    export TB_INTENTION_START=$(date +%s)
    
    echo "🎯 Intention set: $goal"
    echo "💡 I'll track your progress and learn from your approach"
}

# Mark intention complete
tb::achieved() {
    if [[ -z "$TB_ACTIVE_INTENTION_ID" ]]; then
        echo "❓ No active intention. What did you accomplish?"
        read -r goal
        tb::intend "$goal"
    fi
    
    local duration=$(($(date +%s) - TB_INTENTION_START))
    
    echo "✅ Great! What did you learn?"
    read -r learnings
    
    sqlite3 "$TERMBRAIN_DB" "
        UPDATE intentions
        SET success = 1,
            learnings = '$(tb::escape_sql "$learnings")',
            time_spent = $duration
        WHERE id = $TB_ACTIVE_INTENTION_ID;
    "
    
    # Extract knowledge from the experience
    tb::extract_knowledge "$learnings"
    
    unset TB_ACTIVE_INTENTION_ID TB_INTENTION_START
    echo "🎉 Achievement recorded and knowledge extracted!"
}

# ============================================
# KNOWLEDGE EXTRACTION
# ============================================

# Extract knowledge from experiences
tb::extract_knowledge() {
    local insight="$1"
    local source="${2:-experience}"
    
    # Analyze recent commands to understand topic
    local topic=$(sqlite3 "$TERMBRAIN_DB" "
        SELECT semantic_type 
        FROM commands 
        WHERE session_id = '$TERMBRAIN_SESSION_ID'
        ORDER BY timestamp DESC 
        LIMIT 1;
    ")
    
    # Store knowledge
    sqlite3 "$TERMBRAIN_DB" "
        INSERT INTO knowledge (topic, insight, source)
        VALUES ('$topic', '$(tb::escape_sql "$insight")', '$source');
    "
    
    # Create connections
    tb::link_knowledge_to_commands
}

# Learn from errors automatically
tb::learn_from_error() {
    local error_id="$1"
    local solution="$2"
    
    # Extract insight
    local insight="Error fixed by: $solution"
    tb::extract_knowledge "$insight" "error"
    
    # Increase confidence if similar errors were solved before
    sqlite3 "$TERMBRAIN_DB" "
        UPDATE knowledge
        SET confidence = MIN(10, confidence + 1),
            verified = 1
        WHERE insight LIKE '%$solution%';
    "
}

# ============================================
# MENTAL MODEL DETECTION
# ============================================

# Detect and create mental models
tb::detect_mental_models() {
    echo "🧩 Analyzing your patterns to build mental models..."
    
    # Find recurring command sequences
    local patterns=$(sqlite3 "$TERMBRAIN_DB" "
        WITH Sequences AS (
            SELECT 
                c1.semantic_type as step1,
                c2.semantic_type as step2,
                c3.semantic_type as step3,
                COUNT(*) as frequency
            FROM commands c1
            JOIN commands c2 ON c2.id = c1.id + 1
            JOIN commands c3 ON c3.id = c2.id + 1
            WHERE c1.session_id = c2.session_id 
            AND c2.session_id = c3.session_id
            GROUP BY step1, step2, step3
            HAVING frequency > 2
        )
        SELECT json_object(
            'pattern', json_array(step1, step2, step3),
            'frequency', frequency
        ) FROM Sequences;
    ")
    
    # Create mental models from patterns
    echo "$patterns" | while read -r pattern; do
        tb::create_mental_model "$pattern"
    done
}

# Create a mental model
tb::create_mental_model() {
    local pattern_json="$1"
    local pattern_name=$(echo "$pattern_json" | jq -r '.pattern | join("-")')
    
    echo "🧩 Discovered pattern: $pattern_name"
    echo "Would you like to name this workflow? (Enter for skip)"
    read -r custom_name
    
    if [[ -n "$custom_name" ]]; then
        sqlite3 "$TERMBRAIN_DB" "
            INSERT OR REPLACE INTO mental_models (name, pattern)
            VALUES ('$custom_name', '$pattern_json');
        "
        echo "✅ Mental model '$custom_name' created!"
    fi
}

# ============================================
# COGNITIVE STATE TRACKING
# ============================================

# Track productivity and flow
tb::flow() {
    local action="${1:-status}"
    
    case "$action" in
        start)
            export TB_FLOW_START=$(date +%s)
            export TB_FLOW_INTERRUPTIONS=0
            echo "🌊 Flow state tracking started"
            ;;
            
        end)
            if [[ -n "$TB_FLOW_START" ]]; then
                local duration=$(($(date +%s) - TB_FLOW_START))
                
                echo "Rate your productivity (1-10):"
                read -r productivity
                
                sqlite3 "$TERMBRAIN_DB" "
                    INSERT INTO cognitive_state 
                    (focus_area, productivity_score, interruption_count, flow_duration)
                    VALUES (
                        '$(tb::detect_focus_area)',
                        $productivity,
                        $TB_FLOW_INTERRUPTIONS,
                        $duration
                    );
                "
                
                echo "🌊 Flow session recorded: $(($duration / 60)) minutes"
                unset TB_FLOW_START TB_FLOW_INTERRUPTIONS
            fi
            ;;
            
        status)
            if [[ -n "$TB_FLOW_START" ]]; then
                local elapsed=$(( ($(date +%s) - TB_FLOW_START) / 60 ))
                echo "🌊 In flow for $elapsed minutes"
                echo "🎯 Focus: $(tb::detect_focus_area)"
                echo "🚫 Interruptions: ${TB_FLOW_INTERRUPTIONS:-0}"
            else
                echo "💤 Not in flow state. Use 'tb-flow start' to begin"
            fi
            ;;
    esac
}

# Detect current focus area
tb::detect_focus_area() {
    sqlite3 "$TERMBRAIN_DB" "
        SELECT semantic_type
        FROM commands
        WHERE session_id = '$TERMBRAIN_SESSION_ID'
        GROUP BY semantic_type
        ORDER BY COUNT(*) DESC
        LIMIT 1;
    " || echo "general"
}

# ============================================
# INTELLIGENT CONTEXT GENERATION
# ============================================

# Generate context with cognitive understanding
tb::context_cognitive() {
    local query="${1:-general}"
    local output="$TERMBRAIN_HOME/cognitive-context.md"
    
    {
        echo "# Termbrain Cognitive Context"
        echo "Generated: $(date)"
        echo ""
        
        # Current cognitive state
        echo "## Your Current State"
        local current_focus=$(tb::detect_focus_area)
        echo "- Focus Area: $current_focus"
        
        if [[ -n "$TB_ACTIVE_INTENTION_ID" ]]; then
            local intention=$(sqlite3 "$TERMBRAIN_DB" "
                SELECT goal FROM intentions WHERE id = $TB_ACTIVE_INTENTION_ID;
            ")
            echo "- Active Goal: $intention"
        fi
        echo ""
        
        # Relevant knowledge
        echo "## What You Know About: $query"
        sqlite3 "$TERMBRAIN_DB" "
            SELECT printf('- %s (confidence: %d/10, source: %s)',
                   insight, confidence, source)
            FROM knowledge
            WHERE topic LIKE '%$query%' OR insight LIKE '%$query%'
            ORDER BY confidence DESC, last_used DESC
            LIMIT 10;
        "
        echo ""
        
        # Applicable mental models
        echo "## Your Workflows"
        sqlite3 "$TERMBRAIN_DB" "
            SELECT printf('**%s** (%.0f%% effective, used %d times)\n%s\n',
                   name, effectiveness * 100, usage_count, description)
            FROM mental_models
            WHERE name LIKE '%$query%' OR description LIKE '%$query%'
            ORDER BY effectiveness DESC;
        "
        echo ""
        
        # Historical intentions and learnings
        echo "## Past Experiences"
        sqlite3 "$TERMBRAIN_DB" "
            SELECT printf('Goal: %s\nLearned: %s\nTime: %d minutes\n',
                   goal, learnings, time_spent / 60)
            FROM intentions
            WHERE goal LIKE '%$query%' AND success = 1
            ORDER BY timestamp DESC
            LIMIT 5;
        "
        echo ""
        
        # Connections graph
        echo "## How Things Connect"
        tb::show_connections "$query"
        
    } > "$output"
    
    # Copy to AI providers
    cp "$output" .termbrain-context.md
    echo "🧠 Cognitive context generated!"
}

# ============================================
# LEARNING DASHBOARD
# ============================================

# Show learning progress
tb::growth() {
    clear
    echo "🌱 Your Learning Journey"
    echo "======================="
    echo ""
    
    # Knowledge growth
    echo "📚 Knowledge Base"
    sqlite3 "$TERMBRAIN_DB" -column -header "
        SELECT 
            topic as Domain,
            COUNT(*) as Insights,
            AVG(confidence) as 'Avg Confidence'
        FROM knowledge
        GROUP BY topic
        ORDER BY COUNT(*) DESC;
    "
    echo ""
    
    # Productivity trends
    echo "📈 Productivity Trends"
    sqlite3 "$TERMBRAIN_DB" "
        SELECT printf('Week of %s: Avg score %.1f, Total flow time: %d hours',
               date(timestamp, 'weekday 0', '-6 days'),
               AVG(productivity_score),
               SUM(flow_duration) / 3600)
        FROM cognitive_state
        GROUP BY date(timestamp, 'weekday 0', '-6 days')
        ORDER BY timestamp DESC
        LIMIT 4;
    "
    echo ""
    
    # Success patterns
    echo "✅ Success Patterns"
    sqlite3 "$TERMBRAIN_DB" "
        SELECT printf('- %s: %d successes, avg time %d min',
               substr(goal, 1, 40),
               COUNT(*),
               AVG(time_spent) / 60)
        FROM intentions
        WHERE success = 1
        GROUP BY substr(goal, 1, 20)
        HAVING COUNT(*) > 1
        ORDER BY COUNT(*) DESC;
    "
}

# ============================================
# RECOMMENDATION ENGINE
# ============================================

# Suggest based on cognitive state
tb::suggest_cognitive() {
    echo "💡 Personalized Suggestions"
    echo "========================="
    
    # Based on current focus
    local focus=$(tb::detect_focus_area)
    echo "📍 You're focusing on: $focus"
    
    # Suggest relevant knowledge
    echo -e "\n📚 Relevant knowledge:"
    sqlite3 "$TERMBRAIN_DB" "
        SELECT printf('- %s', insight)
        FROM knowledge
        WHERE topic = '$focus'
        AND confidence >= 7
        ORDER BY last_used DESC
        LIMIT 3;
    "
    
    # Suggest mental models
    echo -e "\n🧩 Try these workflows:"
    sqlite3 "$TERMBRAIN_DB" "
        SELECT printf('- %s (%.0f%% success rate)', name, effectiveness * 100)
        FROM mental_models
        WHERE pattern LIKE '%$focus%'
        ORDER BY effectiveness DESC
        LIMIT 3;
    "
    
    # Productivity insights
    local avg_productivity=$(sqlite3 "$TERMBRAIN_DB" "
        SELECT AVG(productivity_score) FROM cognitive_state
        WHERE timestamp > datetime('now', '-7 days');
    ")
    
    echo -e "\n📊 Your productivity:"
    echo "- 7-day average: ${avg_productivity:-0}/10"
    
    if [[ "${avg_productivity:-0}" -lt "6" ]]; then
        echo "- 💡 Consider taking breaks or switching tasks"
    else
        echo "- 🚀 You're in a productive streak!"
    fi
}

# ============================================
# QUICK ACCESS COMMANDS
# ============================================

# Cognitive command aliases
alias tb-intend='tb::intend'          # Set intention
alias tb-achieved='tb::achieved'       # Mark success
alias tb-learn='tb::detect_mental_models'  # Find patterns
alias tb-flow='tb::flow'              # Flow state
alias tb-growth='tb::growth'           # Learning dashboard
alias tb-suggest='tb::suggest_cognitive'   # Get suggestions
alias tb-context='tb::context_cognitive'   # Cognitive context

# ============================================
# AUTO-LEARNING HOOKS
# ============================================

# Enhanced preexec with cognitive awareness
tb::preexec_cognitive() {
    tb::preexec "$1"  # Original capture
    
    # Track interruptions during flow
    if [[ -n "$TB_FLOW_START" ]]; then
        # Detect context switches
        local last_type=$(sqlite3 "$TERMBRAIN_DB" "
            SELECT semantic_type FROM commands 
            ORDER BY timestamp DESC LIMIT 1;
        ")
        local current_type=$(tb::analyze_semantic "$1")
        
        if [[ "$last_type" != "$current_type" ]]; then
            ((TB_FLOW_INTERRUPTIONS++))
        fi
    fi
}

# Enhanced precmd with auto-learning
tb::precmd_cognitive() {
    tb::precmd  # Original capture
    
    # Auto-detect successful patterns
    if [[ $? -eq 0 ]] && [[ -n "$TB_ACTIVE_INTENTION_ID" ]]; then
        # Track progress toward intention
        tb::update_intention_progress
    fi
}

# ============================================
# INITIALIZATION
# ============================================

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Initialize cognitive features
    tb::init_cognitive
    
    # Set up cognitive hooks
    if [[ -n "$BASH_VERSION" ]]; then
        trap 'tb::preexec_cognitive "$BASH_COMMAND"' DEBUG
        PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}tb::precmd_cognitive"
    elif [[ -n "$ZSH_VERSION" ]]; then
        autoload -U add-zsh-hook
        add-zsh-hook preexec tb::preexec_cognitive
        add-zsh-hook precmd tb::precmd_cognitive
    fi
    
    echo "🧠✨ Termbrain Cognitive Layer Active"
    echo "New commands: tb intend, tb achieved, tb flow, tb growth"
fi