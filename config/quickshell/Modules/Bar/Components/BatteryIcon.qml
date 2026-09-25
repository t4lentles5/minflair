import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property int batteryLevel: SystemInfoService.batteryLevel
    property string batteryStatus: SystemInfoService.batteryStatus
    property bool hasBattery: SystemInfoService.hasBattery
    property var notificationService
    property string _prevStatus: ""
    property int _prevLevel: -1
    property bool notifiedFull: false
    property color activeColor: Theme.fg
    property int textOffsetX: 0
    property int textOffsetY: 0

    visible: hasBattery
    implicitWidth: 32
    implicitHeight: 16
    onBatteryStatusChanged: {
        if (batteryStatus === "" || batteryStatus === _prevStatus)
            return ;

        if (_prevStatus !== "") {
            let summary = "Battery";
            let body = "";
            if (batteryStatus === "Charging") {
                if (_prevStatus === "Discharging") {
                    summary = "Battery";
                    body = "Charger connected";
                }
            } else if (batteryStatus === "Discharging") {
                if (_prevStatus === "Charging" || _prevStatus === "Full" || _prevStatus === "Not charging") {
                    summary = "Battery";
                    body = "Charger disconnected";
                }
            } else if (batteryStatus === "Full" || batteryStatus === "Not charging") {
                if (!root.notifiedFull && batteryStatus === "Full" && root.batteryLevel >= 95) {
                    summary = "Battery";
                    body = "Battery fully charged";
                    root.notifiedFull = true;
                }
            }
            if (body !== "" && notificationService)
                notificationService.notify(summary, body);

        }
        _prevStatus = batteryStatus;
    }
    onBatteryLevelChanged: {
        if (batteryLevel <= 0 || batteryLevel === _prevLevel)
            return ;

        if (batteryStatus === "Discharging" && batteryLevel < 95)
            root.notifiedFull = false;

        if (_prevLevel !== -1 && batteryStatus === "Discharging") {
            let threshold = 0;
            if (batteryLevel <= 5 && _prevLevel > 5)
                threshold = 5;
            else if (batteryLevel <= 10 && _prevLevel > 10)
                threshold = 10;
            else if (batteryLevel <= 20 && _prevLevel > 20)
                threshold = 20;
            if (threshold > 0 && notificationService)
                notificationService.notify("Low Battery", "Battery level: " + batteryLevel + "%", "", "System", NotificationUrgency.Critical);

        }
        _prevLevel = batteryLevel;
    }

    Item {
        anchors.centerIn: parent
        width: 28
        height: 14

        Rectangle {
            id: batteryBody

            anchors.fill: parent
            anchors.rightMargin: 2
            color: "transparent"
            border.width: 1
            border.color: Theme.fg
            radius: 4

            Rectangle {
                id: batteryFill

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 1.5
                width: Math.max(0, (parent.width - 3) * (root.batteryLevel / 100))
                radius: 2.5
                color: Theme.bgSecondary

                Behavior on width {
                    NumberAnimation {
                        duration: Constants.animNormal
                        easing.type: Easing.OutCubic
                    }

                }

            }

            ThemedText {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: root.textOffsetX
                anchors.verticalCenterOffset: root.textOffsetY
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: root.batteryLevel.toString()
                customSize: Constants.sizeXs + 1
                font.bold: true
                color: Theme.fg
                renderType: Text.QtRendering
            }

        }

        Item {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: 4

            Rectangle {
                anchors.fill: parent
                radius: 1
                color: Theme.fg
            }

        }

    }

    Behavior on activeColor {
        ColorAnimation {
            duration: Constants.animSlow
            easing.type: Easing.OutQuint
        }

    }

    SequentialAnimation on opacity {
        loops: Animation.Infinite
        running: root.batteryStatus === "Charging" && root.batteryLevel < 100
        onRunningChanged: {
            if (!running)
                root.opacity = 1;

        }

        NumberAnimation {
            to: 0.5
            duration: 1000
            easing.type: Easing.InOutSine
        }

        NumberAnimation {
            to: 1
            duration: 1000
            easing.type: Easing.InOutSine
        }

    }

}
