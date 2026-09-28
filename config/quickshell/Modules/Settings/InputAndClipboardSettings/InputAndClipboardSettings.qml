import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

AppContainer {
    id: root

    AppGroup {
        title: "Keyboard Layouts"
        icon: "keyboard"
        showDividers: false

        Repeater {
            model: SettingsService.enabledKbLayouts

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Constants.sizeSm

                SettingRowTemplate {
                    label: {
                        let nameMap = {
                            "us": "English (US)",
                            "latam": "Spanish (LatAm)",
                            "es": "Spanish (ES)",
                            "fr": "French",
                            "de": "German",
                            "it": "Italian",
                            "pt": "Portuguese",
                            "ru": "Russian"
                        };
                        return nameMap[modelData] || modelData;
                    }
                    description: index === 0 ? "Primary Layout" : "Secondary Layout"

                    SvgIconButton {
                        icon: "trash"
                        visible: SettingsService.enabledKbLayouts.length > 1
                        onClicked: {
                            let layouts = [...SettingsService.enabledKbLayouts];
                            let idx = layouts.indexOf(modelData);
                            if (idx !== -1) {
                                layouts.splice(idx, 1);
                                SettingsService.enabledKbLayouts = layouts;
                            }
                        }
                    }
                }

                Divider {
                    Layout.fillWidth: true
                    visible: true
                }
            }
        }

        ThemedSelect {
            label: "Add Layout"
            description: "Select a language to add"
            searchable: true
            model: [
                "None",
                "English (US)",
                "Spanish (LatAm)",
                "Spanish (ES)",
                "French",
                "German",
                "Italian",
                "Portuguese",
                "Russian"
            ]
            currentIndex: 0
            onActivated: (index) => {
                if (index === 0) return;
                
                let codeMap = [
                    "", "us", "latam", "es", "fr", "de", "it", "pt", "ru"
                ];
                let code = codeMap[index];
                if (SettingsService.enabledKbLayouts.indexOf(code) === -1) {
                    let layouts = [...SettingsService.enabledKbLayouts];
                    layouts.push(code);
                    SettingsService.enabledKbLayouts = layouts;
                }
                
                // Reset the select back to "None"
                currentIndex = Qt.binding(() => 0);
            }
        }
    }

    AppGroup {
        title: "Clipboard"
        icon: "clipboard"

        ThemedSelect {
            label: "Clipboard Max History Items"
            description: "Limit number of clipboard entries displayed"
            model: ["25 items", "50 items", "100 items", "200 items", "500 items"]
            currentIndex: {
                let items = SettingsService.clipboardMaxItems;
                if (items === 25)
                    return 0;

                if (items === 50)
                    return 1;

                if (items === 100)
                    return 2;

                if (items === 200)
                    return 3;

                if (items === 500)
                    return 4;

                return 1;
            }
            onActivated: (index) => {
                let vals = [25, 50, 100, 200, 500];
                SettingsService.clipboardMaxItems = vals[index];
            }
        }

    }

}
