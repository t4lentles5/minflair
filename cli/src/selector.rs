use anyhow::{Context, Result};
use crossterm::cursor::{Hide, MoveTo, Show};
use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyEventKind, KeyModifiers};
use crossterm::execute;
use crossterm::terminal::{
    disable_raw_mode, enable_raw_mode, Clear, ClearType, EnterAlternateScreen, LeaveAlternateScreen,
};
use ratatui::backend::CrosstermBackend;
use ratatui::layout::{Alignment, Constraint, Layout, Rect};
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, Paragraph, Wrap};
use ratatui::{Frame, Terminal};
use std::collections::BTreeSet;
use std::io::{self, IsTerminal, Stdout};

use crate::manifest::{category_label, Manifest};

/// Minimum contrast between the selected row and the terminal background.
const HIGHLIGHT_BACKGROUND_CONTRAST: f64 = 2.0;
/// Default Minflair theme, used before Quickshell has written its cache.
const DEFAULT_THEME_ACCENT: [u8; 3] = [0xa7, 0x7e, 0xf5];
const DEFAULT_THEME_BG: [u8; 3] = [0x03, 0x01, 0x07];

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Mode {
    List,
    Search,
    Review,
}

#[derive(Debug, Clone)]
struct Entry {
    id: String,
    label: String,
    category: String,
    core: bool,
    description: String,
    packages: Vec<String>,
    paths: Vec<String>,
    reload: String,
    selected: bool,
}

#[derive(Debug)]
pub struct SelectorState {
    entries: Vec<Entry>,
    filter: String,
    cursor: usize,
    mode: Mode,
    scroll: usize,
    review_scroll: u16,
    version: String,
    action: String,
    highlight_bg: Color,
    highlight_fg: Color,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum Action {
    Continue,
    Confirm,
    Cancel,
}

/// Builds the cursor highlight from the active wallpaper theme.
///
/// The accent is regenerated whenever the wallpaper changes, so it can be any
/// hue and lightness. We keep the accent as the row background when it is
/// distinguishable from the theme background, nudge it if it is not, and pick
/// black or white text depending on which has the better contrast.
///
/// On a first install Quickshell has not written its cache yet, so the default
/// Minflair theme is used instead of a generic terminal color.
fn theme_highlight() -> (Color, Color) {
    let (accent, background) = theme_accent().unwrap_or((DEFAULT_THEME_ACCENT, DEFAULT_THEME_BG));
    highlight_colors(accent, background)
}

fn theme_accent() -> Option<([u8; 3], [u8; 3])> {
    let path = crate::repo::home_dir()
        .ok()?
        .join(".cache/quickshell/colorscheme.json");
    let content = std::fs::read_to_string(path).ok()?;
    let value: serde_json::Value = serde_json::from_str(&content).ok()?;
    let accent = parse_hex(value.get("accent")?.as_str()?)?;
    let background = value
        .get("bg")
        .and_then(|value| value.as_str())
        .and_then(parse_hex)
        .unwrap_or([0x10, 0x10, 0x10]);
    Some((accent, background))
}

fn highlight_colors(accent: [u8; 3], background: [u8; 3]) -> (Color, Color) {
    let visible = ensure_visible(accent, background);
    (to_color(visible), to_color(readable_foreground(visible)))
}

fn to_color(rgb: [u8; 3]) -> Color {
    Color::Rgb(rgb[0], rgb[1], rgb[2])
}

fn parse_hex(value: &str) -> Option<[u8; 3]> {
    let value = value.strip_prefix('#').unwrap_or(value);
    let (value, digits) = match value.len() {
        3 => (value, 1),
        6 => (value, 2),
        // Qt serializes colors as #AARRGGBB; ignore the alpha channel.
        8 => (&value[2..], 2),
        _ => return None,
    };
    let mut channels = [0u8; 3];
    if digits == 1 {
        for (index, channel) in channels.iter_mut().enumerate() {
            let digit = u8::from_str_radix(&value[index..=index], 16).ok()?;
            *channel = digit * 0x11;
        }
    } else {
        for (index, channel) in channels.iter_mut().enumerate() {
            *channel = u8::from_str_radix(&value[index * 2..index * 2 + 2], 16).ok()?;
        }
    }
    Some(channels)
}

fn ensure_visible(accent: [u8; 3], background: [u8; 3]) -> [u8; 3] {
    if contrast_ratio(accent, background) >= HIGHLIGHT_BACKGROUND_CONTRAST {
        return accent;
    }

    let target = if relative_luminance(background) < 0.4 {
        [0xff, 0xff, 0xff]
    } else {
        [0x00, 0x00, 0x00]
    };

    for step in 1..=20 {
        let candidate = mix(accent, target, step as f64 / 20.0);
        if contrast_ratio(candidate, background) >= HIGHLIGHT_BACKGROUND_CONTRAST {
            return candidate;
        }
    }
    target
}

fn readable_foreground(background: [u8; 3]) -> [u8; 3] {
    let black = [0x00, 0x00, 0x00];
    let white = [0xff, 0xff, 0xff];
    if contrast_ratio(background, black) >= contrast_ratio(background, white) {
        black
    } else {
        white
    }
}

fn mix(from: [u8; 3], to: [u8; 3], amount: f64) -> [u8; 3] {
    let channel =
        |from: u8, to: u8| (from as f64 + (to as f64 - from as f64) * amount).round() as u8;
    [
        channel(from[0], to[0]),
        channel(from[1], to[1]),
        channel(from[2], to[2]),
    ]
}

fn relative_luminance(rgb: [u8; 3]) -> f64 {
    let linear = |channel: u8| {
        let value = channel as f64 / 255.0;
        if value <= 0.039_28 {
            value / 12.92
        } else {
            ((value + 0.055) / 1.055).powf(2.4)
        }
    };
    0.2126 * linear(rgb[0]) + 0.7152 * linear(rgb[1]) + 0.0722 * linear(rgb[2])
}

fn contrast_ratio(first: [u8; 3], second: [u8; 3]) -> f64 {
    let first = relative_luminance(first);
    let second = relative_luminance(second);
    let (lighter, darker) = if first > second {
        (first, second)
    } else {
        (second, first)
    };
    (lighter + 0.05) / (darker + 0.05)
}

impl SelectorState {
    pub fn new(manifest: &Manifest, disabled: &BTreeSet<String>, version: &str) -> Self {
        let (highlight_bg, highlight_fg) = theme_highlight();
        let entries = manifest
            .components()
            .iter()
            .map(|component| {
                let enabled = component.core || !disabled.contains(&component.id);
                Entry {
                    id: component.id.clone(),
                    label: component.label.clone(),
                    category: component.category.clone(),
                    core: component.core,
                    description: component.description.clone(),
                    packages: component.packages.clone(),
                    paths: component.paths.clone(),
                    reload: component.reload.clone(),
                    selected: enabled,
                }
            })
            .collect();

        Self {
            entries,
            filter: String::new(),
            cursor: 0,
            mode: Mode::List,
            scroll: 0,
            review_scroll: 0,
            version: version.to_string(),
            action: "start installation".to_string(),
            highlight_bg,
            highlight_fg,
        }
    }

