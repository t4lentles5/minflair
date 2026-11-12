import QtQuick
import Quickshell.Io
import qs.Core
import qs.Core.Services

// The components that are disabled are listed in the preferences file, one
// id per line. A component is enabled unless it is listed there, which is
// the same rule the installer and the theme appliers use.
pragma Singleton

Item {
    id: componentService

    property var disabledComponents: []
    property bool loaded: false

    // Read the preferences again, so a change made with
    // `minflair components` is picked up.
    function refresh() {
        loadProc.running = false;
        loadProc.running = true;
    }

    function isEnabled(componentId) {
        return disabledComponents.indexOf(componentId) === -1;
    }

    Process {
        id: loadProc

        command: ["sh", "-c", "cat \"$HOME/.config/minflair/preferences.conf\" 2>/dev/null"]
        stdout: SplitParser {
            onRead: (data) => {
                let ids = [];
                if (data) {
                    let lines = data.split("\n");
                    for (let i = 0; i < lines.length; i++) {
                        let id = lines[i].trim();
                        if (id !== "" && !id.startsWith("#"))
                            ids.push(id);
                    }
                }
                componentService.disabledComponents = ids;
            }
        }
        onExited: componentService.loaded = true;
    }

    Component.onCompleted: refresh();
}
