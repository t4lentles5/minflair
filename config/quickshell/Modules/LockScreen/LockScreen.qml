import "./Components"
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    property string typedPassword: ""

    LockScreenIpcController {
        id: ipcController

        onToggleLockRequested: {
            if (!lockManager.locked) {
                ipcController.reset();
                lockManager.locked = true;
            } else {
                lockManager.locked = false;
            }
        }
        onUnlockRequested: lockManager.locked = false
    }

    WlSessionLock {
        id: lockManager

        onLockedChanged: {
            if (locked)
                root.typedPassword = "";

        }

        WlSessionLockSurface {
            id: lockSurface

            Rectangle {
                id: mainOverlay

                property bool ready: false

                Component.onCompleted: ready = true
                anchors.fill: parent
                color: Theme.bg
                opacity: 1
                state: ipcController.unlocking ? "unlocking" : (ready ? "locked" : "hidden")
                states: [
                    State {
                        name: "hidden"

                        PropertyChanges {
                            target: dimOverlay
                            opacity: 1
                        }

                        PropertyChanges {
                            target: mainContent
                            opacity: 0
                            scale: 1.05
                        }

                        PropertyChanges {
                            target: topLeftGroup
                            opacity: 0
                        }

                        PropertyChanges {
                            target: topLeftTranslate
                            y: -30
                        }

                        PropertyChanges {
                            target: topRightGroup
                            opacity: 0
                        }

                        PropertyChanges {
                            target: topRightTranslate
                            y: -30
                        }

                        PropertyChanges {
                            target: middleLeftGroup
                            opacity: 0
                        }

                        PropertyChanges {
                            target: middleLeftTranslate
                            x: -40
                        }

                        PropertyChanges {
                            target: authBox
                            opacity: 0
                        }

                        PropertyChanges {
                            target: authBoxEntryTranslate
                            y: 40
                        }

                        PropertyChanges {
                            target: bottomRightGroup
                            opacity: 0
                        }

                        PropertyChanges {
                            target: bottomRightTranslate
                            y: 40
                        }

                    },
                    State {
                        name: "locked"

                        PropertyChanges {
                            target: dimOverlay
                            opacity: 0
                        }

                        PropertyChanges {
                            target: mainContent
                            opacity: 1
                            scale: 1
                        }

                        PropertyChanges {
                            target: topLeftGroup
                            opacity: 1
                        }

                        PropertyChanges {
                            target: topLeftTranslate
                            y: 0
                        }

                        PropertyChanges {
                            target: topRightGroup
                            opacity: 1
                        }

                        PropertyChanges {
                            target: topRightTranslate
                            y: 0
                        }

                        PropertyChanges {
                            target: middleLeftGroup
                            opacity: 1
                        }

                        PropertyChanges {
                            target: middleLeftTranslate
                            x: 0
                        }

                        PropertyChanges {
                            target: authBox
                            opacity: 1
                        }

                        PropertyChanges {
                            target: authBoxEntryTranslate
                            y: 0
                        }

                        PropertyChanges {
                            target: bottomRightGroup
                            opacity: 1
                        }

                        PropertyChanges {
                            target: bottomRightTranslate
                            y: 0
                        }

                    },
                    State {
                        name: "unlocking"

                        PropertyChanges {
                            target: dimOverlay
                            opacity: 0
                        }

                        PropertyChanges {
                            target: mainContent
                            opacity: 0
                            scale: 0.95
                        }

                        PropertyChanges {
                            target: topLeftGroup
                            opacity: 0
                        }

                        PropertyChanges {
                            target: topLeftTranslate
                            y: -20
                        }

                        PropertyChanges {
                            target: topRightGroup
                            opacity: 0
                        }

                        PropertyChanges {
                            target: topRightTranslate
                            y: -20
                        }

                        PropertyChanges {
                            target: middleLeftGroup
                            opacity: 0
                        }

                        PropertyChanges {
                            target: middleLeftTranslate
                            x: -20
                        }

                        PropertyChanges {
                            target: authBox
                            opacity: 0
                        }

                        PropertyChanges {
                            target: authBoxEntryTranslate
                            y: 20
                        }

                        PropertyChanges {
                            target: bottomRightGroup
                            opacity: 0
                        }

                        PropertyChanges {
                            target: bottomRightTranslate
                            y: 20
                        }

                    }
                ]
                transitions: [
                    Transition {
                        to: "locked"

                        SequentialAnimation {
                            ParallelAnimation {
                                NumberAnimation {
                                    target: dimOverlay
                                    property: "opacity"
                                    duration: Constants.animExpressive * 1.5
                                    easing.type: Easing.OutExpo
                                }

                                NumberAnimation {
                                    target: mainContent
                                    properties: "opacity,scale"
                                    duration: Constants.animExpressive * 1.5
                                    easing.type: Easing.OutExpo
                                }

                                NumberAnimation {
                                    targets: [topLeftGroup, topRightGroup, middleLeftGroup, authBox, bottomRightGroup]
                                    property: "opacity"
                                    duration: Constants.animExpressive * 1.5
                                    easing.type: Easing.OutExpo
                                }

                                NumberAnimation {
                                    targets: [topLeftTranslate, topRightTranslate, authBoxEntryTranslate, bottomRightTranslate]
                                    property: "y"
                                    duration: Constants.animExpressive * 1.5
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.2
                                }

                                NumberAnimation {
                                    target: middleLeftTranslate
                                    property: "x"
                                    duration: Constants.animExpressive * 1.5
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.2
                                }

                            }

                            ScriptAction {
                                script: authBox.forceFocus()
                            }

                        }

                    },
                    Transition {
                        to: "unlocking"

                        SequentialAnimation {
                            ParallelAnimation {
                                NumberAnimation {
                                    target: mainContent
                                    properties: "opacity,scale"
                                    duration: Constants.animExpressive
                                    easing.type: Easing.OutCubic
                                }

                                NumberAnimation {
                                    targets: [dimOverlay, topLeftGroup, topRightGroup, middleLeftGroup, authBox, bottomRightGroup]
                                    property: "opacity"
                                    duration: Constants.animExpressive
                                    easing.type: Easing.OutCubic
                                }

                                NumberAnimation {
                                    targets: [topLeftTranslate, topRightTranslate, authBoxEntryTranslate, bottomRightTranslate]
                                    property: "y"
                                    duration: Constants.animExpressive
                                    easing.type: Easing.OutCubic
                                }

                                NumberAnimation {
                                    target: middleLeftTranslate
                                    property: "x"
                                    duration: Constants.animExpressive
                                    easing.type: Easing.OutCubic
                                }

                            }

                            ScriptAction {
                                script: lockManager.locked = false
                            }

                        }

                    }
                ]

                Background {
                    id: bgRect

                    anchors.fill: parent
                }

                Rectangle {
                    id: dimOverlay

                    anchors.fill: parent
                    color: Theme.bg
                    opacity: 0
                }

                Item {
                    id: mainContent

                    anchors.fill: parent

                    TopLeftGroup {
                        id: topLeftGroup

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: Constants.size5Xl * 1.2

                        transform: Translate {
                            id: topLeftTranslate
                        }

                    }

                    TopRightGroup {
                        id: topRightGroup

                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: Constants.size5Xl * 1.2

                        transform: Translate {
                            id: topRightTranslate
                        }

                    }

                    ClockGroup {
                        id: middleLeftGroup

                        anchors.left: parent.left
                        anchors.leftMargin: Constants.size5Xl * 1.2
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -Constants.size5Xl * 1.5

                        transform: Translate {
                            id: middleLeftTranslate
                        }

                    }

                    AuthBox {
                        id: authBox

                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: Constants.size5Xl * 1.2
                        backgroundItem: bgRect
                        typedPassword: root.typedPassword
                        authFailed: ipcController.authFailed
                        authenticating: ipcController.authenticating
                        locked: lockManager.locked
                        onPasswordChanged: (text) => {
                            root.typedPassword = text;
                            if (text.length > 0)
                                ipcController.authFailed = false;

                        }
                        onSubmitPassword: (pwd) => {
                            ipcController.submitPassword(pwd);
                        }
                        onClearRequested: () => {
                            root.typedPassword = "";
                            ipcController.authFailed = false;
                        }
                        transform: [
                            Translate {
                                id: authBoxEntryTranslate
                            }
                        ]
                    }

                    QuoteGroup {
                        id: bottomRightGroup

                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: Constants.size5Xl * 1.2

                        transform: Translate {
                            id: bottomRightTranslate
                        }

                    }

                    MouseArea {
                        anchors.fill: parent
                        z: -1
                        onClicked: {
                            root.typedPassword = "";
                            ipcController.authFailed = false;
                            authBox.forceFocus();
                        }
                    }

                }

            }

        }

    }

}
