use serde::Serialize;
use serde_json;
use anyhow::Result;

pub fn format<T: Serialize>(data: &T) -> Result<String> {
    Ok(serde_json::to_string_pretty(data)?)
}