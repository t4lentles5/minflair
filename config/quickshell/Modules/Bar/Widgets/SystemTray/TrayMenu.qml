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

        let list = (children && children.values) ? children.values : children;
        if (!list || !list.length)
            return false;

        let prevIsSeparator = true;
        for (let i = idx - 1; i >= 0; i--) {
            let prev = list[i];
            if (prev && (prev.text !== "" || prev.isSeparator)) {
                if (!prev.isSeparator)
                    prevIsSeparator = false;

                break;
            }
        }
        if (prevIsSeparator)
            return true;

        let nextIsSeparator = true;
        for (let i = idx + 1; i < list.length; i++) {
            let next = list[i];
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

    Component.onCompleted: {
        resetToRoot();
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
        if (newLen <= 1) {
            contentSlideX = 0;
            contentOpacity = 1;
            prevStackLength = 1;
            if (scrollView && scrollView.contentItem)
                scrollView.contentItem.contentY = 0;

            return ;
        }
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

                delegate: TrayMenuItemDelegate {
                    menuRoot: menuRoot
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
            width: Constants.size2Xs

            contentItem: Rectangle {
                implicitWidth: Constants.size2Xs
                radius: width / 2
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
