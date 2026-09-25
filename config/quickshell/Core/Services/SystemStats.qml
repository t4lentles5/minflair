import QtQuick
import Quickshell
import Quickshell.Io
import qs.Core
pragma Singleton

Item {
    id: root

    property string osName: "Linux"
    property string hostModel: ""
    property string kernel: "Loading..."
    property string hostname: "Loading..."
    property string username: "Loading..."
    property string shell: "Loading..."
    property string wm: "Hyprland (Wayland)"
    property string packages: "Loading..."
    property string display: "Loading..."
    property string cpuModel: "Loading..."
    property string cpuCores: "Loading..."
    property string memTotal: "0 GB"
    property string diskTotal: "0 GB"
    property string gpuName: "None"
    property bool hasGpu: false
    property real cpuUsage: 0
    property real memUsed: 0
    property string uptime: ""

    Component.onCompleted: {
        if (!staticInfoProc.running)
            staticInfoProc.running = true;

        if (!statsProc.running)
            statsProc.running = true;

    }

    Timer {
        id: restartTimer

        interval: 3000
        repeat: false
        onTriggered: {
            if (!statsProc.running)
                statsProc.running = true;

        }
    }

    Process {
        id: staticInfoProc

        command: ["python3", Quickshell.shellDir + "/Scripts/get_system_info.py"]
        running: true
        onExited: (exitCode) => {
            if (exitCode === 0) {
                try {
                    let info = JSON.parse(staticStdout.text.trim());
                    root.osName = info.os || "Linux";
                    root.hostModel = info.host || "";
                    root.kernel = info.kernel || "";
                    root.hostname = info.hostname || "";
                    root.username = info.username || "";
                    root.shell = info.shell || "";
                    root.wm = info.wm || "Hyprland (Wayland)";
                    root.packages = info.packages || "";
                    root.display = info.display || "";
                    root.cpuModel = info.cpu_model || "";
                    root.cpuCores = info.cpu_cores || "";
                    root.memTotal = info.ram_total || "0 GB";
                    root.diskTotal = info.disk_total || "0 GB";
                    root.gpuName = info.gpus || "None";
                    root.hasGpu = root.gpuName !== "" && root.gpuName !== "None" && root.gpuName !== "Integrated Graphics";
                } catch (e) {
                    console.error("Error parsing get_system_info.py JSON: " + e);
                }
            }
        }

        stdout: StdioCollector {
            id: staticStdout
        }

    }

    Process {
        id: statsProc

        command: ["python3", Quickshell.shellDir + "/Scripts/get_processes.py", "4000", "cpu", "--daemon", "--no-processes"]
        running: true
        onExited: (exitCode) => {
            restartTimer.start();
        }

        stdout: SplitParser {
            onRead: (data) => {
                if (!data)
                    return ;

                try {
                    let parsedData = JSON.parse(data.trim());
                    if (parsedData.system) {
                        let sys = parsedData.system;
                        root.cpuUsage = (sys.cpu_usage !== undefined) ? sys.cpu_usage : 0;
                        root.memUsed = (sys.mem_used_gb !== undefined) ? sys.mem_used_gb : 0;
                        root.uptime = sys.uptime || "";
                    }
                } catch (e) {
                    console.error("Error parsing stats JSON: " + e);
                }
            }
        }

    }

}
