import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
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

    Component.onCompleted: {
        forceFocus();
    }
    onAuthFailedChanged: {
        if (authFailed)
            passwordInput.text = "";

    }
    implicitWidth: 380
    implicitHeight: contentLayout.implicitHeight + (Constants.sizeXl * 2)
    width: implicitWidth
    height: implicitHeight
    states: [
        State {
            name: "error"
            when: rootBox.authFailed
        },
        State {
            name: "default"
            when: !rootBox.authFailed
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
                    to: -14
                    duration: Constants.animFast / 3
                }

                NumberAnimation {
                    target: shakeTranslate
                    property: "x"
                    from: -14
                    to: 14
                    duration: Constants.animFast / 3
                }

                NumberAnimation {
                    target: shakeTranslate
                    property: "x"
                    from: 14
                    to: -10
                    duration: Constants.animFast / 3
                }

                NumberAnimation {
                    target: shakeTranslate
                    property: "x"
                    from: -10
                    to: 10
                    duration: Constants.animFast / 3
                }

                NumberAnimation {
                    target: shakeTranslate
                    property: "x"
                    from: 10
                    to: 0
                    duration: Constants.animFast / 3
                }

            }

        }
    ]

    Timer {
        id: focusEnsureTimer

        interval: 60
        running: rootBox.locked
        repeat: false
        onTriggered: {
            rootBox.forceFocus();
        }
    }

    ThemedShadow {
        anchors.fill: cardBg
        radius: cardBg.radius
        active: true
        opacity: Theme.isDark ? 0.6 : 0.3
    }

    Rectangle {
        id: cardBg

        anchors.fill: parent
        radius: Constants.size2Xl
        color: Theme.bg
        border.color: rootBox.authFailed ? Theme.accentComplementary : (passwordInput.activeFocus ? Theme.accent : Theme.border)
        border.width: 1

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius
            color: Theme.bgSecondary
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                passwordInput.text = "";
                rootBox.clearRequested();
                passwordInput.forceActiveFocus();
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: Constants.animFast
            }

        }

    }

    // Hidden native text field for keyboard capture
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

    ColumnLayout {
        id: contentLayout

        anchors.centerIn: parent
        width: parent.width - (Constants.sizeXl * 2)
        spacing: Constants.sizeLg

        // User Avatar and Name
        RowLayout {
            Layout.alignment: Qt.AlignLeft
            spacing: Constants.sizeMd

            Rectangle {
                id: avatarOuter

                width: 52
                height: 52
                radius: width / 2
                color: "transparent"
                border.color: Theme.accent
                border.width: 1.5

                Rectangle {
                    id: avatarInner

                    anchors.centerIn: parent
                    width: 44
                    height: 44
                    radius: width / 2
                    color: Theme.bg
                    clip: true

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
                                width: avatarInner.width
                                height: avatarInner.height
                                radius: avatarInner.radius
                            }

                        }

                    }

                    ThemedText {
                        anchors.centerIn: parent
                        text: (SystemStats.username ? SystemStats.username.charAt(0).toUpperCase() : "U")
                        customSize: Constants.sizeLg
                        font.bold: true
                        color: Theme.accent
                        visible: !faceImage.visible
                    }

                }

            }

            ColumnLayout {
                spacing: Constants.size3Xs
                Layout.alignment: Qt.AlignVCenter

                ThemedText {
                    text: SystemStats.username || "User"
                    customSize: Constants.sizeMd
                    font.bold: true
                    color: Theme.fg
                }

                ThemedText {
                    text: "@" + (SystemStats.hostname || "arch")
                    customSize: 11
                    color: Theme.muted
                }

            }

        }

        // Styled Password Input Box
        Rectangle {
            id: inputContainer

            Layout.fillWidth: true
            Layout.preferredHeight: 46
            radius: Constants.sizeLg
            color: passwordInput.activeFocus ? (Theme.isDark ? Theme.bgSecondary : Theme.bg) : (Theme.isDark ? Theme.bgTertiary : Theme.bg)
            border.color: rootBox.authFailed ? Theme.accentComplementary : (passwordInput.activeFocus ? Theme.accent : Theme.border)
            border.width: passwordInput.activeFocus ? 2 : 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Constants.sizeMd
                anchors.rightMargin: Constants.sizeSm
                spacing: Constants.sizeSm

                SvgIcon {
                    icon: "lock"
                    iconSize: Constants.sizeMd
                    iconColor: rootBox.authFailed ? Theme.accentComplementary : (passwordInput.activeFocus ? Theme.accent : Theme.muted)
                    flat: true
                    Layout.alignment: Qt.AlignVCenter

                    Behavior on iconColor {
                        ColorAnimation {
                            duration: Constants.animFast
                        }

                    }

                }

                // Password placeholder, cursor, or dots
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        visible: passwordInput.text.length === 0 && !rootBox.authenticating

                        Rectangle {
                            id: blinkingCursorPlaceholder

                            anchors.verticalCenter: parent.verticalCenter
                            width: Constants.size3Xs
                            height: Constants.sizeLg
                            radius: width / 2
                            color: Theme.accent
                            visible: passwordInput.activeFocus
                            opacity: cursorTimer.cursorVisible ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Constants.animFast
                                }

                            }

                        }

                        ThemedText {
                            anchors.verticalCenter: parent.verticalCenter
                            verticalAlignment: Text.AlignVCenter
                            text: "Type password to unlock..."
                            customSize: Constants.sizeSm
                            color: Theme.muted
                            opacity: passwordInput.activeFocus ? 0.9 : 0.6
                        }

                    }

                    ThemedText {
                        anchors.verticalCenter: parent.verticalCenter
                        verticalAlignment: Text.AlignVCenter
                        text: "Verifying..."
                        customSize: Constants.sizeSm
                        color: Theme.accent
                        font.bold: true
                        visible: rootBox.authenticating
                    }

                    Row {
                        id: dotsRow

                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Constants.sizeXs
                        visible: passwordInput.text.length > 0 && !rootBox.authenticating

                        Repeater {
                            model: passwordInput.text.length

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: Constants.sizeXs
                                height: Constants.sizeXs
                                radius: Constants.size2Xs
                                color: Theme.accent

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Constants.animFast
                                        easing.type: Easing.OutBack
                                    }

                                }

                            }

                        }

                        Rectangle {
                            id: blinkingCursorDots

                            anchors.verticalCenter: parent.verticalCenter
                            width: Constants.size3Xs
                            height: Constants.sizeMd
                            radius: width / 2
                            color: Theme.accent
                            visible: passwordInput.activeFocus
                            opacity: cursorTimer.cursorVisible ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Constants.animFast
                                }

                            }

                        }

                    }

                    Timer {
                        id: cursorTimer

                        property bool cursorVisible: true

                        interval: 500
                        running: passwordInput.activeFocus
                        repeat: true
                        onTriggered: cursorVisible = !cursorVisible
                    }

                }

                // Action button (arrow or spinner)
                Item {
                    Layout.preferredWidth: 28
                    Layout.preferredHeight: 28
                    Layout.alignment: Qt.AlignVCenter

                    SvgIcon {
                        anchors.centerIn: parent
                        icon: "reload"
                        iconSize: Constants.sizeLg
                        iconColor: Theme.accent
                        flat: true
                        visible: rootBox.authenticating

                        RotationAnimation on rotation {
                            from: 0
                            to: 360
                            duration: Constants.animExpressive * 2
                            loops: Animation.Infinite
                            running: rootBox.authenticating
                        }

                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: passwordInput.text.length > 0 ? Theme.accent : "transparent"
                        opacity: passwordInput.text.length > 0 ? 0.9 : 0
                        visible: !rootBox.authenticating

                        SvgIcon {
                            anchors.centerIn: parent
                            icon: "rocket"
                            iconSize: Constants.sizeSm
                            iconColor: Theme.bg
                            flat: true
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (passwordInput.text.length > 0)
                                    rootBox.submitPassword(passwordInput.text);

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

            Behavior on border.color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

            Behavior on border.width {
                NumberAnimation {
                    duration: Constants.animFast
                }

            }

            Behavior on color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

        // Status text / hint
        ThemedText {
            Layout.alignment: Qt.AlignHCenter
            text: rootBox.authFailed ? "Incorrect password. Please try again." : (rootBox.authenticating ? "Verifying credentials..." : "Press Enter to unlock • Esc to clear")
            customSize: 11
            color: rootBox.authFailed ? Theme.accentComplementary : Theme.muted
            font.bold: rootBox.authFailed

            Behavior on color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

    }

    transform: Translate {
        id: shakeTranslate
    }

}
