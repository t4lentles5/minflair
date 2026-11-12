use anyhow::{bail, Context, Result};
use std::collections::BTreeSet;
use std::env;
use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use crate::aur;
use crate::cli::InstallArgs;
use crate::manifest::Manifest;
use crate::prefs;
use crate::process;
use crate::repo;
use crate::selection::{self, Flags};
use crate::selector;
use crate::ui;

pub(crate) const GTK_THEME_URL: &str = "https://github.com/t4lentles5/material-gnome-theme.git";
pub(crate) const SDDM_THEME_URL: &str = "https://github.com/t4lentles5/tokyo-night-sddm.git";
pub(crate) const SDDM_THEME_DIR: &str = "/usr/share/sddm/themes/minflair-sddm";
const SERVICES: [&str; 3] = [
    "NetworkManager.service",
    "bluetooth.service",
    "power-profiles-daemon.service",
];

pub fn run(root: &Path, args: InstallArgs) -> Result<u8> {
    // SAFETY: geteuid has no preconditions and cannot fail.
    if unsafe { libc::geteuid() } == 0 {
        bail!("run minflair install as your normal user, not as root");
    }

    let version = repo::app_version(root).unwrap_or_else(|| "unknown".to_string());
    ui::header(&format!("Minflair installer {version}"));

    let manifest = Manifest::load(&root.join(repo::MANIFEST_REL))?;
    validate_manifest(root, &manifest)?;

    let home = repo::home_dir()?;
    let ctx = Ctx::new(root, &home, args.dry_run);

    if let Some(helper) = &args.aur_helper {
        if !aur::valid(helper) {
            bail!("--aur-helper must be yay or paru");
        }
    }

    // In dry-run mode all preference writes go to a temporary copy so the real
    // file is never touched, exactly like install.sh.
    let (prefs_path, dry_prefs) = prepare_prefs(args.dry_run)?;

    let mut disabled = prefs::load(&prefs_path)?;
    for warning in prefs::validate(&manifest, &disabled) {
        ctx.warn(&warning);
    }

    let flags = Flags {
        only: args.selection.only.clone(),
        include: args.selection.include.clone(),
        exclude: args.selection.exclude.clone(),
    };
    let has_flags = !flags.is_empty();
    disabled = selection::apply(&manifest, &disabled, &flags)?;
    if has_flags {
        prefs::save(&prefs_path, &disabled, &manifest)
            .context("could not save component preferences")?;
    }

    let Some(selected) = choose_components(
        &ctx,
        &manifest,
        &disabled,
        &prefs_path,
        &version,
        &args,
        has_flags,
    )?
    else {
        return Ok(0);
    };
    disabled = selected;

    ctx.section("Component selection");
    print_summary(&manifest, &disabled);
    if enabled(&manifest, &disabled, "zsh") {
        ctx.info("zsh will be set as your login shell.");
        if !enabled(&manifest, &disabled, "starship") {
            ctx.warn("Starship is disabled; zsh will use a basic prompt.");
        }
    }

    preflight(&ctx)?;

    ctx.section("Packages");
    let helper = resolve_aur_helper(&ctx, &args)?;
    install_packages(&ctx, &manifest, &disabled, &args, &helper);

    ctx.section("System integration");
    configure_ddc(&ctx, &manifest, &disabled);
    configure_battery(&ctx, &manifest, &disabled, args.no_packages, &helper);

    ctx.section("Dotfiles");
    backup_dotfiles(&ctx, &manifest, &disabled)?;
    copy_dotfiles(&ctx, &manifest, &disabled)?;

    ctx.section("Theme and desktop");
    configure_gtk(&ctx, &manifest, &disabled);
    configure_sddm(&ctx, &manifest, &disabled)?;
    configure_dunst(&ctx, &manifest, &disabled);
    configure_zsh(&ctx, &manifest, &disabled);

    if args.no_packages {
        ctx.info("Skipping Node.js installation (--no-packages).");
    } else if ctx.dry_run {
        println!("[dry-run] would install Node.js LTS with fnm");
    } else if process::which("fnm").is_some() {
        install_node(&ctx);
    } else {
        ctx.warn("fnm not found in PATH. Make sure ~/.local/bin is in your PATH and re-run.");
    }

    ctx.section("Services");
    configure_services(&ctx, &manifest, &disabled);

    run_reloads(&ctx, &manifest, &disabled);

    if ctx.dry_run {
        ui::done("Dry run complete. No files or packages were changed.");
        ui::info(&format!(
            "Preferences that would be used: {}",
            prefs_path.display()
        ));
        ctx.section("Selection preview");
        print_summary(&manifest, &disabled);
        drop(dry_prefs);
        return Ok(0);
    }

    ui::finish("Installation complete");
    ui::ok(&format!("Backup saved at: {}", ctx.backup_dir.display()));
    print_summary(&manifest, &disabled);
    ui::next_steps(&[
        "Reboot to apply every change.",
        "Add wallpapers and review docs/SETUP.md.",
        "Pull new changes and run ./update.sh when needed.",
    ]);
    println!();

    if args.selection.no_input {
        ctx.warn("Please remember to reboot later for all changes to take effect.");
    } else if ui::confirm("Reboot now?", false) {
        ctx.info("Rebooting system...");
        let _ = Command::new("sudo").arg("reboot").status();
    } else {
        ctx.warn("Please remember to reboot later for all changes to take effect.");
    }

    Ok(0)
}

/// Create the preferences file used by the pipeline.
///
/// Dry runs get a temporary copy so the real file is never modified. The
/// returned guard removes the copy on drop.
pub(crate) fn prepare_prefs(dry_run: bool) -> Result<(PathBuf, Option<TempFile>)> {
    let real_prefs = prefs::default_path()?;
    if !dry_run {
        return Ok((real_prefs, None));
    }

    let path = env::temp_dir().join(format!(
        "minflair-prefs-{}-{}.conf",
        std::process::id(),
        unique_suffix()
    ));
    fs::write(&path, "").with_context(|| format!("could not create {}", path.display()))?;
    if real_prefs.is_file() {
        fs::copy(&real_prefs, &path).with_context(|| {
            format!(
                "could not copy {} to {}",
                real_prefs.display(),
                path.display()
            )
        })?;
    }
    Ok((path.clone(), Some(TempFile(path))))
}

