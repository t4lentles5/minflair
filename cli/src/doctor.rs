use anyhow::Result;
use serde::Serialize;
use std::collections::BTreeSet;
use std::env;
use std::fs;
use std::path::Path;

use crate::aur;
use crate::cli::DoctorArgs;
use crate::manifest::Manifest;
use crate::prefs;
use crate::process;
use crate::repo;
use crate::ui;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum Status {
    Ok,
    Warn,
    Fail,
}

#[derive(Debug, Clone, Serialize)]
pub struct Check {
    pub name: String,
    pub status: Status,
    pub detail: String,
}

impl Check {
    fn new(name: impl Into<String>, status: Status, detail: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            status,
            detail: detail.into(),
        }
    }
}

#[derive(Debug, Serialize)]
pub struct Summary {
    pub ok: usize,
    pub warnings: usize,
    pub failures: usize,
}

#[derive(Debug, Serialize)]
pub struct Report {
    pub minflair_version: String,
    pub config_version: Option<String>,
    pub repo: Option<String>,
    pub checks: Vec<Check>,
    pub summary: Summary,
}

pub fn run(args: DoctorArgs) -> Result<u8> {
    let report = build_report(&args);
    if args.json {
        println!("{}", serde_json::to_string_pretty(&report)?);
    } else {
        print_report(&report);
    }
    Ok(if report.summary.failures > 0 { 1 } else { 0 })
}

fn build_report(args: &DoctorArgs) -> Report {
    let mut checks = Vec::new();
    let repo_result = repo::find(args.repo.clone());
    let config_version = repo_result
        .as_ref()
        .ok()
        .and_then(|root| repo::app_version(root));

    match &repo_result {
        Ok(root) => checks.push(Check::new("repo", Status::Ok, root.display().to_string())),
        Err(error) => checks.push(Check::new("repo", Status::Fail, format!("{error:#}"))),
    }

    checks.push(check_user());
    checks.push(check_os());
    checks.push(check_tools());
    checks.push(check_aur());
    checks.push(check_config_dir());

    let disabled = if let Ok(root) = &repo_result {
        match &config_version {
            Some(version) => checks.push(check_version(version)),
            None => checks.push(Check::new(
                "version",
                Status::Warn,
                format!(
                    "binary {}; could not read appVersion from {}",
                    env!("CARGO_PKG_VERSION"),
                    repo::CONSTANTS_REL
                ),
            )),
        }
        let (disabled, manifest) = check_repository(root, &mut checks);
        if let Some(manifest) = &manifest {
            check_packages(root, manifest, &disabled, args.packages, &mut checks);
        }
        disabled
    } else {
        load_disabled()
    };

    check_desktop(&disabled, &mut checks);

    let summary = Summary {
        ok: checks
            .iter()
            .filter(|check| check.status == Status::Ok)
            .count(),
        warnings: checks
            .iter()
            .filter(|check| check.status == Status::Warn)
            .count(),
        failures: checks
            .iter()
            .filter(|check| check.status == Status::Fail)
            .count(),
    };

    Report {
        minflair_version: env!("CARGO_PKG_VERSION").to_string(),
        config_version,
        repo: repo_result
            .as_ref()
            .ok()
            .map(|root| root.display().to_string()),
        checks,
        summary,
    }
}

/// Compare the version of the installed binary with the version the
/// configuration reports. A mismatch means the binary is out of date with
/// the configuration, which happens after an update that skipped the
/// rebuild or when the binary was installed from another release.
fn check_version(config_version: &str) -> Check {
    let binary_version = env!("CARGO_PKG_VERSION");
    if binary_version == config_version {
        Check::new(
            "version",
            Status::Ok,
            format!("binary {binary_version}, config {config_version}"),
        )
    } else {
        Check::new(
            "version",
            Status::Warn,
            format!(
                "binary {binary_version}, config {config_version}; \
                 the binary is out of date, rebuild it with `minflair update --pull`"
            ),
        )
    }
}

fn check_user() -> Check {
    // SAFETY: geteuid has no preconditions and cannot fail.
    let uid = unsafe { libc::geteuid() };
    if uid == 0 {
        Check::new(
            "user",
            Status::Fail,
            "running as root; Minflair must run as a normal user",
        )
    } else {
        let name = env::var("USER")
            .or_else(|_| env::var("LOGNAME"))
            .unwrap_or_else(|_| format!("uid {uid}"));
        Check::new("user", Status::Ok, format!("running as {name}"))
    }
}

