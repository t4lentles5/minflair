use anyhow::{bail, Context, Result};
use std::collections::BTreeSet;
use std::env;
use std::fs;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::thread;
use std::time::Duration;

use crate::aur;
use crate::cli::UpdateArgs;
use crate::install::{self, Ctx};
use crate::manifest::Manifest;
use crate::prefs;
use crate::process;
use crate::repo;
use crate::selection::{self, Flags};
use crate::selector;
use crate::ui;

const DUNST_DBUS_SERVICE: &str = "/usr/share/dbus-1/services/org.knopwob.dunst.service";

pub fn run(root: &Path, args: UpdateArgs) -> Result<u8> {
    // SAFETY: geteuid has no preconditions and cannot fail.
    if unsafe { libc::geteuid() } == 0 {
        bail!("run minflair update as your normal user, not as root");
    }

    let version = repo::app_version(root).unwrap_or_else(|| "unknown".to_string());
    ui::header(&format!("Minflair updater {version}"));

    if args.pull {
        pull(root)?;
        rebuild_cli(root, args.no_build, args.dry_run)?;
    }

    let home = repo::home_dir()?;
    require_existing_install(root, &home)?;

    let manifest = Manifest::load(&root.join(repo::MANIFEST_REL))?;
    install::validate_manifest(root, &manifest)?;

    if let Some(helper) = &args.aur_helper {
        if !aur::valid(helper) {
            bail!("--aur-helper must be yay or paru");
        }
    }

    let ctx = Ctx::new(root, &home, args.dry_run);

    let (prefs_path, dry_prefs) = install::prepare_prefs(args.dry_run)?;

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

    // Unlike install, update only opens the selector when --select is passed.
    if args.selection.select && !args.selection.no_input {
        if selector::available() {
            ctx.info("Choose the components you want to keep.");
            match selector::run(&manifest, &disabled, &version)? {
                Some(selected) => {
                    prefs::save(&prefs_path, &selected, &manifest)
                        .context("could not save component preferences")?;
                    ctx.ok(&format!("Selection saved to {}", prefs_path.display()));
                    disabled = selected;
                }
                None => {
                    ctx.warn("Update cancelled.");
                    return Ok(0);
                }
            }
        } else {
            ctx.warn("--select needs an interactive terminal; using saved preferences.");
        }
    }

    ui::section("Component selection");
    install::print_summary(&manifest, &disabled);
    if install::enabled(&manifest, &disabled, "zsh") {
        ctx.info("zsh will be set as your login shell.");
        if !install::enabled(&manifest, &disabled, "starship") {
            ctx.warn("Starship is disabled; zsh will use a basic prompt.");
        }
    }

    let helper = resolve_aur_helper(&ctx, &args)?;

    if ctx.dry_run {
        ctx.info("Dry run: sudo and package changes are skipped.");
    } else {
        install::authenticate_sudo()?;
    }

    ui::section("Backup");
    ctx.info(&format!(
        "Backing up the files that will be replaced to {} ...",
        ctx.backup_dir.display()
    ));
    if !ctx.dry_run {
        fs::create_dir_all(&ctx.backup_dir)
            .with_context(|| format!("could not create {}", ctx.backup_dir.display()))?;
    }
    install::backup_enabled_paths(&ctx, &manifest, &disabled)?;
    backup_system_files(&ctx, &manifest, &disabled)?;
    ctx.ok("Backup saved.");

    ui::section("Dotfiles");
    ctx.info("Copying enabled components to ~/.config and ~/ ...");
    install::copy_enabled_paths(&ctx, &manifest, &disabled)?;
    restore_zsh_history(&ctx, &manifest, &disabled)?;
    ctx.ok("Configuration updated.");

    ui::section("Packages");
    update_packages(&ctx, &manifest, &disabled, &args, &helper);
    install::configure_zsh(&ctx, &manifest, &disabled);
    install::configure_ddc(&ctx, &manifest, &disabled);
    install::configure_battery(&ctx, &manifest, &disabled, args.no_packages, &helper);
    update_node(&ctx, args.no_packages);

    ui::section("Theme and desktop");
    ensure_gtk(&ctx, &manifest, &disabled);
    update_sddm(&ctx, &manifest, &disabled)?;
    configure_dunst(&ctx, &manifest, &disabled);
    configure_services(&ctx, &manifest, &disabled);

    ui::section("Reload");
    reapply_theme(&ctx);
    install::run_reloads(&ctx, &manifest, &disabled);

    if ctx.dry_run {
        println!();
        ui::done("Dry run complete. No files or packages were changed.");
        ui::info(&format!(
            "Preferences that would be used: {}",
            prefs_path.display()
        ));
        ui::section("Selection preview");
        install::print_summary(&manifest, &disabled);
        drop(dry_prefs);
        return Ok(0);
    }

    reload_desktop(&ctx);

    println!();
    ui::section("Update complete");
    ui::ok(&format!("Backup saved at: {}", ctx.backup_dir.display()));
    install::print_summary(&manifest, &disabled);
    println!();
    ui::info("Next steps:");
    println!("  1. Restart your session if the reload was skipped.");
    println!("  2. Review docs/SETUP.md after major updates.");
    Ok(0)
}