fn choose_components(
    ctx: &Ctx,
    manifest: &Manifest,
    disabled: &BTreeSet<String>,
    prefs_path: &Path,
    version: &str,
    args: &InstallArgs,
    has_flags: bool,
) -> Result<Option<BTreeSet<String>>> {
    if args.selection.no_input {
        ctx.info("Using saved component preferences.");
        return Ok(Some(disabled.clone()));
    }

    let interactive = selector::available();
    let wants_selector = args.selection.select || (!has_flags && interactive);

    if wants_selector {
        if !interactive {
            ctx.warn("--select needs an interactive terminal; using saved preferences.");
            return Ok(Some(disabled.clone()));
        }

        ctx.info("Choose the components you want to install.");
        match selector::run(manifest, disabled, version)? {
            Some(selected) => {
                prefs::save(prefs_path, &selected, manifest)
                    .context("could not save component preferences")?;
                ctx.ok(&format!("Selection saved to {}", prefs_path.display()));
                Ok(Some(selected))
            }
            None => {
                ctx.warn("Installation cancelled.");
                Ok(None)
            }
        }
    } else if has_flags {
        ctx.info("Using the selection from the command line.");
        Ok(Some(disabled.clone()))
    } else {
        ctx.warn("No interactive terminal detected; using saved preferences.");
        ctx.warn("Pass --exclude/--only to choose components non-interactively.");
        Ok(Some(disabled.clone()))
    }
}

pub(crate) fn validate_manifest(root: &Path, manifest: &Manifest) -> Result<()> {
    for component in manifest.components() {
        for relative in &component.paths {
            if !root.join(relative).exists() {
                bail!(
                    "invalid component manifest: {}: path does not exist: {relative}",
                    component.id
                );
            }
        }
    }

    for warning in manifest.validate(root) {
        if warning.contains("path does not exist") {
            bail!("invalid component manifest: {warning}");
        }
        ui::warn(&warning);
    }
    Ok(())
}

fn preflight(ctx: &Ctx) -> Result<()> {
    // The shell installer relies on these tools; keep the same guard so a
    // broken environment fails before anything is changed.
    for command in ["awk", "grep", "sed", "cut", "sort", "mktemp", "head"] {
        if process::which(command).is_none() {
            bail!("missing required command: {command}");
        }
    }

    if ctx.dry_run {
        ctx.info("Dry run: sudo and package changes are skipped.");
        return Ok(());
    }

    authenticate_sudo()
}

/// Ask for the sudo password once and keep the timestamp alive while long
/// package installations run.
pub(crate) fn authenticate_sudo() -> Result<()> {
    let status = Command::new("sudo")
        .arg("-v")
        .status()
        .context("could not run sudo")?;
    if !status.success() {
        bail!("sudo authentication failed");
    }

    thread::spawn(|| loop {
        thread::sleep(Duration::from_secs(60));
        let _ = Command::new("sudo")
            .args(["-n", "true"])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();
    });

    Ok(())
}

fn resolve_aur_helper(ctx: &Ctx, args: &InstallArgs) -> Result<String> {
    if let Some(helper) = &args.aur_helper {
        if ctx.dry_run {
            println!("[dry-run] would save AUR helper: {helper}");
        } else {
            aur::set(helper).context("could not save the AUR helper")?;
            ctx.info(&format!("AUR helper set to {helper}."));
        }
        return Ok(helper.clone());
    }

    if env::var_os("MINFLAIR_AUR_HELPER").is_some() {
        let helper = aur::current()?;
        ctx.info(&format!(
            "Using AUR helper from MINFLAIR_AUR_HELPER: {helper}."
        ));
        return Ok(helper);
    }

    if aur::path()?.is_file() {
        let helper = aur::current()?;
        ctx.info(&format!("Using saved AUR helper: {helper}."));
        return Ok(helper);
    }

    if args.no_packages || args.selection.no_input || !selector::available() {
        let helper = aur::current()?;
        if !ctx.dry_run {
            aur::set(&helper).context("could not save the AUR helper")?;
        }
        ctx.info(&format!("Using default AUR helper: {helper}."));
        return Ok(helper);
    }

    println!("\n  AUR helper\n  1) yay\n  2) paru");
    print!("  Choose [1/2] (default: 1): ");
    std::io::stdout()
        .flush()
        .context("could not flush stdout")?;
    let mut choice = String::new();
    std::io::stdin()
        .read_line(&mut choice)
        .context("could not read the AUR helper choice")?;
    let helper = match choice.trim() {
        "2" | "paru" | "PARU" => "paru",
        "1" | "yay" | "YAY" | "" => "yay",
        other => {
            ctx.warn(&format!("Invalid choice {other:?}; using yay."));
            "yay"
        }
    };

    if ctx.dry_run {
        println!("[dry-run] would save AUR helper: {helper}");
    } else {
        aur::set(helper).context("could not save the AUR helper")?;
        ctx.info(&format!("AUR helper set to {helper}."));
    }
    Ok(helper.to_string())
}

fn install_packages(
    ctx: &Ctx,
    manifest: &Manifest,
    disabled: &BTreeSet<String>,
    args: &InstallArgs,
    helper: &str,
) {
    if args.no_packages {
        ctx.warn("Skipping AUR helper and package installation (--no-packages).");
        return;
    }

    ctx.info(&format!("Installing {helper} (AUR helper)..."));
    if ctx.dry_run {
        println!("[dry-run] would install {helper} if it is missing");
    } else if !aur::installed(helper) {
        if !ctx.run(
            "sudo",
            &strs([
                "pacman",
                "-S",
                "--needed",
                "--noconfirm",
                "git",
                "base-devel",
            ]),
        ) {
            ctx.warn("Could not install git and base-devel.");
        }
        match temp_dir("minflair-aur") {
            Ok(temp) => {
                let destination = temp.path().join(helper);
                let destination_string = destination.to_string_lossy().to_string();
                let url = format!("https://aur.archlinux.org/{helper}.git");
                let cloned = ctx.run(
                    "git",
                    &strs(["clone", url.as_str(), destination_string.as_str()]),
                );
                if cloned && ctx.run_in("makepkg", &strs(["-si", "--noconfirm"]), &destination) {
                    ctx.ok(&format!("{helper} installed."));
                } else {
                    ctx.warn(&format!(
                        "Could not install {helper}; AUR packages will be skipped."
                    ));
                }
            }
            Err(error) => ctx.warn(&format!(
                "Could not create a temporary directory: {error:#}"
            )),
        }
    } else {
        ctx.ok(&format!("{helper} is already installed, skipping."));
    }

    let disabled_packages = manifest.disabled_packages(disabled);
    ctx.info("Installing dependencies from official repositories...");
    let dependencies = filtered_packages(&ctx.root.join(repo::PACKAGES_REL), &disabled_packages);
    if dependencies.is_empty() {
        ctx.warn("No official packages selected.");
    } else {
        let mut command = strs(["pacman", "-S", "--needed", "--noconfirm"]);
        command.extend(dependencies.iter().cloned());
        if ctx.run("sudo", &command) {
            ctx.ok("Official dependencies processed.");
        } else {
            ctx.warn("Some official packages could not be installed (check the messages above).");
        }
    }

    ctx.info(&format!("Installing AUR dependencies with {helper}..."));
    let aur_dependencies =
        filtered_packages(&ctx.root.join(repo::PACKAGES_AUR_REL), &disabled_packages);
    if aur_dependencies.is_empty() {
        ctx.warn("No AUR packages selected.");
    } else if ctx.dry_run || aur::installed(helper) {
        let mut command = strs(["-S", "--needed", "--noconfirm"]);
        command.extend(aur_dependencies.iter().cloned());
        if ctx.run(helper, &command) {
            ctx.ok("AUR dependencies processed.");
        } else {
            ctx.warn("Some AUR packages could not be installed (check the messages above).");
        }
    } else {
        ctx.warn(&format!(
            "{helper} is not installed; skipping AUR dependencies."
        ));
    }
}

