use anyhow::{bail, Context, Result};
use std::env;
use std::fs;
use std::path::{Path, PathBuf};

pub const MANIFEST_REL: &str = "config/quickshell/components.tsv";
pub const CONSTANTS_REL: &str = "config/quickshell/Core/Constants.qml";
pub const PACKAGES_REL: &str = "packages.txt";
pub const PACKAGES_AUR_REL: &str = "packages-aur.txt";
pub const REPO_MARKER_REL: &str = "minflair/repo";

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

pub fn data_dir() -> Result<PathBuf> {
    if let Some(value) = env::var_os("XDG_DATA_HOME").filter(|value| !value.is_empty()) {
        return Ok(PathBuf::from(value));
    }
    Ok(home_dir()?.join(".local/share"))
}

pub fn is_repo(path: &Path) -> bool {
    path.join(MANIFEST_REL).is_file()
}

/// Read the repository path saved by `bootstrap.sh`.
fn repo_marker(config: &Path) -> Option<PathBuf> {
    let content = fs::read_to_string(config.join(REPO_MARKER_REL)).ok()?;
    content
        .lines()
        .map(str::trim)
        .find(|line| !line.is_empty())
        .map(PathBuf::from)
}

/// Usual repository locations, tried after the current directory and the
/// executable location.
fn default_candidates(home: &Path, data: &Path) -> Vec<PathBuf> {
    vec![
        data.join("minflair"),
        data.join("minflair/repo"),
        PathBuf::from("/usr/share/minflair"),
        PathBuf::from("/usr/local/share/minflair"),
        home.join(".minflair"),
        home.join(".dotfiles"),
    ]
}

/// Locate the Minflair repository.
///
/// Resolution order: explicit `--repo`, `MINFLAIR_REPO`, the current directory
/// and its ancestors, the executable location, the path saved by the bootstrap
/// script, and the usual installation directories.
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
    if let Ok(config) = config_dir() {
        if let Some(marker) = repo_marker(&config) {
            candidates.push(marker);
        }
    }
    if let Ok(home) = home_dir() {
        let data = data_dir().unwrap_or_else(|_| home.join(".local/share"));
        candidates.extend(default_candidates(&home, &data));
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

    #[test]
    fn reads_the_repository_marker() {
        let directory = tempfile::tempdir().expect("tempdir");
        let marker = directory.path().join(REPO_MARKER_REL);
        fs::create_dir_all(marker.parent().expect("parent")).expect("mkdir");
        fs::write(&marker, "  /opt/minflair  \n\n").expect("write");

        assert_eq!(
            repo_marker(directory.path()),
            Some(PathBuf::from("/opt/minflair"))
        );
    }

    #[test]
    fn ignores_a_missing_or_empty_marker() {
        let directory = tempfile::tempdir().expect("tempdir");
        assert_eq!(repo_marker(directory.path()), None);

        let marker = directory.path().join(REPO_MARKER_REL);
        fs::create_dir_all(marker.parent().expect("parent")).expect("mkdir");
        fs::write(&marker, "\n  \n").expect("write");
        assert_eq!(repo_marker(directory.path()), None);
    }

    #[test]
    fn default_candidates_cover_packages_and_clones() {
        let home = Path::new("/home/user");
        let data = Path::new("/home/user/.local/share");
        let candidates = default_candidates(home, data);

        assert_eq!(candidates[0], data.join("minflair"));
        assert_eq!(candidates[1], data.join("minflair/repo"));
        assert!(candidates.contains(&PathBuf::from("/usr/share/minflair")));
        assert!(candidates.contains(&home.join(".minflair")));
        assert!(candidates.contains(&home.join(".dotfiles")));
    }
}
