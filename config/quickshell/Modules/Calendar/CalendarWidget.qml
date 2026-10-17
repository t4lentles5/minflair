import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services

// Konten kalender. Sama seperti MiniMusicWidget: cuma Item tanpa window/background,
// wadahnya (Convex panel) yang ngurus posisi dan background.
Item {
    id: root

    property var widget: null
    property real calendarWidth: 320
    readonly property bool isVisibleOnScreen: widget !== null && widget.isOpen !== undefined ? widget.isOpen : true
    readonly property var today: SystemInfoService.currentTime
    property int viewMonth: new Date().getMonth()
    property int viewYear: new Date().getFullYear()
    readonly property bool isCurrentMonth: viewMonth === today.getMonth() && viewYear === today.getFullYear()

    function shiftMonth(delta) {
        let m = viewMonth + delta;
        let y = viewYear;
        while (m < 0) {
            m += 12;
            y--;
        }
        while (m > 11) {
            m -= 12;
            y++;
        }
        viewMonth = m;
        viewYear = y;
    }

    function goToToday() {
        const d = new Date();
        viewMonth = d.getMonth();
        viewYear = d.getFullYear();
    }

    // Balik ke bulan ini tiap kali widget ditutup
    onIsVisibleOnScreenChanged: {
        if (!isVisibleOnScreen)
            goToToday();
    }
    implicitWidth: calendarWidth
    implicitHeight: mainColumn.implicitHeight
    width: implicitWidth
    height: implicitHeight

    // Scroll mouse = ganti bulan
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: (event) => {
            root.shiftMonth(event.angleDelta.y > 0 ? -1 : 1);
        }
    }

    ColumnLayout {
        id: mainColumn

        anchors.fill: parent
        spacing: Constants.sizeMd

        // HEADER: bulan + tahun, tombol prev/next
        RowLayout {
            Layout.fillWidth: true
            spacing: Constants.sizeSm

            Rectangle {
                id: prevBtn

                Layout.preferredWidth: Constants.size2Xl
                Layout.preferredHeight: Constants.size2Xl
                radius: Constants.sizeSm
                color: prevArea.containsMouse ? Theme.bgSecondary : "transparent"

                ThemedText {
                    anchors.centerIn: parent
                    text: "‹"
                    font.bold: true
                    customSize: Constants.sizeMd
                }

                MouseArea {
                    id: prevArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shiftMonth(-1)
                }

            }

            // Klik judul = balik ke bulan ini
            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: Constants.size2Xl

                ThemedText {
                    anchors.centerIn: parent
                    text: Qt.locale().monthName(root.viewMonth) + " " + root.viewYear
                    font.bold: true
                    customSize: Constants.sizeMd
                    color: root.isCurrentMonth ? Theme.fg : Theme.accent
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: root.isCurrentMonth ? Qt.ArrowCursor : Qt.PointingHandCursor
                    enabled: !root.isCurrentMonth
                    onClicked: root.goToToday()
                }

            }

            Rectangle {
                id: nextBtn

                Layout.preferredWidth: Constants.size2Xl
                Layout.preferredHeight: Constants.size2Xl
                radius: Constants.sizeSm
                color: nextArea.containsMouse ? Theme.bgSecondary : "transparent"

                ThemedText {
                    anchors.centerIn: parent
                    text: "›"
                    font.bold: true
                    customSize: Constants.sizeMd
                }

                MouseArea {
                    id: nextArea

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shiftMonth(1)
                }

            }

        }

        // NAMA HARI
        DayOfWeekRow {
            Layout.fillWidth: true
            locale: Qt.locale()

            delegate: ThemedText {
                text: model.shortName
                horizontalAlignment: Text.AlignHCenter
                customSize: Constants.sizeXs + 2
                color: Theme.muted
            }

        }

        // GRID TANGGAL
        MonthGrid {
            id: grid

            Layout.fillWidth: true
            month: root.viewMonth
            year: root.viewYear
            locale: Qt.locale()

            delegate: Item {
                id: cell

                readonly property bool inMonth: model.month === root.viewMonth
                readonly property bool isToday: model.day === root.today.getDate() && model.month === root.today.getMonth() && model.year === root.today.getFullYear()

                implicitWidth: 40
                implicitHeight: 36

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.min(parent.width, parent.height)
                    height: width
                    radius: width / 2
                    color: cell.isToday ? Theme.accent : (cellArea.containsMouse && cell.inMonth ? Theme.bgSecondary : "transparent")
                }

                ThemedText {
                    anchors.centerIn: parent
                    text: model.day
                    customSize: Constants.sizeSm
                    font.bold: cell.isToday
                    opacity: cell.inMonth ? 1 : 0.3
                    color: cell.isToday ? Theme.bg : Theme.fg
                }

                MouseArea {
                    id: cellArea

                    anchors.fill: parent
                    hoverEnabled: true
                }

            }

        }

    }

}
