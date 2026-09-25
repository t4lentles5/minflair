import QtQuick
import qs.Core.Services
pragma Singleton

QtObject {
    id: root

    property var _styles: ({
        "minflair": {
            "hasFrame": false,
            "hasExpandableHost": false,
            "usesFloatingPopups": true,
            "isCompact": false
        },
        "framed": {
            "hasFrame": true,
            "hasExpandableHost": false,
            "usesFloatingPopups": true,
            "isCompact": false
        },
        "island": {
            "hasFrame": false,
            "hasExpandableHost": true,
            "usesFloatingPopups": false,
            "isCompact": true
        },
        "notch": {
            "hasFrame": false,
            "hasExpandableHost": true,
            "usesFloatingPopups": false,
            "isCompact": true
        },
        "convex": {
            "hasFrame": true,
            "hasExpandableHost": false,
            "usesFloatingPopups": true,
            "isCompact": false
        }
    })

    function styleOf(style) {
        return _styles[style] || _styles["minflair"];
    }

    function barHeight(style) {
        if (style === "island" || style === "notch")
            return 36;

        if (SettingsService.barCompactMode && style === "convex")
            return 36;

        return 48; // minflair
    }

    function barMarginTop(style) {
        if (style === "framed" || style === "convex" || style === "notch")
            return 0;

        return 8; // minflair, island
    }

    function barMarginSide(style) {
        if (style === "framed" || style === "convex" || style === "notch" || style === "island")
            return 0;

        return 8; // minflair, island
    }

    function isCompact(style) {
        return style === "island" || style === "notch";
    }

    function isExpandable(style) {
        return style === "island" || style === "notch";
    }

}
