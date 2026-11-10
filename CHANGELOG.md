# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2026-11-10

### Added

- **Component manifest and persistent preferences**:
  - New `config/quickshell/components.tsv` manifest is the single source of truth for component ids, paths, packages, theme appliers, font targets and reload commands.
  - Preferences are stored in `~/.config/minflair/preferences.conf` as a plain list of disabled components, so they work before Python or `jq` are available.
  - Components are opt-out: a component is enabled unless it is listed in the preferences file. `quickshell` and `hyprland` are core and cannot be disabled.
  - New `minflair_components.py` CLI and shared `lib/components.sh` helpers read the manifest from both the installer and the runtime scripts.
- **Interactive component selector**:
  - `install.sh` opens a keyboard-driven selector by default when no selection flags are passed.
  - The selector can toggle optional components, enable everything, disable everything, search by id or description, and cancel without changing anything.
  - Wide terminals show a two-pane layout with the description of the highlighted component.
  - `Enter` opens a review screen; preferences are saved only after confirmation.
  - `update.sh --select` opens the same selector before updating.
- **Installer and updater UI**:
  - New `lib/ui.sh` centralizes one-line headers, ASCII section markers, status symbols, confirmation prompts and terminal size detection.
  - All visible output is ASCII-only. Color is optional and is disabled when there is no TTY, when `NO_COLOR` is set or when `TERM=dumb`.
  - The final summary lists the enabled and skipped components, the backup location and the next steps.
  - The native CLI draws section rules, category-grouped summaries, key-hint footers and a two-panel review screen in the selector instead of plain text.
  - The selector list keeps the component table as the only border and highlights the cursor row with a solid background instead of reverse video.
  - `install.sh`, `update.sh` and `lib/selector.sh` use the same section rules, category-grouped summaries and a review layout with key hints.
- **Native `minflair` CLI**:
  - New Rust CLI with `minflair install`, `minflair update` and `minflair doctor`.
  - `install` and `update` run the native pipeline, including the interactive selector, preferences, backups, themes, services and reloads.
  - `install.sh` and `update.sh` remain compatibility entrypoints with the same selector, preferences and flags.
  - `minflair update --pull` pulls the latest source, rebuilds the CLI and reinstalls it in place; `--no-build` skips the rebuild.
  - New `minflair components` command with `list`, `enable`, `disable`, `edit` and `reset`; `--apply` saves the selection and runs the update pipeline.
  - `minflair components list` accepts `--json`, `--enabled` and `--disabled`, and the other subcommands reject unknown ids and protect core components.
- **One-command installation**:
  - New `bootstrap.sh` installs the missing build tools, clones Minflair into `~/.minflair`, builds the CLI into `~/.local/bin` and starts `minflair install`.
  - The bootstrap keeps the terminal attached for the component selector and falls back to `--no-input` when no terminal is available.
  - `MINFLAIR_DIR`, `MINFLAIR_BIN_DIR`, `MINFLAIR_REPO_URL` and `MINFLAIR_REF` override the clone directory, CLI destination, remote and branch or tag.
  - The repository path is saved in `~/.config/minflair/repo`, so the CLI works from any directory.
- **Selection flags for install and update**:
  - `--exclude`, `--only`, `--include`, `--select`, `--no-input`, `--dry-run` and `--no-packages` are available in both scripts.
  - Selection flags persist the choice and make the run non-interactive.
  - `--dry-run` reports the exact files, packages and reloads without changing the system.
- **Selectable AUR helper**:
  - The first interactive install asks whether to use `yay` or `paru`; the choice is saved in `~/.config/minflair/aur-helper` and reused later.
  - `install.sh` and `update.sh` accept `--aur-helper yay|paru`, so the helper can be changed without editing files.
  - The Package Manager, the update counter and the package search script read the same saved value, so AUR actions work with either helper.
  - `MINFLAIR_AUR_HELPER` and `MINFLAIR_AUR_HELPER_FILE` override the saved value for automation and tests.