pub(crate) fn configure_ddc(ctx: &Ctx, manifest: &Manifest, disabled: &BTreeSet<String>) {
    if !enabled(manifest, disabled, "ddc") {
        ctx.info("Skipping DDC/CI support (ddc component disabled).");
        return;
    }

    ctx.info("Configuring DDC/CI brightness support for external monitors...");
    if ctx.dry_run {
        println!(
            "[dry-run] would load i2c-dev and add {} to the i2c group",
            ctx.user
        );
        return;
    }

    if ctx.write_sudo_file("/etc/modules-load.d/i2c-dev.conf", "i2c-dev\n") {
        ctx.ok("i2c-dev will be loaded on boot.");
    } else {
        ctx.warn("Could not write /etc/modules-load.d/i2c-dev.conf.");
    }

    if ctx.run("sudo", &strs(["modprobe", "i2c-dev"])) {
        ctx.ok("i2c-dev loaded.");
    } else {
        ctx.warn("Could not load i2c-dev now; it will load after the reboot.");
    }

    if user_in_group("i2c") {
        ctx.ok(&format!("User {} is already in the i2c group.", ctx.user));
    } else {
        let group_added = ctx.run("sudo", &strs(["groupadd", "-f", "i2c"]));
        let user_added =
            group_added && ctx.run("sudo", &strs(["usermod", "-aG", "i2c", ctx.user.as_str()]));
        if user_added {
            ctx.ok(&format!(
                "User {} added to the i2c group (takes effect after logging out or rebooting).",
                ctx.user
            ));
        } else {
            ctx.warn(&format!("Could not add {} to the i2c group.", ctx.user));
        }
    }
}

pub(crate) fn configure_battery(
    ctx: &Ctx,
    manifest: &Manifest,
    disabled: &BTreeSet<String>,
    no_packages: bool,
    helper: &str,
) {
    if !enabled(manifest, disabled, "battery") {
        ctx.info("Skipping battery management (battery component disabled).");
        return;
    }

    let vendor = fs::read_to_string("/sys/class/dmi/id/sys_vendor")
        .unwrap_or_default()
        .trim()
        .to_string();
    let chassis = fs::read_to_string("/sys/class/dmi/id/chassis_type")
        .unwrap_or_default()
        .trim()
        .to_string();
    let laptop = matches!(
        chassis.as_str(),
        "8" | "9" | "10" | "14" | "30" | "31" | "32"
    ) || Path::new("/sys/class/power_supply/BAT0").exists()
        || Path::new("/sys/class/power_supply/BAT1").exists()
        || Path::new("/sys/class/power_supply/BAT").exists();

    if !laptop {
        ctx.info("No laptop battery detected, skipping battery management.");
        return;
    }

    let vendor_name = if vendor.is_empty() {
        "Generic".to_string()
    } else {
        vendor.clone()
    };
    ctx.info(&format!(
        "Laptop hardware detected ({vendor_name}). Configuring battery management..."
    ));

    if ctx.dry_run {
        println!("[dry-run] would configure battery management for {vendor_name}");
        return;
    }

    if no_packages {
        ctx.warn("Skipping vendor battery packages (--no-packages).");
    } else {
        let lower = vendor.to_lowercase();
        if lower.contains("acer") {
            ctx.info("Acer laptop detected. Installing linux-headers and acer-wmi-battery-dkms...");
            if !ctx.run(
                "sudo",
                &strs(["pacman", "-S", "--needed", "--noconfirm", "linux-headers"]),
            ) {
                ctx.warn("Could not install linux-headers.");
            }
            if !ctx.run(
                helper,
                &strs(["-S", "--needed", "--noconfirm", "acer-wmi-battery-dkms"]),
            ) {
                ctx.warn("Could not install acer-wmi-battery-dkms.");
            }
        }
        if lower.contains("dell") {
            ctx.info(
                "Dell laptop detected. Installing libsmbios for battery management support...",
            );
            if !ctx.run(
                "sudo",
                &strs(["pacman", "-S", "--needed", "--noconfirm", "libsmbios"]),
            ) {
                ctx.warn("Could not install libsmbios.");
            }
        }
    }

    ctx.info("Configuring sudoers for battery charge limit script...");
    let rule = battery_sudoers_rule(&ctx.user, &ctx.home);
    if ctx.write_sudo_file("/etc/sudoers.d/quickshell-battery", &rule) {
        ctx.ok("Battery charge limit support and sudoers configured.");
    } else {
        ctx.warn("Could not configure the battery sudoers rule.");
    }
}

/// Build the sudoers rule that lets the battery script run without a
/// password. The command path is quoted so a home directory with a space
/// still produces a valid rule; an unquoted path breaks the rule and sudo
/// then refuses to run for every user on the machine.
fn battery_sudoers_rule(user: &str, home: &Path) -> String {
    let script = home.join(".config/quickshell/Scripts/system/toggle_battery_limit.sh");
    format!("{user} ALL=(ALL) NOPASSWD: \"{}\"\n", script.display())
}

fn backup_dotfiles(ctx: &Ctx, manifest: &Manifest, disabled: &BTreeSet<String>) -> Result<()> {
    ctx.info(&format!(
        "Backing up existing dotfiles to {} ...",
        ctx.backup_dir.display()
    ));
    if !ctx.dry_run {
        fs::create_dir_all(&ctx.backup_dir)
            .with_context(|| format!("could not create {}", ctx.backup_dir.display()))?;
    }

    backup_enabled_paths(ctx, manifest, disabled)?;
    ctx.ok("Enabled component files backed up.");
    Ok(())
}