fn require_existing_install(root: &Path, home: &Path) -> Result<()> {
    for relative in [repo::PACKAGES_REL, repo::PACKAGES_AUR_REL] {
        if !root.join(relative).is_file() {
            bail!("{relative} not found. Are you running this from the Minflair repository?");
        }
    }
    if !root.join("config").is_dir() {
        bail!("config/ not found. Are you running this from the Minflair repository?");
    }

    if !home.join(".config/quickshell").is_dir() {
        bail!("Quickshell config not found in ~/.config. Run minflair install first.");
    }
    Ok(())
}

fn resolve_aur_helper(ctx: &Ctx, args: &UpdateArgs) -> Result<String> {
    if let Some(helper) = &args.aur_helper {
        if ctx.dry_run {
            println!("[dry-run] would save AUR helper: {helper}");
        } else {
            aur::set(helper).context("could not save the AUR helper")?;
            ctx.info(&format!("AUR helper set to {helper}."));
        }
        return Ok(helper.clone());
    }

    aur::current()
}

fn update_packages(
    ctx: &Ctx,
    manifest: &Manifest,
    disabled: &BTreeSet<String>,
    args: &UpdateArgs,
    helper: &str,
) {
    if args.no_packages {
        ctx.warn("Skipping package updates (--no-packages).");
        return;
    }

    let disabled_packages = manifest.disabled_packages(disabled);
    ctx.info("Installing dependencies...");
    let dependencies =
        install::filtered_packages(&ctx.root.join(repo::PACKAGES_REL), &disabled_packages);
    if !dependencies.is_empty() {
        let mut command = install::strs(["pacman", "-S", "--needed", "--noconfirm"]);
        command.extend(dependencies);
        if !ctx.run("sudo", &command) {
            ctx.warn("Some official packages could not be installed. Try: sudo pacman -Syu");
        }
    }

    let aur_dependencies =
        install::filtered_packages(&ctx.root.join(repo::PACKAGES_AUR_REL), &disabled_packages);
    if !aur_dependencies.is_empty() {
        if ctx.dry_run || aur::installed(helper) {
            ctx.info(&format!("Installing AUR dependencies with {helper}..."));
            let mut command = install::strs(["-S", "--needed", "--noconfirm"]);
            command.extend(aur_dependencies);
            if !ctx.run(helper, &command) {
                ctx.warn("Some AUR packages could not be installed.");
            }
        } else {
            ctx.warn(&format!(
                "{helper} is not installed, skipping AUR dependencies."
            ));
        }
    }
}

fn backup_system_files(ctx: &Ctx, manifest: &Manifest, disabled: &BTreeSet<String>) -> Result<()> {
    if !install::enabled(manifest, disabled, "sddm") {
        return Ok(());
    }

    let sddm_conf = Path::new("/etc/sddm.conf");
    if sddm_conf.is_file() {
        if ctx.dry_run {
            println!("[dry-run] would back up /etc/sddm.conf");
        } else {
            fs::copy(sddm_conf, ctx.backup_dir.join("sddm.conf.bak"))
                .context("could not back up /etc/sddm.conf")?;
        }
    }

    let theme_conf = Path::new(install::SDDM_THEME_DIR).join("theme.conf");
    if theme_conf.is_file() {
        if ctx.dry_run {
            println!(
                "[dry-run] would back up {}/theme.conf",
                install::SDDM_THEME_DIR
            );
        } else {
            let _ = fs::copy(theme_conf, ctx.backup_dir.join("sddm-theme.conf.bak"));
        }
    }

    Ok(())
}

