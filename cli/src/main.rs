mod aur;
mod cli;
mod doctor;
mod install;
mod manifest;
mod prefs;
mod process;
mod repo;
mod selection;
mod selector;
mod ui;
mod update;

use std::process::ExitCode;

fn main() -> ExitCode {
    let args = cli::parse();
    match cli::run(args) {
        Ok(code) => ExitCode::from(code),
        Err(error) => {
            ui::error(&format!("{error:#}"));
            ExitCode::from(1)
        }
    }
}
