import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

ColumnLayout {
    spacing: Constants.sizeMd

    ThemedText {
        text: "“" + QuoteService.currentQuote.text + "”"
        customSize: Constants.sizeMd
        font.italic: true
        color: Theme.muted
        horizontalAlignment: Text.AlignRight
        Layout.alignment: Qt.AlignRight
        wrapMode: Text.WordWrap
        Layout.maximumWidth: 400
    }

    ThemedText {
        text: "— " + QuoteService.currentQuote.author.toUpperCase()
        customSize: Constants.sizeXs + 2
        color: Theme.muted
        font.letterSpacing: 2
        Layout.alignment: Qt.AlignRight
    }

}
