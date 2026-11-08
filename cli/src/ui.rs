use std::io::{self, IsTerminal};

fn color_enabled() -> bool {
    io::stdout().is_terminal() && std::env::var_os("NO_COLOR").is_none()
}

fn paint(code: &str, text: &str) -> String {
    if color_enabled() {
        format!("\x1b[{code}m{text}\x1b[0m")
    } else {
        text.to_string()
    }
}

pub fn bold(text: &str) -> String {
    paint("1", text)
}

pub fn dim(text: &str) -> String {
    paint("2", text)
}

pub fn green(text: &str) -> String {
    paint("32", text)
}

pub fn yellow(text: &str) -> String {
    paint("33", text)
}

pub fn red(text: &str) -> String {
    paint("31", text)
}

pub fn cyan(text: &str) -> String {
    paint("36", text)
}

pub fn info(message: &str) {
    println!("{} {message}", cyan("[info]"));
}

#[allow(dead_code)] // Used by the install/update pipelines in later phases.
pub fn warn(message: &str) {
    eprintln!("{} {message}", yellow("[warn]"));
}

pub fn error(message: &str) {
    eprintln!("{} {message}", red("[error]"));
}
