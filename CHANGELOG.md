# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-09-30

### Added

- **Multi-Style Bar & Overlay Architecture**: Support for 4 distinct visual styles (`Convex`, `Island`, `Notch`, and `Minflair`) across the status bar and overlay window hosts (`IslandHost`, `NotchHost`, `CornerPopup`, `OverlayWindow`, `GlobalPopups`).
- **Dedicated Notification Center**: Independent `NotificationCenter` module and popup decoupled from the Control Center, with its own dedicated bar trigger button, notification history, and clear-all actions.
- **Mouse & Touchpad Settings**: New configuration module (`MouseSettings`) in the Settings app supporting pointer sensitivity (DPI), acceleration profile (`flat` raw 1:1 vs `adaptive`), left-handed mode, natural scrolling, scroll speed factor, and touchpad preferences (tap-to-click, tap-and-drag, disable while typing).
- **Standalone MusicPopup Module**: Dedicated music interface featuring a real-time Cava audio visualizer, synchronized auto-scrolling lyrics panel (`LyricsService`), playback controls, and wave progress tracking.
- **Modular Theme System**: Refactored theme engine using modular extractors (`palette.py`, `magick_utils.py`, `image_utils.py`) and dedicated appliers for GTK, Qt, Kitty, Hyprland, LazyGit, Neovim, Btop, Starship, plus font (`apply_font.py`) and cursor (`apply_cursor.py`) management.
- **Revamped Package Manager**: Completely redesigned interface featuring debounced real-time search, rich package inspection cards (hero details, dependencies, relations, specifications, resources), category browsing, and a `.desktop` integration with IPC toggle support (`toggle_minflair_packagemanager.sh`).
- **Application Window Templates**: Standardized `SidebarAppWindow` and `SearchAppWindow` base templates with modular building blocks (`AppContainer`, `AppGroup`, `IconSidebar`, `SettingRowTemplate`, `ThemedSelect`).
- **Bar Settings**: Added dedicated `BarSettings` panel in Settings to customize bar styles, positioning, and widget configurations.
- **Unified Screen Capture**: Modernized `ScreenCapture` module replacing legacy screenshot popups, with Wayland socket auto-detection for `grim`, `slurp`, and `wf-recorder`, 3-second delayed screenshot mode, and completion desktop notifications.
- **Battery Charge Threshold**: Added hardware detection and toggle script (`toggle_battery_limit.sh`) supporting major laptop vendors (ASUS, Lenovo, Dell, Acer, Apple Silicon, etc.) to limit battery charging to 80%.
- **LockScreen IPC Controller**: Added `LockScreenIpcController` for external lock/unlock IPC signaling and redesigned lockscreen status groups.
- **Fullscreen Window Detection**: Real-time Hyprland event tracking for active fullscreen windows across bar and overlay hosts.
- **Notification Center Keybind**: Added `CTRL + ALT + N` shortcut in Hyprland (`keybinds.lua`) to toggle the Notifications Center via Quickshell IPC socket (`quickshell_notificationsCenter`).
- **Hardware & Sensor Robustness**:
  - Dynamic CPU temperature sensor scanning (`hwmon` and `thermal_zone`).
  - Dynamic DRM GPU detection supporting hybrid graphics, eGPUs, and multiple display controllers.
  - Universal battery discovery supporting any power supply identifier (`BAT0`, `BAT1`, etc.).
  - Auto-restart watchdog timer for background system stats monitoring.
  - Multi-language package query support (`LC_ALL=C` enforced).

### Changed

