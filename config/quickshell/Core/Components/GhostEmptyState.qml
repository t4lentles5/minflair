import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

ColumnLayout {
    id: root

    property string text: "Nothing here..."
    property bool isAnimating: visible
    property string icon: "ghost"
    property string iconColor: Theme.muted

    spacing: Constants.sizeMd

    SvgIcon {
        id: ghostIcon

        icon: root.icon
        iconColor: root.iconColor
        iconSize: 72
        flat: true
        Layout.alignment: Qt.AlignHCenter

        SequentialAnimation {
            running: root.isAnimating
            loops: Animation.Infinite

            NumberAnimation {
                target: ghostTranslate
                property: "y"
                from: 0
                to: -10
                duration: 1500
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                target: ghostTranslate
                property: "y"
                from: -10
                to: 0
                duration: 1500
                easing.type: Easing.InOutSine
            }

        }

        transform: Translate {
            id: ghostTranslate

            y: 0
        }

    }

    ThemedText {
        id: msgText

        text: root.text
        color: Theme.muted
        customSize: Constants.sizeMd
        Layout.alignment: Qt.AlignHCenter

        SequentialAnimation {
            running: root.isAnimating
            loops: Animation.Infinite

            PauseAnimation {
                duration: 150
            }

            NumberAnimation {
                target: textTranslate
                property: "y"
                from: 0
                to: -8
                duration: 1500
                easing.type: Easing.InOutSine
            }

            NumberAnimation {
                target: textTranslate
                property: "y"
                from: -8
                to: 0
                duration: 1500
                easing.type: Easing.InOutSine
            }

        }

        transform: Translate {
            id: textTranslate

            y: 0
        }

    }

}
