import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
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
    readonly property bool hasActiveNotifications: notificationList.count > 0
    property alias blockContainer: blockContainer
    readonly property real blockX: blockContainer.x
    readonly property real blockY: blockContainer.y
    readonly property real blockWidth: blockContainer.width
    readonly property real blockHeight: blockContainer.height

    anchors.fill: parent

    Item {
        id: blockContainer

        readonly property int topPad: notificationList.count > 0 ? 16 : 0
        readonly property int bottomPad: notificationList.count > 0 ? 16 : 0
        readonly property int leftPad: notificationList.count > 0 ? 16 : 0
        readonly property int rightPad: notificationList.count > 0 ? 16 : 0
        readonly property real targetWidth: 380
        readonly property real targetHeight: notificationContainer.height + topPad + bottomPad

        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 48
        anchors.rightMargin: -8
        width: targetWidth
        height: targetHeight

        Column {
            id: notificationContainer

            x: blockContainer.leftPad
            y: blockContainer.topPad
            width: blockContainer.targetWidth - blockContainer.leftPad - blockContainer.rightPad
            spacing: Constants.sizeLg

            Repeater {
                id: notificationList

                model: notificationService ? notificationService.activeList : null

                delegate: Rectangle {
                    id: toastRect

                    property bool isRemoving: false
                    property bool expanded: false
                    property real slideOffset: (model.notifData.summary === "Volume" || model.notifData.summary === "Brightness" || model.notifData.summary === "Microphone") ? 0 : 400
                    property real dragOffset: 0
                    property string bodyVal: model.notifData.body

                    function closeNotification() {
                        if (isRemoving)
                            return ;

                        isRemoving = true;
                        animInDelayTimer.stop();
                        slideOffset = 400;
                        removalTimer.start();
                    }

                    onExpandedChanged: {
                        if (expanded)
                            model.notifData.lock("expanded");
                        else
                            model.notifData.unlock("expanded");
                    }
                    width: notificationContainer.width
                    height: content.implicitHeight + Constants.sizeSm * 2 + 4
                    color: Theme.bg
                    radius: Constants.sizeLg
                    border.color: "transparent"
                    border.width: 0
                    Component.onCompleted: {
                        if (model.notifData.summary !== "Volume" && model.notifData.summary !== "Brightness" && model.notifData.summary !== "Microphone") {
                            animInDelayTimer.interval = index * Constants.animNormal;
                            animInDelayTimer.start();
                        }
                    }

                    ThemedShadow {
                        z: -1
                        anchors.fill: parent
                        radius: toastRect.radius
                    }

                    Connections {
                        function onPopupChanged() {
                            if (!model.notifData.popup && !toastRect.isRemoving)
                                toastRect.closeNotification();

                        }

                        target: model.notifData
                    }

                    Timer {
                        id: animInDelayTimer

                        repeat: false
                        onTriggered: {
                            if (toastRect.isRemoving)
                                return ;

                            toastRect.slideOffset = 0;
                        }
                    }

                    Timer {
                        id: removalTimer

                        interval: Constants.animSlow
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

                    DragHandler {
                        id: dragHandler

                        target: null
                        yAxis.enabled: false
                        onTranslationChanged: {
                            if (translation.x > 0)
                                toastRect.dragOffset = translation.x;
                            else
                                toastRect.dragOffset = 0;
                        }
                        onActiveChanged: {
                            if (!active) {
                                if (toastRect.dragOffset > toastRect.width / 4)
                                    toastRect.closeNotification();
                                else
                                    snapBackAnim.restart();
                            }
                        }
                    }

                    NumberAnimation {
                        id: snapBackAnim

                        target: toastRect
                        property: "dragOffset"
                        to: 0
                        duration: Constants.animFast
                        easing.type: Easing.OutBack
                    }

                    NotificationDelegateContent {
                        id: content

                        anchors.fill: parent
                        notifData: model.notifData
                        expanded: toastRect.expanded
                        isFramed: false
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: Constants.animNormal
                        }

                    }

                    transform: Translate {
                        x: toastRect.slideOffset + toastRect.dragOffset
                    }

                    Behavior on height {
                        NumberAnimation {
                            duration: Constants.animSlow
                            easing.type: Easing.OutQuint
                        }

                    }

                    Behavior on slideOffset {
                        NumberAnimation {
                            duration: Constants.animSlow
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.2
                        }

                    }

                }

            }

            move: Transition {
                NumberAnimation {
                    properties: "x,y"
                    duration: Constants.animSlow
                    easing.type: Easing.OutQuint
                }

            }

            add: Transition {
                NumberAnimation {
                    properties: "opacity"
                    from: 0
                    to: 1
                    duration: Constants.animFast
                }

            }

        }

    }

}
