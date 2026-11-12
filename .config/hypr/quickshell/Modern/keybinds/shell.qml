import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../../shared"
import "../common"

ShellRoot {
    id: kb

    property bool open: false
    property bool wide: false
    property real t: 0
    property var scr: null
    readonly property int narrow: 380
    readonly property int w: wide ? narrow * 2 : narrow

    function show(all) {
        wide = all
        if (open) return
        scr = HyprShared.focusedScreen()
        KeybindsShared.refresh()
        Theme.refresh()
        open = true
        closing.stop()
        opening.restart()
    }
    function close() {
        if (!open) return
        open = false
        opening.stop()
        closing.restart()
    }
    function toggle() { open && !wide ? close() : show(false) }
    function extend() { open && wide ? close() : show(true) }

    SettleShared { id: opening; target: kb; property: "t"; to: 1; duration: Theme.move }
    NumberAnimation { id: closing; target: kb; property: "t"; to: 0; duration: Theme.fast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.leave }

    IpcHandler {
        target: "keybinds"
        function toggle(): void { kb.toggle() }
        function extend(): void { kb.extend() }
        function open(): void { kb.show(kb.wide) }
        function close(): void { kb.close() }
    }

    component Chip: Rectangle {
        property alias text: label.text
        width: label.implicitWidth + 12
        height: 20
        radius: Theme.r(6)
        color: Theme.alpha(Theme.accent, 0.16)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.3)
        LabelShared {
            id: label
            anchors.centerIn: parent
            font.pixelSize: 11
            color: Theme.bright
        }
    }

    component Sections: Flickable {
        id: list
        property var model: []
        property bool faded: false
        contentHeight: col.height + 12
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        opacity: faded ? 0.55 : 1
        onVisibleChanged: contentY = 0
        onModelChanged: contentY = 0

        Column {
            id: col
            width: list.width
            spacing: 16
            Repeater {
                model: list.model
                Column {
                    id: sec
                    required property var modelData
                    width: col.width
                    spacing: 0
                    Row {
                        spacing: 8
                        height: 26
                        LabelShared { anchors.verticalCenter: parent.verticalCenter; text: sec.modelData.glyph; font.pixelSize: 13; color: Theme.accent }
                        LabelShared { anchors.verticalCenter: parent.verticalCenter; text: sec.modelData.title; font.pixelSize: 13; font.weight: Font.DemiBold; color: Theme.bright }
                    }
                    Repeater {
                        model: sec.modelData.rows
                        Item {
                            id: row
                            required property var modelData
                            required property int index
                            width: sec.width
                            height: 30
                            Rectangle {
                                anchors.fill: parent
                                anchors.topMargin: 2
                                anchors.bottomMargin: 2
                                radius: Theme.r(8)
                                color: Theme.alpha(Theme.fg, row.index % 2 === 0 ? 0.045 : 0)
                            }
                            Row {
                                id: chips
                                x: 8
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                Repeater { model: row.modelData.keys; Chip { required property string modelData; text: modelData } }
                            }
                            LabelShared {
                                anchors.left: chips.right
                                anchors.leftMargin: 10
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideRight
                                text: row.modelData.desc
                                font.pixelSize: 12
                                color: Theme.fg
                            }
                        }
                    }
                }
            }
        }
    }

    PanelWindow {
        id: win
        visible: kb.open || kb.t > 0.001
        screen: kb.scr ?? Quickshell.screens[0]
        anchors { top: true; bottom: true; right: true }
        margins { top: Theme.gapsOut; bottom: Theme.gapsOut }
        implicitWidth: kb.w
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "quickshell-keybinds"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Item {
            id: card
            anchors.fill: parent
            opacity: Math.min(1, kb.t * 4)
            transform: Translate { x: (1 - kb.t) * (kb.w + 24) }
            clip: true

            Rectangle {
                width: parent.width + Theme.rounding + 2
                height: parent.height
                radius: Theme.rounding
                color: Theme.panel
                border.width: 1
                border.color: Theme.edge
            }

            Item {
                id: head
                x: 20; y: 16
                width: parent.width - 40
                height: 30
                LabelShared { anchors.verticalCenter: parent.verticalCenter; text: "Keybinds"; font.pixelSize: 16; font.weight: Font.DemiBold; color: Theme.bright }
                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: ctx.implicitWidth + 16
                        height: 22
                        radius: height / 2 * Math.min(1, Theme.rounding / 10)
                        color: Theme.alpha(Theme.accent, 0.16)
                        LabelShared { id: ctx; anchors.centerIn: parent; text: KeybindsShared.context; font.pixelSize: 11; color: Theme.accent }
                    }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: more.implicitWidth + 16
                        height: 22
                        radius: height / 2 * Math.min(1, Theme.rounding / 10)
                        color: Theme.alpha(Theme.fg, hover.containsMouse ? 0.12 : 0.06)
                        LabelShared { id: more; anchors.centerIn: parent; text: kb.wide ? "Less" : "All"; font.pixelSize: 11; color: Theme.fg }
                        MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: kb.show(!kb.wide) }
                    }
                }
            }

            Row {
                x: 16
                anchors.top: head.bottom
                anchors.topMargin: 12
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                width: parent.width - 32
                spacing: 20

                Sections {
                    width: kb.wide ? (parent.width - parent.spacing) / 2 : parent.width
                    height: parent.height
                    model: KeybindsShared.now
                }
                Column {
                    visible: kb.wide
                    width: (parent.width - parent.spacing) / 2
                    height: parent.height
                    spacing: 6
                    LabelShared { id: away; height: 24; verticalAlignment: Text.AlignVCenter; text: "Not active here"; font.pixelSize: 12; color: Theme.dim }
                    Sections {
                        width: parent.width
                        height: parent.height - away.height - parent.spacing
                        model: KeybindsShared.elsewhere
                        faded: true
                    }
                }
            }
        }
    }
}
