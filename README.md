<div align="center">

# Minflair

**A modular, aesthetic Hyprland desktop environment for Arch Linux, powered by Quickshell and dynamic system-wide theming.**

<img src="https://res.cloudinary.com/diu2godjy/image/upload/v1790370056/output_qn24n5.webp" alt="Preview" />

</div>

---

## ✨ Features

- 🎨 **Multi-Style Shell Architecture** — Seamlessly switch between 5 distinct visual styles: **Convex**, **Framed**, **Island**, **Notch**, and **Minflair**.
- 🌈 **Modular Dynamic Theming** — Generate and auto-apply harmonious color schemes from your current wallpaper across GTK, Qt, Neovim, Starship, Kitty, Hyprland, LazyGit, and Btop.
- 🔤 **Font & Cursor Management** — Easily customize and apply global system fonts, font sizes, and cursor themes directly from the Settings UI.
- 🎵 **Dedicated Music & Visualizer** — Standalone music popup featuring a live Cava audio visualizer, synchronized lyrics, and media playback controls.
- 📦 **Rich Package Manager** — Native graphical package manager with deep package inspection (dependencies, relations, specs, resources) and AUR support.
- 🖼️ **Wallpaper Selector** — Browse, search, and apply wallpapers directly from an interactive grid widget.
- 🔒 **Lock Screen** — Custom Lock Screen built in Quickshell with IPC controller support and robust PAM authentication.
- ⚡ **Zsh & Neovim** — Fully configured developer environment with Starship, fzf-tab, LazyGit, and Neovim (lazy.nvim) auto-synced with your theme.
- 🔋 **Battery Life Optimization** — Integrated 80% charge limit toggle supporting major laptop vendors (ASUS, Lenovo, Dell, Acer, Apple Silicon, etc.).

---

## 🚀 Quick Install

```bash
# Clone this repository (shallow clone to save space and time)
git clone --depth 1 https://github.com/t4lentles5/minflair.git ~/.dotfiles

# Enter the directory
cd ~/.dotfiles

# Give execution permissions to the script and run it
chmod +x install.sh
./install.sh
```

> [!IMPORTANT]
>
> - This script is exclusively designed for **Arch Linux** based distributions (it uses `pacman` natively).
> - **NOTE:** Run the script as your **normal user**. The script will ask for `sudo` permissions on its own when strictly necessary to install system packages.

---

## 🔧 Post-Installation Setup

### 1. Reboot

Once the script finishes, **reboot your computer** to ensure your new `zsh` shell, global variables, themes, and system daemons are fully loaded:

```bash
sudo reboot
```

### 2. Set your profile picture (`.face`)

The Quickshell dashboard displays your user avatar from `~/.face`. Place a **square image** (PNG or JPG, 256×256 recommended) in your home directory:

```bash
# Copy your desired profile picture
cp /path/to/your/avatar.png ~/.face
```

### 3. Set your wallpaper

Wallpapers are stored in `~/Pictures/Wallpapers/`. You can add your own wallpapers to this directory and use the wallpaper selector widget (`Ctrl + Alt + W`) to apply them.

### 4. Monitor Configuration

The default monitor config is set to auto-detect. If you need custom resolution, refresh rate, or multi-monitor setup, edit:

```bash
~/.config/hypr/monitors.lua
```

