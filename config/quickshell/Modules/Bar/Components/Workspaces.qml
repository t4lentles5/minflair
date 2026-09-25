import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property color bgColor: Theme.bgSecondary
    property bool compact: false
    readonly property bool isCompactMode: root.compact || SettingsService.isBarCompact

    implicitWidth: (hLayout.implicitWidth > 0 ? hLayout.implicitWidth : hLayout.childrenRect.width) + (root.bgColor === "transparent" ? 8 : (root.isCompactMode ? 18 : 24))
    implicitHeight: SettingsService.isBarCompact ? 24 : SettingsService.barWidgetHeight
    height: SettingsService.isBarCompact ? 24 : (parent && parent.height > 0 ? parent.height : implicitHeight)

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
        spacing: root.isCompactMode ? 6 : Constants.sizeSm

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
                    if (!workspace)
                        return false;

                    if (workspace.toplevels && workspace.toplevels.count !== undefined)
                        return workspace.toplevels.count > 0;

                    if (workspace.lastIpcObject && workspace.lastIpcObject.windows !== undefined)
                        return workspace.lastIpcObject.windows > 0;

                    return workspace.windows !== undefined ? workspace.windows > 0 : false;
                }
                readonly property bool hasWindows: workspace !== undefined && hasActualWindows
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

}
