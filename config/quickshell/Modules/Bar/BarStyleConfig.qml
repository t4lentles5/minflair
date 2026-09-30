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
            "isPill": false
        },
        "island": {
            "hasFrame": false,
            "hasExpandableHost": true,
            "usesFloatingPopups": false,
            "isPill": true
        },
        "notch": {
            "hasFrame": false,
            "hasExpandableHost": true,
            "usesFloatingPopups": false,
            "isPill": true
        },
        "convex": {
            "hasFrame": true,
            "hasExpandableHost": false,
            "usesFloatingPopups": true,
            "isPill": false
        }
    })

    function styleOf(style) {
        return _styles[style] || _styles["minflair"];
    }

    function barHeight(style) {
        if (style === "convex")
            return 40;

        if (style === "island" || style === "notch")
            return 36;

        return 44; // minflair
    }

    function barMarginTop(style) {
        if (style === "convex" || style === "notch")
            return 0;

        return 8; // minflair, island
    }

    function barMarginSide(style) {
        if (style === "convex" || style === "notch" || style === "island")
            return 0;

        return 8; // minflair, island
    }

    function isPill(style) {
        return style === "island" || style === "notch";
    }

    function isExpandable(style) {
        return style === "island" || style === "notch";
    }

}
