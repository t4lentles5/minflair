import QtQuick
import qs.Modules.Music as MusicModule

Item {
    id: root

    required property QtObject centerWidget
    required property int flareW
    required property int contentPadding
    required property bool isClosing
    required property real openProgress
    required property bool isOpen
    required property string activeContentType
    readonly property alias item: musicLoader.item

    anchors.fill: parent
    anchors.leftMargin: root.flareW + root.contentPadding
    anchors.rightMargin: root.flareW + root.contentPadding
    anchors.topMargin: root.contentPadding
    anchors.bottomMargin: root.contentPadding
    clip: true
    opacity: root.isClosing ? Math.min(1, Math.max(0, (root.openProgress - 0.4) / 0.6)) : Math.min(1, Math.max(0, (root.openProgress - 0.2) / 0.8))
    scale: root.isClosing ? (0.94 + 0.06 * Math.min(1, Math.max(0, (root.openProgress - 0.3) / 0.7))) : (0.94 + 0.06 * Math.min(1, Math.max(0, (root.openProgress - 0.15) / 0.85)))
    visible: opacity > 0.001

    Loader {
        id: musicLoader

        anchors.fill: parent
        active: root.isOpen || root.openProgress > 0.001
        sourceComponent: root.activeContentType === "music" ? musicComp : null
    }

    Component {
        id: musicComp

        MusicModule.MiniMusicWidget {
            widget: root.centerWidget
        }

    }

}
