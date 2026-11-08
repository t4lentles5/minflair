use anyhow::{bail, Context, Result};
use std::collections::BTreeSet;
use std::env;
use std::fs;
use std::path::{Path, PathBuf};

use crate::manifest::Manifest;
use crate::repo;

pub const PREFS_ENV: &str = "MINFLAIR_PREFS";

pub fn default_path() -> Result<PathBuf> {
    if let Some(value) = env::var_os(PREFS_ENV).filter(|value| !value.is_empty()) {
        return Ok(PathBuf::from(value));
    }
    Ok(repo::config_dir()?
        .join("minflair")
        .join("preferences.conf"))
}

pub fn load(path: &Path) -> Result<BTreeSet<String>> {
    if !path.is_file() {
        return Ok(BTreeSet::new());
    }
    let content = fs::read_to_string(path)
        .with_context(|| format!("could not read preferences: {}", path.display()))?;
    Ok(parse(&content))
}

pub fn parse(content: &str) -> BTreeSet<String> {
    content
        .lines()
        .map(str::trim)
        .filter(|line| !line.is_empty() && !line.starts_with('#'))
        .map(str::to_string)
        .collect()
}

/// Persist the disabled components using the format read by the shell and
/// Python runtime scripts.
#[allow(dead_code)] // Used by the interactive selector in phase 1.
pub fn save(path: &Path, disabled: &BTreeSet<String>, manifest: &Manifest) -> Result<()> {
    let unknown: Vec<&String> = disabled
        .iter()
        .filter(|id| manifest.get(id).is_none())
        .collect();
    if !unknown.is_empty() {
        let ids: Vec<&str> = unknown.iter().map(|id| id.as_str()).collect();
        bail!("unknown component ids: {}", ids.join(", "));
    }

    let core: Vec<&String> = disabled
        .iter()
        .filter(|id| manifest.get(id).is_some_and(|component| component.core))
        .collect();
    if !core.is_empty() {
        let ids: Vec<&str> = core.iter().map(|id| id.as_str()).collect();
        bail!("core components cannot be disabled: {}", ids.join(", "));
    }

    let parent = path
        .parent()
        .with_context(|| format!("invalid preferences path: {}", path.display()))?;
    fs::create_dir_all(parent).with_context(|| format!("could not create {}", parent.display()))?;

    let mut body = String::from("# Minflair preferences v1\n");
    body.push_str("# One disabled component id per line.\n\n");
    for id in disabled {
        body.push_str(id);
        body.push('\n');
    }

    let file_name = path
        .file_name()
        .map(|name| name.to_string_lossy().to_string())
        .unwrap_or_else(|| "preferences.conf".to_string());
    let temporary = path.with_file_name(format!(".{file_name}.{}.tmp", std::process::id()));
    fs::write(&temporary, body)
        .with_context(|| format!("could not write {}", temporary.display()))?;
    fs::rename(&temporary, path)
        .with_context(|| format!("could not replace {}", path.display()))?;
    Ok(())
}

pub fn validate(manifest: &Manifest, disabled: &BTreeSet<String>) -> Vec<String> {
    let mut warnings = Vec::new();
    for id in disabled {
        match manifest.get(id) {
            Some(component) if component.core => warnings.push(format!(
                "preferences: core component {:?} cannot be disabled (ignored)",
                id
            )),
            None if id == "chsh" => {
                warnings.push("preferences: chsh is now part of zsh (ignored)".to_string())
            }
            None => warnings.push(format!(
                "preferences: unknown component id {:?} (ignored)",
                id
            )),
            _ => {}
        }
    }
    warnings
}

#[cfg(test)]
mod tests {
    use super::*;

    const SAMPLE: &str = "\
id\tlabel\tcategory\tcore\tpaths\tpackages\ttheme\tfont\treload\tdescription
quickshell\tQuickshell shell\tcore\t1\tconfig/quickshell\tquickshell\t\t\t\tCore shell
kitty\tKitty terminal\tterminal\t0\tconfig/kitty\tkitty\tkitty\tkitty\t\tTerminal
";

    fn manifest() -> Manifest {
        Manifest::parse(SAMPLE).expect("manifest")
    }

    #[test]
    fn parses_comments_and_blank_lines() {
        let disabled = parse("# header\n\nkitty\n  nvim  \n");
        assert_eq!(disabled.len(), 2);
        assert!(disabled.contains("kitty"));
        assert!(disabled.contains("nvim"));
    }

    #[test]
    fn saves_and_reloads_preferences() {
        let directory = tempfile::tempdir().expect("tempdir");
        let path = directory.path().join("minflair/preferences.conf");
        let disabled: BTreeSet<String> = ["kitty".to_string()].into_iter().collect();

        save(&path, &disabled, &manifest()).expect("save");
        assert_eq!(load(&path).expect("load"), disabled);

        let content = fs::read_to_string(&path).expect("read");
        assert!(content.starts_with("# Minflair preferences v1\n"));
        assert!(content.ends_with("\nkitty\n"));
    }

    #[test]
    fn rejects_unknown_ids() {
        let directory = tempfile::tempdir().expect("tempdir");
        let path = directory.path().join("preferences.conf");
        let disabled: BTreeSet<String> = ["ghost".to_string()].into_iter().collect();

        let error = save(&path, &disabled, &manifest()).expect_err("unknown");
        assert!(format!("{error:#}").contains("unknown component ids"));
    }

    #[test]
    fn rejects_core_components() {
        let directory = tempfile::tempdir().expect("tempdir");
        let path = directory.path().join("preferences.conf");
        let disabled: BTreeSet<String> = ["quickshell".to_string()].into_iter().collect();

        let error = save(&path, &disabled, &manifest()).expect_err("core");
        assert!(format!("{error:#}").contains("core components cannot be disabled"));
    }

    #[test]
    fn validates_unknown_and_core_ids() {
        let disabled: BTreeSet<String> = ["ghost".to_string(), "quickshell".to_string()]
            .into_iter()
            .collect();
        let warnings = validate(&manifest(), &disabled);

        assert!(warnings.iter().any(|warning| warning.contains("ghost")));
        assert!(warnings
            .iter()
            .any(|warning| warning.contains("core component")));
    }
}
