import QtQuick
import Quickshell.Services.Pipewire
import qs.Core
import qs.Core.Components

ThemedSlider {
    id: root

    property var sink: Pipewire.defaultAudioSink
    property int volume: (sink && sink.audio) ? Math.round(sink.audio.volume * 100) : 0
    property bool muted: (sink && sink.audio) ? sink.audio.muted : false

    enabled: !root.muted
    value: root.volume
    icon: (root.muted || root.volume === 0) ? "volume-off" : "volume"
    onMoved: (val) => {
        if (sink && sink.audio)
            sink.audio.volume = val / 100;

    }
    onIconClicked: {
        if (sink && sink.audio)
            sink.audio.muted = !sink.audio.muted;

    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

}