    pub fn with_action(mut self, action: &str) -> Self {
        self.action = action.to_string();
        self
    }

    fn filtered(&self) -> Vec<usize> {
        let needle = self.filter.to_lowercase();
        self.entries
            .iter()
            .enumerate()
            .filter(|(_, entry)| {
                needle.is_empty()
                    || entry.id.to_lowercase().contains(&needle)
                    || entry.label.to_lowercase().contains(&needle)
                    || entry.description.to_lowercase().contains(&needle)
            })
            .map(|(index, _)| index)
            .collect()
    }

    fn optional_counts(&self) -> (usize, usize) {
        let mut enabled = 0;
        let mut total = 0;
        for entry in &self.entries {
            if entry.core {
                continue;
            }
            total += 1;
            if entry.selected {
                enabled += 1;
            }
        }
        (enabled, total)
    }

    fn included_labels(&self) -> Vec<&str> {
        self.entries
            .iter()
            .filter(|entry| entry.core || entry.selected)
            .map(|entry| entry.label.as_str())
            .collect()
    }

    fn skipped_labels(&self) -> Vec<&str> {
        self.entries
            .iter()
            .filter(|entry| !entry.core && !entry.selected)
            .map(|entry| entry.label.as_str())
            .collect()
    }

    fn disabled_ids(&self) -> BTreeSet<String> {
        self.entries
            .iter()
            .filter(|entry| !entry.core && !entry.selected)
            .map(|entry| entry.id.clone())
            .collect()
    }

    fn clamp_cursor(&mut self) {
        let filtered = self.filtered();
        if filtered.is_empty() {
            self.cursor = 0;
        } else if self.cursor >= filtered.len() {
            self.cursor = filtered.len() - 1;
        }
    }

    fn move_cursor(&mut self, delta: isize) {
        let filtered = self.filtered();
        if filtered.is_empty() {
            self.cursor = 0;
            return;
        }
        let last = filtered.len() - 1;
        let next = self.cursor as isize + delta;
        self.cursor = next.clamp(0, last as isize) as usize;
    }

    fn toggle(&mut self) {
        let filtered = self.filtered();
        let Some(&index) = filtered.get(self.cursor) else {
            return;
        };
        let entry = &mut self.entries[index];
        if !entry.core {
            entry.selected = !entry.selected;
        }
    }

    fn select_all(&mut self) {
        for entry in &mut self.entries {
            if !entry.core {
                entry.selected = true;
            }
        }
    }

    fn select_none(&mut self) {
        for entry in &mut self.entries {
            if !entry.core {
                entry.selected = false;
            }
        }
    }

    fn start_search(&mut self) {
        self.mode = Mode::Search;
        self.filter.clear();
        self.cursor = 0;
    }

    fn clear_filter(&mut self) {
        self.filter.clear();
        self.cursor = 0;
    }

