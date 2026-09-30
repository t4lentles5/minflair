import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property color bgColor: Theme.bgSecondary

    implicitWidth: (hLayout.implicitWidth > 0 ? hLayout.implicitWidth : hLayout.childrenRect.width) + (root.bgColor === "transparent" ? 8 : 18)
    implicitHeight: SettingsService.barWidgetHeight
    height: parent && parent.height > 0 ? parent.height : implicitHeight

    Rectangle {
        anchors.fill: parent
        color: root.bgColor
        radius: height / 2
        visible: root.bgColor !== "transparent"
    }

    Row {
        id: hLayout

        anchors.centerIn: parent
        width: implicitWidth
        spacing: 6

        Repeater {
            model: 10

            Rectangle {
                id: wsItemH

                readonly property int wsId: index + 1
                readonly property var workspace: Hyprland.workspaces.values.find((ws) => {
                    return ws.id === wsId;
                })
                readonly property bool isActive: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id === wsId : false
                readonly property bool hasActualWindows: {
                    // 1. Direct real-time check via workspace.toplevels (ObjectModel)
                    if (workspace && workspace.toplevels && workspace.toplevels.values) {
                        if (workspace.toplevels.values.length > 0)
                            return true;

                    }
                    // 2. Cross-check with global Hyprland toplevels list
                    if (Hyprland.toplevels && Hyprland.toplevels.values)
                        return Hyprland.toplevels.values.some((top) => {
                        return top && top.workspace && top.workspace.id === wsId;
                    });

                    return false;
                }
                readonly property bool hasWindows: hasActualWindows
                readonly property int scaledActiveWidth: 28
                readonly property int scaledHasWinSize: 10
                readonly property int scaledEmptySize: 8

                width: isActive ? scaledActiveWidth : (hasWindows ? scaledHasWinSize : scaledEmptySize)
                height: isActive ? scaledHasWinSize : (hasWindows ? scaledHasWinSize : scaledEmptySize)
                y: (scaledHasWinSize - height) / 2
                radius: (isActive || hasWindows) ? 5 : 4
                color: mouseAreaH.containsMouse ? Theme.accent : (isActive ? Theme.fg : (hasWindows ? Theme.fg : Theme.muted))
                scale: mouseAreaH.pressed ? 0.9 : (mouseAreaH.containsMouse ? 1.1 : 1)

                MouseArea {
                    id: mouseAreaH

                    anchors.fill: parent
                    anchors.margins: -8
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch('hl.dsp.focus({workspace=' + wsId + '})')
                }

                Behavior on width {
                    NumberAnimation {
                        duration: Constants.animNormal
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.15
                    }

                }

                Behavior on height {
                    NumberAnimation {
                        duration: Constants.animNormal
                        easing.type: Easing.OutQuint
                    }

                }

                Behavior on color {
                    ColorAnimation {
                        duration: Constants.animFast
                    }

                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Constants.animNormal
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.2
                    }

                }

            }

        }

    }

    Connections {
        function onRawEvent(event) {
            if (!event || !event.name)
                return ;

            const ev = event.name;
            if (ev === "openwindow" || ev === "closewindow" || ev === "movewindowv2" || ev === "createworkspacev2" || ev === "destroyworkspacev2")
                refreshDebounce.restart();

        }

        target: Hyprland
    }

    Timer {
        id: refreshDebounce

        interval: 100
        repeat: false
        onTriggered: Hyprland.refreshWorkspaces()
    }

}
