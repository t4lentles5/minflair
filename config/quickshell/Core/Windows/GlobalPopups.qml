import QtQuick
import qs.Core.Components
import qs.Modules.Clipboard
import qs.Modules.KeybindsCheatSheet
import qs.Modules.Launcher
import qs.Modules.LockScreen
import qs.Modules.PackageManager
import qs.Modules.PowerMenu
import qs.Modules.ScreenCapture
import qs.Modules.Settings
import qs.Modules.WallpaperSelector

Item {
    id: root

    PopupLoader {
        popupId: "launcher"

        sourceComponent: Component {
            Launcher {
            }

        }

    }

    PopupLoader {
        popupId: "clipboard"

        sourceComponent: Component {
            Clipboard {
            }

        }

    }

    PopupLoader {
        popupId: "wallpaper"

        sourceComponent: Component {
            WallpaperSelector {
            }

        }

    }

    PopupLoader {
        popupId: "screenshot"
        exclusive: true

        sourceComponent: Component {
            ScreenCapture {
            }

        }

    }

    PopupLoader {
        popupId: "minflair_keybinds"
        exclusive: false

        sourceComponent: Component {
            KeybindsCheatSheet {
            }

        }

    }

    PopupLoader {
        popupId: "minflair_settings"
        exclusive: false

        sourceComponent: Component {
            Settings {
            }

        }

    }

    PopupLoader {
        popupId: "packagemanager"
        exclusive: false

        sourceComponent: Component {
            PackageManager {
            }

        }

    }

    LockScreen {
        id: lockScreen
    }

    PopupLoader {
        popupId: "powerMenu"
        exclusive: true

        sourceComponent: Component {
            PowerMenu {
            }

        }

    }

}
