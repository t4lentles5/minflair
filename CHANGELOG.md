# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] - 2026-10-09

### Added

- **Multi-Style Bar & Gaming Architecture**:
  - **Convex Style**: Screen framing with curved corner bezels (`ConvexFrameBezel`) where all widgets, drawers, and panels seamlessly connect to the bar and desktop contours via custom organic shapes (`ConvexBottomHost`, `ConvexRightHost`, `ConvexShape`, `ConvexDrawerShape`).
  - **Island Style**: Floating dynamic pill bar with expandable island host (`BarCenterContent`, `IslandOverlayStyle`) and configurable right circular island display modes (Auto, Music, Control Center).
  - **Dedicated Gaming Mode (`GamingBar` & `GamingOverlay`)**: High-performance, non-floating surface with zero radius, disabled animations, direct system stats, and zero render overhead.
  - **Gaming Mode Hyprland Profile**: Dynamic profile enforcing `direct_scanout = 1`, VRR (`misc.vrr = 1`), disabled animations (`animations.enabled = false`), zero rounding, disabled blur/shadows, and reduced window gaps.
  - **Gaming Mode Persistence**: Watcher for Hyprland `configreloaded` events to automatically restore game mode optimizations, plus boot-time restoration when enabled.
- **Interactive Wallpaper Crop & Settings (`WallpaperSettings`)**:
  - Dedicated `WallpaperSettings` page in Settings with real-time interactive cropping preview (`WallpaperCropPreview`).
  - Aspect ratio guide frames (`WallpaperCropFrame`) and precise position slider (`WallpaperCropPositionBar`).
  - Configurable wallpaper scaling modes (`Crop (Fill)`, `Fit`, `Stretch`), auto-shuffle timer, and transition customization.
- **Refined Workspace Indicator Behavior (`Workspaces.qml`)**:
  - Maintained the clean pill-and-dot visual aesthetic while revamping its underlying behavior.
  - Dynamic slot count calculation (`visibleWorkspaceCount`) that automatically adapts visible indicators to active and occupied workspaces plus one empty slot.
  - Replaced expanding text number overlays with clean geometric width and scale animations for active and hovered states.
  - Enlarged mouse hitboxes and integrated mouse-wheel scrolling for smooth workspace navigation.
- **Mouse & Touchpad Settings**:
  - Dedicated configuration module (`MouseSettings`) in Settings supporting pointer sensitivity (DPI), acceleration profile (`flat` raw 1:1 vs `adaptive`), left-handed mode, natural scrolling, and touchpad preferences (tap-to-click, tap-and-drag, disable-while-typing).
- **Standalone Music & Cava Visualizer**:
  - Standalone music popup featuring real-time Cava audio visualizer bars (`MusicCavaBars.qml`).
  - Typewriter track metadata, rounded cover art, interactive progress bar, and complete MPRIS media controls.
- **Decoupled Notification Center**:
  - Independent `NotificationCenter` module with a dedicated status bar trigger, unread notification counter badge, and full history list.
  - Smooth clear-all animation and individual notification dismissals.
- **Modular Package Manager**:
  - Completely redesigned modular interface (`PackageManagerSidebar`, `PackageDetailsOverlay`, `PackageDetailsHero`, `PackageSpecsCard`, `PackageRelationsCard`, `PackageResourcesCard`).
  - Real-time debounced package search supporting official Arch repositories and AUR.
  - Featured packages curation (`featured_packages.json`) and external `.desktop` / script launch toggle.
- **Keybinds Cheat Sheet Redesign**:
  - Redesigned search interface with category sidebar (`KeybindsSidebar`), categorized headers, and instant keyboard filtering.
- **Dedicated Dashboard Module**:
  - Modular dashboard window (`CTRL + ALT + D`) featuring GitHub contribution calendar (`GithubWidget`, `GithubContributionsWidget`).
  - Pending system updates monitor (`UpdatesCard`) with direct pacman/yay checking.
  - Daily inspiration quotes widget (`QuoteWidget`).
  - Local caching of GitHub avatars (`fetch_github_info.py`) to `~/.cache/quickshell` avoiding Qt SSL/network glitches, with fallback SVG placeholder.
- **Lock Screen Redesign & Security**:
  - Modernized lockscreen interface with pill containers for clock, date, system metrics, and authentication box (`AuthBox`).
  - Integrated `LockScreenIpcController` with native `IpcHandler`, socket recovery timer, and robust PAM authentication.
- **Asynchronous Wi-Fi & Bluetooth Stack**:
  - Dedicated Python backend script (`wifi.py`) for asynchronous Wi-Fi scanning, connection, and security handling.
  - Interactive Bluetooth device picker and Wi-Fi picker delegates with inline connect/disconnect/password handling.
- **Hyprland Appearance, Rules & Global Keybinds**:
  - New window animation curves (`windowsIn` with popin 80%, `windowsOut` with popin 85%, overshot curve).
  - Global toggle shortcuts: `CTRL + ALT + D` (Dashboard), `CTRL + ALT + M` (Music), `CTRL + ALT + N` (Notification Center).
  - Dedicated Steam window rules with 16px corner radius for friends list, settings, news, and notifications.
  - Standardized window rules and dimensions for Minflair Settings (`1200x750`), Keybinds Cheat Sheet (`1100x700`), and Package Manager (`1300x800`).
  - Default zero border size (`border_size = 0`) with smooth shadows; inner gaps set to 4, outer gaps to 8.
- **Screen Capture & Delayed Screenshot**:
  - Streamlined `ScreenCaptureContent` with fullscreen, active window, region selection, 3-second delayed capture, and OCR text extraction.
  - Screen recording pipeline with desktop notifications upon completion.