pub(crate) fn backup_enabled_paths(
    ctx: &Ctx,
    manifest: &Manifest,
    disabled: &BTreeSet<String>,
) -> Result<()> {
    for relative in enabled_paths(manifest, disabled) {
        let Some(destination) = destination_for(&ctx.home, &relative) else {
            continue;
        };
        let Some(backup) = backup_for(&ctx.backup_dir, &relative) else {
            continue;
        };
        if !destination.exists() {
            continue;
        }

        if ctx.dry_run {
            println!(
                "[dry-run] would back up {} -> {}",
                destination.display(),
                backup.display()
            );
        } else {
            if let Some(parent) = backup.parent() {
                fs::create_dir_all(parent)
                    .with_context(|| format!("could not create {}", parent.display()))?;
            }
            let destination_string = destination.to_string_lossy().to_string();
            let backup_string = backup.to_string_lossy().to_string();
            ctx.run_checked(
                "cp",
                &strs(["-a", destination_string.as_str(), backup_string.as_str()]),
            )?;
        }
    }

    Ok(())
}

fn copy_dotfiles(ctx: &Ctx, manifest: &Manifest, disabled: &BTreeSet<String>) -> Result<()> {
    ctx.info("Copying enabled components to ~/.config and ~/ ...");
    copy_enabled_paths(ctx, manifest, disabled)?;
    ctx.ok("Enabled component files copied.");
    Ok(())
}

pub(crate) fn copy_enabled_paths(
    ctx: &Ctx,
    manifest: &Manifest,
    disabled: &BTreeSet<String>,
) -> Result<()> {
    for relative in enabled_paths(manifest, disabled) {
        let source = ctx.root.join(&relative);
        if relative.starts_with("config/") {
            if ctx.dry_run {
                println!(
                    "[dry-run] would copy {} -> {}/.config/",
                    relative,
                    ctx.home.display()
                );
            } else {
                let config_dir = ctx.home.join(".config");
                fs::create_dir_all(&config_dir)
                    .with_context(|| format!("could not create {}", config_dir.display()))?;
                let source_string = source.to_string_lossy().to_string();
                let config_string = config_dir.to_string_lossy().to_string();
                ctx.run_checked(
                    "cp",
                    &strs(["-a", source_string.as_str(), config_string.as_str()]),
                )?;
            }
        } else if relative.starts_with("home/") {
            if ctx.dry_run {
                println!(
                    "[dry-run] would copy {} -> {}/",
                    relative,
                    ctx.home.display()
                );
            } else {
                let source_string = source.to_string_lossy().to_string();
                let home_string = ctx.home.to_string_lossy().to_string();
                ctx.run_checked(
                    "cp",
                    &strs(["-a", source_string.as_str(), home_string.as_str()]),
                )?;
            }
        }
    }
    Ok(())
}

