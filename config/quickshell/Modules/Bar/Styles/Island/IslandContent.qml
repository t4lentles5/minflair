import QtQuick
import qs.Core
import qs.Modules.Bar.Components

Item {
    id: root

    property var notificationService: null
    property var widget: null
    property QtObject mainBar: null
    property bool animateTransitions: true

    implicitWidth: centerContent.implicitWidth
    implicitHeight: centerContent.implicitHeight

    BarCenterContent {
        id: centerContent

        anchors.centerIn: parent
        mainBar: root.mainBar
        notificationService: root.notificationService
        widget: root.widget
        animateTransitions: root.animateTransitions
    }

}
