import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.Core
import qs.Core.Components

Rectangle {
    id: root

    property bool expanded: false
    property bool isActive: false
    property var btList: []
    property bool isScanning: false
    property bool timedOut: false
    property bool isVisible: true

    signal connect(string mac)

    Layout.fillWidth: true
    Layout.fillHeight: expanded
    implicitHeight: expanded ? Math.max(btListCol.implicitHeight, 80) : 0
    opacity: expanded ? 1 : 0
    visible: opacity > 0
    clip: true
    radius: 0
    color: "transparent"
    border.width: 0

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Constants.sizeSm
        visible: root.expanded && root.btList.length === 0

        Item {
            Layout.alignment: Qt.AlignHCenter
            width: Constants.size2Xl
            height: Constants.size2Xl
            visible: root.isScanning

            SvgIcon {
                anchors.centerIn: parent
                icon: "reload"
                iconColor: Theme.accent
                iconSize: Constants.sizeLg
                flat: true
            }

            RotationAnimation on rotation {
                from: 0
                to: 360
                duration: 1000
                loops: Animation.Infinite
                running: root.expanded && root.isScanning && root.btList.length === 0
            }

        }

        SvgIcon {
            Layout.alignment: Qt.AlignHCenter
            icon: "bluetooth-off"
            iconColor: Theme.muted
            iconSize: Constants.size2Xl
            flat: true
            visible: !root.isScanning
        }

        ThemedText {
            Layout.alignment: Qt.AlignHCenter
            text: root.isScanning ? "Searching for devices..." : "No devices found"
            color: root.isScanning ? Theme.fg : Theme.muted
            font.bold: root.isScanning
        }

        ThemedText {
            Layout.alignment: Qt.AlignHCenter
            text: "Make sure device is in pairing mode"
            color: Theme.muted
            customSize: Constants.sizeXs + 2
            visible: !root.isScanning
        }

    }

    ColumnLayout {
        id: btListCol

        anchors.fill: parent
        visible: root.btList.length > 0

        ThemedText {
            text: "Devices"
            font.letterSpacing: 1
            color: Theme.muted
            visible: false
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: btRepeaterCol.implicitHeight
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                id: btRepeaterCol

                width: btListCol.width
                spacing: Constants.sizeXs

                Repeater {
                    model: root.btList

                    ControlCenterListDelegate {
                        titleText: modelData.name
                        subtitleText: "Connected device"
                        iconName: modelData.connected ? "bluetooth" : "bluetooth-off"
                        isActive: modelData.connected
                        showLock: false
                        onClicked: root.connect(modelData.mac)
                        onActionClicked: {
                            settingsProc.running = true;
                        }
                        onDisconnectClicked: {
                            disconnectProc.command = ["bluetoothctl", "disconnect", modelData.mac];
                            disconnectProc.running = true;
                        }
                        onForgetClicked: {
                            forgetProc.command = ["bluetoothctl", "remove", modelData.mac];
                            forgetProc.running = true;
                        }
                    }

                }

            }

        }

    }

    Process {
        id: settingsProc

        command: ["blueman-manager"]
    }

    Process {
        id: disconnectProc
    }

    Process {
        id: forgetProc
    }

    transform: Translate {
        y: root.expanded ? 0 : -Constants.sizeSm

        Behavior on y {
            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutCubic
            }

        }

    }

    Behavior on Layout.preferredHeight {
        NumberAnimation {
            duration: Constants.animNormal
            easing.type: root.expanded ? Easing.OutExpo : Easing.OutCubic
        }

    }

    Behavior on opacity {
        NumberAnimation {
            duration: Constants.animNormal
            easing.type: root.expanded ? Easing.Linear : Easing.OutCubic
        }

    }

}
