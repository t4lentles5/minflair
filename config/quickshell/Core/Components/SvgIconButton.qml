import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Services

Rectangle {
    id: root

    property string icon: ""
    property int iconSize: Constants.sizeLg
    property bool flat: false
    property bool isActive: false
    property color bgColor: isActive ? Theme.accent : (flat ? "transparent" : Theme.bgSecondary)
    property color iconColor: isActive ? Theme.fg : Theme.fg
    property color hoverColor: "transparent"
    property alias hovered: mouseArea.containsMouse
    property string textIcon: ""
    property int textIconSize: 0
    property bool disabled: false
    property bool useCustomWidth: false
    property bool useOriginalColors: false
    readonly property int scaledIconSize: Math.round(iconSize * SettingsService.fontScale)
    readonly property int scaledTextIconSize: Math.round(textIconSize * SettingsService.fontScale)
    property int padding: Constants.sizeSm
    property int contentAlignment: Qt.AlignHCenter

    signal clicked(var mouse)

    color: {
        if (disabled)
            return flat ? "transparent" : Theme.bgSecondary;

        if (mouseArea.pressed || mouseArea.containsMouse)
            return isActive ? Qt.darker(Theme.accent, 1.1) : Theme.bgSecondary;

        return bgColor;
    }
    scale: disabled ? 1 : mouseArea.pressed ? 0.95 : 1
    radius: height / 2
    implicitWidth: useCustomWidth ? container.width + Constants.sizeLg * 2 : scaledIconSize + padding * 2
    implicitHeight: (scaledIconSize) + padding * 2

    RowLayout {
        id: container

        anchors.verticalCenter: parent.verticalCenter
        anchors.left: root.contentAlignment === Qt.AlignLeft ? parent.left : undefined
        anchors.leftMargin: root.contentAlignment === Qt.AlignLeft ? Constants.sizeLg : 0
        anchors.horizontalCenter: root.contentAlignment === Qt.AlignHCenter ? parent.horizontalCenter : undefined
        spacing: 4

        Item {
            implicitWidth: root.scaledIconSize
            implicitHeight: root.scaledIconSize
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            Image {
                id: iconImage

                anchors.fill: parent
                source: root.icon ? `${Quickshell.shellDir}/assets/${root.icon}.svg` : ""
                sourceSize.width: root.scaledIconSize
                sourceSize.height: root.scaledIconSize
                visible: root.useOriginalColors
            }

            ColorOverlay {
                id: colorOverlay

                property color targetColor: {
                    if (disabled)
                        return Theme.muted;

                    if (mouseArea.containsMouse && root.hoverColor.a !== 0)
                        return root.hoverColor;

                    return root.iconColor;
                }

                anchors.fill: parent
                source: iconImage
                color: Qt.rgba(targetColor.r, targetColor.g, targetColor.b, 1)
                opacity: targetColor.a
                visible: !root.useOriginalColors
                scale: disabled ? 1 : mouseArea.containsMouse ? 1.15 : 1

                Behavior on scale {
                    NumberAnimation {
                        duration: Constants.animFast
                        easing.type: Easing.OutQuint
                    }

                }

                Behavior on color {
                    ColorAnimation {
                        duration: Constants.animNormal
                    }

                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Constants.animNormal
                    }

                }

            }

        }

        ThemedText {
            id: textLabel

            visible: root.textIcon !== ""
            text: root.textIcon
            customSize: root.textIconSize
            color: {
                if (disabled)
                    return Theme.muted;

                return Theme.fg;
            }
        }

    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: (mouse) => {
            if (!root.disabled)
                root.clicked(mouse);

        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Constants.animNormal
        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutBack
        }

    }

}
