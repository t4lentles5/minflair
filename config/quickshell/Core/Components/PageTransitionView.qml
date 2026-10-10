import QtQuick
import qs.Core

Rectangle {
    id: root

    property int activeIndex: 0
    property int lastIndex: activeIndex
    property var order: []
    property int animOff: 0
    property var updateCallback: null
    default property alias content: contentContainer.data

    signal contentNeedsUpdate(int newIndex)

    function triggerTransition(direction, callback) {
        if (switchAnim.running) {
            switchAnim.stop();
            contentContainer.opacity = 0;
        }
        root.animOff = 20 * direction;
        root.updateCallback = callback;
        switchAnim.start();
    }

    color: "transparent"
    onActiveIndexChanged: {
        if (activeIndex === lastIndex)
            return ;

        let dir = 1;
        if (order && order.length > 0) {
            let prevPos = order.indexOf(lastIndex);
            let nextPos = order.indexOf(activeIndex);
            if (prevPos !== -1 && nextPos !== -1)
                dir = nextPos > prevPos ? 1 : -1;
            else
                dir = activeIndex > lastIndex ? 1 : -1;
        } else {
            dir = activeIndex > lastIndex ? 1 : -1;
        }
        if (switchAnim.running) {
            switchAnim.stop();
            contentContainer.opacity = 0;
        }
        root.animOff = 20 * dir;
        root.lastIndex = root.activeIndex;
        switchAnim.start();
    }

    SequentialAnimation {
        id: switchAnim

        NumberAnimation {
            target: contentContainer
            property: "opacity"
            to: 0
            duration: Constants.animFast
            easing.type: Easing.OutQuad
        }

        ScriptAction {
            script: {
                if (root.updateCallback) {
                    root.updateCallback();
                    root.updateCallback = null;
                } else {
                    root.contentNeedsUpdate(root.activeIndex);
                }
            }
        }

        PropertyAction {
            target: contentTranslate
            property: "y"
            value: root.animOff
        }

        ParallelAnimation {
            NumberAnimation {
                target: contentContainer
                property: "opacity"
                from: 0
                to: 1
                duration: Constants.animNormal
                easing.type: Easing.OutQuad
            }

            NumberAnimation {
                target: contentTranslate
                property: "y"
                to: 0
                duration: Constants.animNormal
                easing.type: Easing.OutQuint
            }

        }

    }

    Item {
        id: contentContainer

        anchors.fill: parent
        clip: true

        transform: Translate {
            id: contentTranslate

            y: 0
        }

    }

}
