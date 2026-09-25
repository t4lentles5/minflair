import QtQuick
import qs.Core
import qs.Core.Components
import qs.Core.Services

Item {
    id: rootItem

    property string text: ""
    property int customSize: Constants.sizeSm
    property font font: Qt.font({
        "family": Constants.fontFamily
    })
    property color color: Theme.fg
    property int elide: Text.ElideRight
    property int wrapMode: Text.NoWrap
    property int horizontalAlignment: Text.AlignLeft
    property real lineHeight: 1
    property real slideDistance: 8
    property int duration: Constants.animNormal
    // Internal state
    property string displayText: ""
    property string _targetText: ""
    property bool _initialized: false

    implicitWidth: hiddenText.implicitWidth
    implicitHeight: hiddenText.implicitHeight
    clip: true
    Component.onCompleted: {
        displayText = text;
        _targetText = text;
        _initialized = true;
    }
    onTextChanged: {
        _targetText = text;
        if (!_initialized) {
            displayText = text;
            _initialized = true;
            return ;
        }
        if (text === displayText && !transitionAnim.running)
            return ;

        if (!HyprlandService.enableAnimations || rootItem.duration <= 0) {
            transitionAnim.stop();
            displayText = text;
            textTranslate.y = 0;
            mainText.opacity = 1;
            return ;
        }
        transitionAnim.stop();
        mainText.opacity = 1;
        textTranslate.y = 0;
        transitionAnim.start();
    }

    SequentialAnimation {
        id: transitionAnim

        // Phase 1: Slide up & Fade out old text
        ParallelAnimation {
            NumberAnimation {
                target: mainText
                property: "opacity"
                to: 0
                duration: Math.round(rootItem.duration * 0.45)
                easing.type: Easing.InQuad
            }

            NumberAnimation {
                target: textTranslate
                property: "y"
                to: -rootItem.slideDistance
                duration: Math.round(rootItem.duration * 0.45)
                easing.type: Easing.InQuad
            }

        }

        // Phase 2: Update text to target & reposition at bottom
        ScriptAction {
            script: {
                rootItem.displayText = rootItem._targetText;
                textTranslate.y = rootItem.slideDistance;
            }
        }

        // Phase 3: Slide up from below & Fade in new text
        ParallelAnimation {
            NumberAnimation {
                target: mainText
                property: "opacity"
                to: 1
                duration: Math.round(rootItem.duration * 0.55)
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: textTranslate
                property: "y"
                to: 0
                duration: Math.round(rootItem.duration * 0.55)
                easing.type: Easing.OutCubic
            }

        }

    }

    ThemedText {
        id: hiddenText

        text: rootItem.displayText !== "" ? rootItem.displayText : rootItem.text
        customSize: rootItem.customSize
        font.weight: rootItem.font.weight
        font.bold: rootItem.font.bold
        font.italic: rootItem.font.italic
        font.family: rootItem.font.family
        wrapMode: rootItem.wrapMode
        horizontalAlignment: rootItem.horizontalAlignment
        lineHeight: rootItem.lineHeight
        visible: false
    }

    ThemedText {
        id: mainText

        anchors.fill: parent
        text: rootItem.displayText !== "" ? rootItem.displayText : rootItem.text
        customSize: rootItem.customSize
        font.weight: rootItem.font.weight
        font.bold: rootItem.font.bold
        font.italic: rootItem.font.italic
        font.family: rootItem.font.family
        color: rootItem.color
        elide: rootItem.elide
        wrapMode: rootItem.wrapMode
        horizontalAlignment: rootItem.horizontalAlignment
        lineHeight: rootItem.lineHeight

        transform: Translate {
            id: textTranslate

            y: 0
        }

    }

    Behavior on implicitWidth {
        enabled: HyprlandService.enableAnimations

        NumberAnimation {
            duration: Math.round(rootItem.duration * 0.6)
            easing.type: Easing.OutCubic
        }

    }

}
