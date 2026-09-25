import qs.Core
import qs.Core.Services
import qs.Modules.Bar

BarButton {
    icon: "power"
    iconSize: (SettingsService.isBarCompact || BarStyleConfig.isCompact(SettingsService.barStyle)) ? Constants.sizeLg + 2 : Constants.sizeXl
    iconColor: Theme.accent
}
