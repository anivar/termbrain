//! Output formatting utilities

use anyhow::Result;
use serde_json::Value;

pub fn format_table(headers: Vec<&str>, rows: Vec<Vec<String>>) -> String {
    let mut output = String::new();
    
    // Calculate column widths
    let mut widths = headers.iter().map(|h| h.len()).collect::<Vec<_>>();
    for row in &rows {
        for (i, cell) in row.iter().enumerate() {
            if i < widths.len() {
                widths[i] = widths[i].max(cell.len());
            }
        }
    }
    
    // Top border
    output.push_str("┌");
    for (i, &width) in widths.iter().enumerate() {
        output.push_str(&"─".repeat(width + 2));
        if i < widths.len() - 1 {
            output.push_str("┬");
        }
    }
    output.push_str("┐\n");
    
    // Header
    output.push('│');
    for (i, (header, &width)) in headers.iter().zip(&widths).enumerate() {
        output.push_str(&format!(" {:<width$} ", header, width = width));
        output.push('│');
    }
    output.push('\n');
    
    // Header separator
    output.push_str("├");
    for (i, &width) in widths.iter().enumerate() {
        output.push_str(&"─".repeat(width + 2));
        if i < widths.len() - 1 {
            output.push_str("┼");
        }
    }
    output.push_str("┤\n");
    
    // Rows
    for row in rows {
        output.push('│');
        for (i, (cell, &width)) in row.iter().zip(&widths).enumerate() {
            output.push_str(&format!(" {:<width$} ", cell, width = width));
            output.push('│');
        }
        output.push('\n');
    }
    
    // Bottom border
    output.push_str("└");
    for (i, &width) in widths.iter().enumerate() {
        output.push_str(&"─".repeat(width + 2));
        if i < widths.len() - 1 {
            output.push_str("┴");
        }
    }
    output.push_str("┘");
    
    output
}

pub fn format_json(data: Value) -> Result<String> {
    Ok(serde_json::to_string_pretty(&data)?)
}

pub fn format_csv(headers: Vec<&str>, rows: Vec<Vec<String>>) -> String {
    let mut output = headers.join(",");
    output.push('\n');
    
    for row in rows {
        output.push_str(&row.join(","));
        output.push('\n');
    }
    
    output
}