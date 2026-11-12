import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.Core
import qs.Core.Services
pragma Singleton

Item {
    id: audioService

    readonly property var source: Pipewire.defaultAudioSource
    readonly property bool hasPhysicalMic: source !== null && source.audio !== null && (source.name ? !source.name.endsWith(".monitor") : true)
    readonly property int micVolume: (source && source.audio) ? Math.round(source.audio.volume * 100) : 0
    readonly property bool micMuted: (source && source.audio) ? source.audio.muted : true
    // Volume and mute read from the device, so a saved value can only be
    // restored once the device exists. The values are kept here until the
    // device reports them, which can be later than the device appearing.
    // The mute uses a sentinel because false is a value worth restoring.
    property int pendingMicVolume: -1
    property int pendingMicMuted: -1
    // Set while a saved value is waiting to be applied.
    property bool micRestorePending: false
    // Counts the ticks in which the device already reported the saved value.
    property int micStableChecks: 0

    function updateMicStatus() {
    }

    // Remember the values and apply them as soon as the device is there.
    // The settings are read as soon as the shell starts, which can be before
    // PipeWire has created the source.
    function restoreMic(volume, muted) {
        if (volume !== undefined)
            pendingMicVolume = volume;

        if (muted !== undefined)
            pendingMicMuted = muted ? 1 : 0;

        micRestorePending = true;
        applyPendingMic();
        startMicRestore();
    }

    function applyPendingMic() {
        if (!hasPhysicalMic || !source || !source.audio)
            return ;

        if (pendingMicVolume >= 0) {
            let normalized = Math.max(0, Math.min(100, pendingMicVolume)) / 100;
            source.audio.volume = normalized;
        }

        if (pendingMicMuted >= 0)
            source.audio.muted = pendingMicMuted === 1;

        // The value is written again on every tick until the device keeps
        // reporting it, because the device overwrites it right after it
        // appears.
        micRestorePending = true;
    }

    function setMicVolume(val) {
        if (!hasPhysicalMic || !source || !source.audio)
            return ;

        let normalized = Math.max(0, Math.min(100, val)) / 100;
        source.audio.volume = normalized;
    }

    function setMicMuted(state) {
        if (!hasPhysicalMic || !source || !source.audio)
            return ;

        source.audio.muted = state;
    }

    onMicMutedChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

        if (micRestorePending)
            startMicRestore();
    }
    onMicVolumeChanged: {
        if (SettingsService.settingsLoaded)
            SettingsService.saveSettings();

        if (micRestorePending)
            startMicRestore();
    }
    // The device can appear after the settings were read, so the saved
    // values are applied as soon as it shows up.
    onHasPhysicalMicChanged: {
        if (hasPhysicalMic && micRestorePending)
            startMicRestore();

    }

    // The device reports its own volume a moment after it appears, and can
    // overwrite the value that was applied. The restore is retried until the
    // device reports the saved value twice in a row, so a value that is
    // overwritten right after it was written is applied again.
    Timer {
        id: retryRestoreTimer

        interval: 250
        repeat: true
        running: false
        onTriggered: {
            if (!micRestorePending) {
                retryRestoreTimer.running = false;
                return ;
            }

            if (micDeviceMatches()) {
                micStableChecks += 1;
                if (micStableChecks >= 2) {
                    pendingMicVolume = -1;
                    pendingMicMuted = -1;
                    micRestorePending = false;
                    micStableChecks = 0;
                    retryRestoreTimer.running = false;
                    return ;
                }
            } else {
                micStableChecks = 0;
            }

            applyPendingMic();
        }
    }

    function micDeviceMatches() {
        if (pendingMicVolume >= 0 && micVolume !== pendingMicVolume)
            return false;

        if (pendingMicMuted >= 0 && micMuted !== (pendingMicMuted === 1))
            return false;

        return true;
    }

    function startMicRestore() {
        micStableChecks = 0;
        retryRestoreTimer.running = true;
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSource]
    }

}