fn configure_gtk(ctx: &Ctx, manifest: &Manifest, disabled: &BTreeSet<String>) {
    if !enabled(manifest, disabled, "gtk") {
        ctx.info("Skipping GTK theme (gtk component disabled).");
        return;
    }

    let theme_dir = env::var_os("MINFLAIR_GTK_THEME_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|| ctx.home.join(".themes/Material-Gnome"));
    let theme_url =
        env::var("MINFLAIR_GTK_THEME_URL").unwrap_or_else(|_| GTK_THEME_URL.to_string());

    ctx.info("Installing Material-Gnome theme...");
    if gtk_theme_valid(&theme_dir) {
        ctx.ok("Material-Gnome theme is ready.");
    } else if ctx.dry_run {
        println!(
            "[dry-run] would install Material-Gnome into {}",
            theme_dir.display()
        );
    } else if install_gtk_theme(ctx, &theme_dir, &theme_url) {
        ctx.ok("Material-Gnome theme is ready.");
    } else {
        ctx.warn("Could not install the Material-Gnome theme; GTK colors may not apply.");
    }

    ctx.info("Applying GTK theme...");
    let settings = ctx.home.join(".config/gtk-3.0/settings.ini");
    let Ok(content) = fs::read_to_string(&settings) else {
        ctx.warn("gtk-3.0/settings.ini not found, skipping gsettings.");
        return;
    };

    let schema = "org.gnome.desktop.interface";
    for (ini_key, gsettings_key) in [
        ("gtk-theme-name", "gtk-theme"),
        ("gtk-icon-theme-name", "icon-theme"),
        ("gtk-cursor-theme-name", "cursor-theme"),
        ("gtk-font-name", "font-name"),
    ] {
        if let Some(value) = ini_value(&content, ini_key) {
            if !value.is_empty() {
                let _ = ctx.run_quiet("gsettings", &strs(["set", schema, gsettings_key, &value]));
            }
        }
    }

    let color_scheme = ini_value(&content, "gtk-application-prefer-dark-theme")
        .filter(|value| value == "1")
        .map(|_| "prefer-dark")
        .unwrap_or("default");
    let _ = ctx.run_quiet(
        "gsettings",
        &strs(["set", schema, "color-scheme", color_scheme]),
    );
    ctx.ok("GTK theme applied via gsettings.");
}

pub(crate) fn install_gtk_theme(ctx: &Ctx, theme_dir: &Path, theme_url: &str) -> bool {
    let Some(parent) = theme_dir.parent() else {
        return false;
    };
    if fs::create_dir_all(parent).is_err() {
        return false;
    }

    let prefix = format!(
        "{}.tmp",
        theme_dir.file_name().unwrap_or_default().to_string_lossy()
    );
    let Ok(temp) = temp_dir_in(parent, &prefix) else {
        return false;
    };
    let clone_target = temp.path().join("theme");
    let clone_target_string = clone_target.to_string_lossy().to_string();
    if !ctx.run(
        "git",
        &strs([
            "clone",
            "--depth",
            "1",
            theme_url,
            clone_target_string.as_str(),
        ]),
    ) {
        return false;
    }

    // The old theme is moved aside instead of being deleted, so it can be
    // restored when the new one cannot be put in place.
    let backup = theme_dir.with_extension("minflair-old");
    if backup.exists() {
        let _ = fs::remove_dir_all(&backup);
    }
    let had_previous = theme_dir.exists();
    if had_previous && fs::rename(theme_dir, &backup).is_err() {
        // Without the backup there is no safe way to replace the theme.
        return false;
    }

    match fs::rename(&clone_target, theme_dir) {
        Ok(()) => {
            if had_previous {
                let _ = fs::remove_dir_all(&backup);
            }
            true
        }
        Err(_) => {
            if had_previous {
                let _ = fs::rename(&backup, theme_dir);
            }
            false
        }
    }
}

fn configure_sddm(ctx: &Ctx, manifest: &Manifest, disabled: &BTreeSet<String>) -> Result<()> {
    if !enabled(manifest, disabled, "sddm") {
        ctx.info("Skipping SDDM theme (sddm component disabled).");
        return Ok(());
    }

    if ctx.dry_run {
        println!("[dry-run] would install the SDDM theme in {SDDM_THEME_DIR}");
        println!("[dry-run] would write /etc/sddm.conf");
        return Ok(());
    }

    ctx.info("Configuring SDDM theme...");
    let theme_dir = Path::new(SDDM_THEME_DIR);
    if !theme_dir.is_dir() {
        ctx.run("sudo", &strs(["mkdir", "-p", "/usr/share/sddm/themes"]));
        if ctx.run(
            "sudo",
            &strs([
                "git",
                "clone",
                "--depth",
                "1",
                SDDM_THEME_URL,
                SDDM_THEME_DIR,
            ]),
        ) {
            ctx.ok("SDDM theme (minflair-sddm) installed.");
        } else {
            ctx.warn("Failed to clone SDDM theme.");
        }
    } else if theme_dir.join(".git").is_dir() {
        let _ = ctx.run(
            "sudo",
            &strs([
                "git",
                "-C",
                SDDM_THEME_DIR,
                "remote",
                "set-url",
                "origin",
                SDDM_THEME_URL,
            ]),
        );
        if ctx.run(
            "sudo",
            &strs(["git", "-C", SDDM_THEME_DIR, "pull", "--ff-only"]),
        ) {
            ctx.ok("SDDM theme (minflair-sddm) updated.");
        } else {
            ctx.ok("SDDM theme (minflair-sddm) already up to date.");
        }
    } else {
        ctx.run("sudo", &strs(["rm", "-rf", SDDM_THEME_DIR]));
        if ctx.run(
            "sudo",
            &strs([
                "git",
                "clone",
                "--depth",
                "1",
                SDDM_THEME_URL,
                SDDM_THEME_DIR,
            ]),
        ) {
            ctx.ok("SDDM theme (minflair-sddm) reinstalled.");
        } else {
            ctx.warn("Failed to clone SDDM theme.");
        }
    }

    if !theme_dir.join("theme.conf").is_file() {
        ctx.warn("SDDM theme files are missing; keeping the current /etc/sddm.conf.");
        return Ok(());
    }

    let repo_config = ctx.root.join("etc/sddm.conf");
    if !repo_config.is_file() {
        ctx.warn("etc/sddm.conf not found in repo, skipping SDDM config.");
        return Ok(());
    }

    let system_config = Path::new("/etc/sddm.conf");
    if system_config.is_file() {
        let backup = ctx.backup_dir.join("sddm.conf.bak");
        fs::copy(system_config, &backup)
            .with_context(|| format!("could not back up {}", system_config.display()))?;
        ctx.ok("Existing /etc/sddm.conf backed up.");
    }

    let repo_config_string = repo_config.to_string_lossy().to_string();
    if ctx.run(
        "sudo",
        &strs(["cp", repo_config_string.as_str(), "/etc/sddm.conf"]),
    ) {
        ctx.ok("SDDM theme set to minflair-sddm.");
    } else {
        ctx.warn("Could not write /etc/sddm.conf.");
    }
    Ok(())
}

fn configure_dunst(ctx: &Ctx, manifest: &Manifest, disabled: &BTreeSet<String>) {
    if !enabled(manifest, disabled, "dunst") {
        ctx.info("Skipping dunst configuration (dunst component disabled).");
        return;
    }

    if ctx.dry_run {
        println!("[dry-run] would mask dunst and disable its D-Bus activation");
        return;
    }

    if process::which("dunst").is_none() {
        ctx.ok("dunst is not installed, no conflicts.");
        return;
    }

    ctx.info("Disabling dunst (notifications are managed by QuickShell)...");
    if Command::new("killall")
        .arg("dunst")
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|status| status.success())
        .unwrap_or(false)
    {
        ctx.ok("Stopped running dunst process.");
    }

    if Command::new("systemctl")
        .args(["--user", "mask", "dunst.service"])
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status()
        .map(|status| status.success())
        .unwrap_or(false)
    {
        ctx.ok("dunst.service masked.");
    } else {
        ctx.warn("Could not mask dunst.service (may not exist as a systemd service).");
    }

    let dbus_service = Path::new("/usr/share/dbus-1/services/org.knopwob.dunst.service");
    if dbus_service.is_file() {
        let dbus_string = dbus_service.to_string_lossy().to_string();
        let disabled_path = format!("{dbus_string}.disabled");
        if ctx.run(
            "sudo",
            &strs(["mv", dbus_string.as_str(), disabled_path.as_str()]),
        ) {
            ctx.ok("dunst D-Bus activation disabled.");
        }
    }

    ctx.ok("dunst disabled - QuickShell will handle notifications.");
}

pub(crate) fn configure_zsh(ctx: &Ctx, manifest: &Manifest, disabled: &BTreeSet<String>) {
    if !enabled(manifest, disabled, "zsh") {
        ctx.info("Skipping zsh login shell (zsh component disabled).");
        return;
    }

    ctx.info("Setting zsh as the default shell...");
    if ensure_zsh_login_shell(ctx) {
        ctx.ok("zsh is the default shell.");
    } else {
        let zsh = process::which("zsh")
            .map(|path| path.to_string_lossy().to_string())
            .unwrap_or_else(|| "zsh".to_string());
        ctx.warn(&format!(
            "Could not set zsh as the default shell. Run: sudo chsh -s {zsh} {}",
            ctx.user
        ));
    }
}

fn ensure_zsh_login_shell(ctx: &Ctx) -> bool {
    let Some(zsh_path) = process::which("zsh") else {
        ctx.warn("zsh is not installed; skipping the login shell change.");
        return false;
    };

    let current = process::output("getent", &["passwd", ctx.user.as_str()])
        .and_then(|output| {
            String::from_utf8_lossy(&output.stdout)
                .lines()
                .next()
                .and_then(|line| line.split(':').nth(6).map(str::to_string))
        })
        .or_else(|| env::var("SHELL").ok())
        .unwrap_or_default();

    if Path::new(&current)
        .file_name()
        .map(|name| name == "zsh")
        .unwrap_or(false)
    {
        return true;
    }

    if ctx.dry_run {
        println!(
            "[dry-run] would run sudo chsh -s {} {}",
            zsh_path.display(),
            ctx.user
        );
        return true;
    }

    let zsh_string = zsh_path.to_string_lossy().to_string();
    ctx.run(
        "sudo",
        &strs(["chsh", "-s", zsh_string.as_str(), ctx.user.as_str()]),
    )
}

