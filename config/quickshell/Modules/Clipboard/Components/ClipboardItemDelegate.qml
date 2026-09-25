import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Item {
    id: delegateRoot

    property string itemText: ""
    property string itemId: ""
    property string itemFullLine: ""
    property bool isImg: false
    property bool isCurrent: false

    signal copyRequested(string itemId)
    signal deleteRequested(string fullLine)

    width: ListView.view ? ListView.view.width : 400
    height: isImg ? 108 : 44
    z: 2

    Rectangle {
        anchors.fill: parent
        radius: Constants.sizeLg
        color: Theme.bgSecondary
        visible: hoverHandler.hovered && !delegateRoot.isCurrent
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Constants.sizeLg
        anchors.rightMargin: Constants.sizeLg
        spacing: Constants.sizeLg

        ThemedText {
            text: delegateRoot.itemText
            color: delegateRoot.isCurrent ? Theme.accent : Theme.fg
            font.bold: delegateRoot.isCurrent
            customSize: Constants.sizeMd
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            elide: Text.ElideRight
            visible: !delegateRoot.isImg
            scale: delegateRoot.isCurrent ? 1.02 : 1
            transformOrigin: Item.Left

            Behavior on color {
                ColorAnimation {
                    duration: Constants.animNormal
                }

            }

            Behavior on scale {
                NumberAnimation {
                    duration: Constants.animNormal
                    easing.type: Easing.OutQuint
                }

            }

        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 88
            Layout.alignment: Qt.AlignVCenter
            visible: delegateRoot.isImg

            Image {
                id: clipThumb

                anchors.fill: parent
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignLeft
                source: delegateRoot.isImg && delegateRoot.itemId ? ("file:///tmp/quickshell-clipboard/" + delegateRoot.itemId + ".png") : ""
                asynchronous: true
                cache: true
                smooth: true
                mipmap: true
            }

        }

        SvgIconButton {
            icon: "trash"
            iconColor: Theme.muted
            iconSize: Constants.sizeMd
            flat: true
            Layout.alignment: Qt.AlignVCenter
            onClicked: delegateRoot.deleteRequested(delegateRoot.itemFullLine)
        }

    }

    HoverHandler {
        id: hoverHandler
    }

    TapHandler {
        onTapped: delegateRoot.copyRequested(delegateRoot.itemId)
    }

}
