//! Advanced pattern detection for command sequences

use chrono::{DateTime, Utc, Timelike};
use std::collections::HashMap;
use termbrain_core::domain::entities::Command;

/// Pattern confidence threshold
const MIN_CONFIDENCE: f32 = 0.3;

/// Pattern types with confidence scoring
#[derive(Debug, Clone, serde::Serialize)]
pub struct DetectedPattern {
    pub pattern_type: PatternType,
    pub description: String,
    pub confidence: f32,
    pub frequency: usize,
    pub commands: Vec<String>,
    pub metadata: PatternMetadata,
}

#[derive(Debug, Clone, serde::Serialize)]
pub enum PatternType {
    CommandSequence { length: usize },
    TimeBasedRoutine { hour: u32, variance_minutes: u32 },
    DirectorySpecific { directory: String },
    ErrorRecovery { error_command: String, fix_command: String },
    BuildTest { build_tool: String },
    VersionControl { vcs: String },
    FileManipulation,
    SystemMaintenance,
    DataProcessing,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct PatternMetadata {
    pub first_seen: DateTime<Utc>,
    pub last_seen: DateTime<Utc>,
    pub directories: Vec<String>,
    pub success_rate: f32,
    pub avg_duration_ms: u64,
}

/// Advanced pattern detector
pub struct PatternDetector {
    commands: Vec<Command>,
}

impl PatternDetector {
    pub fn new(commands: Vec<Command>) -> Self {
        Self { commands }
    }

    /// Detect all patterns with confidence scoring
    pub fn detect_patterns(&self) -> Vec<DetectedPattern> {
        let mut patterns = Vec::new();

        // Variable-length command sequences (4-10 commands)
        patterns.extend(self.detect_command_sequences());

        // Time-based patterns
        patterns.extend(self.detect_time_based_patterns());

        // Directory-specific patterns
        patterns.extend(self.detect_directory_patterns());

        // Error recovery patterns
        patterns.extend(self.detect_error_recovery_patterns());

        // Domain-specific patterns
        patterns.extend(self.detect_build_test_patterns());
        patterns.extend(self.detect_version_control_patterns());
        patterns.extend(self.detect_file_manipulation_patterns());
        patterns.extend(self.detect_system_maintenance_patterns());

        // Sort by confidence
        patterns.sort_by(|a, b| b.confidence.partial_cmp(&a.confidence).unwrap_or(std::cmp::Ordering::Equal));

        patterns
    }

    /// Detect variable-length command sequences
    fn detect_command_sequences(&self) -> Vec<DetectedPattern> {
        let mut patterns = Vec::new();
        
        // Try different sequence lengths
        for length in 4..=10 {
            if self.commands.len() < length {
                continue;
            }

            let mut sequence_counts: HashMap<Vec<String>, Vec<usize>> = HashMap::new();

            // Sliding window to find repeated sequences
            for (idx, window) in self.commands.windows(length).enumerate() {
                let sequence: Vec<String> = window.iter()
                    .map(|cmd| normalize_command(&cmd.parsed_command))
                    .collect();
                
                sequence_counts.entry(sequence.clone())
                    .or_insert_with(Vec::new)
                    .push(idx);
            }

            // Find sequences that appear multiple times
            for (_sequence, indices) in sequence_counts {
                if indices.len() >= 2 {
                    let commands: Vec<String> = indices.first()
                        .map(|&idx| {
                            self.commands[idx..idx+length].iter()
                                .map(|cmd| cmd.raw.clone())
                                .collect()
                        })
                        .unwrap_or_default();

                    let metadata = self.calculate_pattern_metadata(&indices, length);
                    let confidence = self.calculate_sequence_confidence(&indices, length);

                    if confidence >= MIN_CONFIDENCE {
                        patterns.push(DetectedPattern {
                            pattern_type: PatternType::CommandSequence { length },
                            description: format!("{}-command workflow pattern", length),
                            confidence,
                            frequency: indices.len(),
                            commands,
                            metadata,
                        });
                    }
                }
            }
        }

        patterns
    }