pub(crate) fn install_node(ctx: &Ctx) {
    ctx.info("Installing Node.js LTS with fnm...");
    let fnm_dir = env::var_os("FNM_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|| ctx.home.join(".local/share/fnm"));

    let script = "eval \"$(fnm env)\" && fnm install --lts && fnm use lts-latest";
    let status = Command::new("bash")
        .arg("-c")
        .arg(script)
        .env("FNM_DIR", &fnm_dir)
        .status();

    if !status.map(|status| status.success()).unwrap_or(false) {
        ctx.warn("Could not install Node.js LTS with fnm.");
        return;
    }

    let version = Command::new("bash")
        .arg("-c")
        .arg("eval \"$(fnm env)\" && node --version")
        .env("FNM_DIR", &fnm_dir)
        .output()
        .ok()
        .map(|output| String::from_utf8_lossy(&output.stdout).trim().to_string())
        .filter(|version| !version.is_empty())
        .unwrap_or_else(|| "restart your terminal to activate it".to_string());
    ctx.ok(&format!("Node.js LTS installed: {version}"));
}

pub(crate) fn configure_services(ctx: &Ctx, manifest: &Manifest, disabled: &BTreeSet<String>) {
    if !enabled(manifest, disabled, "services") {
        ctx.info("Skipping system services (services component disabled).");
        return;
    }

    ctx.info("Checking and enabling system services (NetworkManager, bluetooth, power-profiles-daemon)...");
    for service in SERVICES {
        let enabled = service_enabled(service);
        let active = service_active(service);
        if !enabled || !active {
            ctx.info(&format!("Enabling and starting {service}..."));
            if !ctx.run("sudo", &strs(["systemctl", "enable", "--now", service])) {
                ctx.warn(&format!("Failed to enable {service}."));
            }
        } else {
            ctx.ok(&format!("{service} is already enabled and running."));
        }
    }
}

pub(crate) fn run_reloads(ctx: &Ctx, manifest: &Manifest, disabled: &BTreeSet<String>) {
    for component in manifest.components() {
        if component.core || disabled.contains(&component.id) || component.reload.is_empty() {
            continue;
        }

        if ctx.dry_run {
            println!("[dry-run] reload: {}", component.reload);
        } else {
            let _ = Command::new("bash")
                .arg("-c")
                .arg(&component.reload)
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status();
        }
    }
}

pub(crate) fn print_summary(manifest: &Manifest, disabled: &BTreeSet<String>) {
    let included = summary_groups(manifest, disabled, true);
    let skipped = summary_groups(manifest, disabled, false);
    let included_count: usize = included.iter().map(|(_, labels)| labels.len()).sum();
    let skipped_count: usize = skipped.iter().map(|(_, labels)| labels.len()).sum();

    if included_count == 0 {
        println!("  {}", ui::dim("Enabled (0): none"));
    } else {
        println!(
            "  {}",
            ui::green(&ui::bold(&format!("Enabled ({included_count}):")))
        );
        print_summary_groups(&included);
    }

    if skipped_count == 0 {
        println!("  {}", ui::dim("Skipped (0): none"));
    } else {
        println!(
            "  {}",
            ui::yellow(&ui::bold(&format!("Skipped ({skipped_count}):")))
        );
        print_summary_groups(&skipped);
        println!(
            "  {}",
            ui::dim("Skipped components keep their existing files.")
        );
    }
}

/// Group the labels of the enabled or skipped components by category,
/// preserving the manifest order.
fn summary_groups<'a>(
    manifest: &'a Manifest,
    disabled: &BTreeSet<String>,
    include_enabled: bool,
) -> Vec<(&'a str, Vec<&'a str>)> {
    let mut groups: Vec<(&str, Vec<&str>)> = Vec::new();
    for component in manifest.components() {
        let enabled = component.core || !disabled.contains(&component.id);
        if enabled != include_enabled {
            continue;
        }
        if let Some((_, labels)) = groups
            .iter_mut()
            .find(|(category, _)| *category == component.category)
        {
            labels.push(&component.label);
        } else {
            groups.push((&component.category, vec![&component.label]));
        }
    }
    groups
}

fn print_summary_groups(groups: &[(&str, Vec<&str>)]) {
    for (category, labels) in groups {
        ui::print_labeled(
            "    ",
            crate::manifest::category_label(category),
            &labels.join(", "),
            12,
        );
    }
}

pub(crate) fn enabled(manifest: &Manifest, disabled: &BTreeSet<String>, id: &str) -> bool {
    manifest.is_enabled(id, disabled).unwrap_or(false)
}

fn enabled_paths(manifest: &Manifest, disabled: &BTreeSet<String>) -> Vec<String> {
    manifest
        .components()
        .iter()
        .filter(|component| component.core || !disabled.contains(&component.id))
        .flat_map(|component| component.paths.iter().cloned())
        .collect()
}

fn destination_for(home: &Path, relative: &str) -> Option<PathBuf> {
    if let Some(rest) = relative.strip_prefix("config/") {
        Some(home.join(".config").join(rest))
    } else {
        relative.strip_prefix("home/").map(|rest| home.join(rest))
    }
}

fn backup_for(backup: &Path, relative: &str) -> Option<PathBuf> {
    if let Some(rest) = relative.strip_prefix("config/") {
        Some(backup.join("config").join(rest))
    } else {
        relative
            .strip_prefix("home/")
            .map(|rest| backup.join("home").join(rest))
    }
}

pub(crate) fn filtered_packages(path: &Path, disabled: &BTreeSet<String>) -> Vec<String> {
    let Ok(content) = fs::read_to_string(path) else {
        return Vec::new();
    };

    content
        .lines()
        .map(str::trim)
        .filter(|line| !line.is_empty() && !line.starts_with('#'))
        .map(|line| line.split_whitespace().collect::<String>())
        .filter(|package| !package.is_empty() && !disabled.contains(package))
        .collect()
}

pub(crate) fn gtk_theme_valid(theme_dir: &Path) -> bool {
    gtk_css_valid(&theme_dir.join("gtk-3.0/gtk.css"))
        && gtk_css_valid(&theme_dir.join("gtk-4.0/gtk.css"))
        && gtk_css_valid(&theme_dir.join("gtk-4.0/gtk-dark.css"))
}

fn gtk_css_valid(path: &Path) -> bool {
    let Ok(metadata) = fs::metadata(path) else {
        return false;
    };
    if metadata.len() <= 1024 {
        return false;
    }
    fs::read_to_string(path)
        .map(|content| content.contains("colors.css"))
        .unwrap_or(false)
}

