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
    property var wifiList: []
    property bool isScanning: false
    property bool timedOut: false
    property bool isVisible: true

    signal connect(string ssid)

    function getWifiIcon(signal) {
        let sig = parseInt(signal) || 0;
        if (sig <= 25)
            return "wifi-0";

        if (sig <= 50)
            return "wifi-1";

        if (sig <= 75)
            return "wifi-2";

        return "wifi";
    }

    Layout.fillWidth: true
    Layout.fillHeight: expanded
    implicitHeight: expanded ? Math.max(wifiListCol.implicitHeight, 80) : 0
    opacity: expanded ? 1 : 0
    visible: opacity > 0
    clip: true
    radius: 0
    color: "transparent"
    border.width: 0

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Constants.sizeSm
        visible: root.expanded && root.wifiList.length === 0

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
                running: root.expanded && root.isScanning && root.wifiList.length === 0
            }

        }

        SvgIcon {
            Layout.alignment: Qt.AlignHCenter
            icon: "wifi-off"
            iconColor: Theme.muted
            iconSize: Constants.size2Xl
            flat: true
            visible: !root.isScanning
        }

        ThemedText {
            Layout.alignment: Qt.AlignHCenter
            text: root.isScanning ? "Searching for networks..." : "No networks found"
            color: root.isScanning ? Theme.fg : Theme.muted
            font.bold: root.isScanning
        }

        ThemedText {
            Layout.alignment: Qt.AlignHCenter
            text: "Make sure Wi-Fi is turned on or tap reload"
            color: Theme.muted
            customSize: Constants.sizeXs + 2
            visible: !root.isScanning
        }

    }

    ColumnLayout {
        id: wifiListCol

        anchors.fill: parent
        visible: root.wifiList.length > 0

        ThemedText {
            text: "Networks"
            font.letterSpacing: 1
            color: Theme.muted
            visible: false
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: wifiRepeaterCol.implicitHeight
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                id: wifiRepeaterCol

                width: wifiListCol.width
                spacing: Constants.sizeXs

                Repeater {
                    model: root.wifiList

                    ControlCenterListDelegate {
                        titleText: modelData.ssid
                        subtitleText: modelData.signal > 75 ? "Excellent signal" : (modelData.signal > 50 ? "Good signal" : "Weak signal")
                        iconName: root.getWifiIcon(modelData.signal)
                        isActive: modelData.active
                        showLock: modelData.secured
                        onClicked: root.connect(modelData.ssid)
                        onActionClicked: {
                            settingsProc.running = true;
                        }
                        onDisconnectClicked: {
                            disconnectProc.command = ["nmcli", "connection", "down", "id", modelData.ssid];
                            disconnectProc.running = true;
                        }
                        onForgetClicked: {
                            forgetProc.command = ["nmcli", "connection", "delete", "id", modelData.ssid];
                            forgetProc.running = true;
                        }
                    }

                }

            }

        }

    }

    Process {
        id: settingsProc

        command: ["nm-connection-editor"]
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
