use anyhow::{bail, Result};
use std::collections::BTreeSet;

use crate::manifest::Manifest;

/// Component selection coming from the command line.
#[derive(Debug, Default, Clone)]
pub struct Flags {
    pub only: Vec<String>,
    pub include: Vec<String>,
    pub exclude: Vec<String>,
}

impl Flags {
    pub fn is_empty(&self) -> bool {
        normalized(&self.only).is_empty()
            && normalized(&self.include).is_empty()
            && normalized(&self.exclude).is_empty()
    }
}

fn normalized(values: &[String]) -> Vec<String> {
    values
        .iter()
        .map(|value| value.trim())
        .filter(|value| !value.is_empty())
        .map(str::to_string)
        .collect()
}

/// Apply `--only`, `--include` then `--exclude` to the disabled set.
///
/// The order matches `apply_selection_flags` in `install.sh`: core components
/// are always enabled and unknown or stale ids from an old preferences file
/// are dropped when a selection is written.
pub fn apply(
    manifest: &Manifest,
    current: &BTreeSet<String>,
    flags: &Flags,
) -> Result<BTreeSet<String>> {
    let mut disabled: BTreeSet<String> = current
        .iter()
        .filter(|id| manifest.get(id).is_some_and(|component| !component.core))
        .cloned()
        .collect();

    let only = normalized(&flags.only);
    if !only.is_empty() {
        validate_known(manifest, &only)?;
        let wanted: BTreeSet<&str> = only.iter().map(String::as_str).collect();
        disabled = manifest
            .components()
            .iter()
            .filter(|component| !component.core && !wanted.contains(component.id.as_str()))
            .map(|component| component.id.clone())
            .collect();
    }

    let include = normalized(&flags.include);
    if !include.is_empty() {
        validate_known(manifest, &include)?;
        for id in &include {
            disabled.remove(id);
        }
    }

    let exclude = normalized(&flags.exclude);
    if !exclude.is_empty() {
        for id in &exclude {
            let Some(component) = manifest.get(id) else {
                bail!("unknown component: {id}");
            };
            if component.core {
                bail!("core component cannot be disabled: {id}");
            }
            disabled.insert(id.clone());
        }
    }

    Ok(disabled)
}

fn validate_known(manifest: &Manifest, ids: &[String]) -> Result<()> {
    for id in ids {
        if manifest.get(id).is_none() {
            bail!("unknown component: {id}");
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    const SAMPLE: &str = "\
id\tlabel\tcategory\tcore\tpaths\tpackages\ttheme\tfont\treload\tdescription
quickshell\tQuickshell shell\tcore\t1\tconfig/quickshell\tquickshell\t\t\t\tCore shell
hyprland\tHyprland\tcore\t1\tconfig/hypr\thyprland\t\t\t\thyprland
kitty\tKitty terminal\tterminal\t0\tconfig/kitty\tkitty\tkitty\tkitty\t\tTerminal
nvim\tNeovim\tterminal\t0\tconfig/nvim\tnvim\tnvim\t\t\tEditor
";

    fn manifest() -> Manifest {
        Manifest::parse(SAMPLE).expect("manifest")
    }

    fn set(ids: &[&str]) -> BTreeSet<String> {
        ids.iter().map(|id| id.to_string()).collect()
    }

    #[test]
    fn only_disables_every_optional_component_that_is_not_listed() {
        let flags = Flags {
            only: vec!["kitty".to_string()],
            ..Flags::default()
        };
        let disabled = apply(&manifest(), &BTreeSet::new(), &flags).expect("selection");

        assert_eq!(disabled, set(&["nvim"]));
    }

    #[test]
    fn include_removes_a_previous_disabled_component() {
        let flags = Flags {
            include: vec!["nvim".to_string()],
            ..Flags::default()
        };
        let disabled = apply(&manifest(), &set(&["kitty", "nvim"]), &flags).expect("selection");

        assert_eq!(disabled, set(&["kitty"]));
    }

    #[test]
    fn exclude_wins_over_include_and_only() {
        let flags = Flags {
            only: vec!["kitty".to_string(), "nvim".to_string()],
            include: vec!["nvim".to_string()],
            exclude: vec!["kitty".to_string()],
        };
        let disabled = apply(&manifest(), &BTreeSet::new(), &flags).expect("selection");

        assert_eq!(disabled, set(&["kitty"]));
    }

    #[test]
    fn stale_preferences_are_dropped_when_a_selection_is_applied() {
        let flags = Flags {
            exclude: vec!["kitty".to_string()],
            ..Flags::default()
        };
        let disabled =
            apply(&manifest(), &set(&["ghost", "quickshell"]), &flags).expect("selection");

        assert_eq!(disabled, set(&["kitty"]));
    }

    #[test]
    fn trims_whitespace_around_ids() {
        let flags = Flags {
            exclude: vec![" kitty ".to_string(), "  ".to_string()],
            ..Flags::default()
        };
        let disabled = apply(&manifest(), &BTreeSet::new(), &flags).expect("selection");
        assert_eq!(disabled, set(&["kitty"]));
        assert!(Flags {
            exclude: vec!["  ".to_string()],
            ..Flags::default()
        }
        .is_empty());
    }

    #[test]
    fn rejects_unknown_ids() {
        let flags = Flags {
            only: vec!["ghost".to_string()],
            ..Flags::default()
        };
        let error = apply(&manifest(), &BTreeSet::new(), &flags).expect_err("unknown");
        assert!(format!("{error:#}").contains("unknown component: ghost"));
    }

    #[test]
    fn refuses_to_disable_core_components() {
        let flags = Flags {
            exclude: vec!["quickshell".to_string()],
            ..Flags::default()
        };
        let error = apply(&manifest(), &BTreeSet::new(), &flags).expect_err("core");
        assert!(format!("{error:#}").contains("core component cannot be disabled"));
    }
}