    fn handle_key(&mut self, key: KeyEvent) -> Action {
        if key.kind != KeyEventKind::Press {
            return Action::Continue;
        }
        if key.modifiers.contains(KeyModifiers::CONTROL) && key.code == KeyCode::Char('c') {
            return Action::Cancel;
        }

        match self.mode {
            Mode::List => match key.code {
                KeyCode::Char('q') | KeyCode::Char('Q') => Action::Cancel,
                KeyCode::Char(' ') => {
                    self.toggle();
                    Action::Continue
                }
                KeyCode::Char('a') | KeyCode::Char('A') => {
                    self.select_all();
                    Action::Continue
                }
                KeyCode::Char('n') | KeyCode::Char('N') => {
                    self.select_none();
                    Action::Continue
                }
                KeyCode::Char('/') => {
                    self.start_search();
                    Action::Continue
                }
                KeyCode::Char('j') | KeyCode::Down => {
                    self.move_cursor(1);
                    Action::Continue
                }
                KeyCode::Char('k') | KeyCode::Up => {
                    self.move_cursor(-1);
                    Action::Continue
                }
                KeyCode::PageDown => {
                    self.move_cursor(10);
                    Action::Continue
                }
                KeyCode::PageUp => {
                    self.move_cursor(-10);
                    Action::Continue
                }
                KeyCode::Home => {
                    self.cursor = 0;
                    Action::Continue
                }
                KeyCode::End => {
                    self.cursor = self.filtered().len().saturating_sub(1);
                    Action::Continue
                }
                KeyCode::Enter => {
                    self.mode = Mode::Review;
                    self.review_scroll = 0;
                    Action::Continue
                }
                KeyCode::Esc => {
                    if !self.filter.is_empty() {
                        self.clear_filter();
                    }
                    Action::Continue
                }
                _ => Action::Continue,
            },
            Mode::Search => match key.code {
                KeyCode::Enter => {
                    self.mode = Mode::List;
                    Action::Continue
                }
                KeyCode::Esc => {
                    self.clear_filter();
                    self.mode = Mode::List;
                    Action::Continue
                }
                KeyCode::Backspace => {
                    self.filter.pop();
                    self.clamp_cursor();
                    Action::Continue
                }
                KeyCode::Down => {
                    self.move_cursor(1);
                    Action::Continue
                }
                KeyCode::Up => {
                    self.move_cursor(-1);
                    Action::Continue
                }
                KeyCode::Char(character) => {
                    self.filter.push(character);
                    self.clamp_cursor();
                    Action::Continue
                }
                _ => Action::Continue,
            },
            Mode::Review => match key.code {
                KeyCode::Char('y') | KeyCode::Char('Y') | KeyCode::Enter => Action::Confirm,
                KeyCode::Char('n') | KeyCode::Char('N') | KeyCode::Esc => {
                    self.mode = Mode::List;
                    Action::Continue
                }
                KeyCode::Char('q') | KeyCode::Char('Q') => Action::Cancel,
                KeyCode::Down | KeyCode::Char('j') => {
                    self.review_scroll = self.review_scroll.saturating_add(1);
                    Action::Continue
                }
                KeyCode::Up | KeyCode::Char('k') => {
                    self.review_scroll = self.review_scroll.saturating_sub(1);
                    Action::Continue
                }
                KeyCode::PageDown => {
                    self.review_scroll = self.review_scroll.saturating_add(10);
                    Action::Continue
                }
                KeyCode::PageUp => {
                    self.review_scroll = self.review_scroll.saturating_sub(10);
                    Action::Continue
                }
                _ => Action::Continue,
            },
        }
    }

    fn ensure_visible(&mut self, row: usize, height: usize) {
        if height == 0 {
            return;
        }
        if row < self.scroll {
            self.scroll = row;
        } else if row >= self.scroll + height {
            self.scroll = row + 1 - height;
        }
    }
}

/// Whether the interactive selector can run in the current terminal.
pub fn available() -> bool {
    io::stdin().is_terminal()
        && io::stdout().is_terminal()
        && std::env::var("TERM")
            .map(|term| term != "dumb")
            .unwrap_or(true)
}

/// Run the selector. `Ok(None)` means the user cancelled.
pub fn run(
    manifest: &Manifest,
    disabled: &BTreeSet<String>,
    version: &str,
) -> Result<Option<BTreeSet<String>>> {
    run_with_action(manifest, disabled, version, "start installation")
}

/// Run the selector with a custom label for the confirm action in the footer.
pub fn run_with_action(
    manifest: &Manifest,
    disabled: &BTreeSet<String>,
    version: &str,
    action: &str,
) -> Result<Option<BTreeSet<String>>> {
    let mut state = SelectorState::new(manifest, disabled, version).with_action(action);
    let mut terminal = TerminalSession::start()?;

    let outcome = loop {
        terminal.draw(|frame| draw(frame, &mut state))?;
        match event::read().context("could not read terminal input")? {
            Event::Key(key) => match state.handle_key(key) {
                Action::Continue => {}
                Action::Confirm => break Some(state.disabled_ids()),
                Action::Cancel => break None,
            },
            Event::Resize(_, _) => {}
            _ => {}
        }
    };

    terminal.restore();
    Ok(outcome)
}

struct TerminalSession {
    terminal: Terminal<CrosstermBackend<Stdout>>,
}

impl TerminalSession {
    fn start() -> Result<Self> {
        enable_raw_mode().context("could not enable raw mode")?;
        let mut stdout = io::stdout();
        // Clear the alternate screen directly instead of calling
        // `Terminal::clear`, which asks the terminal for the cursor position
        // and can block on terminals that do not answer that query.
        execute!(
            stdout,
            EnterAlternateScreen,
            Hide,
            Clear(ClearType::All),
            MoveTo(0, 0)
        )
        .context("could not enter the alternate screen")?;
        let backend = CrosstermBackend::new(stdout);
        let terminal = Terminal::new(backend).context("could not create the terminal")?;
        Ok(Self { terminal })
    }

