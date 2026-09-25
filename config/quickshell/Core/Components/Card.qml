import QtQuick
import qs.Core

Rectangle {
    id: root

    property color backgroundColor: Theme.bgSecondary
    property int contentPadding: Constants.sizeLg
    property int cardRadius: Constants.sizeLg
    property bool useBorder: false
    default property alias content: innerContainer.data

    signal clicked(var mouse)

    border.width: root.useBorder ? 1 : 0
    border.color: root.useBorder ? Theme.border : "transparent"
    implicitWidth: {
        let maxW = 0;
        for (let i = 0; i < innerContainer.children.length; i++) {
            let child = innerContainer.children[i];
            if (child.visible && child.implicitWidth > maxW)
                maxW = child.implicitWidth;

        }
        return maxW + contentPadding * 2;
    }
    implicitHeight: {
        let maxH = 0;
        for (let i = 0; i < innerContainer.children.length; i++) {
            let child = innerContainer.children[i];
            if (child.visible && child.implicitHeight > maxH)
                maxH = child.implicitHeight;

        }
        return maxH + contentPadding * 2;
    }
    color: root.backgroundColor
    radius: root.cardRadius

    Item {
        id: innerContainer

        anchors.fill: parent
        anchors.margins: root.contentPadding
    }

    Behavior on color {
        ColorAnimation {
            duration: Constants.animFast
        }

    }

}