- **Revamped Quick Settings**: Overhauled Control Center with modular `QuickSettingsSliderCard` components for dedicated volume and brightness sliders, unified list delegates (`ControlCenterListDelegate`) for Wi-Fi and Bluetooth pickers, and optimized tile interactions.
- **Dynamic Content-Based Sizing**: Replaced fixed window dimensions with dynamic content-driven sizing across popup modules (`PopupCrossfadeHost`, `OverlayWindow`, `Launcher`, `Clipboard`, `ScreenCapture`, `WallpaperSelector`).
- **Popup Animation & Lifecycle Polish**:
  - Refined entrance/exit animations, durations, and easing curves in `TopPopup` without overshoot.
  - Deferred system tray menu reset and active popup cleanup until `onFullyClosed` for smoother closing transitions.
  - Removed item stagger delays in `TrayMenu` for instantaneous and responsive rendering.
  - Enhanced floating popup visibility detection across active transitions in `BarPopups`.
- **Event-Driven Workspace Refresh**: Switched workspace tracking to immediate Hyprland IPC event listeners with real-time active window detection.
- **Script Directory Reorganization**: Modularized internal scripts into respective component directories (`Modules/*/scripts`) and categorized system/theme subdirectories (`Scripts/system`, `Scripts/theme`).
- **Popup Lifecycle Management**: Enhanced outside-click detection, close handling, and focus management across popup hosts and sidebar windows.
- **Centralized Font Application**: Consolidated font application logic into `apply_font.py` and updated MPRIS player defaults.
- **Clipboard History**: Automatically pre-selects the first item on open for faster keyboard navigation.
- **Refactored Bar Dashboard**: Streamlined widget with GitHub contributions integration.
- **Decoupled Window Hosts**: Separated window hosts and content delegates across all primary modules (`ClipboardContent`, `LauncherContent`, `PowerMenuContent`, `ControlCenterContent`).
- **Upgraded Neovim Configuration**: Improved UI/UX and web development support.
- **Terminal & TUI Polish**: Updated Kitty terminal padding and LazyGit theme integration.
- **Modernized Notification Overlays**: Streamlined toast notifications (`ConvexNotificationOverlay`, `MinflairNotificationOverlay`) matching active shell styles.
- **Python Bytecode Prevention**: Disabled `__pycache__` generation (`PYTHONDONTWRITEBYTECODE=1` / `sys.dont_write_bytecode = True`) across all internal scripts to maintain a clean dotfiles repository.

### Fixed

- **Package Manager Search Responsiveness**: Implemented query debouncing with a timer in `PackageManager.qml` to prevent laggy search executions on fast typing.
- **Music Lyrics Scrolling & Filtering**: Improved synchronized auto-scrolling behavior in `MusicLyricsPanel` and cleaned up lyrics filtering in `get_lyrics.py`.
- **Notification Center Module Import**: Corrected module import path for `NotificationCenter` in `PopupCrossfadeHost.qml`.
- **Missing Module Import**: Added missing `qs.Core` import in `InputAndClipboardSettings.qml`.
- **Colorscheme Path Reference**: Fixed local directory path reference for `luna.nvim` in colorscheme configuration.
- **System Stats Indentation**: Fixed GPU indentation and added auto-restart watchdog timer to system stats monitor.

### Removed

- **Framed Bar Style**: Removed `FramedBar`, `FramedOverlayStyle`, and `FramedNotificationOverlay` in favor of the cleaner, unified `Convex` mode.
- **Redundant Quick Settings Tiles**: Removed `CaptureControl`, `MicControl`, and `VolumeControl` tiles in Quick Settings in favor of dedicated sliders and standalone modules.
- **Repository Badge**: Removed obsolete repository badge from Package Manager details hero card.
- **Bar Compatibility Legacy Code**: Removed deprecated bar compatibility properties and legacy UI elements.
- **Legacy UI Components**: Removed legacy `MainPanel`, `ActivityWatch`, and outdated performance tabs from the bar.
- **Legacy Screenshot Popup**: Removed legacy monolithic `Screenshot.qml` popup.
- **Obsolete Scripts & UI Elements**: Cleaned up obsolete scripts (`refactor_apply_theme.py`, `power_action.sh`) and unused UI components (`ThemedTab`, `ThemedTabs`, `ShadowedText`).

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