- **DDC/CI brightness for external monitors**:
  - New `Scripts/system/brightness.sh` helper uses `brightnessctl` for internal panels and falls back to `ddcutil` over DDC/CI for external monitors.
  - The helper caches the detected backend, the buses and the last value in `$XDG_RUNTIME_DIR`, serializes bus access with `flock` and skips detection for 30 seconds when no display supports DDC/CI.
  - `BrightnessSlider` and the Hyprland brightness keybinds share the helper, so the keys and the slider stay in sync.
  - `install.sh` and `update.sh` install `ddcutil`, load `i2c-dev` on boot and add the user to the `i2c` group.
- **System tray item pinning**:
  - Pinned tray items are validated against the live `SystemTray` list in `AppState`.
  - When a pinned application quits, the stale pin is dropped instead of falling back to an index that now points at a different tray item.
- **Runtime gating**:
  - Theme, font and cursor appliers skip disabled components instead of writing their configuration.
  - The installer filters `packages.txt` and `packages-aur.txt` so disabled applications are not installed or updated.
  - Disabled components are not copied, themed or signalled. Existing files from a disabled component are left untouched.
  - SDDM cache writes are gated in the shell services.
- **Documentation and CI**:
  - New `docs/COMPONENTS.md` and `docs/INSTALL.md` explain the manifest, selector and flags.
  - The README now links to dedicated setup, advanced usage and troubleshooting guides (`docs/SETUP.md`, `docs/ADVANCED.md`, `docs/TROUBLESHOOTING.md`).
  - The README and `docs/INSTALL.md` document the one-command bootstrap install, and `docs/ADVANCED.md` lists its environment variables.
  - The README, `docs/INSTALL.md`, `docs/ADVANCED.md` and `docs/COMPONENTS.md` document `minflair components`, `--no-pull`, the `--no-build` requirement and the install/update selector defaults.
  - The install guide documents how to add `~/.local/bin` to `PATH` in bash when the zsh component is not selected.
  - New GitHub Actions workflow runs the unit tests, validates the manifest and checks shell syntax.
  - The workflow now checks `bootstrap.sh` with `bash -n` and ShellCheck.

### Changed

- The installer now copies only enabled component paths and backs up only the files it is about to replace.
- The update script keeps the saved selection and does not re-enable components that were disabled earlier.
- AUR packages are installed and updated with the selected helper instead of a hardcoded `yay`.
- The git clone path in the documentation is now `~/.minflair`, replacing the old `~/.dotfiles` path.
- New backups are written to `~/.minflair_backup/<timestamp>/`. Backups from older versions remain in `~/.dotfiles_backup/<timestamp>/` and the restore guide covers both locations.
- The version shown in Settings → System Information is now `2.2.0`.
- `minflair` now resolves the repository from the path saved by `bootstrap.sh` and also checks `~/.local/share/minflair`, `/usr/share/minflair` and `/usr/local/share/minflair`.
- The README and install guide present the native CLI as the canonical entrypoint, with `install.sh` and `update.sh` kept as compatibility entrypoints.

### Fixed

- **Missing next step after saving a component selection**: `minflair components edit`, `enable`, `disable` and `reset` now print the `minflair update` command needed to deploy the selection, and skip that hint when `--apply` is used.
- **Caps Lock and Num Lock OSD bindings**: the Hyprland bindings now use `ignore_mods = true`. Hyprland reports both keys as their own modifiers and adds them to the event mask, so the bindings never matched before.
- **Stuck notification toasts**: `BaseNotifLayer` now has a fallback timer that removes notifications when the closing animation never completes.
- **zsh startup without optional components**: zsh now falls back to a basic prompt when Starship is disabled and skips missing plugins instead of printing `command not found`.
- **`update` alias with paru**: the zsh alias now reads the selected AUR helper instead of always calling `yay`.
- **`minflair update --pull` outside a git checkout**: the updater now stops with a clear message instead of failing inside `git pull`.

## [2.1.0] - 2026-10-28

### Added

