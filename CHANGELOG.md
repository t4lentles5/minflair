# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.1] - 2026-09-25

### Fixed
- Fixed an issue where the battery icon would disappear on laptops where the battery is mapped to `BAT0` instead of `BAT1`.
- Added universal ACPI battery auto-detection across `/sys/class/power_supply/` supporting multiple laptop vendors and non-standard battery names.
- Prevented battery status `Unknown` from incorrectly hiding the battery widget when plugged in or fully charged.

## [1.3.0] - 2026-08-09

### Added
- New utility SVG icons (`clipboard.svg`, `keyboard.svg`, `edit-filled.svg`) for the Settings UI.

### Changed
- Modularized the Settings application architecture by splitting large monolithic files into dedicated subdirectories.
- Redesigned `AnimatedMinflair.qml` and `MiniMusicWidget.qml` components for a modern look.
- Updated gradients and paths for `settings-icon.svg` and `keybinds-icon.svg`.
- Prevented a potential double-close bug in `NotificationData.qml`.

## [1.2.2] - 2026-08-09

### Fixed
- Fixed an issue in `brightness.sh` and `volume.sh` where empty notification IDs would cause unexpected behavior.

### Removed
- Removed `pokemon-colorscripts` from `.zshrc` and `install.sh` to reduce bloat.

## [1.2.1] - 2026-08-07

### Fixed
- Resolved a bug in `screenshot.sh` that prevented screenshots from being captured correctly.
- Removed a redundant screenshot option in the `Screenshot.qml` UI to streamline the experience.

## [1.2.0] - 2026-08-07

### Added

- Native Python scripts (`read_hypr_prefs.py` and `update_hypr_prefs.py`) to safely read and persist Hyprland configurations directly to `~/.config/hypr/userprefs.lua`.

### Changed

- Transitioned Hyprland configuration management to use native file modifications instead of ephemeral `hyprctl` runtime commands.
- Updated `PerformanceWidget.qml` descriptions to reflect that the "Performance" and "Balanced" profiles now natively restore Hyprland configuration.
- Optimized `PersonalizationSettings.qml` to prevent redundant font updates and synced font configurations with the Hyprland groupbar.
- Enhanced Zsh prompt configuration in `.zshrc` by adding an empty line before the prompt for improved readability and fixing `clear`/`fastfetch` aliases.

### Removed

- Deprecated Hyprland configuration states from `SettingsService.qml` as they are now securely managed natively on disk.
- Cleaned up leftover `/tmp` debug logging in `auth.py`, `record.sh`, and `screenshot.sh`.

## [1.1.0] - 2026-08-06

### Added

- System-wide font and size management via a custom settings module and Python script.
- Expanded Hyprland decoration settings, adding controls for border size and shadows.
- Modular categorized settings modules (`EffectsSettings.qml`, `IntegrationsSettings.qml`, `PersonalizationSettings.qml`, `SystemInputSettings.qml`, `WindowSettings.qml`).
- Core UI components (`GhostEmptyState.qml`, `PageTransitionView.qml`, `SearchableSidebar.qml`, `SidebarItem.qml`).
- New application and script for keybinds (`minflair-keybinds.desktop`, `toggle_minflair_keybinds.sh`).
- Scalable UI SVG icons (`apps.svg`, `hyprland.svg`, `neovim.svg`, `sparkles.svg`, etc.).
- Utility modules like `ColorUtils.qml`.

### Changed

- Refactored shell configuration by separating bar and popup surfaces.
- Performance: Enabled `mipmap` and optimized `sourceSize` for images across all modules.
- Massive refactoring of the Settings module to use the new modular submodules instead of monolithic files.
- Updated Settings components (`SettingContainer`, `SettingGroup`, `SettingSegmented`, `SettingSelect`, `SettingSpinBox`, `SettingToggle`, `SettingsSidebar`).
- Updated Python scripts (`apply_theme.py`, `generate_theme.py`, `parse_keybinds.py`).
- Updated Hyprland configurations (`autostart.lua`, `keybinds.lua`, `windowrules.lua`) and Fastfetch config.
- Minor UI tweaks in several modules (Bar, Clipboard, ControlCenter, KeybindsCheatSheet, WallpaperSelector, etc.).
- Updated `install.sh` script.

### Removed

- Deprecated `BarWindow` component.
- Monolithic legacy settings modules (`AppearanceSettings.qml`, `WindowManagerSettings.qml`, `DefaultAppsSettings.qml`, `QuoteSettings.qml`, `ServicesSettings.qml`, `SystemSettings.qml`, `UpdatesSettings.qml`).
- Deprecated battery icon SVGs.

## [1.0.7] - 2026-07-31

### Added

- Display system stats instead of hostname on the lockscreen.
- Quote categories and a dedicated quotes settings page.

### Changed

- Adjusted lockscreen font sizes and wallpaper selector colors.
- Updated project description in README.
