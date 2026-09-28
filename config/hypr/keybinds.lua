local mainMod = "SUPER"
local terminal = "kitty"
local fileManager = "nautilus"

-- ## Applications

-- # Open Terminal
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
-- # Open Floating Terminal
hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("kitty --class kitty-floating"))
-- # Open Kew
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.exec_cmd("kitty --class kitty-kew -e kew"))
-- # Open File Manager
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
-- # Open Browser
hl.bind(
	mainMod .. " + B",
	hl.dsp.exec_cmd(
		"if command -v brave; then brave; elif command -v firefox; then firefox; elif command -v chromium; then chromium; else google-chrome-stable; fi"
	)
)

-- ## Window Management

-- # Close Active Window
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
-- # Exit Hyprland
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exit())
-- # Lock Screen
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_lockScreen"))
-- # Toggle Floating Mode
hl.bind(mainMod .. " + W", hl.dsp.window.float({ action = "toggle" }))
-- # Toggle Maximize Window
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
-- # Toggle True Fullscreen
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
-- # Pseudo Tiling Layout
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
-- # Toggle Split Direction
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))
-- # Center Floating Window
hl.bind(mainMod .. " + C", hl.dsp.window.center())
-- # Pin Window on All Workspaces
hl.bind(mainMod .. " + SHIFT + P", hl.dsp.window.pin())
-- # Minimize Window to Scratchpad
hl.bind(mainMod .. " + N", hl.dsp.window.move({ workspace = "special:minimized", silent = true }))
-- # Restore Minimized Windows
hl.bind(mainMod .. " + SHIFT + N", hl.dsp.workspace.toggle_special("minimized"))

-- ## Tools

-- # Pick Color
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))
-- # Switch Keyboard Layout
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("$HOME/.config/quickshell/Scripts/system/toggle_kb_layout.sh"))
-- # Restart Quickshell
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("killall qs; qs"))

-- ## Volume

-- # Raise Volume
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/volume.sh up"),
	{ repeating = true, locked = true }
)
-- # Lower Volume
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/volume.sh down"),
	{ repeating = true, locked = true }
)
-- # Mute Speaker
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/volume.sh mute"), { locked = true })
-- # Mute Microphone
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/volume.sh mic-mute"), { locked = true })

-- ## Brightness

-- # Increase Brightness
hl.bind(
	"XF86MonBrightnessUp",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/brightness.sh up"),
	{ repeating = true, locked = true }
)
-- # Decrease Brightness
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/brightness.sh down"),
	{ repeating = true, locked = true }
)

-- ## Media Player

-- # Play / Pause
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/media_player.sh play-pause"), { locked = true })
-- # Next Track
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/media_player.sh next"), { locked = true })
-- # Previous Track
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/media_player.sh prev"), { locked = true })
-- # Stop
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("$HOME/.config/hypr/scripts/media_player.sh stop"), { locked = true })

-- ## Quickshell Widgets

-- # Toggle App Launcher
hl.bind(mainMod .. " + A", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_launcher"))
-- # Toggle Control Center
hl.bind("CTRL + ALT + S", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_controlCenter"))
-- # Toggle Power Menu
hl.bind("CTRL + ALT + X", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_powerMenu"))
-- # Toggle Clipboard History
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_clipboard"))
-- # Toggle Wallpaper Selector
hl.bind("CTRL + ALT + W", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_wallpaper"))
-- # Toggle Screenshot
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_screenshot"))
-- # Toggle Dashboard
hl.bind("CTRL + ALT + D", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_dashboard"))
-- # Toggle Music Popup
hl.bind("CTRL + ALT + M", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_music"))

-- ## Quickshell Apps

-- # Toggle Settings
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_minflair_settings"))
-- # Toggle Package Manager
hl.bind("CTRL + ALT + P", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_packagemanager"))
-- # Toggle Keybinds Cheat Sheet
hl.bind(mainMod .. " + K", hl.dsp.exec_cmd("socat - UNIX-CONNECT:/tmp/quickshell_minflair_keybinds"))

-- ## Window Groups

-- # Create / Dissolve Group
hl.bind(mainMod .. " + G", hl.dsp.group.toggle())
-- # Cycle Group Windows
hl.bind(mainMod .. " + Tab", hl.dsp.group.next())
-- # Lock / Unlock Group
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.group.lock("toggle"))

-- ## Navigation

-- # Move Focus ←→↑↓
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" }))

-- # Move Window Position ←→↑↓
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "d" }))

-- # Resize Active Window ←→↑↓
hl.bind(mainMod .. " + ALT + right", hl.dsp.window.resize({ x = 10, y = 0 }), { repeating = true })
hl.bind(mainMod .. " + ALT + left", hl.dsp.window.resize({ x = -10, y = 0 }), { repeating = true })
hl.bind(mainMod .. " + ALT + up", hl.dsp.window.resize({ x = 0, y = -10 }), { repeating = true })
hl.bind(mainMod .. " + ALT + down", hl.dsp.window.resize({ x = 0, y = 10 }), { repeating = true })

-- # Swap Window Position ←→↑↓
hl.bind(mainMod .. " + ALT + SHIFT + left", hl.dsp.window.swap({ direction = "l" }))
hl.bind(mainMod .. " + ALT + SHIFT + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(mainMod .. " + ALT + SHIFT + up", hl.dsp.window.swap({ direction = "u" }))
hl.bind(mainMod .. " + ALT + SHIFT + down", hl.dsp.window.swap({ direction = "d" }))

-- ## Workspaces

-- # Switch to Workspace 1..0
hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 }))
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 }))
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 }))
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 }))
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 }))
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = 6 }))
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 }))
hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = 8 }))
hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = 9 }))
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 }))

-- # Send Window to Workspace 1..0
hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 }))
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 }))
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 }))
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 }))
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 }))
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 }))
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 }))
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 }))
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 }))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- # Previous / Next Workspace
hl.bind(mainMod .. " + CTRL + left", hl.dsp.focus({ workspace = "-1" }))
hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ workspace = "+1" }))

-- # Scroll Through Workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- # Toggle Scratchpad
-- UNPARSED: #bind = $mainMod, S, togglespecialworkspace, magic
-- # Send to Scratchpad
-- UNPARSED: #bind = $mainMod SHIFT, S, movetoworkspace, special:magic

-- ## Mouse Binds

-- # Drag to Move Window
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
-- # Drag to Resize Window
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
