use anyhow::{bail, Context, Result};
use clap::{Args, Parser, Subcommand};
use std::ffi::OsString;
use std::path::{Path, PathBuf};
use std::process::Command as ProcessCommand;

use crate::{doctor, install, repo, ui};

#[derive(Debug, Parser)]
#[command(
    name = "minflair",
    version,
    about = "Install, update and diagnose Minflair",
    disable_help_subcommand = true
)]
pub struct Cli {
    #[command(subcommand)]
    pub command: Command,
}

#[derive(Debug, Subcommand)]
pub enum Command {
    /// Install Minflair
    Install(InstallArgs),
    /// Update an existing Minflair installation
    Update(UpdateArgs),
    /// Check the environment, repository and configuration
    Doctor(DoctorArgs),
}

#[derive(Debug, Args, Default, Clone)]
pub struct SelectionArgs {
    /// Disable components (comma-separated, repeatable)
    #[arg(long, value_delimiter = ',', value_name = "IDS")]
    pub exclude: Vec<String>,

    /// Enable only these optional components (plus core)
    #[arg(long, value_delimiter = ',', value_name = "IDS")]
    pub only: Vec<String>,

    /// Re-enable components that were previously disabled
    #[arg(long, value_delimiter = ',', value_name = "IDS")]
    pub include: Vec<String>,

    /// Open the interactive selector
    #[arg(long)]
    pub select: bool,

    /// Never prompt; use the saved preferences
    #[arg(long)]
    pub no_input: bool,
}

#[derive(Debug, Args)]
pub struct InstallArgs {
    #[command(flatten)]
    pub selection: SelectionArgs,

    /// Use yay or paru as the AUR helper
    #[arg(long, value_name = "NAME")]
    pub aur_helper: Option<String>,

    /// Show what would happen without changing anything
    #[arg(long)]
    pub dry_run: bool,

    /// Do not install or update packages
    #[arg(long)]
    pub no_packages: bool,

    /// Repository root (defaults to auto-detection)
    #[arg(long, hide = true)]
    pub repo: Option<PathBuf>,
}

#[derive(Debug, Args)]
pub struct UpdateArgs {
    #[command(flatten)]
    pub selection: SelectionArgs,

    /// Use yay or paru as the AUR helper
    #[arg(long, value_name = "NAME")]
    pub aur_helper: Option<String>,

    /// Show what would happen without changing anything
    #[arg(long)]
    pub dry_run: bool,

    /// Do not install or update packages
    #[arg(long)]
    pub no_packages: bool,

    /// Pull the latest source before updating
    #[arg(long, conflicts_with = "no_pull")]
    pub pull: bool,

    /// Do not pull the latest source
    #[arg(long)]
    pub no_pull: bool,

    /// Do not rebuild the binary before updating
    #[arg(long)]
    pub no_build: bool,

    /// Repository root (defaults to auto-detection)
    #[arg(long, hide = true)]
    pub repo: Option<PathBuf>,
}

#[derive(Debug, Args)]
pub struct DoctorArgs {
    /// Check the packages listed in packages.txt and packages-aur.txt
    #[arg(long)]
    pub packages: bool,

    /// Print the report as JSON
    #[arg(long)]
    pub json: bool,

    /// Repository root (defaults to auto-detection)
    #[arg(long, hide = true)]
    pub repo: Option<PathBuf>,
}

pub fn parse() -> Cli {
    Cli::parse()
}

pub fn run(args: Cli) -> Result<u8> {
    match args.command {
        Command::Doctor(args) => doctor::run(args),
        Command::Install(args) => {
            let root = repo::find(args.repo.clone())?;
            install::run(&root, args)
        }
        Command::Update(args) => {
            let root = repo::find(args.repo.clone())?;
            if args.pull {
                pull(&root)?;
            }

            let mut forwarded = selection_args(&args.selection);
            if let Some(helper) = &args.aur_helper {
                forwarded.push("--aur-helper".into());
                forwarded.push(helper.as_str().into());
            }
            if args.dry_run {
                forwarded.push("--dry-run".into());
            }
            if args.no_packages {
                forwarded.push("--no-packages".into());
            }

            ui::info("delegating update to update.sh; the native pipeline lands in phase 2");
            run_legacy(&root, "update.sh", &forwarded)
        }
    }
}

fn selection_args(selection: &SelectionArgs) -> Vec<OsString> {
    let mut args = Vec::new();
    if !selection.exclude.is_empty() {
        args.push("--exclude".into());
        args.push(selection.exclude.join(",").into());
    }
    if !selection.only.is_empty() {
        args.push("--only".into());
        args.push(selection.only.join(",").into());
    }
    if !selection.include.is_empty() {
        args.push("--include".into());
        args.push(selection.include.join(",").into());
    }
    if selection.select {
        args.push("--select".into());
    }
    if selection.no_input {
        args.push("--no-input".into());
    }
    args
}

fn run_legacy(root: &Path, script: &str, args: &[OsString]) -> Result<u8> {
    let path = root.join(script);
    if !path.is_file() {
        bail!("{} not found in {}", script, root.display());
    }

    let status = ProcessCommand::new("bash")
        .arg(&path)
        .args(args)
        // The shell scripts will check this once they become wrappers, so the
        // delegation cannot recurse back into `minflair`.
        .env("MINFLAIR_CLI_DELEGATED", "1")
        .status()
        .with_context(|| format!("could not run {}", path.display()))?;
    Ok(status.code().unwrap_or(1).clamp(0, 255) as u8)
}

fn pull(root: &Path) -> Result<()> {
    ui::info("pulling the latest source (git pull --ff-only)...");
    let status = ProcessCommand::new("git")
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
