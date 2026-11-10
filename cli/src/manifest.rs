use anyhow::{bail, Context, Result};
use std::collections::{BTreeSet, HashMap, HashSet};
use std::ffi::OsStr;
use std::fs;
use std::path::Path;

pub const COLUMNS: [&str; 10] = [
    "id",
    "label",
    "category",
    "core",
    "paths",
    "packages",
    "theme",
    "font",
    "reload",
    "description",
];

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Component {
    pub id: String,
    pub label: String,
    pub category: String,
    pub core: bool,
    pub paths: Vec<String>,
    pub packages: Vec<String>,
    pub theme: Vec<String>,
    pub font: Vec<String>,
    pub reload: String,
    pub description: String,
}

#[derive(Debug, Clone)]
pub struct Manifest {
    components: Vec<Component>,
    index: HashMap<String, usize>,
}

impl Manifest {
    pub fn load(path: &Path) -> Result<Self> {
        let content = fs::read_to_string(path)
            .with_context(|| format!("could not read component manifest: {}", path.display()))?;
        Self::parse(&content)
            .with_context(|| format!("invalid component manifest: {}", path.display()))
    }

    pub fn parse(content: &str) -> Result<Self> {
        let mut components: Vec<Component> = Vec::new();
        let mut index: HashMap<String, usize> = HashMap::new();
        let mut header_seen = false;

        for (offset, raw) in content.lines().enumerate() {
            let line = raw.trim_end_matches('\r');
            let trimmed = line.trim();
            if trimmed.is_empty() || trimmed.starts_with('#') {
                continue;
            }

            let fields: Vec<&str> = line.split('\t').collect();
            if !header_seen {
                let matches = fields.len() == COLUMNS.len()
                    && fields
                        .iter()
                        .zip(COLUMNS.iter())
                        .all(|(actual, expected)| actual == expected);
                if !matches {
                    bail!("invalid manifest header: expected {}", COLUMNS.join(", "));
                }
                header_seen = true;
                continue;
            }

            let line_number = offset + 1;
            if fields.len() != COLUMNS.len() {
                bail!(
                    "malformed row at line {}: expected {} columns, found {}",
                    line_number,
                    COLUMNS.len(),
                    fields.len()
                );
            }

            let id = fields[0].trim();
            if id.is_empty() {
                bail!("missing component id at line {}", line_number);
            }
            if index.contains_key(id) {
                bail!("duplicate component id {:?} at line {}", id, line_number);
            }

            let component = Component {
                id: id.to_string(),
                label: non_empty(fields[1]).unwrap_or_else(|| id.to_string()),
                category: non_empty(fields[2]).unwrap_or_else(|| "misc".to_string()),
                core: fields[3].trim() == "1",
                paths: split_list(fields[4]),
                packages: split_list(fields[5]),
                theme: split_list(fields[6]),
                font: split_list(fields[7]),
                reload: fields[8].trim().to_string(),
                description: fields[9].trim().to_string(),
            };

            index.insert(component.id.clone(), components.len());
            components.push(component);
        }

        if !header_seen {
            bail!("missing manifest header");
        }
        if components.is_empty() {
            bail!("component manifest is empty");
        }

        Ok(Self { components, index })
    }

    pub fn components(&self) -> &[Component] {
        &self.components
    }

    pub fn get(&self, id: &str) -> Option<&Component> {
        self.index.get(id).map(|index| &self.components[*index])
    }

    pub fn len(&self) -> usize {
        self.components.len()
    }

    pub fn is_enabled(&self, id: &str, disabled: &BTreeSet<String>) -> Option<bool> {
        self.get(id)
            .map(|component| component.core || !disabled.contains(id))
    }

    pub fn disabled_packages(&self, disabled: &BTreeSet<String>) -> BTreeSet<String> {
        self.components
            .iter()
            .filter(|component| !component.core && disabled.contains(&component.id))
            .flat_map(|component| component.packages.iter().cloned())
            .collect()
    }

