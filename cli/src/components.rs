use anyhow::{bail, Result};
use std::collections::BTreeSet;
use std::path::{Path, PathBuf};

use crate::cli::{
    ComponentChangeArgs, ComponentEditArgs, ComponentListArgs, ComponentResetArgs, ComponentsArgs,
    ComponentsCommand, SelectionArgs, UpdateArgs,
};
use crate::manifest::{Component, Manifest};
use crate::prefs;
use crate::repo;
use crate::selector;
use crate::ui;
use crate::update;

pub fn run(root: &Path, args: ComponentsArgs) -> Result<u8> {
    // SAFETY: geteuid has no preconditions and cannot fail.
    if unsafe { libc::geteuid() } == 0 {
        bail!("run minflair components as your normal user, not as root");
    }

    match args.command {
        ComponentsCommand::List(list_args) => list(root, list_args),
        ComponentsCommand::Enable(change_args) => change(root, change_args, true),
        ComponentsCommand::Disable(change_args) => change(root, change_args, false),
        ComponentsCommand::Edit(edit_args) => edit(root, edit_args),
        ComponentsCommand::Reset(reset_args) => reset(root, reset_args),
    }
}

fn is_enabled(component: &Component, disabled: &BTreeSet<String>) -> bool {
    component.core || !disabled.contains(&component.id)
}

/// Load the manifest and the saved preferences, and report stale entries.
///
/// Unknown ids and core ids are dropped from the in-memory set, matching
/// `selection::apply`, so a stale preferences file from an older release
/// cannot make the next save fail.
fn load(root: &Path) -> Result<(Manifest, PathBuf, BTreeSet<String>)> {
    let manifest = Manifest::load(&root.join(repo::MANIFEST_REL))?;
    let path = prefs::default_path()?;
    let mut disabled = prefs::load(&path)?;
    for warning in prefs::validate(&manifest, &disabled) {
        ui::warn(&warning);
    }
    disabled.retain(|id| manifest.get(id).is_some_and(|component| !component.core));
    Ok((manifest, path, disabled))
}

fn list(root: &Path, args: ComponentListArgs) -> Result<u8> {
    let (manifest, path, disabled) = load(root)?;

    let rows: Vec<&Component> = manifest
        .components()
        .iter()
        .filter(|component| !args.enabled || is_enabled(component, &disabled))
        .filter(|component| !args.disabled || !is_enabled(component, &disabled))
        .collect();

    if args.json {
        let components: Vec<_> = rows
            .iter()
            .map(|component| {
                serde_json::json!({
                    "id": component.id,
                    "label": component.label,
                    "category": component.category,
                    "core": component.core,
                    "enabled": is_enabled(component, &disabled),
                })
            })
            .collect();
        let report = serde_json::json!({
            "preferences": path.display().to_string(),
            "components": components,
        });
        println!("{}", serde_json::to_string_pretty(&report)?);
        return Ok(0);
    }

    if !args.enabled && !args.disabled {
        let version = repo::app_version(root).unwrap_or_else(|| "unknown".to_string());
        ui::header(&format!("Minflair components ({version})"));
    }

    let width = rows
        .iter()
        .map(|component| component.id.len())
        .max()
        .unwrap_or(4);

    for component in &rows {
        let enabled = is_enabled(component, &disabled);
        let status = if enabled {
            ui::green("enabled ")
        } else {
            ui::yellow("disabled")
        };
        let core = if component.core { "core" } else { "    " };
        println!(
            "{status} {core} {id:<width$}  {label}",
            id = component.id,
            label = component.label,
            width = width,
        );
    }

    let enabled_count = manifest
        .components()
        .iter()
        .filter(|component| is_enabled(component, &disabled))
        .count();
    let disabled_count = manifest.len() - enabled_count;

    println!(
        "\n{}",
        ui::dim(&format!(
            "{enabled_count} enabled, {disabled_count} disabled. Preferences: {}",
            path.display()
        ))
    );
    Ok(0)
}

fn normalized_ids(values: &[String]) -> Vec<String> {
    values
        .iter()
        .flat_map(|value| value.split(','))
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .map(str::to_string)
        .collect()
}

fn change(root: &Path, args: ComponentChangeArgs, enable: bool) -> Result<u8> {
    let (manifest, path, mut disabled) = load(root)?;

    let ids = normalized_ids(&args.ids);
    if ids.is_empty() {
        bail!("no component ids given");
    }

    let mut changed = 0;
    for id in &ids {
        let Some(component) = manifest.get(id) else {
            bail!("unknown component: {id}");
        };

        if enable {
            if component.core {
                ui::info(&format!("{id} is a core component and is always enabled."));
                continue;
            }
            if disabled.remove(id) {
                changed += 1;
            }
        } else {
            if component.core {
                bail!("core component cannot be disabled: {id}");
            }
            if disabled.insert(id.clone()) {
                changed += 1;
            }
        }
    }

    if changed == 0 {
        ui::info("The selection is already up to date.");
    } else {
        prefs::save(&path, &disabled, &manifest)?;
        ui::ok(&format!(
            "Saved component preferences to {}.",
            path.display()
        ));
        if enable {
            ui::info("Run `minflair update` to deploy the newly enabled components.");
        } else {
            ui::info("Files already installed are kept; disabled components are only skipped.");
        }
    }

    if args.apply {
        apply(root)?;
    }
    Ok(0)
}

fn edit(root: &Path, args: ComponentEditArgs) -> Result<u8> {
    let (manifest, path, disabled) = load(root)?;

    if !selector::available() {
        bail!(
            "the interactive selector needs a terminal; use `minflair components enable/disable` instead"
        );
    }

    let version = repo::app_version(root).unwrap_or_else(|| "unknown".to_string());
    let Some(selection) = selector::run(&manifest, &disabled, &version)? else {
        ui::info("No changes made.");
        return Ok(0);
    };

    prefs::save(&path, &selection, &manifest)?;
    ui::ok(&format!(
        "Saved component preferences to {}.",
        path.display()
    ));

    if args.apply {
        apply(root)?;
    }
    Ok(0)
}

fn reset(root: &Path, args: ComponentResetArgs) -> Result<u8> {
    let (manifest, path, disabled) = load(root)?;

    if disabled.is_empty() {
        ui::info("All optional components are already enabled.");
    } else {
        prefs::save(&path, &BTreeSet::new(), &manifest)?;
        ui::ok(&format!(
            "Enabled every optional component in {}.",
            path.display()
        ));
        ui::info("Run `minflair update` to deploy the newly enabled components.");
    }

    if args.apply {
        apply(root)?;
    }
    Ok(0)
}

/// Apply the saved selection with the update pipeline, never prompting.
fn apply(root: &Path) -> Result<()> {
    let home = repo::home_dir()?;
    if !home.join(".config/quickshell").is_dir() {
        bail!(
            "Quickshell config not found in ~/.config; run `minflair install` before using --apply"
        );
    }

    ui::section("Applying the selection");
    update::run(
        root,
        UpdateArgs {
            selection: SelectionArgs {
                no_input: true,
                ..SelectionArgs::default()
            },
            ..UpdateArgs::default()
        },
    )?;
    Ok(())
}