- **Modular Theming Engine (`Scripts/theme/`)**:
  - Modular extractors (`palette.py`, `image_utils.py`, `magick_utils.py`) and appliers (`gtk.py`, `qt.py`, `kitty.py`, `hyprland.py`, `lazygit.py`, `nvim.py`, `btop.py`, `starship.py`, `svg_assets.py`).
  - Global font (`apply_font.py`) and cursor (`apply_cursor.py`) synchronization.
  - Expanded color palette (`accentComplementary`, `bgAccent`, `bgTertiary`, etc.).
- **Battery Charging Threshold & Automated Setup**:
  - Hardware detection and toggle script (`toggle_battery_limit.sh`) with 80% threshold toggle for supported laptop hardware (ASUS, Lenovo, Dell, Acer, Apple Silicon, etc.).
  - Automatic vendor package configuration (`acer-wmi-battery-dkms`, `libsmbios`) and passwordless sudoers rule generation in `install.sh`.
- **Neovim & Web Development Stack**:
  - Migrated to custom fork [t4lentles5/luna.nvim](https://github.com/t4lentles5/luna.nvim) with a dedicated file-watcher daemon (`theme_sync.lua`) for real-time dynamic palette hot-reloading and automatic Lualine synchronization.
  - Added full web development support: TypeScript (`ts_ls`/`vtsls`), TailwindCSS, ESLint, Emmet LSP servers, Prettier formatting via Conform, TSX/HTML/CSS Treesitter, and `nvim-ts-autotag`.
  - UI enhancements: `dressing.nvim` for native input/select dialogs, dynamic theme-colored `quickbuf`, and `which-key.nvim` automatic group expansion.
- **Developer Tools & Shell Integration**:
  - Integrated `zoxide` for fast directory jumping in Zsh.
  - LazyGit custom theme integration.
  - Added `tree-sitter-cli`, Noto/Roboto fonts, and OCR tesseract packages to `install.sh`.

### Changed

- **Settings Navigation & Architecture**:
  - Migrated `Settings.qml` to `AppWindow` with a dedicated categorized `SettingsSidebar` (Desktop, Management, Input & Hardware, About).
  - Added `Ctrl+Tab` and `Ctrl+Shift+Tab` keyboard shortcuts for seamless tab cycling.
  - Standardized form components (`SettingSegmented`, `SettingSpinBox`, `SettingToggle`, `ThemedTextField`).
- **Starship Prompt & Colors**:
  - Streamlined prompt layout and symbols (``), synced color palette variables with the dynamic theme.
- **Overlay Window Management & IPC**:
  - Added native `IpcHandler` support in `shell.qml` and `LockScreenIpcController`.
  - Replaced ad-hoc cleanup shell processes with socket recovery timers and deferred disconnections (`Qt.callLater`).
  - Set `enabled: visible` across overlay containers in `GamingOverlay` to prevent event capture on hidden layers.
- **Notification Presentation**:
  - Top-aligned text layout in `NotificationDelegateContent` for improved multi-line summary and body readability.
  - Streamlined notification toast overlays (`BaseNotifLayer`, `ConvexNotificationOverlay`).
- **Performance & Code Hygiene**:
  - Disabled Python bytecode generation (`sys.dont_write_bytecode = True` / `PYTHONDONTWRITEBYTECODE=1`) across all scripts.
  - Clamped animation durations with `Math.max(0, ...)` in `MusicCavaBars` and `AnimatedMinflair` to avoid negative duration warnings.
  - Centralized system information and process inspection scripts in `Scripts/system/`.

### Fixed

- **IPC Socket Reconnection**: Resolved intermittent socket connection drops and race conditions during widget toggles via recovery timers and deferred close calls.
- **GitHub Avatar Rendering**: Fixed missing/broken avatar images in dashboard by caching downloads locally instead of passing remote URLs directly to Qt Image components.
- **Negative Animation Durations**: Resolved QML animation warnings by clamping subtraction-based durations to zero with `Math.max(0, ...)`.
- **Search Debouncing in Package Manager**: Prevented UI lag during fast typing in package queries.
- **Game Mode Configuration Overwrite**: Prevented `HyprlandService` and animation watchers from overriding game mode settings when active.
- **Module Import Paths**: Corrected missing or legacy imports across settings and popup hosts.

### Removed

- **Music Lyrics Panel & Service**: Removed `MusicLyricsPanel.qml` and `get_lyrics.py` to keep the music popup lightweight, fast, and focused on playback and visualizer.
- **Legacy Bar Styles & Hosts**: Removed `FramedBar`, `FramedOverlayStyle`, `NotchHost`, `IslandHost`, `MinflairBar`, and `BarWindow`.
- **Obsolete Settings Components**: Removed `SettingSlotSelect`, `SettingGroup`, `SettingHeader`, and deprecated update preference panels.
- **Redundant Quick Settings Tiles**: Replaced legacy volume/mic/capture tiles with dedicated cards and standalone modules.
- **Monolithic Window Wrappers**: Inlined wrappers into content delegates across `PowerMenu`, `ScreenCapture`, and `WallpaperSelector`.
- **ActivityWatch Integration**: Removed `aw-server` and `aw-awatcher` from autostart, AUR dependencies, and system widgets.
- **Legacy Keybinds & Rules**: Removed `kew` CLI player keybind/window rule and removed Nautilus floating rule (now tiled by default).
- **Obsolete Scripts**: Removed deprecated theme scripts (`refactor_apply_theme.py`, legacy root scripts).

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
