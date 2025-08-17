#!/usr/bin/env bash
# Show Growth Analytics Use Case

ShowGrowth::display() {
    clear
    echo "🌱 Your Learning Journey"
    echo "======================="
    echo ""
    
    # Knowledge growth
    ShowGrowth::knowledge_stats
    echo ""
    
    # Productivity trends
    ShowGrowth::productivity_trends
    echo ""
    
    # Success patterns
    ShowGrowth::success_patterns
}

ShowGrowth::knowledge_stats() {
    echo "📚 Knowledge Base"
    sqlite3 "$TERMBRAIN_DB" -column -header "
        SELECT 
            topic as Domain,
            COUNT(*) as Insights,
            printf('%.1f', AVG(confidence)) as 'Avg Confidence'
        FROM knowledge
        GROUP BY topic
        ORDER BY COUNT(*) DESC
        LIMIT 10;
    "
}

ShowGrowth::productivity_trends() {
    echo "📈 Productivity Trends"
    
    # Weekly productivity
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
    
    # Recent average
    local avg_productivity=$(sqlite3 "$TERMBRAIN_DB" "
        SELECT AVG(productivity_score) FROM cognitive_state
        WHERE timestamp > datetime('now', '-7 days');
    " || echo "0")
    
    echo ""
    echo "7-day average productivity: ${avg_productivity:-0}/10"
}

ShowGrowth::success_patterns() {
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
        ORDER BY COUNT(*) DESC
        LIMIT 10;
    "
}

ShowGrowth::learning_velocity() {
    echo "📊 Learning Velocity"
    
    # Knowledge gained over time
    sqlite3 "$TERMBRAIN_DB" "
        SELECT printf('%s: %d new insights',
               date(created_at),
               COUNT(*))
        FROM knowledge
        WHERE created_at > datetime('now', '-7 days')
        GROUP BY date(created_at)
        ORDER BY created_at DESC;
    "
}

# Convenience function
tb::growth() {
    ShowGrowth::display
}