- **Unified Quickshell On-Screen Display (OSD) Engine (`OsdService`)**:
  - Integrated a native, centralized OSD architecture via Quickshell IPC, supported across both **Convex** (`ConvexCenter`) and **Island** (`IslandCenterPill`) shell styles.
  - Real-time animated OSD indicators for volume level, microphone mute/unmute, and display brightness.
  - Native OSD status notifications for keyboard lock states (Caps Lock, Num Lock) with dedicated SVG icons, and touchpad toggle (`touchpad.sh`).
  - Udev-based power event monitoring in `SystemInfoService` dispatching OSD notifications on AC charger connection/disconnection and battery status events.
  - Screen capture feedback: `screenshot.sh` and `record.sh` now invoke Quickshell OSD via IPC instead of external `notify-send`.
- **Dynamic SDDM Theming & Integration (`minflair-sddm`)**:
  - Migrated SDDM login theme to custom fork [t4lentles5/tokyo-night-sddm](https://github.com/t4lentles5/tokyo-night-sddm) installed as `minflair-sddm`.
  - Added dynamic SDDM theme applier (`Scripts/theme/theme_appliers/sddm.py`) integrated into `WallpaperManager` and `apply_theme.py`, synchronizing SDDM login background with the active wallpaper and theme colors in real time.
  - Automated user avatar ACL permissions (`setfacl`) in `install.sh` so SDDM can display `~/.face` or `~/.face.icon` without home directory permission issues.
- **Pomodoro Focus Timer (`PomodoroService`)**:
  - New dedicated Pomodoro module (`Ctrl + Alt + T`) with configurable focus, short-break, and long-break durations, plus a "long break every N focus sessions" cycle setting.
  - Auto-start for the next phase, desktop notifications, and sound cues when a phase ends.
  - Persistent timer state in `~/.cache/quickshell/pomodoro_state.json` with daily completed-session tracking, progress ring, and phase chips.
- **System Usage Monitor**:
  - New modular System Usage module (`Ctrl + Alt + F`) with dedicated CPU, GPU, memory, and storage cards.
  - Live CPU usage/temperature/frequency/cores, GPU usage/temperature/VRAM, RAM utilization, and per-disk storage breakdowns.
  - Extended `get_processes.py` daemon providing structured JSON metrics, integrated into the Convex center panel, Island bar, and Gaming overlay.
- **Unified Calendar Widget**:
  - New `CalendarWidget` (`Ctrl + Alt + C`) shared between Convex and Island styles, opened directly from the bar clock.
- **Smart Launcher**:
  - Inline calculator powered by a new recursive-descent `MathEval` parser (no `eval`/`Function`), supporting arithmetic, parentheses, exponentiation, `sqrt`, and `pi`.
  - Web search shortcuts through explicit prefixes (`g`, `yt`, `w`, `gh`, `ddg`) using a configurable default browser.
  - Quick Minflair commands (`> settings`, `> keybinds`, `> packages`, `> pomodoro`) and a shell command runner for kitty.
- **Notification Grouping & Management**:
  - Notifications grouped by application with expandable stacks and per-group clear actions in the Notification Center.
  - New `NotificationUtils` and `TimeUtils` helpers for grouping, relative timestamps, and notification removal.
- **Island Bar Customization**:
  - New settings to show/hide workspaces and the system tray in the Island bar.
  - New "Single Island" mode that displays only the center pill.
  - Configurable workspace count (1–20) for bar indicators.
- **Obsidian Theme Synchronization**:
  - New `theme_appliers/obsidian.py` that generates a Minflair CSS snippet in every detected vault and enables it automatically, keeping Obsidian in sync with the active palette.
- **UI Animations & Window Rules**:
  - Added smooth opacity fade animations to `AppWindow` during window presentation and dismissal.
  - Added global window rule `suppressevent maximize, class:.*` in Hyprland configuration to eliminate unwanted window maximize events.
  - Added full-tile click interaction, hover animations, and improved click handling for inactive tiles in `QuickSettingsTile`.
  - Unified gaming bar dimensions through a shared `gamingBarHeight` constant and added the app version to Settings → System Information.
- **Configuration Update Script (`update.sh`)**:
  - New updater for existing installations: backs up replaced files to `~/.minflair_backup/<timestamp>/`, syncs `config/` and `home/` (preserving Zsh history), installs new dependencies, refreshes the `minflair-sddm` theme without root-owned Git repositories, and reloads Hyprland and Quickshell.

### Changed

- **Native PipeWire Audio Engine**:
  - Refactored `AudioService` to connect directly to Quickshell's native PipeWire integration, replacing external `pamixer` and `pactl` process spawns for zero-overhead, lag-free audio control.
- **Keyboard Layout Support & Synchronization**:
  - Expanded keyboard layout support and synchronized active layout states between `HyprlandService` and the Settings panel (`InputAndClipboardSettings`).
- **Slider Throttling & Debouncing**:
  - Added debouncing and throttling to `ThemedSlider` and `BrightnessSlider` to prevent `brightnessctl` command flooding during rapid slider adjustments.
- **Script Consolidation & Code Cleanups**:
  - Consolidated standalone widget toggle scripts into a unified widget utility script.
  - Reworked Minflair app scripts from `toggle_*` to `open_*` semantics and removed the legacy `.desktop` entries in favor of in-launcher quick commands.
  - Replaced hardcoded black and white color values across UI components with dynamic `Theme` properties, including `Theme.bgTertiary` for package manager surfaces and theme-aware gradients.
  - Refined sidebar navigation hover and active states with palette-aware color blending.
  - Bound font family directly to `Constants.fontFamily` in `TypewriterText`.
  - Standardized spacing, text sizes, and animation durations via `Constants` and `durationFactor` for consistent motion across the UI.
- **Rendering Stack (`QtQuick.Effects`)**:
  - Migrated all `Qt5Compat.GraphicalEffects` usages (icons, shadows, lock screen, media art, notifications, wallpaper cards) to native `QtQuick.Effects` (`MultiEffect`), reworking `RadialGlow` and removing the `qt6-5compat` dependency.
- **Lock Screen Appearance**:
  - Auth box and clock group now use translucent backgrounds with improved contrast against the active wallpaper; SDDM theme generation was aligned with the new lock screen styling.
- **Island Bar Geometry**:
  - Centralized idle pill geometry (`islandBarHeight`, `idleHeight`, `idleRadius`, `idleGlyph`, `edgeMargin`, `pillGap`) in `IslandBar` so pills, bar surface, exclusive zone, and the overlay start height always share the same metrics.
  - Media artwork, visualizer bars, and tray spacing now derive from `Constants` instead of hardcoded pixel values, keeping the island layout consistent across scales.
- **Game Mode & Bar Surfaces**:
  - Reworked gaming bar/overlay surfaces to reserve exclusive zones only while gaming, added masks to avoid input capture, and prevented bar style switches from instantiating inactive styles.
- **Blur Disabled by Default**:
  - Window and panel blur now ships disabled (`userprefs.lua`, `HyprlandService.hyprBlur`) to save frame time on integrated GPUs; it can still be re-enabled from Settings → Effects, where the toggle now explains the performance trade-off.
- **Settings Performance**:
  - Increased the settings save debounce interval to 500 ms to reduce disk writes while adjusting controls.
- **Command Execution Security**:
  - Shell commands now receive arguments directly instead of interpolated command strings across audio, clipboard, Pomodoro, wallpaper, theme, and settings services.
  - GitHub tokens are read from environment variables instead of being passed through process arguments.
- **Kitty Configuration**:
  - Enabled split layouts with automatic split axis, added window navigation mappings, reduced font size to 11, and adapted window-management shortcuts.
  - Theme applier now generates a distinct ANSI palette from the accent color instead of reusing accent shades.
- **Shared Dependency Lists**:
  - Moved official and AUR packages to `packages.txt` and `packages-aur.txt`, shared by `install.sh` and `update.sh` so updates stay in sync.
- **Dependencies (`install.sh`)**:
  - Added official packages `sddm`, `qt5-quickcontrols2`, `qt5-graphicaleffects`, and `qt5-svg`.
  - Replaced AUR package `sddm-theme-tokyo-night-git` with direct Git repository installation and updates for `minflair-sddm`.
  - Removed `qt6-5compat` and the legacy Quickshell `.desktop` installation step.

### Fixed

- **SDDM Wallpaper Extraction Memory Spikes**:
  - Optimized image processing and downsampling in `theme_extractors/image_utils.py` to prevent memory spikes during high-resolution SDDM wallpaper extraction, with fallback handling.
- **IPC Sockets & Overlay Focus**:
  - Resolved stale IPC socket handling during Quickshell startup.
  - Improved gaming overlay focus and event handling for cleaner input passthrough.
- **Masked Image Antialiasing**:
  - Preserved smooth mask edges on `MultiEffect`-clipped images by keeping a real 0..1 alpha ramp (`maskThresholdMin: 0.5`, `maskSpreadAtMin: 1`) and enabling `smooth` on mask sources, fixing jagged avatars, notification icons, wallpaper cards, and mini music artwork.
- **Bar Style Switching Stability**:
  - Prevented crashes and duplicated surfaces when switching between Convex, Island, and Gaming styles by gating inactive style loaders and unifying bar window lifecycle handling.
- **Game Mode Surfaces**:
  - Fixed overlapping bar surfaces and incorrect exclusive zones when entering or leaving Game Mode, including masks and visibility gating for hidden surfaces.
- **Convex Surface Flashing**:
  - `ConvexDesktop.isConvexMode` now requires `SettingsService.settingsLoaded`, preventing the Convex frame and mask from flashing on screen before the saved bar style has been read.
- **Keyboard Lock Detection**:
  - Caps Lock and Num Lock states are now read from `hyprctl devices` instead of sysfs, fixing unreliable OSD indicators.
- **System Usage Animations**:
  - Synchronized animation states in `SystemUsageCard` when disabled to prevent stale segment displays.
- **Package Manager Contrast**:
  - Updated package cards and overlays to use `Theme.bgTertiary` for consistent contrast across themes.
- **Battery Polling Overhead**:
  - `SystemInfoService`'s battery timer is now a 60 s safety net instead of polling at `performanceInterval`, since uevent monitoring already refreshes battery state on every change; this removes a shell script spawn every second.
- **MathEval Parsing**:
  - Fixed operator precedence, loop handling, and division/modulo-by-zero behavior in the launcher calculator.

### Removed

- **Legacy Floating Bar Style**:
  - Removed deprecated `FloatingOverlayStyle.qml` and associated settings slots in favor of Convex and Island bar styles.
  - Removed unused `BarCenterContent.qml` and `IslandContent.qml` bar components.
- **Lock Screen Components & Unused Services**:
  - Removed top-left and top-right component groups from `LockScreen.qml` for a cleaner, focused layout.
  - Removed legacy `OsdProgressBar.qml`, superseded by the unified OSD engine.
- **Legacy Desktop Entries & Scripts**:
  - Removed the shipped `.desktop` entries for Settings, Keybinds, Package Manager, and Pomodoro; they are now launched from the smart launcher or via widgets.
  - Removed the per-app `toggle_*` scripts and `toggle_widget.sh` in favor of unified `open_*` and `open_widget.sh` utilities.
- **Deprecated Theming & Components**:
  - Removed the unused `svg_assets.py` theme applier and its icon-recoloring pipeline.
  - Removed unused `ClockContent.qml` in favor of the unified `CalendarWidget`.

## [2.0.1] - 2026-10-12

### Fixed

- **Installer Dependency (`qt6-5compat`)**: Added `qt6-5compat` to the official package dependencies in `install.sh`. Resolves a startup crash where Quickshell failed to load `SvgIcon` and graphical effects (`module "Qt5Compat.GraphicalEffects" is not installed`) on fresh Arch installations.
- **Power Menu Logout & State Reset**:
  - Improved session logout command to cleanly terminate `uwsm` managed sessions (`uwsm stop`) when active, falling back to `hyprctl dispatch exit` or `loginctl terminate-user ""`.
  - Reset pending action state (`pendingActionIndex = -1`) when closing or hiding the Power Menu to prevent stale confirmation states when reopened.

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
