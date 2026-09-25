import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Services

Card {
    id: root

    property string username: GithubService.username
    property var contributionData: GithubService.contributionData
    readonly property int cellCount: root.contributionData.length > 0 ? root.contributionData.length : 364
    readonly property int columnCount: Math.max(1, Math.ceil(cellCount / 7))
    readonly property real cellSize: 11
    readonly property real cellSpacing: 3
    readonly property real gridContentWidth: columnCount * cellSize + Math.max(0, columnCount - 1) * cellSpacing
    readonly property real gridContentHeight: 7 * cellSize + 6 * cellSpacing

    function scrollToLatest() {
        if (flickable && flickable.contentWidth > flickable.width)
            flickable.contentX = flickable.contentWidth - flickable.width;

    }

    clip: true
    contentPadding: Constants.sizeMd
    implicitWidth: 420
    implicitHeight: Math.round(headerRow.implicitHeight + mainCol.spacing + gridContentHeight + root.contentPadding * 2)
    onContributionDataChanged: Qt.callLater(scrollToLatest)

    ColumnLayout {
        id: mainCol

        anchors.fill: parent
        spacing: Constants.sizeSm

        RowLayout {
            id: headerRow

            Layout.fillWidth: true

            SvgIcon {
                icon: "github"
                iconSize: Constants.sizeLg
                iconColor: Theme.fg
                flat: true
            }

            ThemedText {
                text: "Contributions"
                font.bold: true
                color: Theme.fg
                customSize: Constants.sizeMd
            }

            Item {
                Layout.fillWidth: true
            }

            ThemedText {
                text: root.username
                color: Theme.muted
                customSize: Constants.sizeXs + 2
                visible: root.username !== ""
            }

        }

        Item {
            id: scrollContainer

            Layout.fillWidth: true
            implicitHeight: root.gridContentHeight
            clip: true

            Flickable {
                id: flickable

                anchors.fill: parent
                contentWidth: grid.implicitWidth
                contentHeight: root.gridContentHeight
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.HorizontalFlick
                clip: true
                interactive: true
                onWidthChanged: root.scrollToLatest()

                WheelHandler {
                    onWheel: (event) => {
                        let delta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x;
                        flickable.contentX = Math.max(0, Math.min(flickable.contentWidth - flickable.width, flickable.contentX - delta));
                    }
                }

                GridLayout {
                    id: grid

                    rows: 7
                    flow: GridLayout.TopToBottom
                    columnSpacing: root.cellSpacing
                    rowSpacing: root.cellSpacing
                    implicitWidth: root.gridContentWidth
                    implicitHeight: root.gridContentHeight

                    Repeater {
                        model: root.contributionData.length > 0 ? root.contributionData : 364

                        Rectangle {
                            property int level: typeof modelData === "number" ? 0 : (modelData.level !== undefined ? modelData.level : 0)

                            width: root.cellSize
                            height: root.cellSize
                            implicitWidth: root.cellSize
                            implicitHeight: root.cellSize
                            radius: 2
                            color: {
                                if (root.contributionData.length === 0)
                                    return Theme.bgTertiary;

                                switch (level) {
                                case 0:
                                    return Theme.bgTertiary;
                                case 1:
                                    return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.35);
                                case 2:
                                    return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.6);
                                case 3:
                                    return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.85);
                                case 4:
                                    return Theme.accent;
                                default:
                                    return Theme.bgTertiary;
                                }
                            }
                        }

                    }

                }

            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 20
                visible: flickable.contentX > 4

                gradient: Gradient {
                    orientation: Gradient.Horizontal

                    GradientStop {
                        position: 0
                        color: Theme.bgSecondary
                    }

                    GradientStop {
                        position: 1
                        color: "transparent"
                    }

                }

            }

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 20
                visible: flickable.contentX < (flickable.contentWidth - flickable.width - 4)

                gradient: Gradient {
                    orientation: Gradient.Horizontal

                    GradientStop {
                        position: 0
                        color: "transparent"
                    }

                    GradientStop {
                        position: 1
                        color: Theme.bgSecondary
                    }

                }

            }

        }

    }

}
