import QtQuick
import qs.Core
import qs.Core.Components

Rectangle {
    id: progressTrack

    property var notifData

    height: 2
    radius: height / 2
    color: Theme.bgSecondary
    visible: notifData && notifData.summary !== "Volume" && notifData.summary !== "Brightness" && notifData.summary !== "Microphone"

    Rectangle {
        id: progressBar

        height: parent.height
        radius: height / 2
        color: Theme.accent
        width: notifData ? parent.width * Math.max(0, Math.min(1, notifData.progress)) : 0
    }

}