    /// Detect time-based routine patterns
    fn detect_time_based_patterns(&self) -> Vec<DetectedPattern> {
        let mut patterns = Vec::new();
        let mut hourly_commands: HashMap<u32, Vec<&Command>> = HashMap::new();

        // Group commands by hour
        for cmd in &self.commands {
            let hour = cmd.timestamp.hour();
            hourly_commands.entry(hour).or_insert_with(Vec::new).push(cmd);
        }

        // Find patterns in hourly routines
        for (hour, cmds) in hourly_commands {
            if cmds.len() >= 3 {
                // Check for similar commands at similar times
                let mut command_types: HashMap<String, usize> = HashMap::new();
                for cmd in &cmds {
                    *command_types.entry(normalize_command(&cmd.parsed_command)).or_insert(0) += 1;
                }

                // Find dominant commands for this hour
                for (cmd_type, count) in command_types {
                    if count >= 3 {
                        let variance = self.calculate_time_variance(&cmds);
                        let confidence = (count as f32 / cmds.len() as f32) * 0.8;

                        if confidence >= MIN_CONFIDENCE {
                            patterns.push(DetectedPattern {
                                pattern_type: PatternType::TimeBasedRoutine { 
                                    hour, 
                                    variance_minutes: variance as u32 
                                },
                                description: format!("Daily routine around {}:00", hour),
                                confidence,
                                frequency: count,
                                commands: cmds.iter()
                                    .filter(|c| normalize_command(&c.parsed_command) == cmd_type)
                                    .map(|c| c.raw.clone())
                                    .collect(),
                                metadata: self.calculate_metadata_from_commands(cmds.clone()),
                            });
                        }
                    }
                }
            }
        }

        patterns
    }

    /// Detect directory-specific patterns
    fn detect_directory_patterns(&self) -> Vec<DetectedPattern> {
        let mut patterns = Vec::new();
        let mut dir_commands: HashMap<String, Vec<&Command>> = HashMap::new();

        // Group by directory
        for cmd in &self.commands {
            dir_commands.entry(cmd.working_directory.clone())
                .or_insert_with(Vec::new)
                .push(cmd);
        }

        // Find patterns within directories
        for (directory, cmds) in dir_commands {
            if cmds.len() >= 5 {
                // Analyze command patterns in this directory
                let mut cmd_sequences: HashMap<Vec<String>, usize> = HashMap::new();
                
                for window in cmds.windows(3) {
                    let seq: Vec<String> = window.iter()
                        .map(|c| normalize_command(&c.parsed_command))
                        .collect();
                    *cmd_sequences.entry(seq).or_insert(0) += 1;
                }

                // Find repeated sequences
                for (sequence, count) in cmd_sequences {
                    if count >= 2 {
                        let confidence = (count as f32 / cmds.len() as f32) * 1.2;
                        
                        if confidence >= MIN_CONFIDENCE {
                            patterns.push(DetectedPattern {
                                pattern_type: PatternType::DirectorySpecific { 
                                    directory: directory.clone() 
                                },
                                description: format!("Common workflow in {}", shorten_path(&directory)),
                                confidence: confidence.min(1.0),
                                frequency: count,
                                commands: sequence.clone(),
                                metadata: self.calculate_metadata_from_commands(cmds.clone()),
                            });
                        }
                    }
                }
            }
        }

        patterns
    }

    /// Detect error recovery patterns
    fn detect_error_recovery_patterns(&self) -> Vec<DetectedPattern> {
        let mut patterns = Vec::new();
        
        // Look for failed commands followed by successful ones
        for i in 1..self.commands.len() {
            let prev = &self.commands[i-1];
            let curr = &self.commands[i];
            
            // Failed command followed by success
            if prev.exit_code != 0 && curr.exit_code == 0 {
                // Check if the commands are related
                if are_related_commands(&prev.parsed_command, &curr.parsed_command) {
                    // Look for more instances of this pattern
                    let mut instances = vec![(i-1, i)];
                    
                    for j in i+1..self.commands.len() {
                        if j > 0 {
                            let p = &self.commands[j-1];
                            let c = &self.commands[j];
                            
                            if p.exit_code != 0 && c.exit_code == 0 &&
                               normalize_command(&p.parsed_command) == normalize_command(&prev.parsed_command) &&
                               normalize_command(&c.parsed_command) == normalize_command(&curr.parsed_command) {
                                instances.push((j-1, j));
                            }
                        }
                    }
                    
                    if instances.len() >= 2 {
                        let confidence = (instances.len() as f32 / self.commands.len() as f32) * 5.0;
                        
                        if confidence >= MIN_CONFIDENCE {
                            patterns.push(DetectedPattern {
                                pattern_type: PatternType::ErrorRecovery {
                                    error_command: prev.raw.clone(),
                                    fix_command: curr.raw.clone(),
                                },
                                description: "Error recovery pattern detected".to_string(),
                                confidence: confidence.min(1.0),
                                frequency: instances.len(),
                                commands: vec![prev.raw.clone(), curr.raw.clone()],
                                metadata: self.calculate_recovery_metadata(&instances),
                            });
                        }
                    }
                }
            }
        }
        
        patterns
    }

