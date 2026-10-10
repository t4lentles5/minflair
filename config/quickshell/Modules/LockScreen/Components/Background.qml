import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Effects
import qs.Core
import qs.Core.Services
import qs.Core.Utils

Rectangle {
    id: bgRect

    property bool isDark: ColorUtils.isDark(Theme.bg)

    color: Theme.bg
    opacity: 1

    Image {
        id: wallpaperImg

        anchors.fill: parent
        sourceSize: Qt.size(480, 270)
        source: {
            let p = WallpaperManager.currentWallpaperPath;
            if (!p)
                return "";

            return p.startsWith("file://") ? p : ("file://" + p);
        }
        fillMode: {
            let mode = HyprlandService.wpResizeMode;
            if (mode === "fit")
                return Image.PreserveAspectFit;

            if (mode === "stretch")
                return Image.Stretch;

            return Image.PreserveAspectCrop;
        }
        horizontalAlignment: {
            let g = HyprlandService.wpCropGravity || "center";
            if (g.includes("left"))
                return Image.AlignLeft;

            if (g.includes("right"))
                return Image.AlignRight;

            return Image.AlignHCenter;
        }
        verticalAlignment: {
            let g = HyprlandService.wpCropGravity || "center";
            if (g.includes("top"))
                return Image.AlignTop;

            if (g.includes("bottom"))
                return Image.AlignBottom;

            return Image.AlignVCenter;
        }
        asynchronous: true
        cache: true
        layer.enabled: true

        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1
            blurMax: Constants.size5Xl
        }

    }

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        opacity: 0.7
    }

    Item {
        anchors.fill: parent
        opacity: 0.03

        Repeater {
            model: Math.ceil(parent.width / (Constants.size5Xl * 1.5))

            Rectangle {
                x: index * (Constants.size5Xl * 1.5)
                width: 1
                height: parent.height
                color: Theme.muted
            }

        }

        Repeater {
            model: Math.ceil(parent.height / (Constants.size5Xl * 1.5))

            Rectangle {
                y: index * (Constants.size5Xl * 1.5)
                width: parent.width
                height: 1
                color: Theme.muted
            }

        }

    }

    RadialGradient {
        anchors.fill: parent
        horizontalOffset: parent.width / 3
        verticalOffset: -parent.height / 3.5
        horizontalRadius: parent.width / 3
        verticalRadius: parent.height / 3

        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.bgAccentComplementary
            }

            GradientStop {
                position: 1
                color: "transparent"
            }

        }

    }

    RadialGradient {
        anchors.fill: parent
        horizontalOffset: -parent.width / 3
        verticalOffset: parent.height / 3.5
        horizontalRadius: parent.width / 3
        verticalRadius: parent.height / 3

        gradient: Gradient {
            GradientStop {
                position: 0
                color: Theme.bgAccent
            }

            GradientStop {
                position: 1
                color: "transparent"
            }

        }

    }

}
