import QtQuick
import qs.Core
import qs.Core.Services

Text {
    property int customSize: Constants.sizeSm

    font.family: Constants.fontFamily
    font.pixelSize: Math.round(customSize * SettingsService.fontScale)
    color: Theme.fg
}
