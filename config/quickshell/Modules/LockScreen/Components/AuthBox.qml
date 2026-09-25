import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

Rectangle {
    id: rootBox

    property Item backgroundItem
    property string typedPassword: ""
    property bool authFailed: false
    property bool authenticating: false
    property bool locked: true

    signal passwordChanged(string text)
    signal submitPassword(string pwd)
    signal clearRequested()

    function forceFocus() {
        passwordInput.forceActiveFocus();
    }

    onAuthFailedChanged: {
        if (authFailed)
            passwordInput.text = "";

    }
    width: Constants.size5Xl * 8
    height: Constants.size5Xl * 3.8
    color: "transparent"
    border.color: Theme.border
    border.width: 1
    radius: Constants.sizeLg
    state: rootBox.authFailed ? "error" : "default"
    states: [
        State {
            name: "error"
        },
        State {
            name: "default"
        }
    ]
    transitions: [
        Transition {
            to: "error"

            SequentialAnimation {
                NumberAnimation {
                    target: shakeTranslate
                    property: "x"
                    from: 0
                    to: -15
                    duration: Constants.animUltraFast / 2
                }

                NumberAnimation {
                    target: shakeTranslate
                    property: "x"
                    from: -15
                    to: 15
                    duration: Constants.animUltraFast / 2
                }

                NumberAnimation {
                    target: shakeTranslate
                    property: "x"
                    from: 15
                    to: -15
                    duration: Constants.animUltraFast / 2
                }

                NumberAnimation {
                    target: shakeTranslate
                    property: "x"
                    from: -15
                    to: 15
                    duration: Constants.animUltraFast / 2
                }

                NumberAnimation {
                    target: shakeTranslate
                    property: "x"
                    from: 15
                    to: 0
                    duration: Constants.animUltraFast / 2
                }

            }

        }
    ]

    Item {
        anchors.fill: parent
        layer.enabled: true

        ShaderEffectSource {
            id: authBoxBlurSource

            sourceItem: rootBox.backgroundItem
            sourceRect: Qt.rect(rootBox.x, rootBox.y, rootBox.width, rootBox.height)
        }

        FastBlur {
            anchors.fill: parent
            source: authBoxBlurSource
            radius: 64
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 0.4)
        }

        layer.effect: OpacityMask {

            maskSource: Rectangle {
                width: rootBox.width
                height: rootBox.height
                radius: rootBox.radius
            }

        }

    }

    TextField {
        id: passwordInput

        anchors.fill: parent
        opacity: 0
        focus: true
        echoMode: TextInput.Password
        onTextChanged: {
            if (rootBox.locked && !rootBox.authenticating)
                rootBox.passwordChanged(text);

        }
        onAccepted: {
            if (text.length > 0)
                rootBox.submitPassword(text);

        }
        Keys.onEscapePressed: {
            passwordInput.text = "";
            rootBox.clearRequested();
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: {
            passwordInput.text = "";
            rootBox.clearRequested();
            passwordInput.forceActiveFocus();
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Constants.size2Xl
        spacing: Constants.sizeLg

        RowLayout {
            spacing: Constants.sizeLg

            Rectangle {
                id: avatarContainer

                width: Constants.size4Xl
                height: Constants.size4Xl
                radius: Constants.sizeSm
                color: Theme.bg
                border.color: Theme.border
                border.width: 1

                Image {
                    id: faceImage

                    anchors.fill: parent
                    source: "file://" + Quickshell.env("HOME") + "/.face"
                    fillMode: Image.PreserveAspectCrop
                    mipmap: true
                    visible: status === Image.Ready
                    asynchronous: true
                    layer.enabled: true

                    layer.effect: OpacityMask {

                        maskSource: Rectangle {
                            width: avatarContainer.width
                            height: avatarContainer.height
                            radius: avatarContainer.radius
                        }

                    }

                }

                ThemedText {
                    anchors.centerIn: parent
                    text: SystemStats.username.charAt(0).toUpperCase()
                    customSize: Constants.sizeLg
                    font.bold: true
                    color: Theme.accent
                    visible: !faceImage.visible
                }

            }

            ColumnLayout {
                spacing: Constants.size3Xs

                ThemedText {
                    text: SystemStats.username
                    customSize: Constants.sizeLg
                    font.bold: true
                }

                ThemedText {
                    text: "@" + SystemStats.hostname
                    customSize: Constants.sizeSm
                    color: Theme.muted
                }

            }

        }

        ColumnLayout {
            spacing: Constants.sizeXs

            ThemedText {
                text: "PASSWORD"
                customSize: Constants.sizeSm
                color: Theme.muted
                font.letterSpacing: 2
                font.bold: true
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Constants.sizeLg
                clip: true

                Row {
                    id: dotsRow

                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    x: Math.min(0, parent.width - width)
                    spacing: Constants.sizeXs

                    Repeater {
                        model: Math.max(8, passwordInput.text.length)

                        Rectangle {
                            width: Constants.sizeLg
                            height: Constants.sizeLg
                            radius: Constants.size3Xs
                            color: index < passwordInput.text.length ? Theme.accent : Theme.muted
                            opacity: index < passwordInput.text.length ? 1 : 0.2

                            Behavior on color {
                                ColorAnimation {
                                    duration: Constants.animFast
                                }

                            }

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Constants.animFast
                                }

                            }

                        }

                    }

                    Behavior on x {
                        NumberAnimation {
                            duration: Constants.animFast
                            easing.type: Easing.OutCubic
                        }

                    }

                }

            }

        }

        ThemedText {
            text: rootBox.authFailed ? "incorrect password" : (rootBox.authenticating ? "verifying..." : "enter to unlock - esc to clear")
            color: rootBox.authFailed ? Theme.accent : Theme.muted
        }

    }

    transform: Translate {
        id: shakeTranslate
    }

}
