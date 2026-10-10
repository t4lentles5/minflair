import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar
import qs.Modules.Bar.Components

Rectangle {
    id: root

    property var mainPanelWidget: null
    property var notificationService: null
    property QtObject mainBar: null
    property real sidePadding: Constants.size3Xl
    property real contentMargin: Constants.sizeLg
    readonly property real targetWidth: contentRow.implicitWidth + root.sidePadding

    height: parent ? parent.height : implicitHeight
    width: targetWidth
    color: "transparent"

    RowLayout {
        id: contentRow

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: root.contentMargin
        spacing: Constants.sizeXs

        MinflairButton {
            id: minflairBtn

            Layout.alignment: Qt.AlignVCenter
        }

        Workspaces {
            id: workspacesWidget

            Layout.alignment: Qt.AlignVCenter
            visible: true
        }

    }

}
