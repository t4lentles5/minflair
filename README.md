<div align="center">

# Minflair

**A modular, aesthetic Hyprland desktop environment for Arch Linux, powered by Quickshell and dynamic system-wide theming.**

<a href="#gallery">
  <img src="https://img.shields.io/badge/📸_Gallery-Explore_Styles_%26_Widgets-7f65cc?style=for-the-badge&logoColor=white" alt="View Gallery" />
</a>

<br />
<br />

<img src="./assets/preview.webp" alt="Preview" />

</div>

## ✨ Features

- **Unique shell styles** — Switch between **Convex** (organic curved frames) and **Island** (a floating pill bar with expandable widgets).
- **Adaptive wallpaper theming** — Your bar, terminals, Neovim, GTK, Qt, SDDM, Obsidian and supported apps follow the active wallpaper in real time.
- **Unified OSD and hardware controls** — Volume, microphone, brightness, keyboard locks, touchpad toggles and power alerts, integrated into the active bar style.
- **Settings center and wallpaper tools** — Crop, align and preview wallpapers, and tune mouse, touchpad, fonts and bar appearance without editing config files.
- **Music, notifications and calendar** — Media controls with a live visualizer, grouped notifications and a calendar shared by both shell styles.
- **Smart launcher and clipboard** — App search with an inline calculator, web search prefixes, quick commands and clipboard history.
- **Pomodoro and system monitor** — Focus cycles with notifications, plus live CPU, GPU, RAM and storage metrics.
- **Gaming mode** — Strips animations, blur and borders while enabling VRR and low latency.
- **Package manager and lock screen** — A graphical Arch/AUR package store and a wallpaper-matched lock screen with PAM authentication.
- **Developer-ready terminal** — Zsh, Starship, fast directory jumping, LazyGit, kitty layouts and a theme-synced Neovim setup.
- **Battery health protection** — Optional 80% charge limit for supported laptops.

---

## 📋 Requirements

- **Arch Linux** or an Arch-based distribution.
- A normal user account. Minflair refuses to run as root.
- `git`, `base-devel` and `pacman`.
- **Rust and Cargo** to build the `minflair` CLI.
- Python 3, `yay`/`paru` and the desktop dependencies are installed by the
  installer itself.

Install the build prerequisites first:

```bash
sudo pacman -S --needed git base-devel rust
```

> [!NOTE]
> The `rust` package provides `rustc` and `cargo`. If you already use `rustup`,
> `rust-toolchain.toml` pins a stable toolchain and the required components.

---

## 🚀 Quick Install

### From git

```bash
# Shallow clone to save space and time
git clone --depth 1 https://github.com/t4lentles5/minflair.git ~/.minflair
cd ~/.minflair

# Install the minflair CLI (the first build downloads the Rust dependencies)
cargo install --path cli --locked

# Run the installer
minflair install
```

`cargo install` puts the binary in `~/.cargo/bin`, which rustup adds to your
`PATH`. If you installed Rust from the `rust` package, make sure that directory
is in your shell configuration:

```bash
export PATH="$HOME/.cargo/bin:$PATH"   # add it to ~/.zshrc
```

As an alternative, build explicitly and copy the binary to a directory that is
already in `PATH`:

```bash
cargo build --release --locked
sudo install -Dm755 target/release/minflair /usr/local/bin/minflair
```

`minflair` finds the repository automatically when it is in `~/.minflair` (or
`~/.dotfiles`). For a clone in another location, pass `--repo <path>` or set
`MINFLAIR_REPO`.

> [!IMPORTANT]
>
> - Minflair is designed exclusively for **Arch Linux** distributions.
> - Run the installer as your **normal user**. It asks for `sudo` only when needed.
> - Reboot after installation so services, themes and shell changes take effect.

> [!NOTE]
> `minflair install` and `minflair update` run the native Rust pipelines,
> including the interactive selector, preferences, backups, themes, services
> and reloads. `./install.sh` and `./update.sh` remain compatibility
> entrypoints with the same selector, preferences and flags. If you do not want
> to install the CLI, both scripts keep working on their own.

> [!TIP]
> On first run, the interactive selector lets you keep your own Kitty, Neovim,
> Starship or other configuration. You can also choose `yay` or `paru` as the
> AUR helper; the choice is used by the installer, the updater and the Package
> Manager. See [docs/INSTALL.md](docs/INSTALL.md).