fn restore_zsh_history(ctx: &Ctx, manifest: &Manifest, disabled: &BTreeSet<String>) -> Result<()> {
    if !install::enabled(manifest, disabled, "zsh") {
        return Ok(());
    }

    let backup = ctx.backup_dir.join("config/zsh/zhistory");
    if !backup.is_file() {
        return Ok(());
    }

    if ctx.dry_run {
        println!("[dry-run] would restore the zsh history");
        return Ok(());
    }

    let destination = ctx.home.join(".config/zsh/zhistory");
    fs::copy(&backup, &destination)
        .with_context(|| format!("could not restore {}", destination.display()))?;
    Ok(())
}

fn update_node(ctx: &Ctx, no_packages: bool) {
    if no_packages {
        ctx.info("Skipping Node.js update (--no-packages).");
    } else if ctx.dry_run {
        println!("[dry-run] would install Node.js LTS with fnm");
    } else if process::which("fnm").is_some() {
        install::install_node(ctx);
    } else {
        ctx.warn("fnm not found in PATH. Make sure ~/.local/bin is in your PATH and re-run.");
    }
}

fn ensure_gtk(ctx: &Ctx, manifest: &Manifest, disabled: &BTreeSet<String>) {
    if !install::enabled(manifest, disabled, "gtk") {
        ctx.info("Skipping GTK theme (gtk component disabled).");
        return;
    }

    let theme_dir = env::var_os("MINFLAIR_GTK_THEME_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(|| ctx.home.join(".themes/Material-Gnome"));
    let theme_url =
        env::var("MINFLAIR_GTK_THEME_URL").unwrap_or_else(|_| install::GTK_THEME_URL.to_string());

    ctx.info("Installing Material-Gnome theme...");
    if install::gtk_theme_valid(&theme_dir) {
        ctx.ok("Material-Gnome theme is ready.");
    } else if ctx.dry_run {
        println!(
            "[dry-run] would install Material-Gnome into {}",
            theme_dir.display()
        );
    } else if install::install_gtk_theme(ctx, &theme_dir, &theme_url) {
        ctx.ok("Material-Gnome theme is ready.");
    } else {
        ctx.warn("Could not install the Material-Gnome theme; GTK colors may not apply.");
    }
}

fn update_sddm(ctx: &Ctx, manifest: &Manifest, disabled: &BTreeSet<String>) -> Result<()> {
    if !install::enabled(manifest, disabled, "sddm") {
        ctx.info("Skipping SDDM theme (sddm component disabled).");
        return Ok(());
    }

    if process::which("sddm").is_none() {
        ctx.warn("SDDM is not installed, skipping theme update.");
        return Ok(());
    }

    if ctx.dry_run {
        println!(
            "[dry-run] would update the SDDM theme in {}",
            install::SDDM_THEME_DIR
        );
        return Ok(());
    }

    ctx.info("Updating SDDM theme (minflair-sddm)...");
    let temp = install::temp_dir("minflair-sddm")?;
    let clone_target = temp.path().join("theme");
    let clone_target_string = clone_target.to_string_lossy().to_string();
    if !ctx.run(
        "git",
        &install::strs([
            "clone",
            "--depth",
            "1",
            install::SDDM_THEME_URL,
            clone_target_string.as_str(),
        ]),
    ) {
        bail!("failed to clone the SDDM theme");
    }

    let _ = fs::remove_dir_all(clone_target.join(".git"));
    let source = format!("{}/.", clone_target.display());
    let destination = format!("{}/", install::SDDM_THEME_DIR);
    ctx.run(
        "sudo",
        &install::strs(["mkdir", "-p", install::SDDM_THEME_DIR]),
    );
    if !ctx.run(
        "sudo",
        &install::strs(["cp", "-a", source.as_str(), destination.as_str()]),
    ) {
        bail!("failed to install the SDDM theme");
    }

    let theme_git = format!("{}/.git", install::SDDM_THEME_DIR);
    ctx.run("sudo", &install::strs(["rm", "-rf", theme_git.as_str()]));
    ctx.run(
        "sudo",
        &install::strs(["chown", "-R", "root:root", install::SDDM_THEME_DIR]),
    );

    if !Path::new(install::SDDM_THEME_DIR)
        .join("theme.conf")
        .is_file()
    {
        ctx.warn("SDDM theme files are missing; keeping the current /etc/sddm.conf.");
        return Ok(());
    }

    let repo_config = ctx.root.join("etc/sddm.conf");
    if !repo_config.is_file() {
        ctx.warn("etc/sddm.conf not found in repo, keeping the current SDDM configuration.");
        return Ok(());
    }

    let config_string = repo_config.to_string_lossy().to_string();
    if !ctx.run(
        "sudo",
        &install::strs(["cp", config_string.as_str(), "/etc/sddm.conf"]),
    ) {
        ctx.warn("Could not write /etc/sddm.conf.");
    }

    ctx.ok("SDDM theme updated.");
    Ok(())
}

fn configure_dunst(ctx: &Ctx, manifest: &Manifest, disabled: &BTreeSet<String>) {
    let enabled = install::enabled(manifest, disabled, "dunst");

    if ctx.dry_run {
        if enabled {
            println!("[dry-run] would mask dunst and disable its D-Bus activation");
        } else {
            println!("[dry-run] would restore dunst");
        }
        return;
    }

    if enabled {
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

        let dbus_service = Path::new(DUNST_DBUS_SERVICE);
        if dbus_service.is_file() {
            let dbus_string = dbus_service.to_string_lossy().to_string();
            let disabled_path = format!("{dbus_string}.disabled");
            if ctx.run(
                "sudo",
                &install::strs(["mv", dbus_string.as_str(), disabled_path.as_str()]),
            ) {
                ctx.ok("dunst D-Bus activation disabled.");
            } else {
                ctx.warn("Could not disable the dunst D-Bus activation.");
            }
        }

        ctx.ok("dunst disabled - QuickShell will handle notifications.");
    } else {
        ctx.info("Restoring dunst (dunst component disabled)...");
        let _ = Command::new("systemctl")
            .args(["--user", "unmask", "dunst.service"])
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .status();

        let disabled_path = format!("{DUNST_DBUS_SERVICE}.disabled");
        if Path::new(&disabled_path).is_file() {
            if ctx.run(
                "sudo",
                &install::strs(["mv", disabled_path.as_str(), DUNST_DBUS_SERVICE]),
            ) {
                ctx.ok("dunst D-Bus activation restored.");
            } else {
                ctx.warn("Could not restore the dunst D-Bus activation.");
            }
        }

        ctx.ok("dunst restored.");
    }
}

fn configure_services(ctx: &Ctx, manifest: &Manifest, disabled: &BTreeSet<String>) {
    if !install::enabled(manifest, disabled, "services") {
        ctx.info("Skipping system services (services component disabled).");
        return;
    }

    if ctx.dry_run {
        println!("[dry-run] would enable NetworkManager, bluetooth and power-profiles-daemon");
        return;
    }

    install::configure_services(ctx, manifest, disabled);
}

fn reapply_theme(ctx: &Ctx) {
    if !ctx
        .home
        .join(".cache/quickshell/colorscheme.json")
        .is_file()
    {
        ctx.warn("No cached colorscheme found; the theme will be applied on next login.");
        return;
    }

    ctx.info("Reapplying theme...");
    if ctx.dry_run {
        println!("[dry-run] would reapply the theme for enabled components");
        return;
    }

    let script = ctx
        .home
        .join(".config/quickshell/Scripts/theme/apply_theme.py");
    let script_string = script.to_string_lossy().to_string();
    if !ctx.run("python3", &install::strs([script_string.as_str()])) {
        ctx.warn("Theme could not be reapplied; it will be generated on next login.");
    }
}

fn reload_desktop(ctx: &Ctx) {
    if env::var_os("HYPRLAND_INSTANCE_SIGNATURE").is_none() {
        ctx.warn("Hyprland session not detected; restart Quickshell manually.");
        return;
    }

    ctx.info("Reloading Hyprland and Quickshell...");
    if !ctx.run("hyprctl", &install::strs(["reload"])) {
        ctx.warn("Could not reload Hyprland.");
    }
    let _ = Command::new("killall")
        .arg("qs")
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .status();
    thread::sleep(Duration::from_millis(500));
    if !ctx.run(
        "hyprctl",
        &install::strs(["dispatch", "hl.dsp.exec_cmd(\"qs\")"]),
    ) {
        ctx.warn("Could not restart Quickshell. Run 'qs' manually.");
    }
}

fn pull(root: &Path) -> Result<()> {
    ui::info("pulling the latest source (git pull --ff-only)...");
    let status = Command::new("git")
        .arg("-C")
        .arg(root)
        .args(["pull", "--ff-only"])
        .status()
        .context("could not run git pull")?;
    if !status.success() {
        bail!("git pull --ff-only failed; clean the working tree or use --no-pull");
    }
    Ok(())
}

fn rebuild_cli(root: &Path, no_build: bool, dry_run: bool) -> Result<()> {
    if no_build {
        ui::info("Skipping the CLI rebuild (--no-build).");
        return Ok(());
    }

    if dry_run {
        println!("[dry-run] would rebuild the minflair CLI");
        return Ok(());
    }

    let Some(cargo) = process::which("cargo") else {
        ui::warn("cargo not found; rebuild the minflair CLI manually.");
        return Ok(());
    };

    ui::info("Rebuilding the minflair CLI...");
    let status = Command::new(cargo)
        .args(["build", "--release", "--locked"])
        .current_dir(root)
        .status()
        .context("could not run cargo build")?;
    if !status.success() {
        ui::warn("Could not rebuild the minflair CLI; continuing with the current binary.");
        return Ok(());
    }

    let target_dir = env::var_os("CARGO_TARGET_DIR")
        .map(PathBuf::from)
        .map(|path| {
            if path.is_absolute() {
                path
            } else {
                root.join(path)
            }
        })
        .unwrap_or_else(|| root.join("target"));
    let built = target_dir.join("release/minflair");

    let Ok(current) = env::current_exe() else {
        ui::ok("minflair CLI rebuilt.");
        return Ok(());
    };
    let current = fs::canonicalize(&current).unwrap_or(current);
    if current == built || current.starts_with(root.join("target")) {
        ui::ok("minflair CLI rebuilt.");
        return Ok(());
    }

    match reinstall_binary(&built, &current) {
        Ok(()) => ui::ok(&format!(
            "minflair CLI reinstalled at {}.",
            current.display()
        )),
        Err(error) => ui::warn(&format!(
            "Could not reinstall the minflair CLI at {}: {error:#}. Reinstall it manually or run the build as a user with write access.",
            current.display()
        )),
    }
    Ok(())
}

fn reinstall_binary(built: &Path, destination: &Path) -> Result<()> {
    let parent = destination.parent().context("invalid CLI destination")?;
    let temp = parent.join(format!(
        ".minflair-{}-{}",
        std::process::id(),
        install::unique_suffix()
    ));

    fs::copy(built, &temp).with_context(|| format!("could not copy {}", built.display()))?;
    let mut permissions = fs::metadata(&temp)?.permissions();
    permissions.set_mode(0o755);
    fs::set_permissions(&temp, permissions)?;
    fs::rename(&temp, destination)
        .with_context(|| format!("could not replace {}", destination.display()))?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn requires_an_existing_quickshell_config() {
        let directory = tempfile::tempdir().expect("tempdir");
        let root = directory.path().join("repo");
        fs::create_dir_all(root.join("config")).expect("mkdir");
        fs::write(root.join(repo::PACKAGES_REL), "kitty\n").expect("write");
        fs::write(root.join(repo::PACKAGES_AUR_REL), "yay\n").expect("write");

        let home = directory.path().join("home");
        fs::create_dir_all(&home).expect("mkdir");

        let error = require_existing_install(&root, &home).expect_err("missing install");
        assert!(format!("{error:#}").contains("Quickshell config not found"));
    }

    #[test]
    fn reinstall_binary_replaces_the_destination_with_0755() {
        let directory = tempfile::tempdir().expect("tempdir");
        let built = directory.path().join("built");
        let destination = directory.path().join("minflair");
        fs::write(&built, b"new binary").expect("write built");
        fs::write(&destination, b"old binary").expect("write destination");

        reinstall_binary(&built, &destination).expect("reinstall");

        assert_eq!(fs::read(&destination).expect("read"), b"new binary");
        let mode = fs::metadata(&destination)
            .expect("metadata")
            .permissions()
            .mode()
            & 0o777;
        assert_eq!(mode, 0o755);

        let entries = fs::read_dir(directory.path()).expect("read_dir").count();
        assert_eq!(entries, 2, "temporary file must not be left behind");
    }

    #[test]
    fn rejects_a_repository_without_package_lists() {
        let directory = tempfile::tempdir().expect("tempdir");
        let root = directory.path().join("repo");
        fs::create_dir_all(root.join("config")).expect("mkdir");

        let error =
            require_existing_install(&root, directory.path()).expect_err("missing packages");
        assert!(format!("{error:#}").contains(repo::PACKAGES_REL));
    }
}
