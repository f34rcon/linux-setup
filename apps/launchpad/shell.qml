import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets

ShellRoot {
    id: root

    // Panel size as a fraction of the screen. Tweak to taste.
    readonly property real panelWidthFraction: 0.5
    readonly property real panelHeightFraction: 0.6

    property bool shown: false
    property var targetScreen: Quickshell.screens[0]
    property string query: ""
    property int sel: 0

    function setShown(v) {
        if (v) {
            const name = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
            targetScreen = Quickshell.screens.find(s => s.name === name) ?? Quickshell.screens[0]
            search.text = ""
            sel = 0
            appGrid.positionViewAtBeginning()
        }
        shown = v
        if (v) Qt.callLater(() => search.forceActiveFocus())
    }

    IpcHandler {
        target: "launchpad"
        function toggle(): void { root.setShown(!root.shown) }
        function show(): void { root.setShown(true) }
        function hide(): void { root.setShown(false) }
    }

    readonly property var allApps: {
        const seen = {}
        return DesktopEntries.applications.values
            .filter(e => {
                if (e.noDisplay || e.id === "launchpad") return false
                const k = e.name.toLowerCase()
                if (seen[k]) return false
                seen[k] = true
                return true
            })
            .sort((a, b) => a.name.localeCompare(b.name))
    }

    readonly property var results: {
        const q = query.trim().toLowerCase()
        if (!q) return allApps
        const score = e => {
            const n = e.name.toLowerCase()
            if (n.startsWith(q)) return 0
            if (n.includes(q)) return 1
            const rest = ((e.genericName || "") + " " + (e.comment || "") + " "
                          + (e.keywords || []).join(" ")).toLowerCase()
            return rest.includes(q) ? 2 : -1
        }
        return allApps.filter(e => score(e) >= 0)
                      .sort((a, b) => score(a) - score(b) || a.name.localeCompare(b.name))
    }

    function iconSource(icon) {
        const fallback = Quickshell.iconPath("application-x-executable", true)
        if (!icon) return fallback
        if (icon.startsWith("/")) return "file://" + icon
        return Quickshell.iconPath(icon, true) || fallback
    }

    function launch(entry) {
        if (!entry) return
        entry.execute()
        setShown(false)
    }

    function move(delta) {
        if (results.length === 0) return
        sel = Math.max(0, Math.min(results.length - 1, sel + delta))
        appGrid.positionViewAtIndex(sel, GridView.Contain)
    }

    PanelWindow {
        id: win
        visible: root.shown || panel.opacity > 0.01
        screen: root.targetScreen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"

        WlrLayershell.namespace: "launchpad"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        // Click outside the panel closes
        MouseArea { anchors.fill: parent; onClicked: root.setShown(false) }

        Rectangle {
            id: panel
            width: Math.max(620, parent.width * root.panelWidthFraction)
            height: Math.max(460, parent.height * root.panelHeightFraction)
            anchors.centerIn: parent
            radius: 30
            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

            // Semi-transparent so the compositor blur shows through
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#a60d1426" }
                GradientStop { position: 1.0; color: "#a6081020" }
            }
            border.width: 1
            border.color: "#33ffffff"

            // Swallow clicks inside the panel
            MouseArea { anchors.fill: parent }

            Rectangle {
                id: searchBox
                width: 340; height: 40; radius: 20
                anchors { top: parent.top; topMargin: 24; horizontalCenter: parent.horizontalCenter }
                color: "#26ffffff"
                border.width: 1
                border.color: search.activeFocus ? "#5fb4ff" : "#33ffffff"
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    id: glass
                    text: "⌕"; color: "#99ffffff"; font.pixelSize: 20
                    anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
                }

                TextInput {
                    id: search
                    anchors {
                        left: glass.right; leftMargin: 8
                        right: parent.right; rightMargin: 16
                        verticalCenter: parent.verticalCenter
                    }
                    color: "white"; font.pixelSize: 15
                    selectByMouse: true
                    clip: true
                    onTextChanged: {
                        root.query = text
                        root.sel = 0
                        appGrid.positionViewAtBeginning()
                    }

                    Text {
                        visible: !search.text
                        text: "Search"; color: "#80ffffff"; font: search.font
                    }

                    Keys.onEscapePressed: root.setShown(false)
                    Keys.onReturnPressed: root.launch(root.results[root.sel])
                    Keys.onEnterPressed: root.launch(root.results[root.sel])
                    Keys.onLeftPressed: root.move(-1)
                    Keys.onRightPressed: root.move(1)
                    Keys.onUpPressed: root.move(-appGrid.cols)
                    Keys.onDownPressed: root.move(appGrid.cols)
                    Keys.onPressed: e => {
                        const page = appGrid.cols * Math.max(1, Math.floor(appGrid.height / appGrid.cellHeight))
                        if (e.key === Qt.Key_PageDown) { root.move(page); e.accepted = true }
                        else if (e.key === Qt.Key_PageUp) { root.move(-page); e.accepted = true }
                        else if (e.key === Qt.Key_Tab) { root.move(1); e.accepted = true }
                        else if (e.key === Qt.Key_Backtab) { root.move(-1); e.accepted = true }
                    }
                }
            }

            GridView {
                id: appGrid
                anchors {
                    top: searchBox.bottom; topMargin: 20
                    bottom: parent.bottom; bottomMargin: 16
                    left: parent.left; leftMargin: 28
                    right: parent.right; rightMargin: 20
                }
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                readonly property int cols: Math.max(1, Math.floor(width / 140))
                cellWidth: Math.floor(width / cols)
                cellHeight: 128
                model: root.results

                ScrollBar.vertical: ScrollBar {
                    id: vbar
                    policy: ScrollBar.AlwaysOn
                    width: 8
                    contentItem: Rectangle {
                        implicitWidth: 6
                        radius: 3
                        color: vbar.pressed ? "#6fd0ff" : "#66a9d6ff"
                    }
                    background: Rectangle { radius: 3; color: "#14ffffff" }
                }

                delegate: Item {
                    id: cell
                    required property var modelData
                    required property int index
                    readonly property bool active: index === root.sel
                    width: appGrid.cellWidth; height: appGrid.cellHeight

                    Rectangle {
                        id: tile
                        width: 72; height: 72; radius: 20
                        anchors { top: parent.top; topMargin: 8; horizontalCenter: parent.horizontalCenter }
                        scale: cell.active ? 1.1 : 1
                        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutBack } }
                        gradient: Gradient {
                            GradientStop { position: 0; color: cell.active ? "#3a5a8a" : "#2a3350" }
                            GradientStop { position: 1; color: cell.active ? "#1f3f6b" : "#1a2036" }
                        }
                        border.width: 1
                        border.color: cell.active ? "#6fd0ff" : "#22ffffff"

                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 48
                            source: root.iconSource(cell.modelData.icon)
                        }
                    }

                    Text {
                        anchors {
                            top: tile.bottom; topMargin: 10
                            left: parent.left; right: parent.right
                            leftMargin: 6; rightMargin: 6
                        }
                        text: cell.modelData.name
                        color: cell.active ? "white" : "#d8e2f0"
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onPositionChanged: root.sel = cell.index
                        onClicked: root.launch(cell.modelData)
                    }
                }
            }
        }
    }
}
