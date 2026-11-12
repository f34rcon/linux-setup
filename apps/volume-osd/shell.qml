import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    property real volumeLevel: 0.65
    property bool muted: false
    property bool shown: false
    property var targetScreen: Quickshell.screens[0]

    function reveal() {
        const name = Hyprland.focusedMonitor
            ? Hyprland.focusedMonitor.name : ""

        targetScreen = Quickshell.screens.find(s => s.name === name)
            ?? Quickshell.screens[0]

        shown = true
        hideTimer.restart()
    }

    function updateVolume(percent, isMuted) {
        volumeLevel = Math.max(0, Math.min(100, percent)) / 100
        muted = isMuted
        reveal()
    }

    IpcHandler {
        target: "volume-osd"

        function showTest(): void {
            root.updateVolume(65, false)
        }

        function update(percent: int, isMuted: bool): void {
            root.updateVolume(percent, isMuted)
        }
    }

    Timer {
        id: hideTimer
        interval: 2000
        repeat: false
        onTriggered: root.shown = false
    }

    PanelWindow {
        id: window

        visible: root.shown
        screen: root.targetScreen

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "volume-osd"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Rectangle {
            id: panel

            width: 340
            height: 48
            anchors.centerIn: parent

            radius: 12
            color: "#e9101928"
            border.width: 1
            border.color: root.muted ? "#66ff555d" : "#5548baff"

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: 11
                color: "transparent"
                border.width: 1
                border.color: "#12ffffff"
            }

            Row {
                anchors {
                    fill: parent
                    leftMargin: 16
                    rightMargin: 16
                }

                spacing: 12

                Text {
                    width: 54
                    anchors.verticalCenter: parent.verticalCenter

                    text: root.muted ? "MUTED" : "VOLUME"
                    color: root.muted ? "#ff777d" : "#a9c8e8"
                    font.pixelSize: 10
                    font.bold: true
                    font.letterSpacing: 1
                }

                Item {
                    id: track

                    width: 208
                    height: 20
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: 5
                        color: "#26394e"
                    }

                    Rectangle {
                        width: track.width * root.volumeLevel
                        height: 17
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 5
                        color: root.muted ? "#55ff555d" : "#5548baff"
                    }

                    Rectangle {
                        width: track.width * root.volumeLevel
                        height: 8
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        radius: 4
                        color: root.muted ? "#ff555d" : "#48baff"
                    }
                }

                Text {
                    width: 34
                    anchors.verticalCenter: parent.verticalCenter

                    text: Math.round(root.volumeLevel * 100) + "%"
                    color: root.muted ? "#ff777d" : "#63baff"
                    font.pixelSize: 12
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
