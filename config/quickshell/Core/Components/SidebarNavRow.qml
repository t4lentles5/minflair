import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Rectangle {
    id: rowRoot

    property string iconName: ""
    property string labelText: ""
    property string statusText: ""
    property bool isActive: false

    signal rowClicked()

    Layout.fillWidth: true
    Layout.preferredHeight: Constants.size3Xl
    radius: Constants.sizeXs
    scale: tapHandler.pressed ? 0.98 : 1
    color: isActive ? Theme.bgSecondary : (hoverHandler.hovered ? Theme.border : "transparent")
    border.color: isActive ? Theme.border : "transparent"
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Constants.sizeSm
        anchors.rightMargin: Constants.sizeSm
        spacing: Constants.sizeXs

        SvgIcon {
            icon: rowRoot.iconName
            iconSize: 15
            flat: true
            iconColor: rowRoot.isActive ? Theme.fg : (hoverHandler.hovered ? Theme.fg : Theme.muted)

            Behavior on iconColor {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

        ThemedText {
            text: rowRoot.labelText
            font.weight: rowRoot.isActive ? Font.DemiBold : Font.Normal
            color: rowRoot.isActive ? Theme.fg : (hoverHandler.hovered ? Theme.fg : Theme.muted)
            elide: Text.ElideRight
            Layout.fillWidth: true

            Behavior on color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

        Rectangle {
            visible: rowRoot.statusText !== ""
            implicitHeight: Constants.sizeLg + 2
            implicitWidth: Math.max(statusLabel.implicitWidth + 10, 18)
            radius: height / 2
            color: rowRoot.isActive ? Theme.bgAccent : Theme.bgSecondary
            Layout.alignment: Qt.AlignVCenter

            ThemedText {
                id: statusLabel

                anchors.centerIn: parent
                text: rowRoot.statusText
                customSize: 10
                font.weight: rowRoot.isActive ? Font.Bold : Font.Normal
                color: rowRoot.isActive ? Theme.accent : Theme.muted
            }

        }

    }

    HoverHandler {
        id: hoverHandler

        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tapHandler

        onTapped: rowRoot.rowClicked()
    }

    Behavior on color {
        ColorAnimation {
            duration: Constants.animFast
        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutQuart
        }

    }

}
