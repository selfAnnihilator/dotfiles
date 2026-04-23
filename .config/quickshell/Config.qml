pragma Singleton
import QtQuick

QtObject {
    // ── System commands ────────────────────────────────────────────────────
    // Replace these with equivalents on non-Omarchy systems
    readonly property string audioApp:     "omarchy-launch-audio"   // volume control GUI
    readonly property string wifiApp:      "omarchy-launch-wifi"    // wifi manager GUI
    readonly property string wallpaperCmd: "omarchy-theme-bg-set"   // set wallpaper + colorscheme
    readonly property string lockCmd:      "hyprlock"               // lock screen
    readonly property string recorderCmd:  "wf-recorder"            // screen recorder (optional)
}