    fn draw<F>(&mut self, draw: F) -> Result<()>
    where
        F: FnOnce(&mut Frame),
    {
        self.terminal
            .draw(draw)
            .context("could not draw the component selector")?;
        Ok(())
    }

    fn restore(&mut self) {
        let _ = disable_raw_mode();
        let _ = execute!(self.terminal.backend_mut(), LeaveAlternateScreen, Show);
        let _ = self.terminal.show_cursor();
    }
}

impl Drop for TerminalSession {
    fn drop(&mut self) {
        self.restore();
    }
}

fn draw(frame: &mut Frame, state: &mut SelectorState) {
    if state.mode == Mode::Review {
        draw_review(frame, state);
        return;
    }

    let area = frame.area();
    let chunks = Layout::vertical([
        Constraint::Length(1),
        Constraint::Min(5),
        Constraint::Length(3),
    ])
    .split(area);

    let title = format!("Minflair {} - Select components", state.version);
    let header = Paragraph::new(Line::from(vec![Span::styled(
        title,
        Style::new().fg(Color::Cyan).add_modifier(Modifier::BOLD),
    )]));
    frame.render_widget(header, chunks[0]);

    let two_pane = area.width >= 90;
    let mut list_area = chunks[1];
    let mut details_area = None;

    if two_pane {
        let left_width = (area.width * 45 / 100).clamp(36, 54);
        let panes = Layout::horizontal([Constraint::Length(left_width), Constraint::Min(24)])
            .split(chunks[1]);
        list_area = panes[0];
        details_area = Some(panes[1]);
    }

    draw_list(frame, state, list_area, two_pane);
    if let Some(area) = details_area {
        draw_details(frame, state, area);
    }
    draw_footer(frame, state, chunks[2]);
}

struct Row {
    line: Line<'static>,
    item: Option<usize>,
}

fn draw_list(frame: &mut Frame, state: &mut SelectorState, area: Rect, two_pane: bool) {
    let filtered = state.filtered();
    let selected = filtered.get(state.cursor).copied();
    let width = area.width.saturating_sub(4) as usize;
    let mut rows: Vec<Row> = Vec::new();
    let mut previous_category: Option<&str> = None;

    for &index in &filtered {
        let entry = &state.entries[index];
        let is_selected = Some(index) == selected;
        if previous_category != Some(entry.category.as_str()) {
            if previous_category.is_some() {
                rows.push(Row {
                    line: Line::from(""),
                    item: None,
                });
            }
            rows.push(Row {
                line: Line::from(Span::styled(
                    category_label(&entry.category).to_string(),
                    Style::new().fg(Color::Cyan).add_modifier(Modifier::BOLD),
                )),
                item: None,
            });
            previous_category = Some(entry.category.as_str());
        }

        let mark = if entry.core {
            Span::styled(
                "[core]",
                Style::new()
                    .fg(if is_selected {
                        state.highlight_fg
                    } else {
                        Color::Yellow
                    })
                    .add_modifier(if is_selected {
                        Modifier::BOLD
                    } else {
                        Modifier::empty()
                    }),
            )
        } else if entry.selected {
            Span::styled(
                "[x]   ",
                Style::new().fg(if is_selected {
                    state.highlight_fg
                } else {
                    Color::Green
                }),
            )
        } else {
            Span::styled(
                "[ ]   ",
                Style::new().fg(if is_selected {
                    state.highlight_fg
                } else {
                    Color::DarkGray
                }),
            )
        };

        let id_style = if entry.core {
            Style::new()
                .fg(if is_selected {
                    state.highlight_fg
                } else {
                    Color::Reset
                })
                .add_modifier(Modifier::BOLD)
        } else if entry.selected {
            Style::new().fg(if is_selected {
                state.highlight_fg
            } else {
                Color::Reset
            })
        } else {
            Style::new().fg(if is_selected {
                state.highlight_fg
            } else {
                Color::DarkGray
            })
        };

        let mut spans = vec![
            Span::raw("  "),
            mark,
            Span::raw(" "),
            Span::styled(format!("{:<18}", entry.id), id_style),
        ];

        if !two_pane && width >= 30 {
            let description_width = width.saturating_sub(28);
            if description_width > 0 {
                spans.push(Span::styled(
                    truncate(&entry.description, description_width),
                    Style::new().fg(if is_selected {
                        state.highlight_fg
                    } else {
                        Color::Gray
                    }),
                ));
            }
        }

        if is_selected {
            let used: usize = spans.iter().map(|span| span.content.chars().count()).sum();
            let available = area.width.saturating_sub(2) as usize;
            if used < available {
                spans.push(Span::raw(" ".repeat(available - used)));
            }
        }

        let mut line = Line::from(spans);
        if is_selected {
            line = line.style(Style::new().fg(state.highlight_fg).bg(state.highlight_bg));
        }
        rows.push(Row {
            line,
            item: Some(index),
        });
    }

    if rows.is_empty() {
        rows.push(Row {
            line: Line::from(Span::styled(
                format!("  No components match \"{}\".", state.filter),
                Style::new().fg(Color::Yellow),
            )),
            item: None,
        });
    }

    if selected.is_none() {
        state.scroll = 0;
    } else if let Some(row) = rows.iter().position(|row| row.item == selected) {
        let height = area.height.saturating_sub(2) as usize;
        state.ensure_visible(row, height);
    }

    let block = Block::default()
        .borders(Borders::ALL)
        .title(" Components ")
        .border_style(Style::new().fg(Color::DarkGray));
    let lines: Vec<Line> = rows.into_iter().map(|row| row.line).collect();
    let paragraph = Paragraph::new(lines)
        .block(block)
        .scroll((state.scroll as u16, 0));
    frame.render_widget(paragraph, area);
}

fn draw_details(frame: &mut Frame, state: &SelectorState, area: Rect) {
    let filtered = state.filtered();
    let entry = filtered
        .get(state.cursor)
        .and_then(|index| state.entries.get(*index));

    let mut lines: Vec<Line> = Vec::new();
    if let Some(entry) = entry {
        let marker = if entry.core {
            Span::styled("[core]", Style::new().fg(Color::Yellow))
        } else if entry.selected {
            Span::styled("[x]", Style::new().fg(Color::Green))
        } else {
            Span::styled("[ ]", Style::new().fg(Color::DarkGray))
        };
        lines.push(Line::from(vec![
            marker,
            Span::raw(" "),
            Span::styled(
                entry.label.clone(),
                Style::new().fg(Color::Cyan).add_modifier(Modifier::BOLD),
            ),
        ]));
        lines.push(Line::from(""));
        lines.push(Line::from(vec![
            Span::styled("id: ", Style::new().fg(Color::DarkGray)),
            Span::raw(entry.id.clone()),
        ]));
        lines.push(Line::from(vec![
            Span::styled("category: ", Style::new().fg(Color::DarkGray)),
            Span::raw(category_label(&entry.category).to_string()),
        ]));
        lines.push(Line::from(vec![
            Span::styled("status: ", Style::new().fg(Color::DarkGray)),
            if entry.core {
                Span::styled("core (always installed)", Style::new().fg(Color::Yellow))
            } else if entry.selected {
                Span::styled("enabled", Style::new().fg(Color::Green))
            } else {
                Span::styled("skipped", Style::new().fg(Color::DarkGray))
            },
        ]));
        lines.push(Line::from(""));
        if !entry.description.is_empty() {
            lines.push(Line::from(entry.description.clone()));
            lines.push(Line::from(""));
        }
        if !entry.paths.is_empty() {
            lines.push(Line::from(vec![
                Span::styled("paths: ", Style::new().fg(Color::DarkGray)),
                Span::raw(entry.paths.join(", ")),
            ]));
        }
        if !entry.packages.is_empty() {
            lines.push(Line::from(vec![
                Span::styled("packages: ", Style::new().fg(Color::DarkGray)),
                Span::raw(entry.packages.join(", ")),
            ]));
        }
        if !entry.reload.is_empty() {
            lines.push(Line::from(vec![
                Span::styled("reload: ", Style::new().fg(Color::DarkGray)),
                Span::raw(entry.reload.clone()),
            ]));
        }
    } else {
        lines.push(Line::from(Span::styled(
            "No component selected.",
            Style::new().fg(Color::DarkGray),
        )));
    }

    let block = Block::default()
        .borders(Borders::ALL)
        .title(" Details ")
        .border_style(Style::new().fg(Color::DarkGray));
    let paragraph = Paragraph::new(lines)
        .block(block)
        .wrap(Wrap { trim: false });
    frame.render_widget(paragraph, area);
}

fn key_span(key: &str) -> Span<'static> {
    Span::styled(
        format!(" {key} "),
        Style::new()
            .fg(Color::Black)
            .bg(Color::Cyan)
            .add_modifier(Modifier::BOLD),
    )
}

