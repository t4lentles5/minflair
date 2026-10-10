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
                            target: bgRect
                            opacity: 0
                        }

                        PropertyChanges {
                            target: dimOverlay
                            opacity: 1
                        }

                        PropertyChanges {
                            target: mainContent
                            opacity: 0
                        }

                        PropertyChanges {
                            target: mainContentTranslate
                            y: 20
                        }

                        PropertyChanges {
                            target: mainContentScale
                            xScale: 0.98
                            yScale: 0.98
                        }

                        PropertyChanges {
                            target: topLeftGroup
                            opacity: 0
                        }

                        PropertyChanges {
                            target: topLeftTranslate
                            y: -15
                        }

                        PropertyChanges {
                            target: topRightGroup
                            opacity: 0
                        }

                        PropertyChanges {
                            target: topRightTranslate
                            y: -15
                        }

                        PropertyChanges {
                            target: clockGroup
                            opacity: 0
                        }

                        PropertyChanges {
                            target: clockTranslate
                            y: -20
                        }

                        PropertyChanges {
                            target: authBox
                            opacity: 0
                        }

                        PropertyChanges {
                            target: authTranslate
                            y: 24
                        }

                    },
                    State {
                        name: "locked"

                        PropertyChanges {
                            target: bgRect
                            opacity: 1
                        }

                        PropertyChanges {
                            target: dimOverlay
                            opacity: 0
                        }

                        PropertyChanges {
                            target: mainContent
                            opacity: 1
                        }

                        PropertyChanges {
                            target: mainContentTranslate
                            y: 0
                        }

                        PropertyChanges {
                            target: mainContentScale
                            xScale: 1
                            yScale: 1
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
                            target: clockGroup
                            opacity: 1
                        }

                        PropertyChanges {
                            target: clockTranslate
                            y: 0
                        }

                        PropertyChanges {
                            target: authBox
                            opacity: 1
                        }

                        PropertyChanges {
                            target: authTranslate
                            y: 0
                        }

                    },
                    State {
                        name: "unlocking"

                        PropertyChanges {
                            target: bgRect
                            opacity: 1
                        }

                        PropertyChanges {
                            target: dimOverlay
                            opacity: 0
                        }

                        PropertyChanges {
                            target: mainContent
                            opacity: 0
                        }

                        PropertyChanges {
                            target: mainContentTranslate
                            y: -40
                        }

                        PropertyChanges {
                            target: mainContentScale
                            xScale: 1.02
                            yScale: 1.02
                        }

                    }
                ]
                transitions: [
                    Transition {
                        to: "locked"

                        SequentialAnimation {
                            ParallelAnimation {
                                NumberAnimation {
                                    target: bgRect
                                    property: "opacity"
                                    duration: Constants.animExpressive
                                    easing.type: Easing.OutCubic
                                }

                                NumberAnimation {
                                    target: dimOverlay
                                    property: "opacity"
                                    duration: Constants.animNormal
                                    easing.type: Easing.OutExpo
                                }

                                NumberAnimation {
                                    target: mainContent
                                    property: "opacity"
                                    duration: Constants.animNormal
                                    easing.type: Easing.OutCubic
                                }

                                NumberAnimation {
                                    target: mainContentTranslate
                                    property: "y"
                                    duration: Constants.animExpressive
                                    easing.type: Easing.OutCubic
                                }

                                NumberAnimation {
                                    targets: [mainContentScale]
                                    properties: "xScale,yScale"
                                    duration: Constants.animExpressive
                                    easing.type: Easing.OutCubic
                                }

                                NumberAnimation {
                                    target: clockGroup
                                    property: "opacity"
                                    duration: Constants.animExpressive
                                    easing.type: Easing.OutCubic
                                }

                                NumberAnimation {
                                    target: clockTranslate
                                    property: "y"
                                    duration: Math.round(Constants.animExpressive * 1.1)
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.08
                                }

                                NumberAnimation {
                                    target: authBox
                                    property: "opacity"
                                    duration: Constants.animSlow
                                    easing.type: Easing.OutCubic
                                }

                                NumberAnimation {
                                    target: authTranslate
                                    property: "y"
                                    duration: Math.round(Constants.animExpressive * 1.1)
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.15
                                }

                                NumberAnimation {
                                    targets: [topLeftGroup, topRightGroup]
                                    property: "opacity"
                                    duration: Constants.animNormal
                                    easing.type: Easing.OutCubic
                                }

                                NumberAnimation {
                                    targets: [topLeftTranslate, topRightTranslate]
                                    property: "y"
                                    duration: Constants.animSlow
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.1
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
                                    property: "opacity"
                                    duration: Math.round(Constants.animNormal * 0.9)
                                    easing.type: Easing.OutCubic
                                }

                                NumberAnimation {
                                    target: mainContentTranslate
                                    property: "y"
                                    duration: Constants.animNormal
                                    easing.type: Easing.OutCubic
                                }

                                NumberAnimation {
                                    targets: [mainContentScale]
                                    properties: "xScale,yScale"
                                    duration: Constants.animNormal
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
                    transform: [
                        Translate {
                            id: mainContentTranslate
                        },
                        Scale {
                            id: mainContentScale

                            origin.x: mainContent.width / 2
                            origin.y: mainContent.height / 2
                        }
                    ]

                    TopLeftGroup {
                        id: topLeftGroup

                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: Constants.size2Xl

                        transform: Translate {
                            id: topLeftTranslate
                        }

                    }

                    TopRightGroup {
                        id: topRightGroup

                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: Constants.size2Xl

                        transform: Translate {
                            id: topRightTranslate
                        }

                    }

                    ColumnLayout {
                        id: centerGroup

                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -Constants.sizeLg
                        spacing: Constants.size2Xl
                        width: Math.min(parent.width - 48, 480)

                        ClockGroup {
                            id: clockGroup

                            Layout.alignment: Qt.AlignHCenter

                            transform: Translate {
                                id: clockTranslate
                            }

                        }

                        AuthBox {
                            id: authBox

                            Layout.alignment: Qt.AlignHCenter
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

                            transform: Translate {
                                id: authTranslate
                            }

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
