import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: root

    required property var notificationService
    readonly property int activeCount: notificationService && notificationService.activeList ? notificationService.activeList.count : 0
    readonly property bool hasActiveNotifications: activeCount > 0
    property bool isClosingLast: false
    readonly property bool isOpen: hasActiveNotifications && !isClosingLast
    property alias blockContainer: blockContainer
    readonly property real blockX: blockContainer.x
    readonly property real blockY: blockContainer.y
    readonly property real blockWidth: blockContainer.width
    readonly property real blockHeight: blockContainer.height
    property real diagProgress: root.isOpen ? 1 : 0
    property real lastHeight: 120
    readonly property int animationDuration: HyprlandService.enableAnimations ? Constants.animSlow : 0
    readonly property int closeDuration: HyprlandService.enableAnimations ? Constants.animNormal : 0

    anchors.fill: parent
    onActiveCountChanged: {
        if (activeCount === 0)
            isClosingLast = false;

    }

    Timer {
        id: lastCloseTimer

        interval: root.closeDuration + 50
        repeat: false
        onTriggered: {
            if (root.isClosingLast && notificationService) {
                while (notificationService.activeList && notificationService.activeList.count > 0) {
                    let first = notificationService.activeList.get(0);
                    if (first && first.notifData)
                        notificationService.dismissNotification(first.notifData.notificationId);
                    else if (first && first.id)
                        notificationService.dismissNotification(first.id);
                    else
                        notificationService.activeList.remove(0);
                }
                root.isClosingLast = false;
            }
        }
    }

    Item {
        id: blockContainer

        readonly property int cornerRad: Constants.size2Xl
        readonly property int topPad: Constants.sizeLg
        readonly property int bottomPad: cornerRad + Constants.sizeLg
        readonly property int leftPad: cornerRad + Constants.sizeLg
        readonly property int rightPad: Constants.sizeLg
        readonly property real targetWidth: 380
        readonly property real naturalHeight: notificationContainer.implicitHeight + topPad + bottomPad
        readonly property real targetHeight: root.isOpen ? Math.max(naturalHeight, 80) : root.lastHeight

        onNaturalHeightChanged: {
            if (root.isOpen && naturalHeight > 80)
                root.lastHeight = naturalHeight;

        }
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 48
        anchors.rightMargin: 8
        width: Math.max(0.01, targetWidth * Math.max(0, root.diagProgress))
        height: Math.max(0.01, targetHeight * Math.max(0, root.diagProgress))
        clip: true

        FramedShape {
            anchors.fill: parent
            color: Theme.bg
            cornerRadius: Constants.size2Xl
            borderWidth: 0
            positionAtRight: true
            isFramed: true
            visible: blockContainer.width > 1
            enableShadow: false
        }

        Column {
            id: notificationContainer

            x: blockContainer.width - blockContainer.targetWidth + blockContainer.leftPad
            y: blockContainer.topPad
            width: blockContainer.targetWidth - blockContainer.leftPad - blockContainer.rightPad
            spacing: Constants.sizeXs

            Repeater {
                id: notificationList

                model: notificationService ? notificationService.activeList : null

                delegate: Rectangle {
                    id: toastRect

                    property bool isRemoving: false
                    property bool expanded: false
                    property string bodyVal: model.notifData.body

                    function closeNotification() {
                        if (isRemoving)
                            return ;

                        isRemoving = true;
                        if (root.activeCount <= 1) {
                            root.isClosingLast = true;
                            lastCloseTimer.start();
                        } else {
                            removalTimer.start();
                        }
                    }

                    onExpandedChanged: {
                        if (expanded)
                            model.notifData.lock("expanded");
                        else
                            model.notifData.unlock("expanded");
                    }
                    width: notificationContainer.width
                    height: (isRemoving && root.activeCount > 1) ? 0 : (content.implicitHeight + Constants.sizeSm * 2 + 4)
                    opacity: (isRemoving && root.activeCount > 1) ? 0 : 1
                    color: mainMouseArea.containsMouse ? Theme.bgTertiary : Theme.bgSecondary
                    radius: Constants.sizeSm
                    border.width: 0
                    clip: true

                    Connections {
                        function onPopupChanged() {
                            if (!model.notifData.popup && !toastRect.isRemoving)
                                toastRect.closeNotification();

                        }

                        target: model.notifData
                    }

                    Timer {
                        id: removalTimer

                        interval: Constants.animNormal
                        repeat: false
                        onTriggered: {
                            if (model.notifData.closed || model.notifData.isTransient) {
                                if (notificationService)
                                    notificationService.dismissNotification(model.notifData.notificationId);

                            } else {
                                if (notificationService) {
                                    for (var i = 0; i < notificationService.activeList.count; i++) {
                                        if (notificationService.activeList.get(i).id == model.notifData.notificationId) {
                                            notificationService.activeList.remove(i);
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: mainMouseArea

                        onEntered: model.notifData.lock(toastRect)
                        onExited: model.notifData.unlock(toastRect)
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            toastRect.closeNotification();
                        }
                    }

                    NotificationDelegateContent {
                        id: content

                        anchors.fill: parent
                        notifData: model.notifData
                        expanded: toastRect.expanded
                        isFramed: true
                    }

                    Behavior on color {
                        ColorAnimation {
                            duration: Constants.animFast
                        }

                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: Constants.animNormal
                            easing.type: Easing.OutCubic
                        }

                    }

                    Behavior on opacity {
                        NumberAnimation {
                            duration: Constants.animFast
                            easing.type: Easing.OutQuad
                        }

                    }

                }

            }

            move: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: Constants.animNormal
                    easing.type: Easing.OutCubic
                }

            }

            add: Transition {
                NumberAnimation {
                    properties: "opacity"
                    from: 0
                    to: 1
                    duration: Constants.animNormal
                    easing.type: Easing.OutCubic
                }

            }

        }

        Behavior on height {
            enabled: HyprlandService.enableAnimations && root.isOpen && root.diagProgress === 1

            NumberAnimation {
                duration: Constants.animNormal
                easing.type: Easing.OutExpo
            }

        }

    }

    Behavior on diagProgress {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            id: diagAnim

            duration: root.isOpen ? root.animationDuration : root.closeDuration
            easing.type: root.isOpen ? Easing.OutCubic : Easing.InCubic
        }

    }

}
