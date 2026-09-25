import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Services

FocusScope {
    id: root

    property int customSize: Constants.sizeSm
    property alias text: textInput.text
    property string label: ""
    property string placeholderText: ""
    property bool isPassword: false
    property bool revealPassword: false
    property bool showSubmitHint: true
    property alias textField: textInput
    property string _savedText: ""

    signal editingFinished()

    Layout.fillWidth: true
    Layout.preferredHeight: (label !== "" ? 20 + Constants.sizeXs : 0) + 36

    ColumnLayout {
        anchors.fill: parent
        spacing: Constants.sizeXs

        ThemedText {
            text: root.label
            font.bold: true
            color: Theme.fg
            visible: root.label !== ""
            customSize: root.customSize
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            color: Theme.bg
            radius: Constants.sizeSm
            border.color: textInput.activeFocus ? Theme.accent : Theme.border
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Constants.sizeSm
                anchors.rightMargin: Constants.sizeSm
                spacing: Constants.sizeXs

                TextField {
                    id: textInput

                    focus: true
                    Layout.fillWidth: true
                    placeholderText: root.placeholderText
                    placeholderTextColor: Theme.muted
                    font.family: Constants.fontFamily
                    font.pixelSize: Math.round(root.customSize * SettingsService.fontScale)
                    color: Theme.fg
                    selectByMouse: true
                    echoMode: (root.isPassword && !root.revealPassword) ? TextInput.Password : TextInput.Normal
                    background: null
                    onActiveFocusChanged: {
                        if (activeFocus)
                            root._savedText = text;

                    }
                    onEditingFinished: {
                        root._savedText = text;
                        root.editingFinished();
                    }
                }

                SvgIconButton {
                    icon: root.revealPassword ? "eye" : "eye-off"
                    iconColor: Theme.muted
                    hoverColor: Theme.accent
                    flat: true
                    visible: root.isPassword
                    onClicked: root.revealPassword = !root.revealPassword
                }

                SvgIconButton {
                    icon: "check"
                    iconColor: Theme.accent
                    hoverColor: Theme.fg
                    flat: true
                    visible: root.showSubmitHint && textInput.activeFocus && textInput.text !== root._savedText
                    onClicked: {
                        textInput.focus = false;
                        root.editingFinished();
                    }
                }

            }

            Behavior on border.color {
                ColorAnimation {
                    duration: Constants.animFast
                }

            }

        }

    }

}
