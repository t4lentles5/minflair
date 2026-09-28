import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Core.Services

Item {
    id: root

    property bool authenticating: false
    property bool authFailed: false
    property bool unlocking: false

    signal authSucceeded()
    signal toggleLockRequested()
    signal unlockRequested()

    function reset() {
        root.authFailed = false;
        root.authenticating = false;
        root.unlocking = false;
    }

    function submitPassword(pwd) {
        if (root.authenticating)
            return ;

        authProc.running = false;
        root.authenticating = true;
        root.authFailed = false;
        authProc.command = ["python3", Quickshell.shellDir + "/Scripts/system/auth.py"];
        authProc.running = true;
        authProc.write(pwd + "\n");
    }

    SocketServer {
        id: server

        path: "/tmp/quickshell_lockScreen"
        active: AppState.socketsCleaned

        handler: Component {
            Socket {
                onConnectedChanged: {
                    if (connected) {
                        root.toggleLockRequested();
                        connected = false;
                    }
                }
            }

        }

    }

    Process {
        id: authProc

        onExited: function(exitCode) {
            if (!root.authenticating)
                return ;

            root.authenticating = false;
            if (exitCode === 0) {
                root.unlocking = true;
                root.authSucceeded();
            } else {
                root.authFailed = true;
            }
        }
    }

}
