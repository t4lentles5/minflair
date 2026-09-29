import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Modules.Notifications.Components

Item {
    id: root

    property var notifData
    property bool expanded: false
    property bool isConvex: false

    implicitHeight: layout.implicitHeight

    RowLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Constants.sizeSm
        spacing: Constants.sizeSm

        NotificationIcon {
            id: iconContainer

            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 2
            Layout.preferredWidth: iconContainer.isUrgencyIcon ? Constants.sizeLg : Constants.size4Xl
            Layout.preferredHeight: iconContainer.isUrgencyIcon ? Constants.sizeLg : Constants.size4Xl
            notifData: root.notifData
            bgColor: root.isConvex ? "transparent" : Theme.bgSecondary
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: Constants.sizeMd

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Constants.sizeXs

                    ThemedText {
                        id: summaryText

                        Layout.fillWidth: true
                        text: root.notifData ? root.notifData.summary : ""
                        color: Theme.accent
                        customSize: Constants.sizeMd
                        font.weight: Font.Medium
                        maximumLineCount: root.expanded ? 100 : 1
                        elide: Text.ElideRight
                        wrapMode: Text.Wrap
                    }

                    SvgIconButton {
                        id: expandButton

                        Layout.alignment: Qt.AlignTop
                        iconSize: Constants.sizeSm
                        iconColor: Theme.fg
                        icon: root.expanded ? "chevron-up" : "chevron-down"
                        visible: bodyText.truncated || summaryText.truncated || root.expanded
                        onClicked: {
                            root.expanded = !root.expanded;
                        }
                    }

                }

                ThemedText {
                    id: bodyText

                    Layout.fillWidth: true
                    text: root.notifData ? root.notifData.body : ""
                    wrapMode: Text.Wrap
                    color: Theme.muted
                    maximumLineCount: root.expanded ? 100 : 2
                    elide: Text.ElideRight
                }

            }

            OsdProgressBar {
                Layout.fillWidth: true
                notifData: root.notifData
            }

        }

    }

    NotificationProgressBar {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottomMargin: 0
        anchors.leftMargin: Constants.sizeSm
        anchors.rightMargin: Constants.sizeSm
        notifData: root.notifData
    }

}