fn ini_value(content: &str, key: &str) -> Option<String> {
    content.lines().find_map(|line| {
        let (name, value) = line.split_once('=')?;
        (name.trim() == key).then(|| value.trim().to_string())
    })
}

fn service_enabled(service: &str) -> bool {
    Command::new("systemctl")
        .args(["is-enabled", "--quiet", service])
        .status()
        .map(|status| status.success())
        .unwrap_or(false)
}

fn service_active(service: &str) -> bool {
    Command::new("systemctl")
        .args(["is-active", "--quiet", service])
        .status()
        .map(|status| status.success())
        .unwrap_or(false)
}

pub(crate) fn current_user() -> String {
    env::var("USER")
        .or_else(|_| env::var("LOGNAME"))
        .unwrap_or_else(|_| {
            process::output("id", &["-un"])
                .map(|output| String::from_utf8_lossy(&output.stdout).trim().to_string())
                .unwrap_or_else(|| "user".to_string())
        })
}

fn user_in_group(group: &str) -> bool {
    process::output("id", &["-nG"])
        .map(|output| {
            String::from_utf8_lossy(&output.stdout)
                .split_whitespace()
                .any(|name| name == group)
        })
        .unwrap_or(false)
}

pub(crate) fn error_log_path(home: &Path, dry_run: bool) -> Option<PathBuf> {
    if dry_run {
        // A dry run must not change any files, even a log file.
        return None;
    }
    let path = home.join("install_errors.log");
    let _ = fs::write(&path, "");
    Some(path)
}

pub(crate) fn timestamp() -> String {
    let now = unsafe { libc::time(std::ptr::null_mut()) };
    let mut value: libc::tm = unsafe { std::mem::zeroed() };
    // SAFETY: `now` and `value` are valid pointers for the duration of the call.
    unsafe { libc::localtime_r(&now, &mut value) };
    format!(
        "{:04}{:02}{:02}_{:02}{:02}{:02}",
        value.tm_year + 1900,
        value.tm_mon + 1,
        value.tm_mday,
        value.tm_hour,
        value.tm_min,
        value.tm_sec
    )
}

pub(crate) fn unique_suffix() -> u128 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_nanos())
        .unwrap_or(0)
}

pub(crate) fn strs<const N: usize>(values: [&str; N]) -> Vec<String> {
    values.into_iter().map(str::to_string).collect()
}

pub(crate) struct TempFile(PathBuf);

impl Drop for TempFile {
    fn drop(&mut self) {
        let _ = fs::remove_file(&self.0);
    }
}

pub(crate) struct TempDir(PathBuf);

impl TempDir {
    pub(crate) fn path(&self) -> &Path {
        &self.0
    }
}

impl Drop for TempDir {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.0);
    }
}

pub(crate) fn temp_dir(prefix: &str) -> Result<TempDir> {
    temp_dir_in(&env::temp_dir(), prefix)
}

fn temp_dir_in(parent: &Path, prefix: &str) -> Result<TempDir> {
    let path = parent.join(format!(
        "{prefix}-{}-{}",
        std::process::id(),
        unique_suffix()
    ));
    fs::create_dir_all(&path).with_context(|| format!("could not create {}", path.display()))?;
    Ok(TempDir(path))
}

pub(crate) struct Ctx {
    pub(crate) root: PathBuf,
    pub(crate) home: PathBuf,
    pub(crate) user: String,
    pub(crate) backup_dir: PathBuf,
    pub(crate) dry_run: bool,
    error_log: Option<PathBuf>,
}

impl Ctx {
    pub(crate) fn new(root: &Path, home: &Path, dry_run: bool) -> Self {
        Self {
            root: root.to_path_buf(),
            home: home.to_path_buf(),
            user: current_user(),
            backup_dir: home.join(".minflair_backup").join(timestamp()),
            dry_run,
            error_log: error_log_path(home, dry_run),
        }
    }

    pub(crate) fn info(&self, message: &str) {
        ui::info(message);
    }

    pub(crate) fn ok(&self, message: &str) {
        ui::ok(message);
    }

    pub(crate) fn warn(&self, message: &str) {
        ui::warn(message);
        self.log(message);
    }

    pub(crate) fn section(&self, title: &str) {
        ui::section(title);
    }

    fn log(&self, message: &str) {
        let Some(path) = &self.error_log else {
            return;
        };
        if let Ok(mut file) = fs::OpenOptions::new().append(true).create(true).open(path) {
            let _ = writeln!(file, "{message}");
        }
    }

    pub(crate) fn run(&self, program: &str, args: &[String]) -> bool {
        if self.dry_run {
            println!("[dry-run] {}", ui::command_line(program, args));
            return true;
        }
        self.execute(program, args, None)
    }

    pub(crate) fn run_in(&self, program: &str, args: &[String], cwd: &Path) -> bool {
        if self.dry_run {
            println!(
                "[dry-run] (cd {} && {})",
                cwd.display(),
                ui::command_line(program, args)
            );
            return true;
        }
        self.execute(program, args, Some(cwd))
    }

    pub(crate) fn run_quiet(&self, program: &str, args: &[String]) -> bool {
        if self.dry_run {
            println!("[dry-run] {}", ui::command_line(program, args));
            return true;
        }
        Command::new(program)
            .args(args)
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .map(|status| status.success())
            .unwrap_or(false)
    }

    pub(crate) fn run_checked(&self, program: &str, args: &[String]) -> Result<()> {
        if self.dry_run {
            println!("[dry-run] {}", ui::command_line(program, args));
            return Ok(());
        }
        let status = Command::new(program)
            .args(args)
            .status()
            .with_context(|| format!("could not run {program}"))?;
        if !status.success() {
            bail!("{program} failed with {status}");
        }
        Ok(())
    }

    pub(crate) fn execute(&self, program: &str, args: &[String], cwd: Option<&Path>) -> bool {
        let mut command = Command::new(program);
        command.args(args);
        if let Some(cwd) = cwd {
            command.current_dir(cwd);
        }
        match command.status() {
            Ok(status) => status.success(),
            Err(error) => {
                self.warn(&format!("could not run {program}: {error}"));
                false
            }
        }
    }

