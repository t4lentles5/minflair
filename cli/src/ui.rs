use std::io::{self, IsTerminal, Write};

fn color_enabled() -> bool {
    io::stdout().is_terminal()
        && std::env::var_os("NO_COLOR").is_none()
        && std::env::var("TERM")
            .map(|term| term != "dumb")
            .unwrap_or(true)
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

pub fn header(title: &str) {
    println!("\n{}", paint("1;36", title));
}

pub fn section(title: &str) {
    println!("\n{}", bold(&format!("== {title} ==")));
}

pub fn info(message: &str) {
    println!("{} {message}", cyan("[INFO]"));
}

pub fn ok(message: &str) {
    println!("{} {message}", green("[OK]"));
}

#[allow(dead_code)] // Used by the install/update pipelines in later phases.
pub fn warn(message: &str) {
    eprintln!("{} {message}", yellow("[WARN]"));
}

pub fn error(message: &str) {
    eprintln!("{} {message}", red("[ERROR]"));
}

pub fn done(message: &str) {
    println!("\n{} {message}", green("[OK]"));
}

/// Ask a yes/no question on the controlling terminal.
///
/// Returns `false` when stdin is not a terminal, matching the shell helpers
/// used by the current installer.
pub fn confirm(prompt: &str, default_yes: bool) -> bool {
    if !io::stdin().is_terminal() {
        return false;
    }

    let suffix = if default_yes { "[Y/n] " } else { "[y/N] " };
    print!("{prompt} {suffix}");
    let _ = io::stdout().flush();

    let mut reply = String::new();
    if io::stdin().read_line(&mut reply).is_err() {
        return false;
    }
    let reply = reply.trim();
    if reply.is_empty() {
        return default_yes;
    }
    reply.eq_ignore_ascii_case("y") || reply.eq_ignore_ascii_case("yes")
}

/// Terminal width used by the plain-text summaries.
pub fn terminal_width() -> usize {
    std::env::var("COLUMNS")
        .ok()
        .and_then(|value| value.parse::<usize>().ok())
        .filter(|width| *width >= 40)
        .unwrap_or(100)
}

/// Wrap a comma-separated list, preserving the indentation used by the shell
/// installer. This mirrors `components_print_list`.
pub fn print_list(indent: &str, text: &str) {
    if text.is_empty() {
        return;
    }
    let width = terminal_width().saturating_sub(indent.len()).max(20);
    for line in wrap(text, width) {
        println!("{indent}{line}");
    }
}

fn wrap(text: &str, width: usize) -> Vec<String> {
    let mut lines = Vec::new();
    let mut current = String::new();

    for word in text.split_whitespace() {
        if current.is_empty() {
            current.push_str(word);
        } else if current.len() + 1 + word.len() <= width {
            current.push(' ');
            current.push_str(word);
        } else {
            lines.push(current);
            current = word.to_string();
        }
    }
    if !current.is_empty() {
        lines.push(current);
    }
    lines
}

/// Quote an argument for the `[dry-run]` command previews.
pub fn shell_quote(value: &str) -> String {
    if value.is_empty() {
        return "''".to_string();
    }
    if value
        .chars()
        .all(|character| character.is_ascii_alphanumeric() || "-_./:=@%+,".contains(character))
    {
        return value.to_string();
    }
    format!("'{}'", value.replace('\'', "'\\''"))
}

/// Render a command the same way the shell helper does in dry-run mode.
pub fn command_line(program: &str, args: &[String]) -> String {
    let mut parts = Vec::with_capacity(args.len() + 1);
    parts.push(shell_quote(program));
    for arg in args {
        parts.push(shell_quote(arg));
    }
    parts.join(" ")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn quotes_plain_arguments_without_quotes() {
        assert_eq!(shell_quote("pacman"), "pacman");
        assert_eq!(shell_quote("config/kitty"), "config/kitty");
    }

    #[test]
    fn quotes_arguments_with_spaces() {
        assert_eq!(shell_quote("some value"), "'some value'");
        assert_eq!(shell_quote("it's"), "'it'\\''s'");
        assert_eq!(shell_quote(""), "''");
    }

    #[test]
    fn wraps_long_lists() {
        let wrapped = wrap("one two three four five", 10);
        assert_eq!(wrapped, vec!["one two", "three four", "five"]);
    }
}
