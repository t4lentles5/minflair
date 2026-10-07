import QtQuick
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
    property int customHeight: compact ? 22 : SettingsService.barWidgetHeight
    readonly property real containerPadding: compact ? 3 : 5
    readonly property int itemHeight: Math.min(20, Math.max(16, (root.height > 0 ? root.height : root.customHeight) - (root.compact ? 4 : 6)))
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
    height: parent && parent.height > 0 ? parent.height : implicitHeight
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
        spacing: root.compact ? 3 : 4

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
                height: root.itemHeight
                width: wsItemH.currentSize

                Rectangle {
                    id: wsItemH

                    readonly property real targetSize: (wsSlot.isActive || wsSlot.hasWindows || wsSlot.isHovered) ? root.itemHeight : (root.compact ? 5 : 6)
                    property real currentSize: targetSize

                    anchors.centerIn: parent
                    height: currentSize
                    width: currentSize
                    radius: DisplayProfileService.gameModeActive ? 0 : currentSize / 2
                    color: {
                        if (wsSlot.isActive)
                            return Theme.accent;

                        if (wsSlot.hasWindows)
                            return mouseAreaH.pressed ? Theme.bgTertiary : (wsSlot.isHovered ? Theme.bgSecondary : Theme.bgTertiary);

                        return wsSlot.isHovered ? Theme.bgTertiary : Theme.bgSecondary;
                    }
                    scale: mouseAreaH.pressed ? 0.9 : 1

                    ThemedText {
                        id: numText

                        // Smoothly scale & fade text with circle expansion
                        readonly property real textProgress: Math.min(1, Math.max(0, (wsItemH.currentSize - (root.compact ? 5 : 6)) / Math.max(1, root.itemHeight - (root.compact ? 5 : 6))))

                        anchors.centerIn: parent
                        text: wsSlot.wsId.toString()
                        customSize: root.compact ? 10 : 11
                        font.weight: wsSlot.isActive ? Font.Bold : (wsSlot.hasWindows ? Font.DemiBold : Font.Normal)
                        color: {
                            if (wsSlot.isActive)
                                return ColorUtils.isDark(Theme.accent) ? Theme.fg : Theme.opaqueBg;

                            if (wsSlot.hasWindows)
                                return Theme.fg;

                            return Theme.fg;
                        }
                        scale: 0.5 + 0.5 * textProgress
                        opacity: {
                            if (wsSlot.isActive)
                                return textProgress;

                            if (wsSlot.hasWindows)
                                return wsSlot.isHovered ? 1 : 0.85;

                            return wsSlot.isHovered ? 0.85 : 0;
                        }
                        visible: opacity > 0.01

                        Behavior on color {
                            ColorAnimation {
                                duration: Constants.animFast
                            }

                        }

                    }

                    MouseArea {
                        id: mouseAreaH

                        anchors.fill: parent
                        anchors.margins: wsSlot.isActive || wsSlot.hasWindows ? 0 : -4
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch('hl.dsp.focus({workspace=' + wsSlot.wsId + '})')
                        onWheel: (wheel) => {
                            return root.handleWheel(wheel);
                        }
                    }

                    Behavior on currentSize {
                        NumberAnimation {
                            duration: Constants.animNormal
                            easing.type: Easing.OutCubic
                        }

                    }

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
