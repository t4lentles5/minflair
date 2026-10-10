import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Utils

Item {
    id: root

    property color bgColor: Theme.bgSecondary
    property bool compact: false
    property int customHeight: compact ? 20 : SettingsService.barWidgetHeight
    readonly property real containerPadding: compact ? 8 : 10
    readonly property int dotHeight: compact ? 6 : 8
    readonly property int activePillWidth: compact ? 18 : 24
    readonly property int activeWsId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    readonly property int maxOccupiedWsId: {
        let maxId = 1;
        if (Hyprland.workspaces && Hyprland.workspaces.values) {
            const list = Hyprland.workspaces.values;
            for (let i = 0; i < list.length; i++) {
                const ws = list[i];
                if (!ws || ws.id <= 0)
                    continue;

                let hasWins = false;
                if (ws.toplevels && ws.toplevels.values && ws.toplevels.values.length > 0)
                    hasWins = true;

                if (!hasWins && Hyprland.toplevels && Hyprland.toplevels.values)
                    hasWins = Hyprland.toplevels.values.some((top) => {
                    return top && top.workspace && top.workspace.id === ws.id;
                });

                if (hasWins && ws.id > maxId)
                    maxId = ws.id;

            }
        }
        if (Hyprland.toplevels && Hyprland.toplevels.values) {
            for (let j = 0; j < Hyprland.toplevels.values.length; j++) {
                const top = Hyprland.toplevels.values[j];
                if (top && top.workspace && top.workspace.id > maxId)
                    maxId = top.workspace.id;

            }
        }
        return maxId;
    }
    readonly property int visibleWorkspaceCount: Math.min(10, Math.max(Math.max(activeWsId, maxOccupiedWsId) + 1, 5))

    function handleWheel(wheel) {
        const currentId = Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1;
        const targetId = wheel.angleDelta.y > 0 ? (currentId - 1) : (currentId + 1);
        if (targetId >= 1 && targetId <= 10)
            Hyprland.dispatch('hl.dsp.focus({workspace=' + targetId + '})');

    }

    implicitHeight: customHeight
    height: customHeight
    Layout.preferredHeight: customHeight
    Layout.preferredWidth: implicitWidth
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: Math.round(hLayout.implicitWidth + (root.bgColor === "transparent" ? 0 : (containerPadding * 2)))
    width: implicitWidth

    Rectangle {
        id: bgContainer

        anchors.fill: parent
        color: root.bgColor
        radius: DisplayProfileService.gameModeActive ? 0 : height / 2
        visible: root.bgColor !== "transparent"

        Behavior on color {
            ColorAnimation {
                duration: Constants.animFast
            }

        }

    }

    MouseArea {
        id: wheelArea

        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: (wheel) => {
            return root.handleWheel(wheel);
        }
    }

    Row {
        id: hLayout

        anchors.centerIn: parent
        spacing: root.compact ? 5 : 6

        Repeater {
            model: 10

            Item {
                id: wsSlot

                readonly property int wsId: index + 1
                readonly property bool isVisibleSlot: wsId <= root.visibleWorkspaceCount
                readonly property var workspace: Hyprland.workspaces.values.find((ws) => {
                    return ws.id === wsId;
                })
                readonly property bool isActive: root.activeWsId === wsId
                readonly property bool hasActualWindows: {
                    if (workspace && workspace.toplevels && workspace.toplevels.values) {
                        if (workspace.toplevels.values.length > 0)
                            return true;

                    }
                    if (Hyprland.toplevels && Hyprland.toplevels.values)
                        return Hyprland.toplevels.values.some((top) => {
                        return top && top.workspace && top.workspace.id === wsId;
                    });

                    return false;
                }
                readonly property bool hasWindows: hasActualWindows
                readonly property bool isHovered: mouseAreaH.containsMouse

                visible: opacity > 0.001
                opacity: isVisibleSlot ? 1 : 0
                height: root.dotHeight
                width: isActive ? root.activePillWidth : root.dotHeight

                Rectangle {
                    id: dotItem

                    anchors.centerIn: parent
                    height: root.dotHeight
                    width: parent.width
                    radius: DisplayProfileService.gameModeActive ? 0 : height / 2
                    color: {
                        if (wsSlot.isActive)
                            return Theme.accent;

                        if (wsSlot.hasWindows)
                            return wsSlot.isHovered ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.95) : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.65);

                        return wsSlot.isHovered ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.45) : Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.22);
                    }
                    scale: mouseAreaH.pressed ? 0.85 : (wsSlot.isHovered && !wsSlot.isActive ? 1.2 : 1)

                    Behavior on color {
                        ColorAnimation {
                            duration: Constants.animFast
                        }

                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: Constants.animFast
                            easing.type: Easing.OutQuad
                        }

                    }

                }

                MouseArea {
                    id: mouseAreaH

                    anchors.centerIn: parent
                    width: Math.max(parent.width, 14)
                    height: Math.max(parent.height, 18)
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Hyprland.dispatch('hl.dsp.focus({workspace=' + wsSlot.wsId + '})')
                    onWheel: (wheel) => {
                        return root.handleWheel(wheel);
                    }
                }

                Behavior on width {
                    NumberAnimation {
                        duration: Constants.animNormal
                        easing.type: Easing.OutCubic
                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Constants.animFast
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
