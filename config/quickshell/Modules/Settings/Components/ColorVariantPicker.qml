import QtQuick
import qs.Core
import qs.Core.Components
import qs.Core.Services

SettingRowTemplate {
    id: root

    property var variants: []
    property int currentIndex: 0

    signal activated(int index)

    Row {
        spacing: Constants.sizeXs

        Repeater {
            model: root.variants

            delegate: Item {
                id: swatchItem

                property bool isCurrent: root.currentIndex === index

                width: Constants.size3Xl - Constants.size2Xs
                height: width

                Rectangle {
                    id: swatch

                    anchors.fill: parent
                    radius: width / 2
                    color: modelData.accent || Theme.bg
                    border.width: swatchItem.isCurrent ? 2 : 1
                    border.color: swatchItem.isCurrent ? Theme.fg : Theme.border
                    scale: hoverHandler.hovered ? 1.08 : 1

                    Behavior on scale {
                        NumberAnimation {
                            duration: Constants.animFast
                            easing.type: Easing.OutBack
                        }

                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Constants.animFast
                        }

                    }

                }

                HoverHandler {
                    id: hoverHandler

                    cursorShape: Qt.PointingHandCursor
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!swatchItem.isCurrent)
                            root.activated(index);

                    }
                }

                ThemedTooltip {
                    text: {
                        let label = modelData.label || "Color";
                        if (modelData.accent)
                            return label + " · " + modelData.accent;
                        return label;
                    }
                    visible: hoverHandler.hovered
                }

            }

        }

    }

}