fn hint_span(label: &str) -> Span<'static> {
    Span::styled(format!(" {label}   "), Style::new().fg(Color::DarkGray))
}

fn draw_footer(frame: &mut Frame, state: &SelectorState, area: Rect) {
    let (enabled, total) = state.optional_counts();
    let skipped = total.saturating_sub(enabled);
    let mut lines = vec![Line::from(vec![
        Span::styled("  Optional components  ", Style::new().fg(Color::DarkGray)),
        Span::styled(
            format!("{enabled}/{total} enabled"),
            Style::new().fg(Color::Green).add_modifier(Modifier::BOLD),
        ),
        Span::styled(
            format!("   {skipped} skipped"),
            Style::new().fg(Color::Yellow),
        ),
    ])];

    match state.mode {
        Mode::Search => lines.push(Line::from(vec![
            Span::styled(
                "  Search: ",
                Style::new().fg(Color::Cyan).add_modifier(Modifier::BOLD),
            ),
            Span::raw(state.filter.clone()),
            Span::styled("_", Style::new().add_modifier(Modifier::RAPID_BLINK)),
        ])),
        _ if !state.filter.is_empty() => lines.push(Line::from(vec![
            Span::styled(
                "  Filter: ",
                Style::new().fg(Color::Cyan).add_modifier(Modifier::BOLD),
            ),
            Span::raw(state.filter.clone()),
            Span::styled("  (Esc clears)", Style::new().fg(Color::DarkGray)),
        ])),
        _ => lines.push(Line::from("")),
    }

    let help = if state.mode == Mode::Search {
        Line::from(vec![
            Span::raw("  "),
            key_span("Type"),
            hint_span("filter"),
            key_span("Enter"),
            hint_span("accept"),
            key_span("Esc"),
            hint_span("clear"),
        ])
    } else if area.width < 76 {
        Line::from(vec![
            Span::raw("  "),
            key_span("Space"),
            hint_span("toggle"),
            key_span("Enter"),
            hint_span("review"),
            key_span("q"),
            hint_span("cancel"),
        ])
    } else {
        Line::from(vec![
            Span::raw("  "),
            key_span("Space"),
            hint_span("toggle"),
            key_span("Enter"),
            hint_span("review"),
            key_span("a"),
            hint_span("all"),
            key_span("n"),
            hint_span("none"),
            key_span("/"),
            hint_span("search"),
            key_span("q"),
            hint_span("cancel"),
        ])
    };
    lines.push(help);

    let paragraph = Paragraph::new(lines);
    frame.render_widget(paragraph, area);
}

