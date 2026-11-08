use anyhow::{bail, Context, Result};
use std::env;
use std::fs;
use std::path::{Path, PathBuf};

pub const MANIFEST_REL: &str = "config/quickshell/components.tsv";
pub const CONSTANTS_REL: &str = "config/quickshell/Core/Constants.qml";
pub const PACKAGES_REL: &str = "packages.txt";
pub const PACKAGES_AUR_REL: &str = "packages-aur.txt";

pub fn home_dir() -> Result<PathBuf> {
    env::var_os("HOME")
        .filter(|value| !value.is_empty())
        .map(PathBuf::from)
        .context("HOME is not set")
}

pub fn config_dir() -> Result<PathBuf> {
    if let Some(value) = env::var_os("XDG_CONFIG_HOME").filter(|value| !value.is_empty()) {
        return Ok(PathBuf::from(value));
    }
    Ok(home_dir()?.join(".config"))
}

pub fn is_repo(path: &Path) -> bool {
    path.join(MANIFEST_REL).is_file()
}

/// Locate the Minflair repository.
///
/// Resolution order: explicit `--repo`, `MINFLAIR_REPO`, the current directory
/// and its ancestors, the executable location, and the usual clone names.
pub fn find(explicit: Option<PathBuf>) -> Result<PathBuf> {
    if let Some(path) = explicit {
        let path = fs::canonicalize(&path)
            .with_context(|| format!("repository not found: {}", path.display()))?;
        if !is_repo(&path) {
            bail!(
                "{} does not look like the Minflair repository (missing {})",
                path.display(),
                MANIFEST_REL
            );
        }
        return Ok(path);
    }

    let mut candidates: Vec<PathBuf> = Vec::new();
    if let Some(value) = env::var_os("MINFLAIR_REPO").filter(|value| !value.is_empty()) {
        candidates.push(PathBuf::from(value));
    }
    if let Ok(cwd) = env::current_dir() {
        candidates.extend(cwd.ancestors().take(6).map(Path::to_path_buf));
    }
    if let Ok(executable) = env::current_exe() {
        if let Some(parent) = executable.parent() {
            candidates.extend(parent.ancestors().take(6).map(Path::to_path_buf));
        }
    }
    if let Ok(home) = home_dir() {
        candidates.push(home.join(".minflair"));
        candidates.push(home.join(".dotfiles"));
    }

    for candidate in candidates {
        if is_repo(&candidate) {
            return Ok(fs::canonicalize(&candidate).unwrap_or(candidate));
        }
    }

    bail!("could not locate the Minflair repository; pass --repo <path> or set MINFLAIR_REPO")
}

/// Read `appVersion` from the Quickshell constants, the version shown by the UI.
pub fn app_version(root: &Path) -> Option<String> {
    let content = fs::read_to_string(root.join(CONSTANTS_REL)).ok()?;
    for line in content.lines() {
        let Some((_, rest)) = line.split_once("appVersion:") else {
            continue;
        };
        if let Some(version) = extract_quoted(rest) {
            return Some(version);
        }
    }
    None
}

fn extract_quoted(text: &str) -> Option<String> {
    let start = text.find('"')?;
    let rest = &text[start + 1..];
    let end = rest.find('"')?;
    Some(rest[..end].to_string())
}

/// Read a package list, skipping comments and blank lines.
pub fn read_package_list(path: &Path) -> Result<Vec<String>> {
    let content = fs::read_to_string(path)
        .with_context(|| format!("could not read package list: {}", path.display()))?;
    Ok(content
        .lines()
        .map(str::trim)
        .filter(|line| !line.is_empty() && !line.starts_with('#'))
        .map(str::to_string)
        .collect())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn extracts_the_app_version() {
        let directory = tempfile::tempdir().expect("tempdir");
        let constants = directory.path().join(CONSTANTS_REL);
        fs::create_dir_all(constants.parent().expect("parent")).expect("mkdir");
        fs::write(
            &constants,
            "Item {\n    readonly property string appVersion: \"2.2.0\"\n}\n",
        )
        .expect("write");

        assert_eq!(app_version(directory.path()), Some("2.2.0".to_string()));
    }

    #[test]
    fn finds_an_explicit_repository() {
        let directory = tempfile::tempdir().expect("tempdir");
        let manifest = directory.path().join(MANIFEST_REL);
        fs::create_dir_all(manifest.parent().expect("parent")).expect("mkdir");
        fs::write(&manifest, "id\n").expect("write");

        let found = find(Some(directory.path().to_path_buf())).expect("repository");
        assert_eq!(
            found,
            fs::canonicalize(directory.path()).expect("canonical")
        );
    }

    #[test]
    fn rejects_a_directory_without_a_manifest() {
        let directory = tempfile::tempdir().expect("tempdir");
        let error = find(Some(directory.path().to_path_buf())).expect_err("must fail");
        assert!(format!("{error:#}").contains(MANIFEST_REL));
    }
}
