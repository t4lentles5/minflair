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
    property bool isDeletingAnim: false
    readonly property real baseHeight: isImg ? 108 : 44

    signal copyRequested(string itemId)
    signal deleteRequested(string fullLine)

    function startDeleteAnimation() {
        if (isDeletingAnim)
            return ;

        isDeletingAnim = true;
    }

    width: ListView.view ? ListView.view.width : 400
    height: isDeletingAnim ? 0 : baseHeight
    z: isDeletingAnim ? 1 : 2
    clip: true
    opacity: isDeletingAnim ? 0 : 1

    Item {
        id: delegateContent

        anchors.fill: parent
        x: delegateRoot.isDeletingAnim ? 36 : 0
        scale: delegateRoot.isDeletingAnim ? 0.94 : 1
        transformOrigin: Item.Center

        Rectangle {
            anchors.fill: parent
            radius: Constants.sizeLg
            color: Theme.bgSecondary
            visible: hoverHandler.hovered && !delegateRoot.isCurrent && !delegateRoot.isDeletingAnim
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
                enabled: !delegateRoot.isDeletingAnim
                onClicked: delegateRoot.startDeleteAnimation()
            }

        }

        HoverHandler {
            id: hoverHandler

            enabled: !delegateRoot.isDeletingAnim
        }

        TapHandler {
            enabled: !delegateRoot.isDeletingAnim
            onTapped: delegateRoot.copyRequested(delegateRoot.itemId)
        }

        Behavior on x {
            NumberAnimation {
                duration: Constants.animFast
                easing.type: Easing.OutCubic
            }

        }

        Behavior on scale {
            NumberAnimation {
                duration: Constants.animFast
                easing.type: Easing.OutCubic
            }

        }

    }

    Behavior on height {
        NumberAnimation {
            duration: Constants.animFast + 30
            easing.type: Easing.InOutCubic
            onRunningChanged: {
                if (!running && delegateRoot.isDeletingAnim)
                    delegateRoot.deleteRequested(delegateRoot.itemFullLine);

            }
        }

    }

    Behavior on opacity {
        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutQuad
        }

    }

}