fn draw_review(frame: &mut Frame, state: &SelectorState) {
    let included: Vec<String> = state
        .included_labels()
        .into_iter()
        .map(str::to_string)
        .collect();
    let skipped: Vec<String> = state
        .skipped_labels()
        .into_iter()
        .map(str::to_string)
        .collect();
    let (enabled, total) = state.optional_counts();
    let notes = review_notes(state);

    let area = frame.area();
    let popup = centered_rect(area, 92, 88);
    let outer = Block::default()
        .borders(Borders::ALL)
        .title(format!(" Review selection | Minflair {} ", state.version))
        .title_alignment(Alignment::Center)
        .border_style(Style::new().fg(Color::Cyan));
    let inner = outer.inner(popup);
    frame.render_widget(outer, popup);

    let mut constraints = vec![Constraint::Length(2), Constraint::Min(5)];
    if !notes.is_empty() {
        constraints.push(Constraint::Length(notes.len() as u16 + 2));
    }
    constraints.push(Constraint::Length(3));
    let chunks = Layout::vertical(constraints).split(inner);

    let header = Paragraph::new(vec![
        Line::from(vec![
            Span::styled("  Optional components  ", Style::new().fg(Color::DarkGray)),
            Span::styled(
                format!("{enabled}/{total} enabled"),
                Style::new().fg(Color::Green).add_modifier(Modifier::BOLD),
            ),
            Span::styled(
                format!("   {} skipped", total.saturating_sub(enabled)),
                Style::new().fg(Color::Yellow),
            ),
        ]),
        Line::from(Span::styled(
            "  Core components are always installed and cannot be disabled.",
            Style::new().fg(Color::DarkGray),
        )),
    ]);
    frame.render_widget(header, chunks[0]);

    let content = chunks[1];
    let included_panel = ReviewPanel {
        title: format!(" Included ({}) ", included.len()),
        color: Color::Green,
        items: &included,
        empty: "Every optional component is selected.",
        marker: "+",
        scroll: state.review_scroll,
    };
    let skipped_panel = ReviewPanel {
        title: format!(" Skipped ({}) ", skipped.len()),
        color: Color::Yellow,
        items: &skipped,
        empty: "Nothing skipped.",
        marker: "-",
        scroll: state.review_scroll,
    };

    if content.width >= 60 {
        let columns = Layout::horizontal([
            Constraint::Percentage(55),
            Constraint::Length(1),
            Constraint::Min(20),
        ])
        .split(content);
        draw_review_panel(frame, columns[0], &included_panel);
        draw_review_panel(frame, columns[2], &skipped_panel);
    } else {
        let rows = Layout::vertical([
            Constraint::Percentage(55),
            Constraint::Length(1),
            Constraint::Min(3),
        ])
        .split(content);
        draw_review_panel(frame, rows[0], &included_panel);
        draw_review_panel(frame, rows[2], &skipped_panel);
    }

    if !notes.is_empty() {
        draw_notes_panel(frame, chunks[2], &notes);
    }

    let footer_line = if inner.width < 62 {
        Line::from(vec![
            Span::raw("  "),
            key_span("Enter/y"),
            hint_span(&state.action),
            key_span("Esc/n"),
            hint_span("back"),
        ])
    } else {
        Line::from(vec![
            Span::raw("  "),
            key_span("Enter/y"),
            hint_span(&state.action),
            key_span("Esc/n"),
            hint_span("back"),
            key_span("q"),
            hint_span("cancel"),
        ])
    };
    let footer = Paragraph::new(vec![
        footer_line,
        Line::from(Span::styled(
            "  j/k scroll   PgUp/PgDn faster",
            Style::new().fg(Color::DarkGray),
        )),
    ])
    .block(Block::default().borders(Borders::TOP));
    frame.render_widget(footer, chunks[chunks.len() - 1]);
}

struct ReviewPanel<'a> {
    title: String,
    color: Color,
    items: &'a [String],
    empty: &'a str,
    marker: &'a str,
    scroll: u16,
}

