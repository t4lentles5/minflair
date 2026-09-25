import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Core
import qs.Core.Components
import qs.Core.Windows

TopPopup {
    id: root

    popupId: "music"
    animateHeight: true
    contentPadding: Constants.sizeLg

    MiniMusicWidget {
        id: content

        widget: root
    }

}
