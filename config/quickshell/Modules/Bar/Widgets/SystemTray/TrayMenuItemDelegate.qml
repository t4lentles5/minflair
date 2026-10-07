import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

Rectangle {
    id: itemRoot

    required property var menuRoot
    required property var modelData
    required property int index
    property bool isHovered: itemMouseArea.containsMouse
    property bool isPressed: itemMouseArea.pressed

    Layout.fillWidth: true
    Layout.preferredHeight: (modelData && modelData.isSeparator) ? 1 : Constants.size3Xl
    implicitWidth: (modelData && modelData.isSeparator) ? 0 : (itemRow.implicitWidth + (Constants.sizeSm * 2))
    implicitHeight: (modelData && modelData.isSeparator) ? 1 : Constants.size3Xl
    color: isPressed ? Theme.bgAccent : (isHovered ? Theme.bgSecondary : "transparent")
    radius: Constants.sizeMd
    scale: isPressed ? 0.98 : (isHovered ? 1.01 : 1)
    transformOrigin: Item.Center
    visible: {
        if (!modelData)
            return false;

        if (modelData.isSeparator)
            return menuRoot ? !menuRoot.isRedundantSeparator(index) : false;

        return Boolean(modelData.text && modelData.text !== "");
    }

    RowLayout {
        id: itemRow

        anchors.fill: parent
        anchors.leftMargin: Constants.sizeSm
        anchors.rightMargin: Constants.sizeSm
        spacing: Constants.sizeSm
        visible: Boolean(modelData && !modelData.isSeparator)

        Item {
            Layout.preferredWidth: trayIcon.status === Image.Ready ? Constants.sizeLg : 0
            Layout.preferredHeight: Constants.sizeLg
            Layout.alignment: Qt.AlignVCenter
            visible: trayIcon.status === Image.Ready

            SvgIcon {
                id: trayIcon

                anchors.centerIn: parent
                iconSize: Constants.sizeLg
                flat: true
                iconColor: itemRoot.isHovered ? Theme.accent : Theme.fg
                icon: {
                    if (!modelData || !modelData.icon)
                        return "";

                    try {
                        let ic = modelData.icon;
                        let icStr = ic.toString().trim();
                        if (icStr === "")
                            return "";

                        if (icStr.indexOf("://") !== -1 || icStr.startsWith("/"))
                            return icStr;

                        return "image://icon/" + icStr + "?fallback=false";
                    } catch (e) {
                        return "";
                    }
                }

                Behavior on iconColor {
                    ColorAnimation {
                        duration: Constants.animFast
                    }

                }

            }

        }

        ThemedText {
            Layout.fillWidth: true
            text: (modelData && modelData.text) ? modelData.text : ""
            color: (modelData && modelData.enabled) ? Theme.fg : Theme.muted
            elide: Text.ElideRight
        }

        SvgIcon {
            icon: "check"
            visible: Boolean(modelData && modelData.checkState === Qt.Checked)
            iconColor: Theme.accent
            iconSize: Constants.sizeXs
            flat: true
        }

        SvgIcon {
            id: subChevron

            icon: "chevron-right"
            visible: Boolean(modelData && modelData.hasChildren)
            iconColor: itemRoot.isHovered ? Theme.fg : Theme.muted
            iconSize: Constants.sizeXs
            flat: true

            transform: Translate {
                x: itemRoot.isHovered ? 2.5 : 0

                Behavior on x {
                    NumberAnimation {
                        duration: Constants.animFast
                        easing.type: Easing.OutQuad
                    }

                }

            }

            Behavior on iconColor {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

    }

    Rectangle {
        anchors.fill: parent
        color: Theme.border
        visible: Boolean(modelData && modelData.isSeparator)
    }

    MouseArea {
        id: itemMouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        visible: Boolean(modelData && !modelData.isSeparator && modelData.enabled)
        onClicked: {
            if (!modelData)
                return ;

            if (modelData.hasChildren) {
                let s = menuRoot.menuStack.slice();
                s.push(modelData);
                menuRoot.menuStack = s;
            } else {
                if (typeof modelData.triggered === "function")
                    modelData.triggered();

                menuRoot.closeRequested();
            }
        }
    }

    Behavior on color {
        ColorAnimation {
            duration: Constants.animFast
        }

    }

    Behavior on scale {
        NumberAnimation {
            duration: Constants.animFast
            easing.type: Easing.OutQuad
        }

    }

}
