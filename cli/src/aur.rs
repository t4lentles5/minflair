use anyhow::{bail, Context, Result};
use std::env;
use std::fs;
use std::path::PathBuf;

use crate::process;
use crate::repo;

pub const HELPERS: [&str; 2] = ["yay", "paru"];

pub fn valid(name: &str) -> bool {
    HELPERS.contains(&name)
}

pub fn path() -> Result<PathBuf> {
    if let Some(value) = env::var_os("MINFLAIR_AUR_HELPER_FILE").filter(|value| !value.is_empty()) {
        return Ok(PathBuf::from(value));
    }
    Ok(repo::config_dir()?.join("minflair").join("aur-helper"))
}

/// Read the configured helper, matching `lib/aur.sh`.
///
/// `MINFLAIR_AUR_HELPER` wins over the saved file. An invalid value falls back
/// to the default instead of being returned.
pub fn current() -> Result<String> {
    if let Some(value) = env::var_os("MINFLAIR_AUR_HELPER") {
        let value = value.to_string_lossy().trim().to_string();
        return Ok(if valid(&value) {
            value
        } else {
            "yay".to_string()
        });
    }

    let path = path()?;
    if path.is_file() {
        let content = fs::read_to_string(&path)
            .with_context(|| format!("could not read {}", path.display()))?;
        let value = content.lines().next().unwrap_or("").trim();
        if valid(value) {
            return Ok(value.to_string());
        }
    }

    Ok("yay".to_string())
}

#[allow(dead_code)] // Used by the install/update pipelines in later phases.
pub fn set(name: &str) -> Result<()> {
    if !valid(name) {
        bail!("invalid AUR helper {:?}; use yay or paru", name);
    }

    let path = path()?;
    let parent = path
        .parent()
        .with_context(|| format!("invalid AUR helper path: {}", path.display()))?;
    fs::create_dir_all(parent).with_context(|| format!("could not create {}", parent.display()))?;

    let file_name = path
        .file_name()
        .map(|value| value.to_string_lossy().to_string())
        .unwrap_or_else(|| "aur-helper".to_string());
    let temporary = path.with_file_name(format!(".{file_name}.{}.tmp", std::process::id()));
    fs::write(&temporary, format!("{}\n", name))
        .with_context(|| format!("could not write {}", temporary.display()))?;
    fs::rename(&temporary, &path)
        .with_context(|| format!("could not replace {}", path.display()))?;
    Ok(())
}

pub fn installed(name: &str) -> bool {
    process::which(name).is_some()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn only_accepts_supported_helpers() {
        assert!(valid("yay"));
        assert!(valid("paru"));
        assert!(!valid("pikaur"));
        assert!(!valid(""));
    }
}
