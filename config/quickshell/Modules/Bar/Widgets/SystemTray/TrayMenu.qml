import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import qs.Core
import qs.Core.Components

ColumnLayout {
    id: menuRoot

    property var menuHandle: null
    property var menuStack: []
    property string title: "Menu"
    property var activeChildren: menuRoot.menuStack.length > 1 ? subOpener.children : rootOpener.children
    property int prevStackLength: 1
    property real contentSlideX: 0
    property real contentOpacity: 1

    signal backRequested()
    signal closeRequested()

    function resetToRoot() {
        if (menuHandle)
            menuRoot.menuStack = [menuHandle];
        else
            menuRoot.menuStack = [];
    }

    function isRedundantSeparator(idx) {
        let children = menuRoot.activeChildren;
        if (!children)
            return false;

        let prevIsSeparator = true;
        for (let i = idx - 1; i >= 0; i--) {
            let prev = children[i];
            if (prev && (prev.text !== "" || prev.isSeparator)) {
                if (!prev.isSeparator)
                    prevIsSeparator = false;

                break;
            }
        }
        if (prevIsSeparator)
            return true;

        let nextIsSeparator = true;
        for (let i = idx + 1; i < children.length; i++) {
            let next = children[i];
            if (next && (next.text !== "" || next.isSeparator)) {
                if (!next.isSeparator)
                    nextIsSeparator = false;

                break;
            }
        }
        if (nextIsSeparator)
            return true;

        return false;
    }

    spacing: Constants.sizeXs
    onMenuHandleChanged: {
        if (menuHandle)
            menuRoot.menuStack = [menuHandle];
        else
            menuRoot.menuStack = [];
    }
    onMenuStackChanged: {
        let newLen = menuStack.length;
        let goingDeeper = newLen > prevStackLength;
        prevStackLength = newLen;
        if (scrollView && scrollView.contentItem)
            scrollView.contentItem.contentY = 0;

        contentSlideX = goingDeeper ? 14 : -14;
        contentOpacity = 0.2;
        slideInAnim.restart();
    }

    ParallelAnimation {
        id: slideInAnim

        NumberAnimation {
            target: menuRoot
            property: "contentSlideX"
            to: 0
            duration: Constants.animNormal
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            target: menuRoot
            property: "contentOpacity"
            to: 1
            duration: Constants.animNormal
            easing.type: Easing.OutCubic
        }

    }

    QsMenuOpener {
        id: rootOpener

        menu: menuRoot.menuHandle
    }

    QsMenuOpener {
        id: subOpener

        menu: menuRoot.menuStack.length > 1 ? menuRoot.menuStack[menuRoot.menuStack.length - 1] : null
    }

    RowLayout {
        id: headerRow

        Layout.fillWidth: true
        spacing: Constants.sizeSm

        SvgIcon {
            id: backIcon

            icon: "chevron-left"
            iconColor: backHover.hovered ? Theme.accent : Theme.muted
            iconSize: Constants.sizeLg
            flat: true
            visible: menuRoot.menuStack.length > 1
            scale: backHover.hovered ? 1.15 : 1

            HoverHandler {
                id: backHover
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    let s = menuRoot.menuStack.slice();
                    s.pop();
                    menuRoot.menuStack = s;
                }
            }

            Behavior on scale {
                NumberAnimation {
                    duration: Constants.animFast
                    easing.type: Easing.OutQuad
                }

            }

            Behavior on iconColor {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

        ThemedText {
            text: menuRoot.menuStack.length > 1 ? (menuRoot.menuStack[menuRoot.menuStack.length - 1].text || "Back") : menuRoot.title
            customSize: Constants.sizeLg
            font.bold: true
            Layout.fillWidth: true
            elide: Text.ElideRight
        }

    }

    Divider {
    }

    ScrollView {
        id: scrollView

        Layout.fillWidth: true
        Layout.fillHeight: true
        implicitWidth: itemsColumn.implicitWidth
        implicitHeight: itemsColumn.implicitHeight
        clip: true
        contentWidth: availableWidth
        contentHeight: itemsColumn.implicitHeight
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: itemsColumn

            width: parent.width
            spacing: Constants.sizeXs
            opacity: menuRoot.contentOpacity

            Repeater {
                model: menuRoot.activeChildren

                delegate: Rectangle {
                    id: itemRoot

                    property bool isHovered: itemMouseArea.containsMouse
                    property bool isPressed: itemMouseArea.pressed

                    Layout.fillWidth: true
                    Layout.preferredHeight: (modelData && modelData.isSeparator) ? 1 : 32
                    implicitWidth: (modelData && modelData.isSeparator) ? 0 : (itemRow.implicitWidth + (Constants.sizeSm * 2))
                    implicitHeight: (modelData && modelData.isSeparator) ? 1 : 32
                    color: isPressed ? Qt.alpha(Theme.accent, 0.15) : (isHovered ? Theme.bgSecondary : "transparent")
                    radius: Constants.sizeMd
                    scale: isPressed ? 0.98 : (isHovered ? 1.01 : 1)
                    transformOrigin: Item.Center
                    visible: {
                        if (!modelData)
                            return false;

                        if (modelData.isSeparator)
                            return !menuRoot.isRedundantSeparator(index);

                        return modelData.text !== "";
                    }

                    RowLayout {
                        id: itemRow

                        anchors.fill: parent
                        anchors.leftMargin: Constants.sizeSm
                        anchors.rightMargin: Constants.sizeSm
                        spacing: Constants.sizeSm
                        visible: modelData && !modelData.isSeparator

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
                            text: modelData ? modelData.text : ""
                            color: (modelData && modelData.enabled) ? (itemRoot.isHovered ? Theme.fg : Theme.fg) : Theme.muted
                            elide: Text.ElideRight
                        }

                        SvgIcon {
                            icon: "check"
                            visible: modelData && modelData.checkState === Qt.Checked
                            iconColor: Theme.accent
                            iconSize: Constants.sizeXs
                            flat: true
                        }

                        SvgIcon {
                            id: subChevron

                            icon: "chevron-right"
                            visible: modelData && modelData.hasChildren
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
                        visible: modelData.isSeparator
                    }

                    MouseArea {
                        id: itemMouseArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        visible: !modelData.isSeparator && modelData.enabled
                        onClicked: {
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

            }

            transform: Translate {
                x: menuRoot.contentSlideX
            }

        }

        ScrollBar.vertical: ScrollBar {
            id: vbar

            active: true
            policy: ScrollBar.AsNeeded
            width: 4

            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: Theme.accent
                opacity: vbar.active ? 0.6 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Constants.animFast
                    }

                }

            }

        }

    }

}