fn check_os() -> Check {
    let path = Path::new("/etc/os-release");
    let content = match fs::read_to_string(path) {
        Ok(content) => content,
        Err(error) => {
            return Check::new(
                "os",
                Status::Warn,
                format!("could not read {}: {error}", path.display()),
            )
        }
    };

    let mut id = String::new();
    let mut like = String::new();
    let mut pretty = String::new();
    for line in content.lines() {
        let Some((key, value)) = line.split_once('=') else {
            continue;
        };
        let value = value.trim_matches('"').to_string();
        match key {
            "ID" => id = value,
            "ID_LIKE" => like = value,
            "PRETTY_NAME" => pretty = value,
            _ => {}
        }
    }

    let is_arch =
        id == "arch" || id.contains("arch") || like.split_whitespace().any(|value| value == "arch");
    let name = if pretty.is_empty() {
        format!("{id} {like}").trim().to_string()
    } else {
        pretty
    };

    if is_arch {
        Check::new("os", Status::Ok, name)
    } else {
        Check::new(
            "os",
            Status::Warn,
            format!("{name} (Minflair targets Arch Linux)"),
        )
    }
}

fn check_tools() -> Check {
    const REQUIRED: &[&str] = &["git", "pacman", "sudo"];
    const OPTIONAL: &[&str] = &[
        "python3",
        "curl",
        "hyprctl",
        "qs",
        "systemctl",
        "pgrep",
        "id",
    ];

    let missing_required: Vec<&str> = REQUIRED
        .iter()
        .copied()
        .filter(|tool| process::which(tool).is_none())
        .collect();
    let missing_optional: Vec<&str> = OPTIONAL
        .iter()
        .copied()
        .filter(|tool| process::which(tool).is_none())
        .collect();

    if !missing_required.is_empty() {
        Check::new(
            "tools",
            Status::Fail,
            format!("missing required: {}", missing_required.join(", ")),
        )
    } else if !missing_optional.is_empty() {
        Check::new(
            "tools",
            Status::Warn,
            format!("missing optional: {}", missing_optional.join(", ")),
        )
    } else {
        Check::new("tools", Status::Ok, "required and optional tools found")
    }
}

fn check_aur() -> Check {
    match aur::current() {
        Ok(name) if !aur::valid(&name) => Check::new(
            "aur helper",
            Status::Fail,
            format!("invalid helper {name:?}; use yay or paru"),
        ),
        Ok(name) if !aur::installed(&name) => Check::new(
            "aur helper",
            Status::Warn,
            format!("{name} configured but not installed"),
        ),
        Ok(name) => Check::new("aur helper", Status::Ok, format!("{name} installed")),
        Err(error) => Check::new("aur helper", Status::Warn, format!("{error:#}")),
    }
}

fn check_config_dir() -> Check {
    let directory = match repo::config_dir() {
        Ok(directory) => directory,
        Err(error) => return Check::new("config dir", Status::Fail, format!("{error:#}")),
    };

    if directory.is_dir() {
        if process::writable(&directory) {
            Check::new("config dir", Status::Ok, directory.display().to_string())
        } else {
            Check::new(
                "config dir",
                Status::Fail,
                format!("{} is not writable", directory.display()),
            )
        }
    } else {
        let parent = directory.parent().unwrap_or_else(|| Path::new("/"));
        if process::writable(parent) {
            Check::new(
                "config dir",
                Status::Ok,
                format!("{} will be created", directory.display()),
            )
        } else {
            Check::new(
                "config dir",
                Status::Fail,
                format!("cannot create {}", directory.display()),
            )
        }
    }
}

fn load_disabled() -> BTreeSet<String> {
    prefs::default_path()
        .ok()
        .and_then(|path| prefs::load(&path).ok())
        .unwrap_or_default()
}

