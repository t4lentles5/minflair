use anyhow::Result;
use clap::{Args, Parser, Subcommand};
use std::path::PathBuf;

use crate::{doctor, install, repo, update};

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

    /// Do not rebuild the CLI after --pull
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
            update::run(&root, args)
        }
    }
}