---

## 🩺 Diagnostics

The CLI can inspect the environment before or after installing:

```bash
minflair doctor             # human-readable report
minflair doctor --packages  # also check packages.txt and packages-aur.txt
minflair doctor --json      # machine-readable report for automation
```

`doctor` checks the Arch base, required tools, repository, manifest,
preferences, AUR helper, themes, services and the active Hyprland/Quickshell
session. It never changes anything.

---

## 🔄 Updating

With `minflair` in `PATH`, pull and update in one step:

```bash
minflair update --pull
```

`--pull` runs `git pull --ff-only` and then rebuilds and reinstalls the CLI
automatically, so the command stays up to date. Use `--no-build` to skip the
rebuild, or omit `--pull` if you already pulled.

To update manually instead:

```bash
cd ~/.minflair
git pull --ff-only
cargo install --path cli --locked --force
minflair update
```

> If you cloned Minflair before 2.2.0, the repository may still be in
> `~/.dotfiles`. The folder name does not affect the CLI, `install.sh` or
> `update.sh`.

The updater backs up replaced files to `~/.minflair_backup/<timestamp>/`,
copies the updated configuration, installs new dependencies, refreshes the
`minflair-sddm` theme and reloads Hyprland and Quickshell. Both
`minflair update` and `./update.sh` run the same native pipeline.

