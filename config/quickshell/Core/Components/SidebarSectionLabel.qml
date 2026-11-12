import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components

// The uppercase title that groups a run of rows inside an app sidebar.
ThemedText {
    id: root

    // Sections that follow a group of rows need more space above them.
    property int sectionTopMargin: Constants.size2Xs

    customSize: Constants.sizeXs + 2
    font.weight: Font.Bold
    font.letterSpacing: 0.8
    color: Theme.muted
    Layout.leftMargin: Constants.sizeLg
    Layout.topMargin: root.sectionTopMargin
    Layout.bottomMargin: Constants.size2Xs
}