fn check_repository(root: &Path, checks: &mut Vec<Check>) -> (BTreeSet<String>, Option<Manifest>) {
    let prefs_path = match prefs::default_path() {
        Ok(path) => path,
        Err(error) => {
            checks.push(Check::new(
                "preferences",
                Status::Warn,
                format!("{error:#}"),
            ));
            return (BTreeSet::new(), None);
        }
    };

    let disabled = match prefs::load(&prefs_path) {
        Ok(disabled) => {
            checks.push(Check::new(
                "preferences",
                Status::Ok,
                format!(
                    "{} disabled component(s) in {}",
                    disabled.len(),
                    prefs_path.display()
                ),
            ));
            disabled
        }
        Err(error) => {
            checks.push(Check::new(
                "preferences",
                Status::Fail,
                format!("{error:#}"),
            ));
            BTreeSet::new()
        }
    };

    let manifest = match Manifest::load(&root.join(repo::MANIFEST_REL)) {
        Ok(manifest) => {
            checks.push(Check::new(
                "manifest",
                Status::Ok,
                format!("{} components", manifest.len()),
            ));
            manifest
        }
        Err(error) => {
            checks.push(Check::new("manifest", Status::Fail, format!("{error:#}")));
            return (disabled, None);
        }
    };

    let missing_core: Vec<&str> = ["quickshell", "hyprland"]
        .into_iter()
        .filter(|id| manifest.get(id).is_none())
        .collect();
    if missing_core.is_empty() {
        checks.push(Check::new(
            "core components",
            Status::Ok,
            "quickshell and hyprland present",
        ));
    } else {
        checks.push(Check::new(
            "core components",
            Status::Fail,
            format!("missing: {}", missing_core.join(", ")),
        ));
    }

    let path_warnings = manifest.validate(root);
    checks.push(if path_warnings.is_empty() {
        Check::new(
            "manifest paths",
            Status::Ok,
            "all component paths and theme appliers are mapped",
        )
    } else {
        Check::new("manifest paths", Status::Warn, summarize(&path_warnings))
    });

    let pref_warnings = prefs::validate(&manifest, &disabled);
    checks.push(if pref_warnings.is_empty() {
        Check::new(
            "preferences ids",
            Status::Ok,
            "every id is known and enabled",
        )
    } else {
        Check::new("preferences ids", Status::Warn, summarize(&pref_warnings))
    });

    (disabled, Some(manifest))
}

fn check_packages(
    root: &Path,
    manifest: &Manifest,
    disabled: &BTreeSet<String>,
    enabled: bool,
    checks: &mut Vec<Check>,
) {
    if !enabled {
        return;
    }

    let installed: BTreeSet<String> = match process::output("pacman", &["-Qq"]) {
        Some(output) if output.status.success() => String::from_utf8_lossy(&output.stdout)
            .lines()
            .map(str::trim)
            .filter(|line| !line.is_empty())
            .map(str::to_string)
            .collect(),
        _ => {
            checks.push(Check::new(
                "packages",
                Status::Warn,
                "could not query pacman; skipping package check",
            ));
            return;
        }
    };

    let mut wanted = Vec::new();
    for relative in [repo::PACKAGES_REL, repo::PACKAGES_AUR_REL] {
        match repo::read_package_list(&root.join(relative)) {
            Ok(mut packages) => wanted.append(&mut packages),
            Err(error) => checks.push(Check::new("packages", Status::Warn, format!("{error:#}"))),
        }
    }

    let disabled_packages = manifest.disabled_packages(disabled);
    let mut missing: Vec<String> = wanted
        .into_iter()
        .filter(|package| !disabled_packages.contains(package) && !installed.contains(package))
        .collect();
    missing.sort();
    missing.dedup();

    if missing.is_empty() {
        checks.push(Check::new(
            "packages",
            Status::Ok,
            "every enabled package is installed",
        ));
    } else {
        checks.push(Check::new(
            "packages",
            Status::Warn,
            format!("{} missing: {}", missing.len(), summarize(&missing)),
        ));
    }
}