> [!NOTE]
> The update overwrites configuration files with the repository versions.
> Previous files are kept in the backup directory. See
> [docs/INSTALL.md](docs/INSTALL.md#restoring-a-backup) for restore commands and
> the SDDM preview command.

---

## 📚 Documentation

| Guide                                      | Contents                                           |
| ------------------------------------------ | -------------------------------------------------- |
| [Install and update](docs/INSTALL.md)      | Selector, preferences and partial adoption         |
| [Advanced usage](docs/ADVANCED.md)         | Non-interactive flags, dry runs and automation     |
| [Components](docs/COMPONENTS.md)           | Manifest format and runtime gating                 |
| [Post-installation setup](docs/SETUP.md)   | Avatar, wallpapers, monitors, OCR and DDC/CI       |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Logs, brightness, notifications and install errors |

---

<a id="gallery"></a>

## 🖥️ Shell Styles & Desktop Experience

Minflair is designed around distinct bar architectures and a unified suite of desktop utilities. You can switch styles anytime directly from the Settings app:

### 🌟 Convex Style

The signature desktop layout. Features an organic curved bezel frame where top widgets (Control Center, Notifications, Music, Dashboard) and bottom tools (Launcher, Clipboard, Wallpaper Selector) connect directly into the screen contours.

<img src="./assets/convex.webp" alt="Convex Style Preview" />

### 🏝️ Island Style

A modern, floating pill bar with an expandable dynamic island center. Notifications, media playback, and quick controls expand smoothly from the island while preserving maximum screen real estate.

<img src="./assets/island.webp" alt="Island Style Preview" />

### 🎮 Gaming Mode

An ultra-clean, zero-overhead bar dedicated to gaming sessions. Strips away all blur, animations, and rounded frames, activating tear-free variable refresh rate (VRR) and minimal latency for maximum performance.

<img src="./assets/gaming.webp" alt="Gaming Mode Preview" />

### 📱 Standalone Applications

Deep graphical customization built natively for Arch Linux:

<table align="center">
  <tr>
    <td align="center" width="50%">
      <b>Settings App</b><br />
      <img src="./assets/settings.png" alt="Settings App" /><br />
      Complete control over wallpapers, cropping, touchpad, and desktop effects.
    </td>
    <td align="center" width="50%">
      <b>Package Manager</b><br />
      <img src="./assets/package-manager.png" alt="Package Manager" /><br />
      Searchable GUI store to inspect, install, and update Arch &amp; AUR packages.
    </td>
  </tr>
  <tr>
    <td align="center" width="50%">
      <b>Keybinds Cheat Sheet</b><br />
      <img src="./assets/keybinds.png" alt="Keybinds Cheat Sheet" /><br />
      Interactive shortcut browser accessible anytime with <code>Super + K</code>.
    </td>
    <td align="center" width="50%">
      <b>Pomodoro</b><br />
      <img src="./assets/pomodoro.png" alt="Pomodoro Timer Preview" /><br />
      Focus timer with configurable cycles, notifications, sound cues, and daily session tracking.
    </td>
  </tr>
</table>

### 🔒 Lock Screen

A clean, wallpaper-matched lock screen featuring PAM authentication, smooth unlock transitions, and real-time battery and system status.

<img src="./assets/lockscreen.png" alt="Lock Screen Preview" />

### 🚪 SDDM Login Screen

A dynamic, theme-synced login screen (`minflair-sddm`) that adapts its background to your active wallpaper in real time, featuring smooth user authentication and profile picture support.

<img src="./assets/sddm.png" alt="SDDM Login Screen Preview" />

### 🎚️ On-Screen Display (OSD)

Centralized, minimal on-screen displays integrated natively into Quickshell IPC across both Convex and Island styles. Delivers instant visual feedback for volume, microphone mute, display brightness, Caps/Num Lock keys, touchpad toggles, power notifications, and screen capture actions.

<img src="./assets/osd.webp" alt="OSD Preview" />

### 🎛️ Shell Utilities & Overlays

All desktop styles share a cohesive, shared set of utilities:

- **Notification Center**: Dedicated panel for alert history with per-app grouping, expandable stacks, and an unread badge on the bar.
- **Music & Visualizer**: Sleek media player with album artwork, live audio bars, and seek control.
- **Smart Launcher & Clipboard**: Keyboard-driven app search with calculator, web search prefixes, quick commands, and clipboard history management.
- **Calendar**: Unified calendar popup shared across Convex and Island styles.
- **System Usage**: CPU, GPU, memory, and storage monitoring with live metrics and per-disk details.
- **Screen Capture**: All-in-one screenshot tool (region/window/delay/OCR) and screen recorder.

## ⌨️ Keybinds

> [!NOTE]
> You don't need to memorize these! Press `SUPER + K` at any time to open the built-in **Keybinds Cheat Sheet** directly on your desktop.

| Shortcut         | Action              |
| :--------------- | :------------------ |
| `CTRL + ALT + D` | Dashboard           |
| `CTRL + ALT + M` | Music player        |
| `CTRL + ALT + N` | Notification Center |
| `CTRL + ALT + F` | System Usage        |
| `CTRL + ALT + C` | Calendar            |
| `CTRL + ALT + T` | Pomodoro            |
| `CTRL + ALT + W` | Wallpaper Selector  |
| `SUPER + V`      | Clipboard history   |
| `SUPER + S`      | Minflair Settings   |

## 📜 License and Credits

This project is licensed under the [GNU General Public License v3.0](LICENSE).

### Third-Party Assets & Projects

- **Tabler Icons**: Licensed under the [MIT License](https://github.com/tabler/tabler-icons/blob/master/LICENSE).
- **Material Symbols (Google Fonts)**: Licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
- **Material GNOME Theme**: Custom fork at [t4lentles5/material-gnome-theme](https://github.com/t4lentles5/material-gnome-theme) (upstream: [SakibShahariar/material-gnome-theme](https://github.com/SakibShahariar/material-gnome-theme)), licensed under the [GNU General Public License v3.0](https://github.com/SakibShahariar/material-gnome-theme/blob/main/LICENSE).
- **tokyo-night-sddm**: Custom fork at [t4lentles5/tokyo-night-sddm](https://github.com/t4lentles5/tokyo-night-sddm) (`minflair-sddm`) (upstream: [rototrash/tokyo-night-sddm](https://github.com/rototrash/tokyo-night-sddm)), licensed under the [GNU General Public License v3.0](https://github.com/rototrash/tokyo-night-sddm/blob/master/LICENSE). Tailored for Minflair with dynamic wallpaper background synchronization.
- **luna.nvim**: Custom fork at [t4lentles5/luna.nvim](https://github.com/t4lentles5/luna.nvim) (upstream: [WTFox/luna.nvim](https://github.com/WTFox/luna.nvim)), licensed under the [MIT License](https://github.com/WTFox/luna.nvim/blob/main/LICENSE). Tailored specifically for Minflair to enable real-time dynamic palette hot-reloading and automatic Lualine synchronization.
- **Simple Icons**: Licensed under the [CC0 1.0 Universal License](https://creativecommons.org/publicdomain/zero/1.0/).