    /// Write a file that root owns, atomically.
    ///
    /// The contents go to a temporary file first and are only moved into
    /// place once they are complete. Writing straight to the destination
    /// truncates it before the data arrives, so a failure in the middle
    /// would leave a half written file behind. That matters for the files
    /// under /etc, where a broken sudoers rule locks every user out of
    /// sudo.
    pub(crate) fn write_sudo_file(&self, path: &str, contents: &str) -> bool {
        if self.dry_run {
            println!("[dry-run] would write {path}");
            return true;
        }

        let target = Path::new(path);
        let temporary = match target.file_name() {
            Some(name) => {
                target.with_file_name(format!(".{}.minflair-new", name.to_string_lossy()))
            }
            None => {
                self.warn(&format!("could not write {path}: invalid path"));
                return false;
            }
        };

        let mut child = match Command::new("sudo")
            .args(["tee", temporary.to_string_lossy().as_ref()])
            .stdin(Stdio::piped())
            .stdout(Stdio::null())
            .spawn()
        {
            Ok(child) => child,
            Err(error) => {
                self.warn(&format!("could not run sudo tee {path}: {error}"));
                return false;
            }
        };

        let written = match child.stdin.as_mut() {
            Some(stdin) => stdin.write_all(contents.as_bytes()).is_ok(),
            None => false,
        };
        // Dropping stdin closes the pipe so tee can finish and exit.
        drop(child.stdin.take());

        if !written {
            let _ = child.wait();
            let _ = Command::new("sudo")
                .args(["rm", "-f", temporary.to_string_lossy().as_ref()])
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status();
            self.warn(&format!("could not write {path}: the write failed"));
            return false;
        }

        if !child.wait().map(|status| status.success()).unwrap_or(false) {
            let _ = Command::new("sudo")
                .args(["rm", "-f", temporary.to_string_lossy().as_ref()])
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status();
            self.warn(&format!("could not write {path}"));
            return false;
        }

        // The mode is set on the temporary file, so the file is never
        // readable by other users even for an instant.
        let mode = if path.starts_with("/etc/sudoers.d/") {
            "0440"
        } else {
            "0644"
        };
        if !Command::new("sudo")
            .args(["chmod", mode, temporary.to_string_lossy().as_ref()])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .map(|status| status.success())
            .unwrap_or(false)
        {
            let _ = Command::new("sudo")
                .args(["rm", "-f", temporary.to_string_lossy().as_ref()])
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status();
            self.warn(&format!("could not set the permissions of {path}"));
            return false;
        }

        let moved = Command::new("sudo")
            .args(["mv", "-f", temporary.to_string_lossy().as_ref(), path])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status()
            .map(|status| status.success())
            .unwrap_or(false);

        if !moved {
            let _ = Command::new("sudo")
                .args(["rm", "-f", temporary.to_string_lossy().as_ref()])
                .stdout(Stdio::null())
                .stderr(Stdio::null())
                .status();
            self.warn(&format!("could not move the new file into {path}"));
        }

        moved
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn filters_disabled_packages_and_comments() {
        let directory = tempfile::tempdir().expect("tempdir");
        let packages = directory.path().join("packages.txt");
        fs::write(&packages, "# comment\nkitty\nnvim\n\n  btop  \n").expect("write");

        let disabled: BTreeSet<String> = ["nvim".to_string()].into_iter().collect();
        let filtered = filtered_packages(&packages, &disabled);
        assert_eq!(filtered, vec!["kitty", "btop"]);
    }

    #[test]
    fn the_sudoers_rule_quotes_the_script_path() {
        let rule = battery_sudoers_rule("octo", Path::new("/home/john doe"));
        assert_eq!(
            rule,
            "octo ALL=(ALL) NOPASSWD: \"/home/john doe/.config/quickshell/Scripts/system/toggle_battery_limit.sh\"\n"
        );
    }

    #[test]
    fn the_sudoers_rule_is_a_single_command() {
        // An unquoted path with a space is parsed by sudo as the command
        // "/home/john" plus the argument "doe/...", which is not the script.
        let rule = battery_sudoers_rule("octo", Path::new("/home/john doe"));
        let command = rule.split("NOPASSWD: ").nth(1).expect("command");
        let command = command.trim().trim_matches('"');
        assert_eq!(
            command,
            "/home/john doe/.config/quickshell/Scripts/system/toggle_battery_limit.sh"
        );
    }

    #[test]
    fn groups_the_summary_by_category() {
        let manifest = Manifest::parse(
            "id\tlabel\tcategory\tcore\tpaths\tpackages\ttheme\tfont\treload\tdescription\n\
             quickshell\tQuickshell shell\tcore\t1\tconfig/quickshell\tquickshell\t\t\t\tCore shell\n\
             kitty\tKitty terminal\tterminal\t0\tconfig/kitty\tkitty\tkitty\tkitty\t\tTerminal\n\
             nvim\tNeovim\tterminal\t0\tconfig/nvim\tnvim\tnvim\t\t\tEditor\n",
        )
        .expect("manifest");
        let disabled: BTreeSet<String> = ["nvim".to_string()].into_iter().collect();

        assert_eq!(
            summary_groups(&manifest, &disabled, true),
            vec![
                ("core", vec!["Quickshell shell"]),
                ("terminal", vec!["Kitty terminal"]),
            ]
        );
        assert_eq!(
            summary_groups(&manifest, &disabled, false),
            vec![("terminal", vec!["Neovim"])]
        );
    }

    #[test]
    fn maps_component_paths_to_home_and_backup() {
        let home = Path::new("/home/user");
        let backup = Path::new("/home/user/.minflair_backup/20260101_000000");

        assert_eq!(
            destination_for(home, "config/kitty"),
            Some(PathBuf::from("/home/user/.config/kitty"))
        );
        assert_eq!(
            destination_for(home, "home/.zshrc"),
            Some(PathBuf::from("/home/user/.zshrc"))
        );
        assert_eq!(
            backup_for(backup, "config/kitty"),
            Some(PathBuf::from(
                "/home/user/.minflair_backup/20260101_000000/config/kitty"
            ))
        );
        assert_eq!(destination_for(home, "etc/sddm.conf"), None);
    }

    #[test]
    fn reads_ini_values() {
        let content =
            "[Settings]\ngtk-theme-name=Material-Gnome\ngtk-application-prefer-dark-theme=1\n";
        assert_eq!(
            ini_value(content, "gtk-theme-name"),
            Some("Material-Gnome".to_string())
        );
        assert_eq!(
            ini_value(content, "gtk-application-prefer-dark-theme"),
            Some("1".to_string())
        );
        assert_eq!(ini_value(content, "missing"), None);
    }

    #[test]
    fn rejects_short_gtk_css_files() {
        let directory = tempfile::tempdir().expect("tempdir");
        let css = directory.path().join("gtk.css");
        fs::write(&css, "/* colors.css */\n").expect("write");
        assert!(!gtk_css_valid(&css));

        let mut content = "/* colors.css */\n".to_string();
        content.push_str(&"a".repeat(2048));
        fs::write(&css, content).expect("write");
        assert!(gtk_css_valid(&css));
    }
}