    /// Detect build and test patterns
    fn detect_build_test_patterns(&self) -> Vec<DetectedPattern> {
        let mut patterns = Vec::new();
        let build_tools = ["cargo", "npm", "make", "mvn", "gradle", "yarn", "pip", "go"];
        
        for tool in &build_tools {
            let tool_commands: Vec<&Command> = self.commands.iter()
                .filter(|c| c.parsed_command == *tool)
                .collect();
                
            if tool_commands.len() >= 3 {
                // Analyze subcommands
                let mut subcommand_patterns: HashMap<String, usize> = HashMap::new();
                
                for cmd in &tool_commands {
                    if let Some(subcommand) = cmd.arguments.first() {
                        *subcommand_patterns.entry(subcommand.clone()).or_insert(0) += 1;
                    }
                }
                
                // Look for test-build patterns
                let has_test = subcommand_patterns.contains_key("test");
                let has_build = subcommand_patterns.contains_key("build") || 
                               subcommand_patterns.contains_key("compile");
                
                if has_test && has_build {
                    let confidence = (tool_commands.len() as f32 / self.commands.len() as f32) * 3.0;
                    
                    if confidence >= MIN_CONFIDENCE {
                        patterns.push(DetectedPattern {
                            pattern_type: PatternType::BuildTest { 
                                build_tool: tool.to_string() 
                            },
                            description: format!("Build-test workflow using {}", tool),
                            confidence: confidence.min(1.0),
                            frequency: tool_commands.len(),
                            commands: tool_commands.iter()
                                .map(|c| c.raw.clone())
                                .take(10)
                                .collect(),
                            metadata: self.calculate_metadata_from_commands(
                                tool_commands.clone()
                            ),
                        });
                    }
                }
            }
        }
        
        patterns
    }

    /// Detect version control patterns
    fn detect_version_control_patterns(&self) -> Vec<DetectedPattern> {
        let mut patterns = Vec::new();
        let vcs_tools = ["git", "svn", "hg", "fossil"];
        
        for vcs in &vcs_tools {
            let vcs_commands: Vec<&Command> = self.commands.iter()
                .filter(|c| c.parsed_command == *vcs)
                .collect();
                
            if vcs_commands.len() >= 5 {
                // Common VCS workflow patterns
                let mut workflow_score = 0.0;
                let mut _has_status = false;
                let mut has_add = false;
                let mut has_commit = false;
                let mut _has_push = false;
                
                for cmd in &vcs_commands {
                    if let Some(subcommand) = cmd.arguments.first() {
                        match subcommand.as_str() {
                            "status" => { _has_status = true; workflow_score += 0.2; }
                            "add" => { has_add = true; workflow_score += 0.3; }
                            "commit" => { has_commit = true; workflow_score += 0.3; }
                            "push" => { _has_push = true; workflow_score += 0.2; }
                            _ => {}
                        }
                    }
                }
                
                if has_add && has_commit {
                    let confidence = workflow_score * (vcs_commands.len() as f32 / 10.0);
                    
                    if confidence >= MIN_CONFIDENCE {
                        patterns.push(DetectedPattern {
                            pattern_type: PatternType::VersionControl { 
                                vcs: vcs.to_string() 
                            },
                            description: format!("{} workflow pattern", vcs),
                            confidence: confidence.min(1.0),
                            frequency: vcs_commands.len(),
                            commands: vcs_commands.iter()
                                .map(|c| c.raw.clone())
                                .take(10)
                                .collect(),
                            metadata: self.calculate_metadata_from_commands(
                                vcs_commands.clone()
                            ),
                        });
                    }
                }
            }
        }
        
        patterns
    }

