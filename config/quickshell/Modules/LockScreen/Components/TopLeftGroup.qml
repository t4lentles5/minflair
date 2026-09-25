import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

RowLayout {
    spacing: Constants.sizeLg

    Rectangle {
        width: Constants.sizeXs
        height: Constants.sizeXs
        color: Theme.accent
        Layout.alignment: Qt.AlignVCenter
    }

    ThemedText {
        text: "LOCKED"
        font.letterSpacing: 2
        color: Theme.muted
    }

}
