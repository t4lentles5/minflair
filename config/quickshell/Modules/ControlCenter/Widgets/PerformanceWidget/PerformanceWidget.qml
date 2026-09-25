import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Core.Windows

Card {
    id: root

    property string powerProfile: SystemInfoService.powerProfile
    property var profilesList: {
        let m = ["power-saver", "balanced"];
        if (SystemInfoService.hasPerformanceProfile)
            m.push("performance");

        return m;
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Constants.sizeLg

        ThemedSelect {
            id: profileSelect

            label: "Performance Mode"
            comboWidth: 140
            description: {
                let p = root.powerProfile;
                if (p === "power-saver")
                    return "Limits CPU and saves battery";

                if (p === "balanced")
                    return "Standard balanced profile";

                if (p === "performance")
                    return "Max performance \u0026 brightness";

                return "";
            }
            model: root.profilesList
            Component.onCompleted: {
                for (let i = 0; i < root.profilesList.length; i++) {
                    if (root.profilesList[i] === SystemInfoService.powerProfile) {
                        profileSelect.currentIndex = i;
                        return ;
                    }
                }
                profileSelect.currentIndex = 0;
            }
            onActivated: (index) => {
                SystemInfoService.applyProfile(root.profilesList[index]);
            }

            Connections {
                function onPowerProfileChanged() {
                    for (let i = 0; i < root.profilesList.length; i++) {
                        if (root.profilesList[i] === SystemInfoService.powerProfile) {
                            profileSelect.currentIndex = i;
                            return ;
                        }
                    }
                    profileSelect.currentIndex = 0;
                }

                target: SystemInfoService
            }

        }

    }

}
