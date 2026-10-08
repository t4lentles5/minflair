import QtQuick
import QtQuick.Layouts
import qs.Core
import qs.Core.Components
import qs.Core.Services
import qs.Modules.Settings.Components

SettingSegmented {
    id: positionBarRoot

    required property var previewRoot
    readonly property string currentPos: {
        let cur = HyprlandService.wpCropGravity;
        if (previewRoot.isWider) {
            if (cur.includes("left"))
                return "left";

            if (cur.includes("right"))
                return "right";

            return "center";
        } else {
            if (cur.includes("top"))
                return "top";

            if (cur.includes("bottom"))
                return "bottom";

            return "center";
        }
    }
    readonly property var optionsModel: {
        if (previewRoot.isWider)
            return [{
            "text": "Left Side",
            "value": "left"
        }, {
            "text": "Center",
            "value": "center"
        }, {
            "text": "Right Side",
            "value": "right"
        }];
        else
            return [{
            "text": "Top Side",
            "value": "top"
        }, {
            "text": "Center",
            "value": "center"
        }, {
            "text": "Bottom Side",
            "value": "bottom"
        }];
    }

    label: "Focus Position"
    model: optionsModel
    currentValue: currentPos
    visible: previewRoot.isCropMode && (previewRoot.isWider || previewRoot.isTaller)
    onActivated: (val) => {
        previewRoot.selectPosition(val);
    }
}