fn draw_review_panel(frame: &mut Frame, area: Rect, panel: &ReviewPanel) {
    let block = Block::default()
        .borders(Borders::ALL)
        .title(panel.title.clone())
        .border_style(Style::new().fg(panel.color));
    let lines: Vec<Line> = if panel.items.is_empty() {
        vec![Line::from(Span::styled(
            format!(" {}", panel.empty),
            Style::new().fg(Color::DarkGray),
        ))]
    } else {
        panel
            .items
            .iter()
            .map(|item| {
                Line::from(vec![
                    Span::styled(
                        format!(" {} ", panel.marker),
                        Style::new().fg(panel.color).add_modifier(Modifier::BOLD),
                    ),
                    Span::raw(item.clone()),
                ])
            })
            .collect()
    };
    let paragraph = Paragraph::new(lines)
        .block(block)
        .wrap(Wrap { trim: false })
        .scroll((panel.scroll, 0));
    frame.render_widget(paragraph, area);
}

fn draw_notes_panel(frame: &mut Frame, area: Rect, notes: &[String]) {
    let block = Block::default()
        .borders(Borders::ALL)
        .title(" Notes ")
        .border_style(Style::new().fg(Color::Yellow));
    let lines: Vec<Line> = notes
        .iter()
        .map(|note| {
            Line::from(vec![
                Span::styled(
                    " ! ",
                    Style::new().fg(Color::Yellow).add_modifier(Modifier::BOLD),
                ),
                Span::styled(note.clone(), Style::new().fg(Color::Yellow)),
            ])
        })
        .collect();
    let paragraph = Paragraph::new(lines)
        .block(block)
        .wrap(Wrap { trim: false });
    frame.render_widget(paragraph, area);
}

fn review_notes(state: &SelectorState) -> Vec<String> {
    let is_selected = |id: &str| {
        state
            .entries
            .iter()
            .any(|entry| entry.id == id && entry.selected)
    };

    let mut notes = Vec::new();
    if is_selected("zsh") {
        notes.push("zsh will be set as your login shell.".to_string());
        if !is_selected("starship") {
            notes.push("Starship is disabled; zsh will use a basic prompt.".to_string());
        }
    }
    notes
}

fn centered_rect(area: Rect, percent_x: u16, percent_y: u16) -> Rect {
    let vertical = Layout::vertical([
        Constraint::Percentage((100 - percent_y) / 2),
        Constraint::Percentage(percent_y),
        Constraint::Percentage((100 - percent_y) / 2),
    ])
    .split(area);
    let horizontal = Layout::horizontal([
        Constraint::Percentage((100 - percent_x) / 2),
        Constraint::Percentage(percent_x),
        Constraint::Percentage((100 - percent_x) / 2),
    ])
    .split(vertical[1]);
    horizontal[1]
}

