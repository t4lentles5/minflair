import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Core
import qs.Core.Components

Item {
    id: itemRoot

    property var trayItem: null
    property int iconSize: Constants.sizeSm

    signal clicked(var mouse)

    implicitWidth: iconImage.implicitWidth
    implicitHeight: iconImage.implicitHeight

    SvgIcon {
        id: iconImage

        anchors.centerIn: parent
        iconSize: itemRoot.iconSize
        width: implicitWidth
        height: implicitHeight
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
        iconColor: Theme.fg
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
        scale: mouseArea.pressed ? 0.9 : (mouseArea.containsMouse ? 1.1 : 1)

        Behavior on scale {
            NumberAnimation {
                duration: Constants.animFast
                easing.type: Easing.OutQuad
            }

        }

    }

    MouseArea {
        id: mouseArea

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => {
            if (!itemRoot.trayItem)
                return ;

            if (mouse.button === Qt.LeftButton)
                itemRoot.trayItem.activate();

            itemRoot.clicked(mouse);
        }
    }

}
