import Qt5Compat.GraphicalEffects
import QtQuick
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: delegateRoot

    property var selectorRoot: null
    property var targetView: null
    required property int index
    required property string name
    required property string filePath
    required property string rawPath
    readonly property bool isCurrent: ListView.isCurrentItem || (targetView && targetView.currentIndex === index)
    readonly property bool isApplied: {
        let cur = WallpaperManager.currentWallpaper ? WallpaperManager.currentWallpaper.trim() : "";
        let curPath = WallpaperManager.currentWallpaperPath ? WallpaperManager.currentWallpaperPath.trim() : "";
        return (cur !== "" && name === cur) || (curPath !== "" && rawPath === curPath);
    }

    width: selectorRoot ? selectorRoot.cardItemWidth : 0
    height: selectorRoot ? selectorRoot.cardItemHeight : 0
    z: isCurrent ? 5 : (hoverHandler.hovered ? 3 : 1)

    Rectangle {
        id: cardBg

        anchors.fill: parent
        radius: Constants.sizeLg
        color: Theme.bgSecondary

        Item {
            id: imageMaskContainer

            anchors.fill: parent
            anchors.margins: cardBorder.border.width
            layer.enabled: true

            Image {
                id: thumbImg

                anchors.fill: parent
                source: delegateRoot.filePath
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                sourceSize: Qt.size(450, 270)
                mipmap: true
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Constants.animNormal
                        easing.type: Easing.OutCubic
                    }

                }

            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * 0.55

                gradient: Gradient {
                    GradientStop {
                        position: 0
                        color: "transparent"
                    }

                    GradientStop {
                        position: 0.35
                        color: Qt.rgba(0, 0, 0, 0.35)
                    }

                    GradientStop {
                        position: 1
                        color: Qt.rgba(0, 0, 0, 0.85)
                    }

                }

            }

            layer.effect: OpacityMask {

                maskSource: Rectangle {
                    width: imageMaskContainer.width
                    height: imageMaskContainer.height
                    radius: Math.max(0, Constants.sizeLg - cardBorder.border.width)
                }

            }

        }

        ThemedText {
            id: nameText

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Constants.sizeSm
            text: delegateRoot.name
            customSize: Constants.sizeSm
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            color: isCurrent ? Theme.accent : "#ffffff"
            font.bold: isCurrent
            z: 11

            Behavior on color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

        Rectangle {
            id: cardBorder

            anchors.fill: parent
            radius: Constants.sizeLg
            color: "transparent"
            border.color: isCurrent ? Theme.accent : (hoverHandler.hovered ? Qt.rgba(Theme.fg.r, Theme.fg.g, Theme.fg.b, 0.35) : Theme.border)
            border.width: isCurrent ? 2 : 1
            z: 10

            Behavior on border.color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

            Behavior on border.width {
                NumberAnimation {
                    duration: Constants.animFast
                }

            }

        }

    }

    HoverHandler {
        id: hoverHandler

        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: {
            if (delegateRoot.targetView)
                delegateRoot.targetView.currentIndex = delegateRoot.index;

            if (delegateRoot.selectorRoot) {
                delegateRoot.selectorRoot.ensureVisible(delegateRoot.index);
                delegateRoot.selectorRoot.setWallpaper(delegateRoot.rawPath);
            }
        }
    }

}
