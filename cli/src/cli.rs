use anyhow::Result;
use clap::{Args, Parser, Subcommand};
use std::path::PathBuf;

use crate::{components, doctor, install, repo, update};

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
    /// List, enable or disable components
    Components(ComponentsArgs),
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

#[derive(Debug, Args, Default)]
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

#[derive(Debug, Args)]
pub struct ComponentsArgs {
    #[command(subcommand)]
    pub command: ComponentsCommand,

    /// Repository root (defaults to auto-detection)
    #[arg(long, global = true, hide = true)]
    pub repo: Option<PathBuf>,
}

#[derive(Debug, Subcommand)]
pub enum ComponentsCommand {
    /// List the components and whether they are enabled
    List(ComponentListArgs),
    /// Enable components and save the preference
    Enable(ComponentChangeArgs),
    /// Disable components and save the preference
    Disable(ComponentChangeArgs),
    /// Change the selection in the interactive selector
    Edit(ComponentEditArgs),
    /// Re-enable every optional component
    Reset(ComponentResetArgs),
}

#[derive(Debug, Args)]
pub struct ComponentListArgs {
    /// Print the list as JSON
    #[arg(long)]
    pub json: bool,

    /// Only show enabled components
    #[arg(long, conflicts_with = "disabled")]
    pub enabled: bool,

    /// Only show disabled components
    #[arg(long)]
    pub disabled: bool,
}

#[derive(Debug, Args)]
pub struct ComponentChangeArgs {
    /// Component ids (comma-separated, repeatable)
    #[arg(value_delimiter = ',', value_name = "IDS", required = true)]
    pub ids: Vec<String>,

    /// Run minflair update after saving the selection
    #[arg(long)]
    pub apply: bool,
}

#[derive(Debug, Args)]
pub struct ComponentEditArgs {
    /// Run minflair update after saving the selection
    #[arg(long)]
    pub apply: bool,
}

#[derive(Debug, Args)]
pub struct ComponentResetArgs {
    /// Run minflair update after saving the selection
    #[arg(long)]
    pub apply: bool,
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
        Command::Components(args) => {
            let root = repo::find(args.repo.clone())?;
            components::run(&root, args)
        }
    }
}
