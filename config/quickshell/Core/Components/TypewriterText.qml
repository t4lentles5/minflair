import QtQuick
import qs.Core
import qs.Core.Components

Item {
    id: rootItem

    property string text: ""
    property int customSize: Constants.sizeSm
    property font font: Qt.font({
        "family": Constants.fontFamily
    })
    property color color: Theme.fg
    property int elide: Text.ElideRight
    property int wrapMode: Text.NoWrap
    property int horizontalAlignment: Text.AlignLeft
    property real lineHeight: 1
    property int typeInterval: 30
    property int _charCount: text.length
    property string _prevText: ""

    implicitWidth: hiddenText.implicitWidth
    implicitHeight: hiddenText.implicitHeight
    onTextChanged: {
        if (text === _prevText)
            return ;

        _prevText = text;
        _charCount = 0;
        typeTimer.restart();
    }

    Timer {
        id: typeTimer

        interval: rootItem.typeInterval
        repeat: true
        running: rootItem._charCount < rootItem.text.length
        onTriggered: {
            rootItem._charCount++;
        }
    }

    ThemedText {
        id: hiddenText

        width: rootItem.width
        text: rootItem.text
        customSize: rootItem.customSize
        font.weight: rootItem.font.weight
        font.bold: rootItem.font.bold
        font.italic: rootItem.font.italic
        font.family: rootItem.font.family
        wrapMode: rootItem.wrapMode
        horizontalAlignment: rootItem.horizontalAlignment
        lineHeight: rootItem.lineHeight
        visible: false
    }

    ThemedText {
        id: mainText

        anchors.fill: parent
        text: rootItem.text.substring(0, rootItem._charCount)
        customSize: rootItem.customSize
        font.weight: rootItem.font.weight
        font.bold: rootItem.font.bold
        font.italic: rootItem.font.italic
        font.family: rootItem.font.family
        color: rootItem.color
        elide: rootItem.elide
        wrapMode: rootItem.wrapMode
        horizontalAlignment: rootItem.horizontalAlignment
        lineHeight: rootItem.lineHeight
    }

}