    /// Detect file manipulation patterns
    fn detect_file_manipulation_patterns(&self) -> Vec<DetectedPattern> {
        let file_commands = ["cp", "mv", "rm", "mkdir", "touch", "chmod", "chown", "ln"];
        let file_cmds: Vec<&Command> = self.commands.iter()
            .filter(|c| file_commands.contains(&c.parsed_command.as_str()))
            .collect();
            
        if file_cmds.len() >= 5 {
            let confidence = (file_cmds.len() as f32 / self.commands.len() as f32) * 2.0;
            
            if confidence >= MIN_CONFIDENCE {
                vec![DetectedPattern {
                    pattern_type: PatternType::FileManipulation,
                    description: "File and directory management pattern".to_string(),
                    confidence: confidence.min(1.0),
                    frequency: file_cmds.len(),
                    commands: file_cmds.iter()
                        .map(|c| c.raw.clone())
                        .take(10)
                        .collect(),
                    metadata: self.calculate_metadata_from_commands(
                        file_cmds.clone()
                    ),
                }]
            } else {
                vec![]
            }
        } else {
            vec![]
        }
    }

    /// Detect system maintenance patterns
    fn detect_system_maintenance_patterns(&self) -> Vec<DetectedPattern> {
        let maintenance_commands = ["apt", "yum", "brew", "systemctl", "service", "df", "du", "ps", "top"];
        let maint_cmds: Vec<&Command> = self.commands.iter()
            .filter(|c| maintenance_commands.contains(&c.parsed_command.as_str()))
            .collect();
            
        if maint_cmds.len() >= 3 {
            let confidence = (maint_cmds.len() as f32 / self.commands.len() as f32) * 3.0;
            
            if confidence >= MIN_CONFIDENCE {
                vec![DetectedPattern {
                    pattern_type: PatternType::SystemMaintenance,
                    description: "System maintenance and monitoring".to_string(),
                    confidence: confidence.min(1.0),
                    frequency: maint_cmds.len(),
                    commands: maint_cmds.iter()
                        .map(|c| c.raw.clone())
                        .take(10)
                        .collect(),
                    metadata: self.calculate_metadata_from_commands(
                        maint_cmds.clone()
                    ),
                }]
            } else {
                vec![]
            }
        } else {
            vec![]
        }
    }

    /// Calculate confidence for command sequences
    fn calculate_sequence_confidence(&self, indices: &[usize], length: usize) -> f32 {
        let frequency = indices.len() as f32;
        let total_windows = (self.commands.len() - length + 1) as f32;
        let base_confidence = frequency / total_windows;
        
        // Boost confidence for longer sequences
        let length_boost = (length as f32 - 3.0) * 0.1;
        
        // Boost confidence for regular intervals
        let interval_boost = if indices.len() > 1 {
            let intervals: Vec<usize> = indices.windows(2)
                .map(|w| w[1] - w[0])
                .collect();
            let avg_interval = intervals.iter().sum::<usize>() as f32 / intervals.len() as f32;
            let variance = intervals.iter()
                .map(|&i| (i as f32 - avg_interval).powi(2))
                .sum::<f32>() / intervals.len() as f32;
            
            if variance < avg_interval * 0.3 {
                0.2 // Regular pattern bonus
            } else {
                0.0
            }
        } else {
            0.0
        };
        
        (base_confidence + length_boost + interval_boost).min(1.0)
    }

    /// Calculate time variance for commands
    fn calculate_time_variance(&self, commands: &[&Command]) -> f64 {
        if commands.len() < 2 {
            return 0.0;
        }
        
        let minutes: Vec<u32> = commands.iter()
            .map(|c| c.timestamp.minute())
            .collect();
            
        let avg = minutes.iter().sum::<u32>() as f64 / minutes.len() as f64;
        let variance = minutes.iter()
            .map(|&m| (m as f64 - avg).powi(2))
            .sum::<f64>() / minutes.len() as f64;
            
        variance.sqrt()
    }

