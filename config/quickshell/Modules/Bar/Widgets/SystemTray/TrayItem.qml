import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Core
import qs.Core.Components
import qs.Core.Services

Rectangle {
    id: itemRoot

    property var trayItem: null
    property int itemIndex: -1
    property int customHeight: SettingsService.barWidgetHeight
    property int iconSize: Constants.sizeSm
    readonly property string widgetId: itemIndex >= 0 ? ("systemTray_" + itemIndex) : ""
    readonly property bool isActive: (widgetId !== "" && AppState.isWidgetOpen(widgetId)) || (AppState.activeTrayItem === trayItem && AppState.activeWidget.startsWith("systemTray_"))
    property bool isHovered: mouseArea.containsMouse
    property bool isPressed: mouseArea.pressed

    signal clicked(var mouse)

    implicitHeight: customHeight
    implicitWidth: customHeight
    width: implicitWidth
    height: implicitHeight
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.alignment: Qt.AlignVCenter
    color: isActive ? Theme.bgAccent : (isHovered ? Theme.bgSecondary : "transparent")
    radius: height / 2
    scale: isPressed ? 0.92 : (isHovered ? 1.05 : 1)

    SvgIcon {
        id: iconImage

        anchors.centerIn: parent
        iconSize: itemRoot.iconSize
        width: itemRoot.iconSize
        height: itemRoot.iconSize
        useOriginalColors: {
            if (!itemRoot.trayItem)
                return true;

            let identifiers = [];
            if (itemRoot.trayItem.iconName !== undefined && itemRoot.trayItem.iconName !== null)
                identifiers.push(itemRoot.trayItem.iconName.toString().toLowerCase());

            if (itemRoot.trayItem.id !== undefined && itemRoot.trayItem.id !== null)
                identifiers.push(itemRoot.trayItem.id.toString().toLowerCase());

            if (itemRoot.trayItem.title !== undefined && itemRoot.trayItem.title !== null)
                identifiers.push(itemRoot.trayItem.title.toString().toLowerCase());

            let identString = identifiers.join(" ");
            let colorIcons = ["youtube", "discord", "spotify", "slack", "telegram", "whatsapp", "skype", "steam", "obs", "vlc", "chrome", "firefox", "brave", "edge", "vesktop", "webcord"];
            for (let i = 0; i < colorIcons.length; i++) {
                if (identString.includes(colorIcons[i]))
                    return true;

            }
            for (let i = 0; i < identifiers.length; i++) {
                let n = identifiers[i];
                if (n.endsWith("-symbolic") || n.endsWith("-tray") || n.endsWith("-panel") || n.endsWith("-indicator"))
                    return false;

            }
            let monoIcons = ["blueman", "nm-device", "network-wireless", "network-wired", "audio-volume", "microphone-sensitivity", "battery", "kdeconnect", "cbatticon", "indicator-sound", "indicator-bluetooth", "network-manager", "nm-applet", "volume", "mic", "network", "bluetooth", "wifi", "sound"];
            for (let i = 0; i < monoIcons.length; i++) {
                if (identString.includes(monoIcons[i]))
                    return false;

            }
            if (itemRoot.trayItem.category === "SystemServices" || itemRoot.trayItem.category === "Hardware")
                return false;

            return false;
        }
        iconColor: itemRoot.isActive ? Theme.accent : Theme.fg
        flat: true
        icon: {
            if (!itemRoot.trayItem)
                return "";

            try {
                if (itemRoot.trayItem.iconName !== undefined && itemRoot.trayItem.iconName !== "")
                    return "image://icon/" + itemRoot.trayItem.iconName + "?fallback=false";

                let icon = itemRoot.trayItem.icon;
                if (!icon)
                    return "";

                let iconStr = icon.toString();
                if (iconStr.indexOf("://") !== -1 || iconStr.startsWith("/"))
                    return iconStr;

                return "image://icon/" + iconStr + "?fallback=false";
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

    MouseArea {
        id: mouseArea

        z: 10
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (!itemRoot.trayItem)
                return ;

            if (mouse.button === Qt.LeftButton && !itemRoot.trayItem.onlyMenu)
                itemRoot.trayItem.activate();

            itemRoot.clicked(mouse);
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
            easing.type: Easing.OutBack
        }

    }

}
