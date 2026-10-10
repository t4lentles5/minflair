import QtQuick
import QtQuick.Controls
import qs.Core

ToolTip {
    id: control

    delay: 300
    timeout: 3000

    contentItem: ThemedText {
        text: control.text
        color: Theme.fg
        customSize: Constants.sizeSm
    }

    background: Rectangle {
        color: Theme.bg
        radius: Constants.sizeXs
        border.width: 1
        border.color: Theme.border
    }

}
