import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Services

FocusScope {
    id: root

    property int customSize: Constants.sizeSm
    property alias text: searchInput.text
    property string placeholderText: "Search..."
    property int preferredHeight: Constants.size4Xl
    property bool showClearButton: true
    property bool autoFocus: true
    property alias textField: searchInput
    property color backgroundColor: Theme.bgSecondary
    property int backgroundRadius: Constants.sizeMd

    signal searchRequested(string text)
    signal accepted()

    Keys.forwardTo: [searchInput]
    Layout.fillWidth: true
    Layout.preferredHeight: preferredHeight

    Rectangle {
        id: bgRect

        anchors.fill: parent
        color: root.backgroundColor
        radius: root.backgroundRadius

        Behavior on color {
            ColorAnimation {
                duration: Constants.animFast
            }

        }

    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Constants.sizeLg
        anchors.rightMargin: Constants.sizeLg

        SvgIcon {
            icon: "search"
            iconColor: Theme.muted
            iconSize: Constants.sizeLg
            flat: true
        }

        TextField {
            id: searchInput

            focus: root.autoFocus
            Layout.fillWidth: true
            placeholderText: root.placeholderText
            placeholderTextColor: Theme.muted
            font.family: Constants.fontFamily
            font.pixelSize: Math.round(root.customSize * SettingsService.fontScale)
            color: Theme.fg
            selectByMouse: true
            background: null
            onTextChanged: root.searchRequested(text)
            onAccepted: root.accepted()
        }

        SvgIconButton {
            id: clearButton

            visible: root.showClearButton && searchInput.text !== ""
            icon: "x"
            iconColor: Theme.muted
            iconSize: Constants.sizeMd
            flat: true
            onClicked: {
                searchInput.text = "";
                searchInput.forceActiveFocus();
            }
        }

    }

}