    /// Check path mappings and theme appliers.
    ///
    /// Preference ids are validated separately by [`crate::prefs::validate`].
    /// The messages mirror `config/quickshell/Scripts/minflair_components.py`
    /// so both validators report the same problems.
    pub fn validate(&self, repo_root: &Path) -> Vec<String> {
        let mut warnings = Vec::new();

        for component in &self.components {
            if component.core && component.category != "core" {
                warnings.push(format!(
                    "{}: core component should use the 'core' category",
                    component.id
                ));
            }
            if !component.core && component.category == "core" {
                warnings.push(format!(
                    "{}: non-core component uses the 'core' category",
                    component.id
                ));
            }
        }

        let mut mapped_config: HashMap<String, String> = HashMap::new();
        for component in &self.components {
            for raw_path in &component.paths {
                let path = Path::new(raw_path);
                if !repo_root.join(path).exists() {
                    warnings.push(format!(
                        "{}: path does not exist: {}",
                        component.id, raw_path
                    ));
                }
                let mut parts = path.iter();
                if parts.next() == Some(OsStr::new("config")) {
                    if let Some(name) = parts.next() {
                        let name = name.to_string_lossy().to_string();
                        if let Some(existing) = mapped_config.get(&name) {
                            warnings.push(format!(
                                "config/{}: mapped to both {} and {}",
                                name, existing, component.id
                            ));
                        } else {
                            mapped_config.insert(name, component.id.clone());
                        }
                    }
                }
            }
        }

        let config_root = repo_root.join("config");
        if config_root.is_dir() {
            let mut names = Vec::new();
            if let Ok(entries) = fs::read_dir(&config_root) {
                for entry in entries.flatten() {
                    if entry.path().is_dir() {
                        names.push(entry.file_name().to_string_lossy().to_string());
                    }
                }
            }
            names.sort();
            for name in names {
                if !mapped_config.contains_key(&name) {
                    warnings.push(format!("config/{}: not mapped to any component", name));
                }
            }
        }

        let home_root = repo_root.join("home");
        let mut mapped_home: HashSet<String> = HashSet::new();
        for component in &self.components {
            for raw_path in &component.paths {
                let mut parts = Path::new(raw_path).iter();
                if parts.next() == Some(OsStr::new("home")) {
                    if let Some(name) = parts.next() {
                        mapped_home.insert(name.to_string_lossy().to_string());
                    }
                }
            }
        }
        if home_root.is_dir() {
            let mut names = Vec::new();
            if let Ok(entries) = fs::read_dir(&home_root) {
                for entry in entries.flatten() {
                    names.push(entry.file_name().to_string_lossy().to_string());
                }
            }
            names.sort();
            for name in names {
                if !mapped_home.contains(&name) {
                    warnings.push(format!("home/{}: not mapped to any component", name));
                }
            }
        }

        let applier_root = repo_root
            .join("config")
            .join("quickshell")
            .join("Scripts")
            .join("theme")
            .join("theme_appliers");
        let mut applier_names: BTreeSet<String> = BTreeSet::new();
        if applier_root.is_dir() {
            if let Ok(entries) = fs::read_dir(&applier_root) {
                for entry in entries.flatten() {
                    let path = entry.path();
                    if path.extension().and_then(OsStr::to_str) != Some("py") {
                        continue;
                    }
                    if let Some(stem) = path.file_stem().and_then(OsStr::to_str) {
                        if stem != "__init__" {
                            applier_names.insert(stem.to_string());
                        }
                    }
                }
            }
        }

        let mapped_appliers: BTreeSet<String> = self
            .components
            .iter()
            .flat_map(|component| component.theme.iter().cloned())
            .collect();
        for applier in &applier_names {
            if !mapped_appliers.contains(applier) {
                warnings.push(format!(
                    "theme_appliers/{}.py: not mapped to any component",
                    applier
                ));
            }
        }

        let mut known_appliers = applier_names;
        known_appliers.insert("cursor".to_string());
        for component in &self.components {
            for applier in &component.theme {
                if !known_appliers.contains(applier) {
                    warnings.push(format!(
                        "{}: unknown theme applier {:?}",
                        component.id, applier
                    ));
                }
            }
        }

        warnings
    }
}