    /// Calculate metadata for a pattern
    fn calculate_pattern_metadata(&self, indices: &[usize], length: usize) -> PatternMetadata {
        let mut all_commands = Vec::new();
        for &idx in indices {
            all_commands.extend(&self.commands[idx..idx+length]);
        }
        
        self.calculate_metadata_from_commands(all_commands)
    }

    /// Calculate metadata from commands
    fn calculate_metadata_from_commands(&self, commands: Vec<&Command>) -> PatternMetadata {
        let first_seen = commands.iter()
            .map(|c| c.timestamp)
            .min()
            .unwrap_or_else(Utc::now);
            
        let last_seen = commands.iter()
            .map(|c| c.timestamp)
            .max()
            .unwrap_or_else(Utc::now);
            
        let directories: Vec<String> = commands.iter()
            .map(|c| c.working_directory.clone())
            .collect::<std::collections::HashSet<_>>()
            .into_iter()
            .collect();
            
        let successful = commands.iter()
            .filter(|c| c.exit_code == 0)
            .count() as f32;
        let success_rate = successful / commands.len() as f32;
        
        let avg_duration_ms = if !commands.is_empty() {
            commands.iter()
                .map(|c| c.duration_ms)
                .sum::<u64>() / commands.len() as u64
        } else {
            0
        };
        
        PatternMetadata {
            first_seen,
            last_seen,
            directories,
            success_rate,
            avg_duration_ms,
        }
    }

    /// Calculate metadata for error recovery patterns
    fn calculate_recovery_metadata(&self, instances: &[(usize, usize)]) -> PatternMetadata {
        let mut all_commands = Vec::new();
        for &(err_idx, fix_idx) in instances {
            all_commands.push(&self.commands[err_idx]);
            all_commands.push(&self.commands[fix_idx]);
        }
        
        self.calculate_metadata_from_commands(all_commands)
    }
}

/// Normalize command for comparison
fn normalize_command(cmd: &str) -> String {
    cmd.to_lowercase()
}

/// Check if two commands are related
fn are_related_commands(cmd1: &str, cmd2: &str) -> bool {
    // Same base command
    if cmd1 == cmd2 {
        return true;
    }
    
    // Common error-fix patterns
    let error_fix_patterns = [
        ("npm", "npm install"),
        ("cargo", "cargo build"),
        ("git", "git checkout"),
        ("docker", "docker start"),
        ("systemctl", "systemctl start"),
    ];
    
    for (error, fix) in &error_fix_patterns {
        if cmd1.contains(error) && cmd2.contains(fix) {
            return true;
        }
    }
    
    false
}

/// Shorten long paths for display
fn shorten_path(path: &str) -> String {
    let parts: Vec<&str> = path.split('/').collect();
    if parts.len() > 3 {
        format!(".../{}", parts[parts.len()-1])
    } else {
        path.to_string()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use uuid::Uuid;
    
    fn create_test_command(cmd: &str, exit_code: i32, timestamp: DateTime<Utc>) -> Command {
        let parts: Vec<&str> = cmd.split_whitespace().collect();
        Command {
            id: Uuid::new_v4(),
            raw: cmd.to_string(),
            parsed_command: parts.first().unwrap_or(&"").to_string(),
            arguments: parts.into_iter().skip(1).map(|s| s.to_string()).collect(),
            working_directory: "/test".to_string(),
            exit_code,
            duration_ms: 100,
            timestamp,
            session_id: "test".to_string(),
            metadata: Default::default(),
        }
    }
    
    #[test]
    fn test_sequence_detection() {
        let now = Utc::now();
        let commands = vec![
            create_test_command("git status", 0, now),
            create_test_command("git add .", 0, now),
            create_test_command("git commit -m test", 0, now),
            create_test_command("git push", 0, now),
            create_test_command("git status", 0, now),
            create_test_command("git add .", 0, now),
            create_test_command("git commit -m test", 0, now),
            create_test_command("git push", 0, now),
        ];
        
        let detector = PatternDetector::new(commands);
        let patterns = detector.detect_patterns();
        
        assert!(!patterns.is_empty());
        assert!(patterns.iter().any(|p| matches!(p.pattern_type, PatternType::CommandSequence { .. })));
    }
}