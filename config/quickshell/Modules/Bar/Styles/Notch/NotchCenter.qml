import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Bar.Components

Item {
    id: root

    property bool enableShadow: true
    property var notificationService: null
    property var mainPanelWidget: null
    property real notchTopBezel: 0
    property real extraPadding: 16
    property bool centerOnly: false
    property QtObject mainBar: null

    function syncDimensions() {
        if (width > 0)
            AppState.barNotchWidth = width;

        if (height > 0)
            AppState.barNotchHeight = height;

    }

    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    height: parent.height
    implicitWidth: {
        let contentW = root.centerOnly ? (centerSlot.implicitWidth > 0 ? centerSlot.implicitWidth : centerSlot.targetWidth) : centerLayout.implicitWidth;
        let w = Math.round(contentW + notchBg.flareWidth * 2 + root.extraPadding);
        return (w % 2 === 0) ? w : (w + 1);
    }
    width: implicitWidth
    onWidthChanged: syncDimensions()
    onHeightChanged: syncDimensions()
    Component.onCompleted: syncDimensions()

    SectionNotchShape {
        id: notchBg

        anchors.fill: parent
        mode: "center"
        flareWidth: 18
        flareHeight: 16
        bottomRadius: 16
        topBezel: root.notchTopBezel
        color: Theme.bg
        enableShadow: root.enableShadow
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (mouse.button === Qt.RightButton && !root.centerOnly)
                SettingsService.barNotchExpanded = !SettingsService.barNotchExpanded;

        }
    }

    BarCenterContent {
        id: centerLayout

        visible: !root.centerOnly
        anchors.centerIn: parent
        mainBar: root.mainBar
        notificationService: root.notificationService
        widget: root.mainPanelWidget
    }

    BarCenterSection {
        id: centerSlot

        visible: root.centerOnly
        anchors.centerIn: parent
        mainBar: root
    }

    Behavior on width {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: Constants.animNormal
            easing.type: Easing.OutQuint
        }

    }

}
