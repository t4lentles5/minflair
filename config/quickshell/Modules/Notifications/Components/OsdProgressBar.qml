import QtQuick
import qs.Core
import qs.Core.Components

Rectangle {
    id: levelBarTrack

    property var notifData

    height: 6
    radius: 3
    color: Theme.bgSecondary
    visible: notifData && (notifData.summary === "Volume" || notifData.summary === "Brightness")

    Rectangle {
        id: levelBar

        height: parent.height
        radius: parent.radius
        color: Theme.accent
        width: {
            if (!notifData)
                return 0;

            let val = parseInt(notifData.body);
            if (isNaN(val))
                val = 0;

            return parent.width * (Math.min(100, Math.max(0, val)) / 100);
        }

        Behavior on width {
            NumberAnimation {
                duration: Constants.animFast
                easing.type: Easing.OutQuad
            }

        }

    }

}
