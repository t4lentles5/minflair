import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

RowLayout {
    spacing: Constants.sizeMd

    ThemedText {
        text: "CPU " + Math.round(SystemStats.cpuUsage) + "%"
        color: Theme.muted
        font.letterSpacing: 1
    }

    Rectangle {
        width: Constants.sizeXl
        height: 2
        color: Theme.accent
        Layout.alignment: Qt.AlignVCenter
    }

    ThemedText {
        text: "RAM " + SystemStats.memUsed.toFixed(1) + "G"
        color: Theme.muted
        font.letterSpacing: 1
    }

    Rectangle {
        width: Constants.sizeXl
        height: 2
        color: Theme.accent
        Layout.alignment: Qt.AlignVCenter
    }

    ThemedText {
        text: "UP " + SystemStats.uptime
        color: Theme.muted
        font.letterSpacing: 1
    }

}