fn non_empty(value: &str) -> Option<String> {
    let value = value.trim();
    (!value.is_empty()).then(|| value.to_string())
}

fn split_list(value: &str) -> Vec<String> {
    value
        .split(',')
        .map(str::trim)
        .filter(|part| !part.is_empty())
        .map(str::to_string)
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;

    const SAMPLE: &str = "\
# Minflair component manifest
id\tlabel\tcategory\tcore\tpaths\tpackages\ttheme\tfont\treload\tdescription
quickshell\tQuickshell shell\tcore\t1\tconfig/quickshell\tquickshell\t\t\t\tCore shell
kitty\tKitty terminal\tterminal\t0\tconfig/kitty\tkitty\tkitty\tkitty\tkillall -USR1 kitty\tTerminal and colors
";

    #[test]
    fn parses_components_and_lists() {
        let manifest = Manifest::parse(SAMPLE).expect("manifest");
        assert_eq!(manifest.len(), 2);

        let quickshell = manifest.get("quickshell").expect("quickshell");
        assert!(quickshell.core);
        assert_eq!(quickshell.paths, vec!["config/quickshell"]);
        assert_eq!(quickshell.category, "core");

        let kitty = manifest.get("kitty").expect("kitty");
        assert!(!kitty.core);
        assert_eq!(kitty.theme, vec!["kitty"]);
        assert_eq!(kitty.font, vec!["kitty"]);
        assert_eq!(kitty.reload, "killall -USR1 kitty");
    }

    #[test]
    fn core_components_ignore_disabled_preferences() {
        let manifest = Manifest::parse(SAMPLE).expect("manifest");
        let disabled: BTreeSet<String> = ["kitty".to_string(), "quickshell".to_string()]
            .into_iter()
            .collect();

        assert_eq!(manifest.is_enabled("kitty", &disabled), Some(false));
        assert_eq!(manifest.is_enabled("quickshell", &disabled), Some(true));
        assert_eq!(manifest.is_enabled("missing", &disabled), None);
    }

    #[test]
    fn collects_packages_from_disabled_components() {
        let manifest = Manifest::parse(SAMPLE).expect("manifest");
        let disabled: BTreeSet<String> = ["kitty".to_string()].into_iter().collect();
        let packages = manifest.disabled_packages(&disabled);

        assert!(packages.contains("kitty"));
        assert!(!packages.contains("quickshell"));
    }

    #[test]
    fn rejects_duplicate_ids() {
        let duplicated = SAMPLE.replace("kitty\tKitty terminal", "quickshell\tKitty terminal");
        let error = Manifest::parse(&duplicated).expect_err("duplicate");
        assert!(format!("{error:#}").contains("duplicate component id"));
    }

    #[test]
    fn rejects_rows_with_the_wrong_column_count() {
        let content = "\
id\tlabel\tcategory\tcore\tpaths\tpackages\ttheme\tfont\treload\tdescription
quickshell\tQuickshell shell\tcore\t1\tconfig/quickshell\tquickshell
";
        let error = Manifest::parse(content).expect_err("malformed");
        assert!(format!("{error:#}").contains("expected 10 columns"));
    }

    #[test]
    fn rejects_an_invalid_header() {
        let content = "id\tlabel\nquickshell\tQuickshell\n";
        let error = Manifest::parse(content).expect_err("header");
        assert!(format!("{error:#}").contains("invalid manifest header"));
    }

    #[test]
    fn reports_missing_paths() {
        let directory = tempfile::tempdir().expect("tempdir");
        let manifest = Manifest::parse(SAMPLE).expect("manifest");
        let warnings = manifest.validate(directory.path());

        assert!(warnings
            .iter()
            .any(|warning| warning.contains("path does not exist: config/quickshell")));
    }
}
