import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

Rectangle {
    id: root
    property var notification: null

    width: 320
    height: contentCol.implicitHeight + 32
    radius: 16
    color: Theme.surface
    border.width: 1
    border.color: Theme.border

    // ── Clip so the card slides in from above without affecting layout ───────
    clip: false
    opacity: 1

    // Inner translate offset — animates the card into view without breaking Column layout
    property real slideOffset: -(height + 20)

    transform: Translate { y: root.slideOffset }

    Component.onCompleted: {
        slideIn.start()
        dismissTimer.start()
    }

    layer.enabled: true
    layer.effect: DropShadow {
        transparentBorder: true
        horizontalOffset: 0
        verticalOffset: 6
        radius: 20
        samples: 41
        color: "#90000000"
    }

    // ── Slide down from above ──────────────────────────────────────────────
    ParallelAnimation {
        id: slideIn
        NumberAnimation {
            target: root; property: "opacity"
            from: 0; to: 1
            duration: 400; easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root; property: "slideOffset"
            from: -(root.height + 20); to: 0
            duration: 480
            easing.type: Easing.OutBack
            easing.overshoot: 1.5
        }
    }

    // ── Slide back up to dismiss ───────────────────────────────────────────
    SequentialAnimation {
        id: slideOut
        ParallelAnimation {
            NumberAnimation {
                target: root; property: "opacity"
                from: 1; to: 0
                duration: 300; easing.type: Easing.InBack; easing.overshoot: 1.5
            }
            NumberAnimation {
                target: root; property: "slideOffset"
                from: 0; to: -(root.height + 20)
                duration: 300; easing.type: Easing.InBack; easing.overshoot: 1.5
            }
        }
        ScriptAction { script: root.destroy() }
    }

    // ── Auto dismiss ──────────────────────────────────────────────────────
    Timer {
        id: dismissTimer
        interval: 5000
        onTriggered: slideOut.start()
    }

    // ── Accent glow line at top ────────────────────────────────────────────
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        height: 2
        radius: 99
        color: Theme.accent
        opacity: 0.8
    }

    // ── Progress bar at bottom ─────────────────────────────────────────────
    Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 12
        anchors.bottomMargin: 8
        height: 2
        radius: 99
        color: Theme.surfaceHover

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width
            radius: 99
            color: Theme.accent
            opacity: 0.6

            NumberAnimation on width {
                from: parent.parent.width
                to: 0
                duration: 5000
                easing.type: Easing.Linear
                running: true
            }
        }
    }

    // ── Main content ───────────────────────────────────────────────────────
    Column {
        id: contentCol
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 16
            topMargin: 18
        }
        spacing: 8

        // ── Header row: icon + app name + dismiss ──────────────────────────
        Row {
            width: parent.width
            spacing: 8

            // App icon
            Item {
                width: 18; height: 18
                anchors.verticalCenter: parent.verticalCenter

                IconImage {
                    id: appIcon
                    anchors.fill: parent
                    source: root.notification ? Quickshell.iconPath(root.notification.appName, true) : ""
                    visible: status === IconImage.Ready
                }

                // Fallback — accent circle
                Rectangle {
                    anchors.fill: parent
                    radius: 99
                    color: Theme.accent
                    opacity: 0.8
                    visible: appIcon.status !== IconImage.Ready

                    Text {
                        anchors.centerIn: parent
                        text: root.notification ? (root.notification.appName || "?").charAt(0).toUpperCase() : "?"
                        font.pixelSize: 10
                        font.family: "JetBrains Mono"
                        font.bold: true
                        color: Theme.background
                    }
                }
            }

            // App name
            Text {
                text: root.notification ? (root.notification.appName || "notification").toLowerCase() : ""
                color: Theme.accent
                font.pixelSize: 10
                font.family: "JetBrains Mono"
                font.bold: true
                font.letterSpacing: 1
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 18 - 20 - 16
                elide: Text.ElideRight
            }

            // Dismiss button
            Text {
                text: "✕"
                color: dismissHover.containsMouse ? Theme.danger : Theme.subtext
                font.pixelSize: 10
                font.family: "JetBrains Mono"
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 100 } }
                MouseArea {
                    id: dismissHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: slideOut.start()
                }
            }
        }

        // ── Divider ────────────────────────────────────────────────────────
        Rectangle {
            width: parent.width
            height: 1
            color: Theme.border
            opacity: 0.5
        }

        // ── Summary ────────────────────────────────────────────────────────
        Text {
            width: parent.width
            text: root.notification ? root.notification.summary : ""
            color: Theme.text
            font.pixelSize: 13
            font.family: "JetBrains Mono"
            font.bold: true
            elide: Text.ElideRight
            visible: text !== ""
        }

        // ── Body ───────────────────────────────────────────────────────────
        Text {
            width: parent.width
            text: root.notification ? root.notification.body : ""
            color: Theme.subtext
            font.pixelSize: 11
            font.family: "JetBrains Mono"
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
            visible: text !== ""
            lineHeight: 1.4
            bottomPadding: 6
        }
    }

    // ── Hover pauses dismiss timer ─────────────────────────────────────────
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: dismissTimer.stop()
        onExited: dismissTimer.start()
        onClicked: slideOut.start()
    }
}
