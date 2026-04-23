import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    // ── Paths (derived from this file's location — no hardcoding needed) ───
    // shell.qml is at ~/.config/quickshell/ so ../../../ = $HOME
    readonly property string homeDir:      Qt.resolvedUrl("../../").toString().replace("file://", "").replace(/\/$/, "")
    readonly property string wallpaperDir: homeDir + "/Pictures/wallpaper"
    readonly property string cavaConfigPath: homeDir + "/.config/cava/quickshell.conf"

    // ── Global layout (auto-adapts to monitor) ─────────────────────────────
    readonly property int screenW: Quickshell.screens.length > 0 ? Quickshell.screens[0].width  : 1920
    readonly property int screenH: Quickshell.screens.length > 0 ? Quickshell.screens[0].height : 1080
    readonly property int cx: screenW / 2   // horizontal center of screen
    readonly property int sideGap: 16       // px gap between center pill edge and side pill edge

    property bool sidepillsVisible: true

    property bool barVisible: true
    property bool pinned: false
    onPinnedChanged: { if (pinned) { hideTimer.stop(); barVisible = true } }
    onBarVisibleChanged: { if (pinned && !barVisible) barVisible = true }

    Timer {
        id: hideTimer
        interval: 1200
        onTriggered: {
            if (pill.islandState !== "idle") return
            if (!hotZoneArea.containsMouse &&
                !islandWindow.containsMouse_ &&
                !statusWindow.containsMouse_ &&
                !statsWindow.containsMouse_) {
                barVisible = false
            }
        }
    }

    Timer {
        id: showTimer
        interval: 100
        onTriggered: barVisible = true
    }

    WlrLayershell {
        anchors.top: true
        anchors.left: true
        anchors.right: true
        implicitHeight: 4
        color: "transparent"
        exclusiveZone: 0
        layer: WlrLayer.Overlay

        MouseArea {
            id: hotZoneArea
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                hideTimer.stop()
                showTimer.start()
            }
            onExited: hideTimer.start()
        }
    }

    IpcHandler {
        target: "island"

        function openLauncher() {
            pill.islandState = "launcher"
        }

        function openWallpaper() {
            pill.islandState = "wallpaper"
        }

        function openHub() {
            pill.islandState = "hub"
        }

        function openThemePicker() {
            themePicker.visible = true
        }
    }

    // Mako owns the D-Bus notification slot — spy via dbus-monitor instead.
    // Parses Notify calls and appends to the bar's notification list.
    // Mako continues to handle popups normally.
    Process {
        id: dbusNotifProc
        command: ["bash", "-c",
            "dbus-monitor --session \"type='method_call',interface='org.freedesktop.Notifications',member='Notify'\" 2>/dev/null | awk '" +
            "/member=Notify/ { notify=1; sc=0; app=\"\"; summary=\"\"; body=\"\" } " +
            "notify && /^   string \"/ { " +
            "  sc++; val=$0; sub(/^   string \"/, \"\", val); sub(/\"$/, \"\", val); " +
            "  if (sc==1) app=val; " +
            "  else if (sc==3) summary=val; " +
            "  else if (sc==4) { body=val; print app \"|\" summary \"|\" body; fflush(); notify=0 } " +
            "}'"
        ]
        running: true
        stdout: SplitParser {
            onRead: function(line) {
                var parts = line.split("|")
                if (parts.length < 2) return
                pill.notificationList = [...pill.notificationList, {
                    appName: parts[0] || "",
                    summary: parts[1] || "",
                    body:    parts[2] || "",
                    id:      Date.now()
                }]
            }
        }
    }

    // ── Status pill ────────────────────────────────────────────────────────
    WlrLayershell {
        id: statusWindow
        anchors.top: true
        anchors.left: true
        implicitWidth: 120
        implicitHeight: 58
        color: "transparent"
        exclusiveZone: 0

        property bool containsMouse_: statusPillArea.containsMouse

        mask: Region { item: statusPill }

        margins {
            left: cx - pill.width / 2 - sideGap - statusPill.width - 10
            top: (!barVisible || !sidepillsVisible) ? -60 : 0
        }

        Behavior on margins.top {
            NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
        }
        Behavior on margins.left {
            NumberAnimation { duration: 0 }
        }

        MouseArea {
            id: statusPillArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onEntered: { hideTimer.stop(); barVisible = true }
            onExited: hideTimer.start()
            onPressed: function(mouse) { mouse.accepted = false }
        }

        Rectangle {
            id: statusPill
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 12

            width: 100
            height: 34
            radius: 999
            color: Theme.surface
            border.color: Theme.border
            border.width: 1

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 4
                radius: 12
                samples: 25
                color: "#60000000"
            }

            property real playerVolume: 0
            property bool networkConnected: false
            property string networkSSID: ""
            property string networkSpeed: ""
            property string networkType: "none"

            Row {
                anchors.centerIn: parent
                spacing: 12

                Item {
                    width: 22; height: 22
                    anchors.verticalCenter: parent.verticalCenter

                    Canvas {
                        id: playerVolCanvas
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            var cx = width / 2, cy = height / 2, r = width / 2 - 2
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, 0, Math.PI * 2)
                            ctx.strokeStyle = "#222222"
                            ctx.lineWidth = 2.5
                            ctx.stroke()
                            ctx.beginPath()
                            ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + (Math.PI * 2 * statusPill.playerVolume))
                            ctx.strokeStyle = Theme.accent
                            ctx.lineWidth = 2.5
                            ctx.lineCap = "round"
                            ctx.stroke()
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰕾"
                        font.pixelSize: 9
                        font.family: "JetBrains Mono"
                        color: Theme.accent
                    }

                    ToolTip {
                        visible: volMouseArea.containsMouse
                        delay: 300
                        text: Math.round(statusPill.playerVolume * 100) + "%"
                        background: Rectangle { color: Theme.surface; radius: 6 }
                        contentItem: Text {
                            text: Math.round(statusPill.playerVolume * 100) + "%"
                            color: Theme.text; font.pixelSize: 11; font.family: "JetBrains Mono"
                        }
                    }

                    MouseArea {
                        id: volMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: { hideTimer.stop(); barVisible = true }
                        onExited: hideTimer.start()
                        onClicked: { audioLaunchProc.running = false; audioLaunchProc.running = true }
                        onWheel: function(wheel) {
                            hideTimer.stop()
                            barVisible = true
                            var delta = wheel.angleDelta.y > 0 ? 0.05 : -0.05
                            var newVol = Math.max(0, Math.min(1, statusPill.playerVolume + delta))
                            statusPill.playerVolume = newVol
                            volumeProc.command = ["playerctl", "volume", newVol.toFixed(2)]
                            volumeProc.running = true
                        }
                    }
                }

                Item {
                    id: networkIconItem
                    width: 22; height: 22
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        id: networkIconText
                        anchors.centerIn: parent
                        text: {
                            if (statusPill.networkType === "wifi")  return "󰖩"
                            if (statusPill.networkType === "wired") return "󰈀"
                            return "󰤭"
                        }
                        font.pixelSize: 14
                        font.family: "JetBrains Mono"
                        color: statusPill.networkConnected ? Theme.text : Theme.danger
                    }

                    ToolTip {
                        id: networkTooltip
                        visible: networkIconMouseArea.containsMouse
                        delay: 400
                        text: statusPill.networkConnected
                            ? (statusPill.networkSSID !== "" ? statusPill.networkSSID : "Connected") +
                              (statusPill.networkSpeed !== "" ? "\n" + statusPill.networkSpeed : "")
                            : "Disconnected"
                        background: Rectangle { color: Theme.surface; radius: 6 }
                        contentItem: Text {
                            text: networkTooltip.text
                            color: Theme.text
                            font.pixelSize: 11
                            font.family: "JetBrains Mono"
                        }
                    }

                    MouseArea {
                        id: networkIconMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: { networkLaunchProc.running = false; networkLaunchProc.running = true }
                        onEntered: { hideTimer.stop(); barVisible = true }
                        onExited: hideTimer.start()
                    }
                }
            }

            onPlayerVolumeChanged: playerVolCanvas.requestPaint()
        }

        Process { id: volumeProc; command: ["playerctl", "volume", "0.5"]; running: false }
        Process { id: audioLaunchProc; command: ["bash", "-c", Config.audioApp + " &"]; running: false }

        Process {
            id: playerVolProc
            command: ["playerctl", "volume"]
            running: true
            stdout: SplitParser {
                onRead: function(line) {
                    var vol = parseFloat(line.trim())
                    if (!isNaN(vol)) statusPill.playerVolume = vol
                }
            }
        }

        Process {
            id: networkProc
            command: ["bash", "-c", "wiface=$(ls /sys/class/net/ 2>/dev/null | grep -E '^wlan|^wlp' | head -1); eiface=$(ls /sys/class/net/ 2>/dev/null | grep -E '^eth|^enp|^eno|^ens' | head -1); if [ -n \"$wiface\" ]; then iwctl station \"$wiface\" show 2>/dev/null | awk '/^[[:space:]]+State[[:space:]]/{state=$NF} /Connected network/{sub(/.*Connected network[[:space:]]+/,\"\"); ssid=$0} /Tx-Bitrate/{speed=$2\" \"$3} END{printf \"%s|%s|%s|wifi\\n\",state,ssid,speed}'; elif [ -n \"$eiface\" ] && grep -q 1 /sys/class/net/$eiface/carrier 2>/dev/null; then echo \"connected|||wired\"; else echo \"disconnected|||none\"; fi"]
            running: true
            stdout: SplitParser {
                onRead: function(line) {
                    var parts = line.trim().split("|")
                    var state = parts[0] || ""
                    var ssid  = parts[1] || ""
                    var speed = parts[2] || ""
                    var type  = parts[3] || "none"
                    statusPill.networkConnected = (state === "connected")
                    statusPill.networkType = statusPill.networkConnected ? type : "none"
                    statusPill.networkSSID = ssid.trim()
                    statusPill.networkSpeed = speed.trim() !== "" ? speed.trim() + " Mbps" : ""
                }
            }
        }

        Process { id: networkLaunchProc; command: ["bash", "-c", Config.wifiApp + " &"]; running: false }

        Timer {
            interval: 2000
            running: true
            repeat: true
            onTriggered: {
                playerVolProc.running = true
                networkProc.running = true
            }
        }
    }

    // ── Main island ────────────────────────────────────────────────────────
    WlrLayershell {
        id: islandWindow
        anchors.top: true
        implicitWidth: 600
        implicitHeight: 700
        color: "transparent"
        exclusiveZone: 0
        keyboardFocus: pill.islandState === "launcher" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand

        property bool containsMouse_: islandPillArea.containsMouse

        mask: Region { item: pill }

        margins {
            top: (barVisible || pill.islandState !== "idle") ? 0 : -(pill.height + 20)
        }

        Behavior on margins.top {
            NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
        }

        MouseArea {
            id: islandPillArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onEntered: { hideTimer.stop(); barVisible = true }
            onExited: hideTimer.start()
            onPressed: function(mouse) { mouse.accepted = false }
        }

        Rectangle {
            id: pill
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 12

            width: {
                if (islandState === "idle")          return pill.musicPlaying ? 200 : 180
                if (islandState === "hub")           return 360  // wider: 6 buttons now
                if (islandState === "power")         return 280
                if (islandState === "wallpaper")     return 400
                if (islandState === "media")         return 320
                if (islandState === "notifications") return 380
                if (islandState === "recorder")      return 280
                if (islandState === "launcher")      return 320
                if (islandState === "stats")         return 360
                return 320
            }
            height: {
                if (islandState === "idle")          return 34
                if (islandState === "hub")           return 76
                if (islandState === "power")         return 76
                if (islandState === "wallpaper")     return 460
                if (islandState === "media")         return 120
                if (islandState === "notifications") return 420
                if (islandState === "recorder")      return 80
                if (islandState === "launcher")      return 420
                if (islandState === "stats")         return 220
                return 420
            }

            radius: Math.min(height * 0.5, 24)
            color: Theme.surface
            border.color: Theme.border
            border.width: 1

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 4
                radius: 16
                samples: 33
                color: "#80000000"
            }

            property string islandState: "idle"
            property var wallpaperList: []
            property string musicTitle: ""
            property string musicArtist: ""
            property string musicArt: ""
            property bool musicPlaying: false
            property real musicPosition: 0
            property real musicLength: 0
            property bool isRecording: false
            property string recordingPath: ""
            property var notificationList: []
            function closeToIdle() { islandState = "idle" }

            Component.onCompleted: {
                lsProc.running = true
                playerctlProc.running = true
            }

            Process { id: lockProc;         command: [Config.lockCmd];           running: false }
            Process { id: suspendProc;      command: ["systemctl", "suspend"];    running: false }
            Process { id: rebootProc;       command: ["systemctl", "reboot"];     running: false }
            Process { id: poweroffProc;     command: ["systemctl", "poweroff"];   running: false }
            Process { id: awwwProc;         command: [Config.wallpaperCmd, ""];  running: false }
            Process { id: walProc;          command: ["wal", "-i", ""];           running: false }
            Process { id: prevProc;         command: ["playerctl", "previous"];   running: false }
            Process { id: nextProc;         command: ["playerctl", "next"];       running: false }
            Process { id: playProc;         command: ["playerctl", "play-pause"]; running: false }
            Process { id: recorderProc;     command: [Config.recorderCmd, "-f", "/tmp/rec.mp4"]; running: false }
            Process { id: stopRecorderProc; command: ["pkill", "-SIGINT", Config.recorderCmd]; running: false }



            // Single cava instance feeds both media vizCanvas and idle pill canvas
            Process {
                id: cavaProc
                command: ["bash", "-c", "cava -p \"$HOME/.config/cava/quickshell.conf\""]
                running: pill.musicPlaying
                stdout: SplitParser {
                    onRead: function(line) {
                        var vals = line.trim().split(";").filter(v => v !== "").map(v => parseFloat(v))
                        if (vals.length === 0) return
                        if (pill.islandState === "media") {
                            vizCanvas.bars = vals
                            vizCanvas.requestPaint()
                        }
                        if (pill.islandState === "idle") {
                            idleCavaCanvas.bars = vals
                            idleCavaCanvas.requestPaint()
                        }
                    }
                }
            }

            Process {
                id: lsProc
                command: ["bash", "-c", "ls -d \"$HOME/Pictures/wallpaper/\"* 2>/dev/null"]
                running: false
                stdout: SplitParser {
                    onRead: function(line) {
                        if (line.trim() !== "") pill.wallpaperList = [...pill.wallpaperList, line.trim()]
                    }
                }
            }

            Process {
                id: playerctlProc
                command: ["playerctl", "metadata", "--format", "{{status}}|{{title}}|{{artist}}|{{mpris:artUrl}}"]
                running: false
                stdout: SplitParser {
                    onRead: function(line) {
                        var parts = line.split("|")
                        if (parts.length >= 4) {
                            pill.musicPlaying  = parts[0] === "Playing"
                            pill.musicTitle    = parts[1] || ""
                            pill.musicArtist   = parts[2] || ""
                            pill.musicArt      = parts[3] || ""

                        } else {
                            pill.musicTitle = ""; pill.musicArtist = ""; pill.musicArt = ""
                        }
                    }
                }
            }

            Timer {
                interval: 2000; running: true; repeat: true
                onTriggered: playerctlProc.running = true
            }

            // Position polled every second for smooth progress bar
            Process {
                id: positionProc
                command: ["playerctl", "position"]
                running: false
                stdout: SplitParser {
                    onRead: function(line) {
                        var v = parseFloat(line.trim())
                        if (!isNaN(v)) pill.musicPosition = v
                    }
                }
            }

            // Length fetched via metadata (microseconds → seconds)
            Process {
                id: lengthProc
                command: ["playerctl", "metadata", "mpris:length"]
                running: false
                stdout: SplitParser {
                    onRead: function(line) {
                        var v = parseFloat(line.trim())
                        if (!isNaN(v) && v > 0) pill.musicLength = v / 1000000
                    }
                }
            }

            Timer {
                interval: 1000; running: true; repeat: true
                onTriggered: {
                    if (pill.musicPlaying) {
                        positionProc.running = true
                        lengthProc.running = true
                    }
                }
            }

            Behavior on width  { NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }
            Behavior on height { NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.2 } }

            // ── Clock / Cava idle ──────────────────────────────────────────
            // Music playing: full-pill cava, right-click overlays clock
            // No music: clock only
            Item {
                id: clockItem
                anchors.fill: parent
                anchors.margins: 8
                opacity: pill.islandState === "idle" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }
                // idleMode: 0=nothing shown, 1=clock overlay, 2=now playing tooltip
                property int idleMode: 0
                property bool showClock: idleMode === 1
                property bool showTooltip: idleMode === 2

                MouseArea {
                    id: idlePillMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onEntered: { hideTimer.stop(); barVisible = true }
                    onExited: hideTimer.start()
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.RightButton) {
                            if (pill.musicPlaying)
                                clockItem.idleMode = (clockItem.idleMode + 1) % 3
                            else
                                clockItem.idleMode = clockItem.idleMode === 1 ? 0 : 1
                        } else {
                            pill.islandState = "hub"
                        }
                    }
                }

                // Full-pill cava bars
                Canvas {
                    id: idleCavaCanvas
                    anchors.fill: parent
                    opacity: pill.musicPlaying ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 400 } }
                    property var bars: []
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        var data = bars
                        if (data.length === 0) return
                        var count = Math.min(data.length, 36)
                        var barW = 3
                        var gap = 2
                        var offsetX = (width - (count * barW + (count - 1) * gap)) / 2
                        for (var i = 0; i < count; i++) {
                            var val = data[i] / 100
                            var barH = Math.max(4, val * height)
                            var x = offsetX + i * (barW + gap)
                            var y = height - barH
                            ctx.beginPath()
                            ctx.rect(x, y, barW, barH)
                            ctx.fillStyle = Theme.accent
                            ctx.globalAlpha = 0.4 + val * 0.6
                            ctx.fill()
                            ctx.globalAlpha = 1.0
                        }
                    }
                }

                // Clock — always shown when no music, overlaid on hover/right-click
                Item {
                    anchors.centerIn: parent
                    opacity: (!pill.musicPlaying || clockItem.showClock || idlePillMouseArea.containsMouse) ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                    width: clockRow.width
                    height: clockRow.height

                    Row {
                        id: clockRow
                        spacing: 0

                        Text {
                            id: hoursText
                            color: Theme.text; font.pixelSize: 18; font.family: "JetBrains Mono"
                            text: Qt.formatTime(new Date(), "hh")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            id: colonText
                            color: Theme.text; font.pixelSize: 18; font.family: "JetBrains Mono"
                            text: ":"
                            anchors.verticalCenter: parent.verticalCenter
                            SequentialAnimation on opacity {
                                running: true; loops: Animation.Infinite
                                NumberAnimation { to: 0.1; duration: 500 }
                                NumberAnimation { to: 1.0; duration: 500 }
                            }
                        }
                        Text {
                            id: minutesText
                            color: Theme.text; font.pixelSize: 18; font.family: "JetBrains Mono"
                            text: Qt.formatTime(new Date(), "mm")
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Canvas {
                            id: secondsArc
                            width: 16; height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            property int seconds: 0
                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                var cx = width/2, cy = height/2, r = width/2 - 2
                                ctx.beginPath(); ctx.arc(cx,cy,r,0,Math.PI*2)
                                ctx.strokeStyle = "#222222"; ctx.lineWidth = 1.5; ctx.stroke()
                                ctx.beginPath()
                                ctx.arc(cx,cy,r,-Math.PI/2,-Math.PI/2+(Math.PI*2*seconds/60))
                                ctx.strokeStyle = Theme.accent; ctx.lineWidth = 1.5; ctx.lineCap = "round"; ctx.stroke()
                            }
                        }
                    }
                }

                Timer {
                    id: clockTimer; interval: 1000; running: true; repeat: true
                    onTriggered: {
                        var now = new Date()
                        hoursText.text = Qt.formatTime(now, "hh")
                        minutesText.text = Qt.formatTime(now, "mm")
                        secondsArc.seconds = now.getSeconds()
                        secondsArc.requestPaint()
                    }
                }
            }

            // ── Hub ────────────────────────────────────────────────────────
            Row {
                anchors.centerIn: parent
                spacing: 12
                opacity: pill.islandState === "hub" ? 1 : 0
                visible: opacity > 0
                Keys.onEscapePressed: pill.closeToIdle()
                Behavior on opacity { NumberAnimation { duration: 150 } }


                Rectangle {
                    width: 52; height: 52; radius: 14
                    color: mediaHover.containsMouse ? Theme.surfaceHover : Theme.background
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "󰝚"; font.pixelSize: 24; font.family: "JetBrains Mono"; color: Theme.text }
                    MouseArea { id: mediaHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pill.islandState = "media" }
                }

                Rectangle {
                    width: 52; height: 52; radius: 14
                    color: notifHover.containsMouse ? Theme.surfaceHover : Theme.background
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "󰂚"; font.pixelSize: 24; font.family: "JetBrains Mono"; color: Theme.text }
                    MouseArea { id: notifHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pill.islandState = "notifications" }
                }

                // ── Stats button (new) ────────────────────────────────────
                Rectangle {
                    width: 52; height: 52; radius: 14
                    color: statsHover.containsMouse ? Theme.surfaceHover : Theme.background
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "󰄧"; font.pixelSize: 24; font.family: "JetBrains Mono"; color: Theme.text }
                    MouseArea { id: statsHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pill.islandState = "stats" }
                }

                Rectangle {
                    width: 52; height: 52; radius: 14
                    color: toggleHover.containsMouse ? Theme.surfaceHover : Theme.background
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text {
                        id: toggleIcon; anchors.centerIn: parent; text: "󰡰"
                        font.pixelSize: 24; font.family: "JetBrains Mono"
                        color: sidepillsVisible ? Theme.accent : Theme.subtext
                        Behavior on color { ColorAnimation { duration: 200 } }
                        rotation: sidepillsVisible ? 0 : 180
                        Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.3 } }
                    }
                    MouseArea { id: toggleHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sidepillsVisible = !sidepillsVisible }
                }

                Rectangle {
                    width: 52; height: 52; radius: 14
                    color: powerHover.containsMouse ? Theme.dangerHover : Theme.dangerBg
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "󰐥"; font.pixelSize: 24; font.family: "JetBrains Mono"; color: Theme.danger }
                    MouseArea { id: powerHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pill.islandState = "power" }
                }
            }

            // ── Stats panel ────────────────────────────────────────────────
            Item {
                id: statsPanel
                anchors.fill: parent
                anchors.margins: 14
                opacity: pill.islandState === "stats" ? 1 : 0
                visible: opacity > 0
                focus: true
                Keys.onEscapePressed: pill.closeToIdle()
                Behavior on opacity { NumberAnimation { duration: 150 } }

                // Rolling history arrays — 60 samples each
                property var cpuHistory: []
                property var ramHistory: []
                property int maxSamples: 60

                // These are fed by the existing statsWindow processes
                // We just mirror the values here
                property real cpuVal: statsPill.cpuPercent
                property real ramVal: statsPill.ramPercent

                onCpuValChanged: {
                    var h = [...cpuHistory, cpuVal]
                    if (h.length > maxSamples) h.shift()
                    cpuHistory = h
                    cpuGraph.requestPaint()
                }
                onRamValChanged: {
                    var h = [...ramHistory, ramVal]
                    if (h.length > maxSamples) h.shift()
                    ramHistory = h
                    ramGraph.requestPaint()
                }

                Column {
                    anchors.fill: parent
                    spacing: 10

                    // ── Header row ──────────────────────────────────────────
                    Row {
                        width: parent.width
                        Text {
                            text: "system"
                            color: Theme.subtext; font.pixelSize: 11; font.family: "JetBrains Mono"
                            width: parent.width - 20
                        }
                        Text {
                            text: "✕"
                            color: closeStatsHover.containsMouse ? Theme.danger : Theme.subtext
                            font.pixelSize: 11; font.family: "JetBrains Mono"
                            Behavior on color { ColorAnimation { duration: 100 } }
                            MouseArea { id: closeStatsHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pill.closeToIdle() }
                        }
                    }

                    // ── CPU graph ───────────────────────────────────────────
                    Column {
                        width: parent.width
                        spacing: 3

                        Row {
                            width: parent.width
                            Text {
                                text: "cpu"
                                color: Theme.subtext; font.pixelSize: 10; font.family: "JetBrains Mono"
                                width: parent.width - 32
                            }
                            Text {
                                text: Math.round(statsPill.cpuPercent) + "%"
                                color: Theme.accent; font.pixelSize: 10; font.family: "JetBrains Mono"
                                horizontalAlignment: Text.AlignRight
                                width: 32
                            }
                        }

                        Canvas {
                            id: cpuGraph
                            width: parent.width
                            height: 52
                            property var history: statsPanel.cpuHistory
                            property string lineColor: Theme.accent

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                var data = statsPanel.cpuHistory
                                if (data.length < 2) return

                                var w = width, h = height
                                var step = w / (statsPanel.maxSamples - 1)

                                // Filled area
                                ctx.beginPath()
                                ctx.moveTo(0, h)
                                for (var i = 0; i < data.length; i++) {
                                    var x = (statsPanel.maxSamples - data.length + i) * step
                                    var y = h - (data[i] / 100) * (h - 4)
                                    if (i === 0) ctx.lineTo(x, y)
                                    else ctx.lineTo(x, y)
                                }
                                ctx.lineTo((statsPanel.maxSamples - 1) * step, h)
                                ctx.closePath()
                                ctx.fillStyle = Theme.accent
                                ctx.globalAlpha = 0.12
                                ctx.fill()
                                ctx.globalAlpha = 1.0

                                // Line
                                ctx.beginPath()
                                for (var j = 0; j < data.length; j++) {
                                    var lx = (statsPanel.maxSamples - data.length + j) * step
                                    var ly = h - (data[j] / 100) * (h - 4)
                                    if (j === 0) ctx.moveTo(lx, ly)
                                    else ctx.lineTo(lx, ly)
                                }
                                ctx.strokeStyle = Theme.accent
                                ctx.lineWidth = 1.5
                                ctx.lineJoin = "round"
                                ctx.lineCap = "round"
                                ctx.stroke()

                                // 50% gridline
                                ctx.beginPath()
                                ctx.moveTo(0, h * 0.5)
                                ctx.lineTo(w, h * 0.5)
                                ctx.strokeStyle = Theme.border
                                ctx.lineWidth = 0.5
                                ctx.setLineDash([3, 4])
                                ctx.stroke()
                                ctx.setLineDash([])
                            }
                        }
                    }

                    // ── RAM graph ───────────────────────────────────────────
                    Column {
                        width: parent.width
                        spacing: 3

                        Row {
                            width: parent.width
                            Text {
                                text: "ram"
                                color: Theme.subtext; font.pixelSize: 10; font.family: "JetBrains Mono"
                                width: parent.width - 32
                            }
                            Text {
                                text: Math.round(statsPill.ramPercent) + "%"
                                color: Theme.accentAlt; font.pixelSize: 10; font.family: "JetBrains Mono"
                                horizontalAlignment: Text.AlignRight
                                width: 32
                            }
                        }

                        Canvas {
                            id: ramGraph
                            width: parent.width
                            height: 52

                            onPaint: {
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                var data = statsPanel.ramHistory
                                if (data.length < 2) return

                                var w = width, h = height
                                var step = w / (statsPanel.maxSamples - 1)

                                ctx.beginPath()
                                ctx.moveTo(0, h)
                                for (var i = 0; i < data.length; i++) {
                                    var x = (statsPanel.maxSamples - data.length + i) * step
                                    var y = h - (data[i] / 100) * (h - 4)
                                    if (i === 0) ctx.lineTo(x, y)
                                    else ctx.lineTo(x, y)
                                }
                                ctx.lineTo((statsPanel.maxSamples - 1) * step, h)
                                ctx.closePath()
                                ctx.fillStyle = Theme.accentAlt
                                ctx.globalAlpha = 0.12
                                ctx.fill()
                                ctx.globalAlpha = 1.0

                                ctx.beginPath()
                                for (var j = 0; j < data.length; j++) {
                                    var lx = (statsPanel.maxSamples - data.length + j) * step
                                    var ly = h - (data[j] / 100) * (h - 4)
                                    if (j === 0) ctx.moveTo(lx, ly)
                                    else ctx.lineTo(lx, ly)
                                }
                                ctx.strokeStyle = Theme.accentAlt
                                ctx.lineWidth = 1.5
                                ctx.lineJoin = "round"
                                ctx.lineCap = "round"
                                ctx.stroke()

                                ctx.beginPath()
                                ctx.moveTo(0, h * 0.5)
                                ctx.lineTo(w, h * 0.5)
                                ctx.strokeStyle = Theme.border
                                ctx.lineWidth = 0.5
                                ctx.setLineDash([3, 4])
                                ctx.stroke()
                                ctx.setLineDash([])
                            }
                        }
                    }
                }
            }

            // ── Power ──────────────────────────────────────────────────────
            Row {
                anchors.centerIn: parent
                spacing: 12
                opacity: pill.islandState === "power" ? 1 : 0
                visible: opacity > 0
                Keys.onEscapePressed: pill.closeToIdle()
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Rectangle {
                    width: 52; height: 52; radius: 14
                    color: lockHover.containsMouse ? Theme.surfaceHover : Theme.background
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "󰌾"; font.pixelSize: 24; font.family: "JetBrains Mono"; color: Theme.text }
                    MouseArea {
                        id: lockHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { lockProc.running = true; pill.closeToIdle() }
                    }
                }
                Rectangle {
                    width: 52; height: 52; radius: 14
                    color: suspendHover.containsMouse ? Theme.surfaceHover : Theme.background
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "󰤄"; font.pixelSize: 24; font.family: "JetBrains Mono"; color: Theme.text }
                    MouseArea {
                        id: suspendHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { suspendProc.running = true; pill.closeToIdle() }
                    }
                }
                Rectangle {
                    width: 52; height: 52; radius: 14
                    color: rebootHover.containsMouse ? Theme.surfaceHover : Theme.background
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "󰑓"; font.pixelSize: 24; font.family: "JetBrains Mono"; color: Theme.text }
                    MouseArea {
                        id: rebootHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { rebootProc.running = true; pill.closeToIdle() }
                    }
                }
                Rectangle {
                    width: 52; height: 52; radius: 14
                    color: shutdownHover.containsMouse ? Theme.dangerHover : Theme.dangerBg
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Text { anchors.centerIn: parent; text: "󰐥"; font.pixelSize: 24; font.family: "JetBrains Mono"; color: Theme.danger }
                    MouseArea {
                        id: shutdownHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: { poweroffProc.running = true; pill.closeToIdle() }
                    }
                }
            }

            // ── Media ──────────────────────────────────────────────────────
            Item {
                anchors.fill: parent
                anchors.margins: 12
                opacity: pill.islandState === "media" ? 1 : 0
                visible: opacity > 0
                Keys.onEscapePressed: pill.closeToIdle()
                Behavior on opacity { NumberAnimation { duration: 150 } }

                Item {
                    id: artContainer
                    width: 80; height: 80
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    Canvas {
                        id: vizCanvas
                        anchors.centerIn: parent
                        width: 80; height: 80
                        property var bars: []
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.clearRect(0, 0, width, height)
                            var cx = width/2, cy = height/2, innerR = 32, maxBarH = 10
                            var count = bars.length
                            if (count === 0) return
                            for (var i = 0; i < count; i++) {
                                var angle = (i / count) * Math.PI * 2 - Math.PI / 2
                                var val = bars[i] / 100
                                var barH = val * maxBarH + 2
                                var x1 = cx + Math.cos(angle) * innerR
                                var y1 = cy + Math.sin(angle) * innerR
                                var x2 = cx + Math.cos(angle) * (innerR + barH)
                                var y2 = cy + Math.sin(angle) * (innerR + barH)
                                ctx.beginPath(); ctx.moveTo(x1,y1); ctx.lineTo(x2,y2)
                                ctx.strokeStyle = val > 0.6 ? Theme.accent : val > 0.3 ? Theme.accentAlt : "#444466"
                                ctx.lineWidth = 2.5; ctx.lineCap = "round"; ctx.stroke()
                            }
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 58; height: 58; radius: 999
                        color: Theme.surfaceHover

                        Image {
                            id: albumArt; anchors.fill: parent
                            source: pill.musicArt; fillMode: Image.PreserveAspectCrop; visible: false
                        }
                        Rectangle { id: circleMask; anchors.fill: parent; radius: 999; visible: false }
                        OpacityMask { anchors.fill: parent; source: albumArt; maskSource: circleMask }
                        Text {
                            anchors.centerIn: parent; text: "♪"; color: Theme.accent
                            font.pixelSize: 22; visible: albumArt.status !== Image.Ready
                        }
                    }
                }

                Column {
                    anchors.left: artContainer.right
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 10
                    spacing: 6

                    Text {
                        width: parent.width
                        text: pill.musicTitle !== "" ? pill.musicTitle : "Nothing playing"
                        color: Theme.text; font.pixelSize: 13; font.family: "JetBrains Mono"; elide: Text.ElideRight
                    }
                    Text {
                        width: parent.width
                        text: pill.musicArtist
                        color: Theme.subtext; font.pixelSize: 11; font.family: "JetBrains Mono"; elide: Text.ElideRight
                    }
                    Row {
                        spacing: 16
                        Text {
                            text: "󰒮"; font.pixelSize: 18
                            color: prevBtn.containsMouse ? Theme.text : Theme.subtext
                            Behavior on color { ColorAnimation { duration: 100 } }
                            MouseArea { id: prevBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: prevProc.running = true }
                        }
                        Text {
                            text: pill.musicPlaying ? "" : ""; font.pixelSize: 19
                            color: playBtn.containsMouse ? Theme.accent : Theme.text
                            Behavior on color { ColorAnimation { duration: 100 } }
                            MouseArea {
                                id: playBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: { playProc.running = true; pill.musicPlaying = !pill.musicPlaying }
                            }
                        }
                        Text {
                            text: "󰒭"; font.pixelSize: 18
                            color: nextBtn.containsMouse ? Theme.text : Theme.subtext
                            Behavior on color { ColorAnimation { duration: 100 } }
                            MouseArea { id: nextBtn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: nextProc.running = true }
                        }
                    }
                }
            }

            // ── Wallpaper ──────────────────────────────────────────────────
            Column {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8
                opacity: pill.islandState === "wallpaper" ? 1 : 0
                visible: opacity > 0
                Keys.onEscapePressed: pill.closeToIdle()
                Behavior on opacity { NumberAnimation { duration: 150 } }

                onVisibleChanged: {
                    if (visible) { pill.wallpaperList = []; lsProc.running = true }
                }

                Text { text: "Wallpapers"; color: Theme.subtext; font.pixelSize: 11; font.family: "JetBrains Mono" }

                GridView {
                    id: wpGrid
                    width: parent.width
                    height: parent.height - 20
                    clip: true
                    cellWidth: Math.floor(parent.width / 3)
                    cellHeight: 80
                    model: pill.wallpaperList

                    delegate: Item {
                        width: wpGrid.cellWidth; height: wpGrid.cellHeight
                        required property var modelData

                        Item {
                            anchors.fill: parent; anchors.margins: 3

                            Image {
                                id: wpThumb
                                anchors.centerIn: parent
                                width: wpThumbHover.containsMouse ? parent.width : parent.width - 6
                                height: wpThumbHover.containsMouse ? parent.height : parent.height - 6
                                source: "file://" + modelData
                                fillMode: Image.PreserveAspectCrop; asynchronous: true
                                Behavior on width  { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            }
                            Rectangle {
                                anchors.fill: wpThumb; color: "transparent"
                                border.color: wpThumbHover.containsMouse ? Theme.accent : "transparent"
                                border.width: 2
                            }
                            MouseArea {
                                id: wpThumbHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    awwwProc.command = [Config.wallpaperCmd, modelData]
                                    awwwProc.running = true
                                    walProc.command = ["wal", "-i", modelData, "-n"]
                                    walProc.running = true
                                    pill.closeToIdle()
                                }
                            }
                        }
                    }
                }
            }

            // ── Launcher ───────────────────────────────────────────────────
            Column {
                anchors.fill: parent; anchors.margins: 12
                spacing: 8
                opacity: pill.islandState === "launcher" ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 150 } }

                onVisibleChanged: {
                    if (visible) { searchInput.text = ""; searchInput.forceActiveFocus() }
                }

                Rectangle {
                    width: parent.width; height: 36; radius: 8; color: Theme.surfaceHover

                    TextInput {
                        id: searchInput
                        focus: true
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 12 }
                        color: Theme.text; font.pixelSize: 14; font.family: "JetBrains Mono"; clip: true

                        Text {
                            anchors.fill: parent; text: "Search..."; color: Theme.subtext
                            font.pixelSize: 14; font.family: "JetBrains Mono"
                            visible: searchInput.text.length === 0
                        }

                        Keys.onEscapePressed: pill.closeToIdle()
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Up) {
                                if (appList.currentIndex > 0) appList.currentIndex--
                                event.accepted = true
                            } else if (event.key === Qt.Key_Down) {
                                if (appList.currentIndex < appList.count - 1) appList.currentIndex++
                                event.accepted = true
                            } else if (event.key === Qt.Key_Return) {
                                var item = appList.currentItem
                                if (item && item.entry) { item.entry.execute(); pill.closeToIdle() }
                                event.accepted = true
                            }
                        }
                    }
                }

                ListView {
                    id: appList
                    width: parent.width; height: parent.height - 36 - 8
                    clip: true; currentIndex: 0
                    Keys.onEscapePressed: pill.closeToIdle()
                    focus: true

                    model: ScriptModel {
                        values: {
                            const all = [...DesktopEntries.applications.values]
                            const q = searchInput.text.trim().toLowerCase()
                            return q === "" ? all : all.filter(d => d.name && d.name.toLowerCase().includes(q))
                        }
                    }

                    highlight: Rectangle { radius: 6; color: Theme.highlight }
                    highlightMoveDuration: 100

                    delegate: Item {
                        id: delegateItem
                        required property var modelData
                        required property int index
                        property var entry: modelData
                        width: appList.width; height: 40

                        MouseArea {
                            anchors.fill: parent
                            onClicked: appList.currentIndex = delegateItem.index
                            onDoubleClicked: { delegateItem.entry.execute(); pill.closeToIdle() }
                        }

                        Row {
                            anchors.fill: parent; anchors.leftMargin: 8; anchors.rightMargin: 8; spacing: 10
                            IconImage {
                                anchors.verticalCenter: parent.verticalCenter
                                source: Quickshell.iconPath(modelData.icon, true)
                                width: 22; height: 22
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                color: Theme.text; font.pixelSize: 13; font.family: "JetBrains Mono"
                                text: modelData.name ?? ""; elide: Text.ElideRight
                            }
                        }
                    }
                }
            }

            // ── Notifications ──────────────────────────────────────────────
            Item {
                anchors.fill: parent
                opacity: pill.islandState === "notifications" ? 1 : 0
                visible: opacity > 0
                focus: true
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Keys.onEscapePressed: pill.closeToIdle()

                Column {
                    id: notifPanel
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Row {
                        width: parent.width
                        Text {
                            text: "Notifications"
                            color: Theme.text; font.pixelSize: 13; font.family: "JetBrains Mono"
                            width: parent.width - 40
                        }
                        Text {
                            text: "clear"
                            color: clearAllHover.containsMouse ? Theme.danger : Theme.subtext
                            font.pixelSize: 10; font.family: "JetBrains Mono"
                            Behavior on color { ColorAnimation { duration: 100 } }
                            MouseArea { id: clearAllHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pill.notificationList = [] }
                        }
                    }

                    Text {
                        visible: pill.notificationList.length === 0
                        text: "no notifications"
                        color: Theme.subtext; font.pixelSize: 12; font.family: "JetBrains Mono"
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                    }

                    ListView {
                        width: parent.width
                        height: notifPanel.height - 50
                        clip: true
                        spacing: 6
                        model: pill.notificationList
                        verticalLayoutDirection: ListView.BottomToTop

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: notifCol.implicitHeight + 16
                            radius: 10
                            color: Theme.surfaceHover
                            required property var modelData
                            required property int index
                            property int notifIndex: index

                            Column {
                                id: notifCol
                                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10; rightMargin: 28 }
                                spacing: 3

                                Text {
                                    text: modelData.summary || modelData.appName || "notification"
                                    color: Theme.text; font.pixelSize: 12; font.family: "JetBrains Mono"
                                    width: parent.width; elide: Text.ElideRight
                                    font.weight: Font.Medium
                                }
                                Text {
                                    visible: modelData.body !== ""
                                    text: modelData.body
                                    color: Theme.subtext; font.pixelSize: 11; font.family: "JetBrains Mono"
                                    width: parent.width; wrapMode: Text.WordWrap
                                    maximumLineCount: 3; elide: Text.ElideRight
                                }
                            }

                            Text {
                                text: "✕"; font.pixelSize: 10
                                color: dismissHover.containsMouse ? Theme.danger : Theme.subtext
                                anchors { right: parent.right; top: parent.top; margins: 8 }
                                Behavior on color { ColorAnimation { duration: 100 } }
                                MouseArea {
                                    id: dismissHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: pill.notificationList = pill.notificationList.filter((_, i) => i !== notifIndex)
                                }
                            }
                        }
                    }
                }
            }

            // ── Recorder ──────────────────────────────────────────────────
            Item {
                anchors.fill: parent
                anchors.margins: 12
                opacity: pill.islandState === "recorder" ? 1 : 0
                visible: opacity > 0
                focus: true
                Behavior on opacity { NumberAnimation { duration: 150 } }
                Keys.onEscapePressed: pill.closeToIdle()

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Rectangle {
                        width: 52; height: 52; radius: 14
                        color: Theme.surfaceHover
                        opacity: 0.5
                        Text {
                            anchors.centerIn: parent
                            text: "⏺"
                            font.pixelSize: 22
                            color: Theme.subtext
                        }
                        MouseArea {
                            id: recStartHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.ArrowCursor
                        }
                    }

                    Column {
                        spacing: 4
                        Text {
                            text: "unavailable"
                            color: Theme.subtext
                            font.pixelSize: 13; font.family: "JetBrains Mono"
                        }
                        Text {
                            text: "install wf-recorder"
                            color: Theme.subtext
                            font.pixelSize: 10; font.family: "JetBrains Mono"
                        }
                    }
                }
            }
        }
    }

    // ── Stats pill ─────────────────────────────────────────────────────────
    WlrLayershell {
        id: statsWindow
        anchors.top: true
        anchors.left: true
        implicitWidth: 120
        implicitHeight: 58
        color: "transparent"
        exclusiveZone: 0

        property bool containsMouse_: statsPillArea.containsMouse

        mask: Region { item: statsPill }

        margins {
            left: cx + pill.width / 2 + sideGap - 10
            top: (!barVisible || !sidepillsVisible) ? -60 : 0
        }

        Behavior on margins.top {
            NumberAnimation { duration: 400; easing.type: Easing.OutBack; easing.overshoot: 1.3 }
        }
        Behavior on margins.left {
            NumberAnimation { duration: 0 }
        }

        MouseArea {
            id: statsPillArea
            anchors.fill: parent
            hoverEnabled: true
            propagateComposedEvents: true
            onEntered: { hideTimer.stop(); barVisible = true }
            onExited: hideTimer.start()
            onPressed: function(mouse) { mouse.accepted = false }
        }

        Rectangle {
            id: statsPill
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 12

            width: 100; height: 34; radius: 999
            color: Theme.surface
            border.color: Theme.border
            border.width: 1

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 4
                radius: 12
                samples: 25
                color: "#60000000"
            }

            property real cpuPercent: 0
            property real ramPercent: 0
            property int batteryPercent: 0
            property bool batteryCharging: false
            property bool batteryPluggedNotCharging: false
            property string batteryStatus: ""

            // ── Weather properties ─────────────────────────────────────────
            property real weatherTemp: 0
            property string weatherIcon: "󰼯"   // fallback: partly cloudy

            // WMO code → Nerd Font weather icon
            function weatherCodeToIcon(code) {
                if (code === 0)              return "󰖙"   // clear
                if (code <= 2)              return "󰖕"   // mainly clear / partly cloudy
                if (code === 3)             return "󰖔"   // overcast
                if (code <= 49)             return "󰖑"   // fog
                if (code <= 55)             return "󰖗"   // drizzle
                if (code <= 65)             return "󰖖"   // rain
                if (code <= 77)             return "󰼻"   // snow
                if (code <= 82)             return "󰖖"   // rain showers
                if (code <= 86)             return "󰼻"   // snow showers
                if (code <= 99)             return "󰖓"   // thunderstorm
                return "󰼯"
            }

            Row {
                anchors.centerIn: parent
                spacing: 10

                // ── Weather (replaces old CPU arc) ─────────────────────────
                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: statsPill.weatherIcon
                        font.pixelSize: 14
                        font.family: "JetBrains Mono"
                        color: Theme.accent
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(statsPill.weatherTemp) + "°"
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                        color: Theme.text
                    }
                }

                // ── Battery ────────────────────────────────────────────────
                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    width: batteryRow.width
                    height: batteryRow.height

                    Row {
                        id: batteryRow
                        spacing: 3

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (statsPill.batteryCharging) return "󰂄"
                                if (statsPill.batteryPluggedNotCharging) return "󰚥"
                                var p = statsPill.batteryPercent
                                if (p >= 90) return "󰁹"
                                if (p >= 70) return "󰂀"
                                if (p >= 50) return "󰁾"
                                if (p >= 30) return "󰁼"
                                if (p >= 10) return "󰁺"
                                return "󰂃"
                            }
                            font.pixelSize: 14
                            font.family: "JetBrains Mono"
                            color: statsPill.batteryPercent <= 20 && !statsPill.batteryCharging && !statsPill.batteryPluggedNotCharging ? Theme.danger : Theme.accentAlt
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: statsPill.batteryPercent + "%"
                            font.pixelSize: 11
                            font.family: "JetBrains Mono"
                            color: Theme.text
                        }
                    }

                    ToolTip {
                        visible: batteryMouseArea.containsMouse
                        delay: 300
                        y: parent.height + 6
                        text: statsPill.batteryStatus
                        background: Rectangle { color: Theme.surface; radius: 6 }
                        contentItem: Text {
                            text: statsPill.batteryStatus
                            color: Theme.text; font.pixelSize: 11; font.family: "JetBrains Mono"
                        }
                    }

                    MouseArea {
                        id: batteryMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                }
            }
        }

        property real prevIdle: 0
        property real prevTotal: 0

        Process {
            id: cpuProc
            command: ["bash", "-c", "head -1 /proc/stat"]
            running: true
            stdout: SplitParser {
                onRead: function(line) {
                    var parts = line.trim().split(/\s+/)
                    var user = parseFloat(parts[1]), nice = parseFloat(parts[2])
                    var system = parseFloat(parts[3]), idle = parseFloat(parts[4])
                    var iowait = parseFloat(parts[5]), irq = parseFloat(parts[6]), softirq = parseFloat(parts[7])
                    var total = user + nice + system + idle + iowait + irq + softirq
                    var diffIdle = idle - statsWindow.prevIdle
                    var diffTotal = total - statsWindow.prevTotal
                    if (diffTotal > 0) statsPill.cpuPercent = Math.round((1 - diffIdle / diffTotal) * 100)
                    statsWindow.prevIdle = idle
                    statsWindow.prevTotal = total
                }
            }
        }

        Process {
            id: ramProc
            command: ["bash", "-c", "free | grep Mem"]
            running: true
            stdout: SplitParser {
                onRead: function(line) {
                    var parts = line.trim().split(/\s+/)
                    // parts[1]=total, parts[2]=used, parts[6]=available
                    // Use (total - available) to exclude cache/buffers
                    var total = parseFloat(parts[1])
                    var available = parseFloat(parts[6])
                    if (total > 0) statsPill.ramPercent = Math.round(((total - available) / total) * 100)
                }
            }
        }

        Process {
            id: batteryProc
            command: ["bash", "-c", "bat=$(ls /sys/class/power_supply/ | grep -E '^BAT' | head -1); [ -n \"$bat\" ] && paste <(cat /sys/class/power_supply/$bat/capacity) <(cat /sys/class/power_supply/$bat/status)"]
            running: true
            stdout: SplitParser {
                onRead: function(line) {
                    var parts = line.trim().split("\t")
                    var pct = parseInt(parts[0])
                    var status = (parts[1] || "").trim()
                    if (!isNaN(pct)) statsPill.batteryPercent = pct
                    var displayStatus = (status === "Not charging" || status === "Full") ? "Plugged" : status
                    statsPill.batteryStatus = statsPill.batteryPercent + "% · " + displayStatus
                    statsPill.batteryCharging = (status === "Charging")
                    statsPill.batteryPluggedNotCharging = (status === "Full" || status === "Not charging")
                }
            }
        }

        // ── Weather fetch (Open-Meteo, auto-detect location via ipinfo.io) ──
        Process {
            id: weatherProc
            command: ["bash", "-c",
                "loc=$(curl -sf 'https://ipinfo.io/loc' 2>/dev/null); lat=$(echo \"$loc\" | cut -d',' -f1); lon=$(echo \"$loc\" | cut -d',' -f2); curl -sf \"https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,weathercode&temperature_unit=celsius&forecast_days=1\" 2>/dev/null"]
            running: false
            stdout: SplitParser {
                onRead: function(line) {
                    try {
                        var json = JSON.parse(line.trim())
                        var cur = json.current
                        if (cur) {
                            statsPill.weatherTemp = cur.temperature_2m
                            statsPill.weatherIcon = statsPill.weatherCodeToIcon(cur.weathercode)
                        }
                    } catch(e) {}
                }
            }
        }

        Timer {
            interval: 2000; running: true; repeat: true
            onTriggered: { cpuProc.running = true; ramProc.running = true; batteryProc.running = true }
        }

        // Fetch weather on startup, then every 10 minutes
        Timer {
            interval: 600000; running: true; repeat: true
            triggeredOnStart: true
            onTriggered: weatherProc.running = true
        }
    }

    // ── Now playing tooltip ────────────────────────────────────────────────
    // Toggled by right-clicking the idle pill (cycles: nothing → clock → tooltip)
    WlrLayershell {
        id: nowPlayingTooltip
        anchors.top: true
        anchors.left: true
        implicitWidth: 320
        implicitHeight: 120
        color: "transparent"
        exclusiveZone: 0
        layer: WlrLayer.Overlay

        margins {
            left: cx - nowPlayingTooltip.implicitWidth / 2
            top: 58
        }

        visible: (pill.musicPlaying && pill.islandState === "idle" && clockItem.showTooltip) || tooltipCard.opacity > 0

        Rectangle {
            id: tooltipCard
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 4
            width: 300
            height: tooltipContent.implicitHeight + 20
            radius: 16
            color: Theme.surface
            border.color: Theme.border
            border.width: 1
            opacity: pill.musicPlaying && pill.islandState === "idle" && clockItem.showTooltip ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 4
                radius: 16
                samples: 33
                color: "#80000000"
            }

            Row {
                id: tooltipContent
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 12

                Rectangle {
                    width: 52; height: 52; radius: 8
                    color: Theme.surfaceHover
                    anchors.verticalCenter: parent.verticalCenter
                    clip: true
                    Image {
                        id: tooltipArt
                        anchors.fill: parent
                        source: pill.musicArt
                        fillMode: Image.PreserveAspectCrop
                        visible: status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent; text: "♪"; color: Theme.accent
                        font.pixelSize: 20
                        visible: tooltipArt.status !== Image.Ready
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 52 - 12
                    spacing: 6

                    Text {
                        width: parent.width
                        text: pill.musicTitle !== "" ? pill.musicTitle : "Unknown"
                        color: Theme.text; font.pixelSize: 13; font.family: "JetBrains Mono"
                        elide: Text.ElideRight; font.weight: Font.Medium
                    }
                    Text {
                        width: parent.width
                        text: pill.musicArtist
                        color: Theme.subtext; font.pixelSize: 11; font.family: "JetBrains Mono"
                        elide: Text.ElideRight
                    }

                    Item {
                        width: parent.width; height: 4
                        Rectangle { anchors.fill: parent; radius: 2; color: Theme.surfaceHover }
                        Rectangle {
                            width: pill.musicLength > 0 ? Math.min(parent.width, (pill.musicPosition / pill.musicLength) * parent.width) : 0
                            height: parent.height; radius: 2; color: Theme.accent
                            Behavior on width { NumberAnimation { duration: 800 } }
                        }
                    }

                    Row {
                        width: parent.width
                        Text {
                            id: posLabel
                            text: { var s = Math.floor(pill.musicPosition); return Math.floor(s/60) + ":" + String(s%60).padStart(2,"0") }
                            color: Theme.subtext; font.pixelSize: 9; font.family: "JetBrains Mono"
                        }
                        Item { width: parent.width - posLabel.width - durLabel.width; height: 1 }
                        Text {
                            id: durLabel
                            text: { var s = Math.floor(pill.musicLength); return Math.floor(s/60) + ":" + String(s%60).padStart(2,"0") }
                            color: Theme.subtext; font.pixelSize: 9; font.family: "JetBrains Mono"
                        }
                    }
                }
            }
        }
    }

    // ── Theme picker overlay ───────────────────────────────────────────────
    // Triggered via: qs ipc call island openThemePicker
    // Bind that command to a key in hyprland.conf
    WlrLayershell {
        id: themePicker
        anchors.top: true
        anchors.left: true
        implicitWidth: screenW
        implicitHeight: screenH
        color: "transparent"
        exclusiveZone: 0
        layer: WlrLayer.Overlay
        keyboardFocus: WlrKeyboardFocus.Exclusive
        visible: false

        // Dismiss on click outside the card or Escape key
        MouseArea {
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: themePicker.visible = false
            onClicked: themePicker.visible = false
        }

        // Centered card
        Rectangle {
            id: themeCard
            anchors.centerIn: parent
            width: 420
            height: themeCol.implicitHeight + 28
            radius: 20
            color: Theme.surface
            border.color: Theme.border
            border.width: 1

            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                horizontalOffset: 0
                verticalOffset: 8
                radius: 24
                samples: 49
                color: "#90000000"
            }

            // Swallow clicks so they don't propagate to the dismiss area
            MouseArea { anchors.fill: parent }

            Column {
                id: themeCol
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 14
                spacing: 10

                // Header
                Row {
                    width: parent.width
                    Text {
                        text: "theme"
                        color: Theme.subtext; font.pixelSize: 11; font.family: "JetBrains Mono"
                        width: parent.width - 52
                    }

                    // Pin toggle
                    Rectangle {
                        width: 28; height: 18; radius: 999
                        color: pinned ? Theme.accent : Theme.surfaceHover
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            width: 12; height: 12; radius: 999
                            color: pinned ? Theme.background : Theme.subtext
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: pinned ? 14 : 2
                            Behavior on anchors.leftMargin { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                pinned = !pinned
                                if (pinned) barVisible = true
                            }
                        }
                    }

                    // Spacer
                    Item { width: 8; height: 1 }

                    Text {
                        text: "✕"
                        color: themeCloseHover.containsMouse ? Theme.danger : Theme.subtext
                        font.pixelSize: 11; font.family: "JetBrains Mono"
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 100 } }
                        MouseArea {
                            id: themeCloseHover; anchors.fill: parent
                            hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: themePicker.visible = false
                        }
                    }
                }

                // Theme swatches grid
                Grid {
                    columns: 2
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: Theme.themes

                        Rectangle {
                            required property var modelData
                            property bool isActive: Theme.currentTheme === modelData.name
                            property bool hovered: themeItemHover.containsMouse

                            width: (themeCol.width - 8) / 2
                            height: 64
                            radius: 12
                            color: modelData.surface
                            border.color: isActive ? modelData.accent : (hovered ? modelData.subtext : modelData.border)
                            border.width: isActive ? 2 : 1

                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            Behavior on border.width { NumberAnimation { duration: 150 } }

                            // Mini color dot row
                            Row {
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom
                                anchors.margins: 10
                                spacing: 5

                                Repeater {
                                    model: [modelData.accent, modelData.accentAlt, modelData.danger, modelData.text]
                                    Rectangle {
                                        required property var modelData
                                        width: 8; height: 8; radius: 4
                                        color: modelData
                                    }
                                }
                            }

                            // Label
                            Text {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.margins: 10
                                text: modelData.label
                                color: modelData.text
                                font.pixelSize: 13; font.family: "JetBrains Mono"
                            }

                            // Active checkmark
                            Text {
                                visible: isActive
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 8
                                text: "✓"
                                color: modelData.accent
                                font.pixelSize: 11; font.family: "JetBrains Mono"
                            }

                            MouseArea {
                                id: themeItemHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Theme.setTheme(modelData.name)
                                    themePicker.visible = false
                                }
                            }
                        }
                    }
                }
            }
        }

    }
}