fn truncate(text: &str, width: usize) -> String {
    if text.chars().count() <= width {
        return text.to_string();
    }
    let mut result: String = text.chars().take(width.saturating_sub(1)).collect();
    result.push('…');
    result
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::manifest::Manifest;

    const SAMPLE: &str = "\
id\tlabel\tcategory\tcore\tpaths\tpackages\ttheme\tfont\treload\tdescription
quickshell\tQuickshell shell\tcore\t1\tconfig/quickshell\tquickshell\t\t\t\tCore shell
hyprland\tHyprland\tcore\t1\tconfig/hypr\thyprland\t\t\t\thyprland
kitty\tKitty terminal\tterminal\t0\tconfig/kitty\tkitty\tkitty\tkitty\t\tTerminal
nvim\tNeovim\tterminal\t0\tconfig/nvim\tnvim\tnvim\t\t\tEditor
";

    fn state() -> SelectorState {
        let manifest = Manifest::parse(SAMPLE).expect("manifest");
        SelectorState::new(&manifest, &BTreeSet::new(), "test")
    }

    fn key(code: KeyCode) -> KeyEvent {
        KeyEvent::new(code, KeyModifiers::NONE)
    }

    #[test]
    fn core_components_cannot_be_toggled() {
        let mut state = state();
        state.handle_key(key(KeyCode::Char(' ')));
        assert!(state.entries[0].selected);
        assert!(!state.disabled_ids().contains("quickshell"));
    }

    #[test]
    fn toggling_records_a_disabled_component() {
        let mut state = state();
        state.handle_key(key(KeyCode::Char('j')));
        state.handle_key(key(KeyCode::Char('j')));
        state.handle_key(key(KeyCode::Char(' ')));

        let disabled = state.disabled_ids();
        assert!(disabled.contains("kitty"));
        assert!(!disabled.contains("quickshell"));
    }

    #[test]
    fn select_none_keeps_core_enabled() {
        let mut state = state();
        state.handle_key(key(KeyCode::Char('n')));

        let disabled = state.disabled_ids();
        assert_eq!(disabled.len(), 2);
        assert!(!disabled.contains("quickshell"));
        assert!(!disabled.contains("hyprland"));
    }

    #[test]
    fn search_filters_by_id_label_and_description() {
        let mut state = state();
        state.handle_key(key(KeyCode::Char('/')));
        for character in "edit".chars() {
            state.handle_key(key(KeyCode::Char(character)));
        }
        state.handle_key(key(KeyCode::Enter));

        let filtered = state.filtered();
        assert_eq!(filtered.len(), 1);
        assert_eq!(state.entries[filtered[0]].id, "nvim");
    }

    #[test]
    fn escape_clears_the_filter() {
        let mut state = state();
        state.filter = "kitty".to_string();
        state.handle_key(key(KeyCode::Esc));
        assert!(state.filter.is_empty());
    }

    #[test]
    fn review_confirms_with_enter() {
        let mut state = state();
        state.handle_key(key(KeyCode::Enter));
        assert_eq!(state.mode, Mode::Review);
        assert_eq!(state.handle_key(key(KeyCode::Enter)), Action::Confirm);
    }

    #[test]
    fn review_can_go_back() {
        let mut state = state();
        state.handle_key(key(KeyCode::Enter));
        state.handle_key(key(KeyCode::Char('n')));
        assert_eq!(state.mode, Mode::List);
    }

    fn render_review(state: &SelectorState, width: u16, height: u16) -> String {
        use ratatui::backend::TestBackend;
        use ratatui::Terminal;

        let backend = TestBackend::new(width, height);
        let mut terminal = Terminal::new(backend).expect("terminal");
        terminal
            .draw(|frame| draw_review(frame, state))
            .expect("draw review");
        terminal
            .backend()
            .buffer()
            .content()
            .iter()
            .map(|cell| cell.symbol())
            .collect()
    }

    fn render_list(state: &mut SelectorState, width: u16, height: u16) -> ratatui::buffer::Buffer {
        use ratatui::backend::TestBackend;
        use ratatui::Terminal;

        let backend = TestBackend::new(width, height);
        let mut terminal = Terminal::new(backend).expect("terminal");
        terminal
            .draw(|frame| draw(frame, state))
            .expect("draw list");
        terminal.backend().buffer().clone()
    }

    #[test]
    fn selected_row_uses_a_solid_background() {
        let mut state = state();
        let buffer = render_list(&mut state, 80, 24);

        // Title, list border, category heading, first component row.
        let cell = buffer.cell((1, 3)).expect("selected cell");
        assert_eq!(cell.bg, state.highlight_bg);
        assert!(!cell.modifier.contains(Modifier::REVERSED));

        let last = buffer.cell((78, 3)).expect("last selected cell");
        assert_eq!(last.bg, state.highlight_bg);

        // The component id must use the contrast-aware foreground.
        let id = buffer.cell((10, 3)).expect("selected id cell");
        assert_eq!(id.fg, state.highlight_fg);
    }

    #[test]
    fn first_install_uses_the_default_theme_accent() {
        let (background, foreground) = highlight_colors(DEFAULT_THEME_ACCENT, DEFAULT_THEME_BG);
        assert_eq!(background, Color::Rgb(0xa7, 0x7e, 0xf5));

        let Color::Rgb(red, green, blue) = foreground else {
            panic!("expected an RGB foreground");
        };
        assert!(contrast_ratio([red, green, blue], DEFAULT_THEME_ACCENT) >= 4.5);
    }

    #[test]
    fn parses_theme_hex_colors() {
        assert_eq!(parse_hex("#b7c5e0"), Some([0xb7, 0xc5, 0xe0]));
        assert_eq!(parse_hex("#B7C5E0"), Some([0xb7, 0xc5, 0xe0]));
        assert_eq!(parse_hex("#fff"), Some([0xff, 0xff, 0xff]));
        assert_eq!(parse_hex("#26b7c5e0"), Some([0xb7, 0xc5, 0xe0]));
        assert_eq!(parse_hex("not-a-color"), None);
    }

    #[test]
    fn light_accents_get_dark_text() {
        let (background, foreground) = highlight_colors([0xb7, 0xc5, 0xe0], [0x09, 0x09, 0x0b]);
        assert_eq!(background, Color::Rgb(0xb7, 0xc5, 0xe0));
        assert_eq!(foreground, Color::Rgb(0, 0, 0));
    }

    #[test]
    fn dark_accents_get_light_text() {
        let (background, foreground) = highlight_colors([0x30, 0x4a, 0x7a], [0x09, 0x09, 0x0b]);
        assert_eq!(background, Color::Rgb(0x30, 0x4a, 0x7a));
        assert_eq!(foreground, Color::Rgb(255, 255, 255));
    }

    #[test]
    fn low_contrast_accents_are_pushed_away_from_the_background() {
        let background = [0x09, 0x09, 0x0b];
        let accent = [0x12, 0x12, 0x14];
        let visible = ensure_visible(accent, background);

        assert!(contrast_ratio(visible, background) >= HIGHLIGHT_BACKGROUND_CONTRAST);
        assert_eq!(readable_foreground(visible), [0xff, 0xff, 0xff]);
    }

    #[test]
    fn review_shows_included_and_skipped_panels() {
        let mut state = state();
        state.handle_key(key(KeyCode::Char('j')));
        state.handle_key(key(KeyCode::Char('j')));
        state.handle_key(key(KeyCode::Char(' ')));

        let text = render_review(&state, 80, 24);
        assert!(text.contains("Review selection"));
        assert!(text.contains("Included (3)"));
        assert!(text.contains("Skipped (1)"));
        assert!(text.contains("Kitty terminal"));
        assert!(text.contains("start installation"));
    }

    #[test]
    fn review_uses_a_custom_action_label() {
        let mut state = state().with_action("save selection");
        state.mode = Mode::Review;
        let text = render_review(&state, 80, 24);
        assert!(text.contains("save selection"));
    }

    #[test]
    fn review_renders_in_a_narrow_terminal() {
        let mut state = state();
        state.mode = Mode::Review;
        let text = render_review(&state, 40, 16);
        assert!(text.contains("Included (4)"));
    }
}
