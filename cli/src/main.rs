mod aur;
mod cli;
mod doctor;
mod manifest;
mod prefs;
mod process;
mod repo;
mod ui;

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
