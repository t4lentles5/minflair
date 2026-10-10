import "Components"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Windows
import qs.Modules.ControlCenter.Widgets.QuickSettings.Components

Item {
    id: root

    property bool quickSettingsOpen: false
    property var notificationService
    property int activePageIndex: 0
    property real extraExpandedHeight: 0

    function resetView() {
        root.activePageIndex = 0;
    }

    onQuickSettingsOpenChanged: {
        if (!quickSettingsOpen) {
            resetPageTimer.restart();
        } else {
            resetPageTimer.stop();
            root.resetView();
        }
    }
    implicitWidth: mainPage.implicitWidth
    implicitHeight: mainPage.implicitHeight + (activePageIndex !== 0 ? extraExpandedHeight : 0)

    Timer {
        id: resetPageTimer

        interval: Constants.animNormal + 50
        repeat: false
        onTriggered: {
            if (!root.quickSettingsOpen)
                root.resetView();

        }
    }

    Item {
        id: stackContainer

        anchors.fill: parent
        clip: true

        ColumnLayout {
            id: mainPage

            width: parent.width
            spacing: Constants.sizeLg
            x: root.activePageIndex === 0 ? 0 : -parent.width

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Constants.sizeLg

                GridLayout {
                    id: topControlsGrid

                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: Constants.sizeMd
                    columnSpacing: Constants.sizeMd

                    WifiControl {
                        id: wifiControl

                        Layout.fillWidth: true
                        isVisible: root.quickSettingsOpen
                        expanded: root.activePageIndex === 1
                        onMenuClicked: {
                            if (isActive)
                                root.activePageIndex = 1;

                        }
                        onIsActiveChanged: {
                            if (!isActive && root.activePageIndex === 1)
                                root.activePageIndex = 0;

                        }
                    }

                    BluetoothControl {
                        id: btControl

                        Layout.fillWidth: true
                        isVisible: root.quickSettingsOpen
                        expanded: root.activePageIndex === 2
                        onMenuClicked: {
                            if (isActive)
                                root.activePageIndex = 2;

                        }
                        onIsActiveChanged: {
                            if (!isActive && root.activePageIndex === 2)
                                root.activePageIndex = 0;

                        }
                    }

                }

                GridLayout {
                    id: middleControlsGrid

                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: Constants.sizeMd
                    columnSpacing: Constants.sizeMd

                    NightLightControl {
                        id: nightLightBtn

                        Layout.fillWidth: true
                    }

                    CaffeineControl {
                        id: caffeineBtn

                        Layout.fillWidth: true
                    }

                    GameModeControl {
                        id: gamepadBtn

                        Layout.fillWidth: true
                    }

                    BatteryLimitControl {
                        id: batteryLimitBtn

                        Layout.fillWidth: true
                        isVisible: root.quickSettingsOpen
                    }

                }

                Card {
                    Layout.fillWidth: true
                    cardRadius: Constants.sizeSm
                    useBorder: false
                    backgroundColor: Theme.bgSecondary
                    contentPadding: Constants.sizeLg

                    ColumnLayout {
                        id: sliderCol

                        anchors.fill: parent
                        spacing: Constants.sizeMd

                        BrightnessSlider {
                            Layout.fillWidth: true
                            isVisible: root.quickSettingsOpen
                        }

                        VolumeSlider {
                            Layout.fillWidth: true
                        }

                        ThemedSlider {
                            id: micSlider

                            Layout.fillWidth: true
                            enabled: !AudioService.micMuted
                            value: AudioService.micVolume
                            icon: AudioService.micMuted ? "microphone-off" : "microphone"
                            onMoved: (val) => {
                                AudioService.setMicVolume(val);
                            }
                            onIconClicked: AudioService.setMicMuted(!AudioService.micMuted)
                        }

                    }

                }

            }

            Behavior on x {
                enabled: root.quickSettingsOpen

                NumberAnimation {
                    duration: Constants.animNormal
                    easing.type: Easing.OutCubic
                }

            }

        }

        ColumnLayout {
            id: wifiPage

            spacing: Constants.sizeSm
            width: parent.width
            height: parent.height
            x: root.activePageIndex === 1 ? 0 : parent.width

            RowLayout {
                Layout.fillWidth: true

                SvgIconButton {
                    icon: "chevron-left"
                    iconSize: Constants.sizeLg
                    flat: true
                    onClicked: root.activePageIndex = 0
                }

                ThemedText {
                    text: "Wi-Fi Networks"
                    customSize: Constants.sizeMd
                    font.bold: true
                    Layout.fillWidth: true
                }

                SvgIconButton {
                    icon: "reload"
                    iconSize: Constants.sizeMd
                    flat: true
                    onClicked: wifiControl.scan()
                    visible: wifiControl.isActive

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: Constants.animExpressive * 2
                        loops: Animation.Infinite
                        running: wifiControl.isScanning
                    }

                }

            }

            WifiList {
                Layout.fillWidth: true
                Layout.fillHeight: true
                isVisible: root.quickSettingsOpen
                expanded: root.activePageIndex === 1
                isActive: wifiControl.isActive
                wifiList: wifiControl.wifiList
                isScanning: wifiControl.isScanning
                onConnect: (ssid) => {
                    return wifiControl.connect(ssid);
                }
                onRefreshRequested: {
                    wifiControl.scan(true);
                }
            }

            Behavior on x {
                enabled: root.quickSettingsOpen

                NumberAnimation {
                    duration: Constants.animNormal
                    easing.type: Easing.OutCubic
                }

            }

        }

        ColumnLayout {
            id: bluetoothPage

            spacing: Constants.sizeSm
            width: parent.width
            height: parent.height
            x: root.activePageIndex === 2 ? 0 : parent.width

            RowLayout {
                Layout.fillWidth: true
                spacing: Constants.sizeSm

                SvgIconButton {
                    icon: "chevron-left"
                    iconSize: Constants.sizeLg
                    flat: true
                    onClicked: root.activePageIndex = 0
                }

                ThemedText {
                    text: "Bluetooth Devices"
                    customSize: Constants.sizeMd
                    font.bold: true
                    Layout.fillWidth: true
                }

                SvgIconButton {
                    icon: "reload"
                    iconSize: Constants.sizeMd
                    flat: true
                    onClicked: btControl.scan()
                    visible: btControl.isActive

                    RotationAnimation on rotation {
                        from: 0
                        to: 360
                        duration: Constants.animExpressive * 2
                        loops: Animation.Infinite
                        running: btControl.isScanning
                    }

                }

            }

            BluetoothList {
                Layout.fillWidth: true
                Layout.fillHeight: true
                isVisible: root.quickSettingsOpen
                expanded: root.activePageIndex === 2
                isActive: btControl.isActive
                btList: btControl.btList
                isScanning: btControl.isScanning
                onConnect: (mac) => {
                    return btControl.connect(mac);
                }
                onRefreshRequested: {
                    btControl.scan();
                }
            }

            Behavior on x {
                enabled: root.quickSettingsOpen

                NumberAnimation {
                    duration: Constants.animNormal
                    easing.type: Easing.OutCubic
                }

            }

        }

    }

}