Refer to the [Hyprland Wiki — Monitors](https://wiki.hyprland.org/Configuring/Monitors/) for syntax details.

### 5. Restore from Backup

If anything goes wrong, the installer creates a timestamped backup of your previous configuration:

```
~/.dotfiles_backup/<timestamp>/
```

### 6. OCR Language Support

The built-in Optical Character Recognition (OCR) feature comes with English (`tesseract-data-eng`) and Spanish (`tesseract-data-spa`) support installed by default. If you need support for other languages, you must install the respective `tesseract-data-*` package via pacman. For example, for French:

```bash
sudo pacman -S tesseract-data-fra
```

### 7. Battery Charge Limit (Laptops)

The Sidebar Control Center includes a quick toggle to cap your battery charge (typically at 80%) to prolong battery lifespan. The installer automatically configures hardware detection and passwordless toggle permissions for supported laptop vendors:

- **Acer**: Automatically installs `acer-wmi-battery-dkms`.
- **ASUS** (ROG, TUF, ZenBook): Handled natively via the `asus-wmi` kernel driver.
- **Lenovo** (ThinkPad, IdeaPad, Legion): Handled natively via `thinkpad_acpi` / `ideapad_laptop` conservation mode.
- **Dell**: Supported with `libsmbios` / kernel sysfs.
- **Framework, LG Gram, Samsung, Sony Vaio, Huawei, Apple Silicon, System76**: Supported natively through Linux kernel battery drivers.

---

## 🖥️ Quickshell Widgets

This rice features a collection of custom widgets built with Quickshell, designed to be fast, interactive, and completely integrated with the system's dynamic styling:

- **Dashboard**: An integrated dashboard featuring your GitHub contributions graph, system statistics, package updates, and daily quotes.
  <img src="https://res.cloudinary.com/diu2godjy/image/upload/v1790370208/Shot-2026-09-25-160258_jxwpzx.png" alt="Dashboard Widget" />

- **Music & Lyrics Popup**: A standalone media interface with a real-time Cava audio visualizer, synchronized lyrics via `LyricsService`, progress wave, and full playback controls.
  <img src="https://res.cloudinary.com/diu2godjy/image/upload/v1790370379/Shot-2026-09-25-160553_tjqvhh.png" alt="Music and Lyrics Popup Widget" />

- **Settings App**: A modular graphical interface built on `SidebarAppWindow` to configure your rice, bar styles, credentials, and preferences effortlessly without manually editing files.
  <img src="https://res.cloudinary.com/diu2godjy/image/upload/v1790370463/Shot-2026-09-25-160728_s57pwz.png" alt="Settings App Widget" />

- **Lock Screen**: A fully functional custom lock screen with external IPC controller and PAM authentication, fully integrated with your dynamic theme.
  <img src="https://res.cloudinary.com/diu2godjy/image/upload/v1790371434/Shot-2026-09-25-162333_vn5jwk.png" alt="Lock Screen Widget" />

- **Keybinds Cheat Sheet**: A built-in, searchable overlay built on `SearchAppWindow` that displays all your configured shortcuts directly on your desktop.
  <img src="https://res.cloudinary.com/diu2godjy/image/upload/v1790370703/Shot-2026-09-25-161127_z3d2da.png" alt="Keybinds Cheat Sheet Widget" />

- **Wallpaper Selector**: An interactive grid browser that lets you preview and apply wallpapers from `~/Pictures/Wallpapers/` on the fly.
  <img src="https://res.cloudinary.com/diu2godjy/image/upload/v1790370867/Shot-2026-09-25-161410_huws7s.png" alt="Wallpaper Selector Widget" />

- **Sidebar (Control Center)**: A unified control center featuring quick toggles (Wifi, Bluetooth, Night Light, Game Mode, Caffeine, Battery Limit), brightness sliders, and desktop notifications.
  <img src="https://res.cloudinary.com/diu2godjy/image/upload/v1790371044/Shot-2026-09-25-161627_wmeb7g.png" alt="Sidebar Control Center Widget" />

- **System Tray**: A minimalist system tray popup to manage active background applications and status indicators with styled context menus.
  <img src="https://res.cloudinary.com/diu2godjy/image/upload/v1790371570/Shot-2026-09-25-162550_khyllq.png" alt="System Tray Widget" />

- **Application Launcher**: A clean, keyboard-navigable menu to search and run applications.
  <img src="https://res.cloudinary.com/diu2godjy/image/upload/v1790371113/Shot-2026-09-25-161814_planwy.png" alt="Application Launcher Widget" />

- **Package Manager**: A rich graphical utility to search, view package details, dependencies, relations, install, update, and remove official Arch Linux and AUR packages.
  <img src="https://res.cloudinary.com/diu2godjy/image/upload/v1790371179/Shot-2026-09-25-161925_xky3ci.png" alt="Package Manager Widget" />

- **Clipboard History**: A handy widget to browse and paste from your clipboard history.
  <img src="https://res.cloudinary.com/diu2godjy/image/upload/v1790371276/Shot-2026-09-25-162101_m9c1ej.png" alt="Clipboard History Widget" />

- **Screen Capture**: A dedicated tool for taking screenshots (full, area, window, delay, OCR text extraction) and recording your screen.
  <img src="https://res.cloudinary.com/diu2godjy/image/upload/v1790371339/Shot-2026-09-25-162202_ciawww.png" alt="Screen Capture Widget" />

- **Power Menu**: A sleek menu for session management (shutdown, reboot, suspend, lock, logout).
  <img src="https://res.cloudinary.com/diu2godjy/image/upload/v1790371393/Shot-2026-09-25-162259_fktls0.png" alt="Power Menu Widget" />

## ⌨️ Keybinds

> [!NOTE]  
> You don't need to memorize these! Press `SUPER + K` at any time to open the built-in **Keybinds Cheat Sheet** directly on your desktop!

## ❓ Troubleshooting

<details>
<summary><b>Inspect Quickshell logs or debug UI issues</b></summary>

If any widget is not showing up or an error occurs in the UI, you can view live Quickshell logs in your terminal:

```bash
qs log
```

This will output real-time QML errors, warnings, missing components, or script failures.

</details>

<details>
<summary><b>Battery charge limit toggle not working</b></summary>

Ensure your laptop vendor supports charging thresholds via the Linux kernel. Check if your vendor's kernel module is loaded (e.g. `asus_wmi`, `ideapad_laptop`, `thinkpad_acpi`). For Acer laptops, the installer automatically configures `acer-wmi-battery-dkms`.

</details>

<details>
<summary><b>Quickshell dashboard shows a generic avatar</b></summary>

Place a square image at `~/.face` (PNG or JPG). The dashboard reads it from `$HOME/.face`. SDDM also uses this file for the login screen.

```bash
cp /path/to/avatar.png ~/.face
```

</details>

<details>
<summary><b>No wallpapers appear in the wallpaper selector</b></summary>

You must manually place your own wallpapers in the `~/Pictures/Wallpapers/` directory. Create this directory if it doesn't exist and add your images there.

</details>

<details>
<summary><b>GTK apps don't follow the theme change</b></summary>

Nautilus is automatically restarted when switching between light ↔ dark mode. For other GTK apps, you may need to close and reopen them. The `nwg-look` tool is used during installation to apply the initial GTK settings.

</details>

<details>
<summary><b>Notifications aren't showing</b></summary>

The installer disables `dunst` because Quickshell handles notifications natively. If you installed another notification daemon, it may conflict. Check with:

```bash
systemctl --user status dunst.service
```

</details>

<details>
<summary><b>Installation errors or packages failed to install</b></summary>

The installer automatically captures all warnings and errors in a log file. You can check it to find out exactly what went wrong:

```bash
cat ~/install_errors.log
```

If packages failed to install, ensure your mirrors are up to date (`sudo pacman -Syy`) and that your AUR helper is working correctly (`yay -Syu`).

</details>

## 📜 License and Credits

This project is licensed under the [GNU General Public License v3.0](LICENSE).

### Third-Party Assets & Projects

- **Tabler Icons**: Licensed under the [MIT License](https://github.com/tabler/tabler-icons/blob/master/LICENSE).
- **Material Symbols (Google Fonts)**: Licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0).
- **Material GNOME Theme**: Custom fork at [t4lentles5/material-gnome-theme](https://github.com/t4lentles5/material-gnome-theme) (upstream: [SakibShahariar/material-gnome-theme](https://github.com/SakibShahariar/material-gnome-theme)), licensed under the [GNU General Public License v3.0](https://github.com/SakibShahariar/material-gnome-theme/blob/main/LICENSE).
- **luna.nvim**: Custom fork at [t4lentles5/luna.nvim](https://github.com/t4lentles5/luna.nvim) (upstream: [WTFox/luna.nvim](https://github.com/WTFox/luna.nvim)), licensed under the [MIT License](https://github.com/WTFox/luna.nvim/blob/main/LICENSE).
- **Simple Icons**: Licensed under the [CC0 1.0 Universal License](https://creativecommons.org/publicdomain/zero/1.0/).
