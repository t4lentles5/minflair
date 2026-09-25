import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Components

Item {
    id: root

    property QtObject mainBar: null
    property bool animateTransitions: true
    readonly property bool shouldShow: (slot1 && slot1.shouldShow) || (slot2 && slot2.shouldShow)
    readonly property real targetWidth: {
        let w1 = (slot1 && slot1.shouldShow) ? slot1.targetWidth : 0;
        let w2 = (slot2 && slot2.shouldShow) ? slot2.targetWidth : 0;
        let hasDivider = (slot1 && slot1.shouldShow) && (slot2 && slot2.shouldShow);
        let spacing = hasDivider ? centerRow.spacing * 2 : (w1 > 0 && w2 > 0 ? centerRow.spacing : 0);
        let divW = hasDivider ? 1 : 0;
        return w1 + w2 + spacing + divW;
    }

    implicitWidth: shouldShow ? targetWidth : 0
    implicitHeight: SettingsService.barWidgetHeight
    width: Layout.preferredWidth >= 0 ? Layout.preferredWidth : implicitWidth
    height: Layout.preferredHeight >= 0 ? Layout.preferredHeight : implicitHeight
    visible: (opacity > 0.001) && (Layout.preferredWidth > 0.5)
    clip: state !== "visible"
    Layout.alignment: Qt.AlignVCenter
    Layout.preferredHeight: SettingsService.barWidgetHeight
    state: (shouldShow && targetWidth > 0.5) ? "visible" : "hidden"
    states: [
        State {
            name: "visible"

            PropertyChanges {
                target: root
                Layout.preferredWidth: root.targetWidth
                opacity: 1
            }

        },
        State {
            name: "hidden"

            PropertyChanges {
                target: root
                Layout.preferredWidth: 0
                opacity: 0
            }

        }
    ]
    transitions: [
        Transition {
            NumberAnimation {
                properties: "Layout.preferredWidth,opacity"
                duration: root.animateTransitions ? Constants.animNormal : 0
                easing.type: Easing.OutCubic
            }

        }
    ]

    RowLayout {
        id: centerRow

        anchors.centerIn: parent
        spacing: Constants.sizeXs

        BarWidgetLoader {
            id: slot1

            widgetType: SettingsService.barSlotC1
            mainBar: root.mainBar
            isCenterSlot: true
            animateTransitions: false
        }

        Divider {
            id: centerDivider

            vertical: true
            visible: (slot1 && slot1.shouldShow) && (slot2 && slot2.shouldShow)
            opacity: visible ? 1 : 0
            Layout.fillHeight: false
            Layout.preferredHeight: 16
            Layout.preferredWidth: visible ? 1 : 0
            Layout.alignment: Qt.AlignVCenter
        }

        BarWidgetLoader {
            id: slot2

            widgetType: SettingsService.barSlotC2
            mainBar: root.mainBar
            isCenterSlot: true
            animateTransitions: false
        }

    }

}
