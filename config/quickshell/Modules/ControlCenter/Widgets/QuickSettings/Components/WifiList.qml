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
    Layout.preferredHeight: expanded ? Math.max(wifiListCol.implicitHeight, 80) : 0
    implicitHeight: Layout.preferredHeight
    opacity: expanded ? 1 : 0
    visible: opacity > 0
    clip: true
    radius: 0
    color: "transparent"
    border.width: 0

    Timer {
        id: scanTimeout

        interval: 10000
        running: root.expanded && root.isVisible && root.wifiList.length === 0
        onTriggered: root.timedOut = true
        onRunningChanged: {
            if (!running && !root.expanded)
                root.timedOut = false;

        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Constants.sizeXs
        visible: root.expanded && root.wifiList.length === 0

        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 20
            height: 20
            visible: !root.timedOut

            SvgIcon {
                anchors.centerIn: parent
                icon: "reload"
                iconColor: Theme.muted
                iconSize: Constants.sizeMd
                flat: true
            }

            RotationAnimation on rotation {
                from: 0
                to: 360
                duration: 1200
                loops: Animation.Infinite
                running: parent.visible
            }

        }

        ThemedText {
            Layout.alignment: Qt.AlignHCenter
            text: root.timedOut ? "No networks found" : "Scanning..."
            color: Theme.muted
        }

    }

    ColumnLayout {
        id: wifiListCol

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.wifiList.length > 0

        ThemedText {
            text: "Networks"
            font.letterSpacing: 1
            color: Theme.muted
            visible: false
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(wifiRepeaterCol.implicitHeight, 200)
            contentHeight: wifiRepeaterCol.implicitHeight
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                id: wifiRepeaterCol

                width: parent.width
                spacing: Constants.sizeXs

                Repeater {
                    model: root.wifiList

                    Item {
                        id: wifiItem

                        Layout.fillWidth: true
                        implicitHeight: 36

                        Rectangle {
                            anchors.fill: parent
                            radius: Constants.sizeLg
                            color: hoverHandlerW.hovered ? Theme.bgSecondary : "transparent"

                            Behavior on color {
                                ColorAnimation {
                                    duration: Constants.animFast
                                }

                            }

                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Constants.sizeSm
                            anchors.rightMargin: Constants.sizeSm
                            spacing: Constants.sizeSm

                            SvgIcon {
                                icon: root.getWifiIcon(modelData.signal)
                                iconColor: modelData.active ? Theme.accent : Theme.fg
                                iconSize: Constants.sizeLg
                                flat: true
                                opacity: modelData.active ? 1 : 0.7
                            }

                            ThemedText {
                                text: modelData.ssid
                                color: modelData.active ? Theme.accent : Theme.fg
                                font.bold: modelData.active
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Rectangle {
                                visible: modelData.active
                                radius: 4
                                implicitWidth: statusText.implicitWidth + Constants.sizeXs
                                implicitHeight: statusText.implicitHeight + 2
                                color: Theme.bgSecondary

                                ThemedText {
                                    id: statusText

                                    anchors.centerIn: parent
                                    text: "Connected"
                                    customSize: Constants.sizeXs - 1
                                    font.bold: true
                                    color: Theme.accent
                                }

                            }

                            SvgIcon {
                                visible: modelData.secured && !modelData.active
                                icon: "lock"
                                iconColor: Theme.muted
                                iconSize: Constants.sizeSm
                                flat: true
                                opacity: 0.5
                            }

                        }

                        HoverHandler {
                            id: hoverHandlerW
                        }

                        TapHandler {
                            onTapped: root.connect(modelData.ssid)
                        }

                    }

                }

            }

        }

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
            easing.type: Easing.OutCubic
        }

    }

    Behavior on opacity {
        NumberAnimation {
            duration: Constants.animNormal
            easing.type: Easing.OutCubic
        }

    }

}