fn check_desktop(disabled: &BTreeSet<String>, checks: &mut Vec<Check>) {
    let home = match repo::home_dir() {
        Ok(home) => home,
        Err(error) => {
            checks.push(Check::new("desktop", Status::Warn, format!("{error:#}")));
            return;
        }
    };

    if disabled.contains("gtk") {
        checks.push(Check::new(
            "gtk theme",
            Status::Ok,
            "gtk component disabled",
        ));
    } else {
        let css = home.join(".themes/Material-Gnome/gtk-3.0/gtk.css");
        if !css.is_file() {
            checks.push(Check::new(
                "gtk theme",
                Status::Warn,
                "Material-Gnome missing; run install.sh or update.sh",
            ));
        } else {
            let size = fs::metadata(&css).map(|meta| meta.len()).unwrap_or(0);
            if size > 1024 {
                checks.push(Check::new(
                    "gtk theme",
                    Status::Ok,
                    format!("Material-Gnome ready ({size} bytes)"),
                ));
            } else {
                checks.push(Check::new(
                    "gtk theme",
                    Status::Warn,
                    format!("{} looks incomplete ({size} bytes)", css.display()),
                ));
            }
        }
    }

    if disabled.contains("sddm") {
        checks.push(Check::new(
            "sddm theme",
            Status::Ok,
            "sddm component disabled",
        ));
    } else {
        let theme = Path::new("/usr/share/sddm/themes/minflair-sddm/theme.conf");
        if theme.is_file() {
            checks.push(Check::new(
                "sddm theme",
                Status::Ok,
                theme.display().to_string(),
            ));
        } else {
            checks.push(Check::new(
                "sddm theme",
                Status::Warn,
                "minflair-sddm theme not installed",
            ));
        }
    }

    if disabled.contains("ddc") {
        checks.push(Check::new("ddc", Status::Ok, "ddc component disabled"));
    } else {
        match process::output("id", &["-nG"]) {
            Some(output) if output.status.success() => {
                let groups = String::from_utf8_lossy(&output.stdout);
                if groups.split_whitespace().any(|group| group == "i2c") {
                    checks.push(Check::new("ddc", Status::Ok, "user is in the i2c group"));
                } else {
                    checks.push(Check::new(
                        "ddc",
                        Status::Warn,
                        "user is not in the i2c group",
                    ));
                }
            }
            _ => checks.push(Check::new(
                "ddc",
                Status::Warn,
                "could not read group membership",
            )),
        }
    }

    if disabled.contains("services") {
        checks.push(Check::new(
            "services",
            Status::Ok,
            "services component disabled",
        ));
    } else {
        let mut missing = Vec::new();
        for service in [
            "NetworkManager.service",
            "bluetooth.service",
            "power-profiles-daemon.service",
        ] {
            let enabled = process::output("systemctl", &["is-enabled", "--quiet", service])
                .map(|output| output.status.success())
                .unwrap_or(false);
            if !enabled {
                missing.push(service);
            }
        }
        if missing.is_empty() {
            checks.push(Check::new(
                "services",
                Status::Ok,
                "required services are enabled",
            ));
        } else {
            checks.push(Check::new(
                "services",
                Status::Warn,
                format!("not enabled: {}", missing.join(", ")),
            ));
        }
    }

    let session = env::var_os("HYPRLAND_INSTANCE_SIGNATURE").is_some();
    let quickshell = process::output("pgrep", &["-x", "qs"])
        .map(|output| output.status.success())
        .unwrap_or(false);
    let status = if session && quickshell {
        Status::Ok
    } else {
        Status::Warn
    };
    let detail = match (session, quickshell) {
        (true, true) => "Hyprland session with Quickshell running".to_string(),
        (true, false) => "Hyprland session, but Quickshell is not running".to_string(),
        (false, true) => "Quickshell running outside a Hyprland session".to_string(),
        (false, false) => "not inside a Hyprland session".to_string(),
    };
    checks.push(Check::new("session", status, detail));
}

fn summarize(items: &[String]) -> String {
    const LIMIT: usize = 3;
    if items.len() <= LIMIT {
        items.join("; ")
    } else {
        format!(
            "{}; +{} more",
            items[..LIMIT].join("; "),
            items.len() - LIMIT
        )
    }
}

fn print_report(report: &Report) {
    println!(
        "{} {}",
        ui::bold("Minflair doctor"),
        report.minflair_version
    );
    if let Some(repo) = &report.repo {
        println!("{} {}", ui::dim("repo:"), repo);
    }
    if let Some(version) = &report.config_version {
        println!("{} {}", ui::dim("config:"), version);
    }
    println!();

    for check in &report.checks {
        let tag = match check.status {
            Status::Ok => ui::green("[ok]"),
            Status::Warn => ui::yellow("[warn]"),
            Status::Fail => ui::red("[fail]"),
        };
        println!("{} {:<18} {}", tag, check.name, check.detail);
    }

    println!();
    let summary = format!(
        "{} ok, {} warning(s), {} failure(s)",
        report.summary.ok, report.summary.warnings, report.summary.failures
    );
    if report.summary.failures > 0 {
        println!("{}", ui::red(&summary));
    } else if report.summary.warnings > 0 {
        println!("{}", ui::yellow(&summary));
    } else {
        println!("{}", ui::green(&summary));
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn summarize_limits_long_lists() {
        let items: Vec<String> = (0..5).map(|index| format!("item-{index}")).collect();
        assert_eq!(summarize(&items), "item-0; item-1; item-2; +2 more");
    }

    #[test]
    fn summarize_keeps_short_lists_intact() {
        let items = vec!["one".to_string(), "two".to_string()];
        assert_eq!(summarize(&items), "one; two");
    }

    #[test]
    fn matching_versions_are_ok() {
        let check = check_version(env!("CARGO_PKG_VERSION"));
        assert_eq!(check.status, Status::Ok);
        assert!(check.detail.contains("binary"));
        assert!(check.detail.contains("config"));
    }

    #[test]
    fn a_different_config_version_warns() {
        let check = check_version("0.0.1");
        assert_eq!(check.status, Status::Warn);
        assert!(check.detail.contains("0.0.1"));
        assert!(check.detail.contains("out of date"));
    }
}
