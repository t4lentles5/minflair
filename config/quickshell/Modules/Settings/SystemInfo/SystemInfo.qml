import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

AppContainer {
    id: root

    property string osName: SystemStats.osName
    property string hostModel: SystemStats.hostModel
    property string kernel: SystemStats.kernel
    property string hostname: SystemStats.hostname
    property string username: SystemStats.username
    property string shell: SystemStats.shell
    property string wm: SystemStats.wm
    property string packages: SystemStats.packages
    property string display: SystemStats.display
    property string cpuModel: SystemStats.cpuModel
    property string cpuCores: SystemStats.cpuCores
    property string memTotal: SystemStats.memTotal
    property string diskTotal: SystemStats.diskTotal
    property string gpuName: SystemStats.gpuName

    // System Overview Hero Card
    Card {
        Layout.fillWidth: true
        contentPadding: Constants.sizeLg
        cardRadius: Constants.sizeSm
        useBorder: true

        RowLayout {
            spacing: Constants.sizeLg

            AnimatedMinflair {
                iconSize: Constants.size5Xl
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Constants.size2Xs

                ThemedText {
                    text: root.username + "@" + root.hostname
                    font.weight: Font.Bold
                    customSize: 15
                    color: Theme.fg
                }

                ThemedText {
                    text: root.osName + (root.kernel !== "" ? (" (" + root.kernel + ")") : "")
                    customSize: 11
                    color: Theme.muted
                }

            }

        }

    }

    AppGroup {
        title: "System Information"
        icon: "info"

        InfoRow {
            label: "Host Model"
            value: root.hostModel
            visible: root.hostModel !== ""
        }

        InfoRow {
            label: "OS"
            value: root.osName
        }

        InfoRow {
            label: "Kernel"
            value: root.kernel
        }

        InfoRow {
            label: "Desktop / WM"
            value: root.wm
        }

        InfoRow {
            label: "Shell"
            value: root.shell
        }

        InfoRow {
            label: "Packages"
            value: root.packages
        }

        InfoRow {
            label: "Display"
            value: root.display
        }

    }

    AppGroup {
        title: "Hardware Specifications"
        icon: "cpu"

        InfoRow {
            label: "Processor"
            value: root.cpuModel
        }

        InfoRow {
            label: "Cores & Threads"
            value: root.cpuCores
        }

        InfoRow {
            label: "Installed Memory"
            value: root.memTotal
        }

        InfoRow {
            label: "Storage (/)"
            value: root.diskTotal
        }

        InfoRow {
            label: "Graphics"
            value: root.gpuName
            visible: root.gpuName !== "" && root.gpuName !== "None"
        }

    }

    AppGroup {
        title: "System Updates"
        icon: "update"

        SettingToggle {
            label: "Auto-check System Updates"
            checked: UpdateService.packageManagerChecksEnabled
            onCheckedChanged: UpdateService.packageManagerChecksEnabled = checked
        }

        ThemedSelect {
            enabled: UpdateService.packageManagerChecksEnabled
            opacity: enabled ? 1 : 0.5
            label: "Check Interval"
            description: "Frequency of update checks"
            model: ["1 hour", "6 hours", "12 hours", "24 hours"]
            currentIndex: {
                let val = UpdateService.packageManagerCheckInterval;
                if (val === 3.6e+06)
                    return 0;

                if (val === 2.16e+07)
                    return 1;

                if (val === 4.32e+07)
                    return 2;

                if (val === 8.64e+07)
                    return 3;

                return 3;
            }
            onActivated: (index) => {
                let intervals = [3.6e+06, 2.16e+07, 4.32e+07, 8.64e+07];
                UpdateService.packageManagerCheckInterval = intervals[index];
            }
        }

    }

}
