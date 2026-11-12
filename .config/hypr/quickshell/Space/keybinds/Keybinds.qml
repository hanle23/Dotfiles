import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import "../../shared"
import "../common"

Scope {
    id: kb

    property bool open: false
    property bool wide: false
    property real t: 0
    property var scr: null
    property int replay: 0
    readonly property int narrow: 363
    readonly property int w: wide ? narrow * 2 : narrow
    readonly property real heightRatio: 0.72
    readonly property int edgeGap: Theme.starGap
    readonly property int cut: 12

    function show(all) {
        if (open && wide !== all) replay++
        wide = all
        if (open) return
        scr = HyprShared.focusedScreen()
        KeybindsShared.refresh()
        replay++
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

    SettleShared { id: opening; target: kb; property: "t"; to: 1; duration: Theme.open }
    SettleShared { id: closing; target: kb; property: "t"; to: 0; duration: Theme.quick; easing.bezierCurve: Theme.leave }

    // Same frame as the bar pills: two cut corners, brackets on the other two.
    component Frame: Item {
        id: frame
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeWidth: 1
                strokeColor: Theme.alpha(Theme.accent, 0.4)
                fillGradient: LinearGradient {
                    y2: frame.height
                    GradientStop { position: 0; color: Theme.alpha(Theme.bg, 0.95) }
                    GradientStop { position: 1; color: Theme.alpha(Theme.bg, 0.88) }
                }
                startX: kb.cut; startY: 0
                PathLine { x: frame.width; y: 0 }
                PathLine { x: frame.width; y: frame.height - kb.cut }
                PathLine { x: frame.width - kb.cut; y: frame.height }
                PathLine { x: 0; y: frame.height }
                PathLine { x: 0; y: kb.cut }
                PathLine { x: kb.cut; y: 0 }
            }
        }
        Bracket { x: frame.width - 9; y: 0; atRight: true }
        Bracket { x: 0; y: frame.height - 9; atBottom: true }
        Rectangle { x: kb.cut; y: frame.height - 1; width: frame.width - kb.cut * 2; height: 1; color: Theme.alpha(Theme.accent, 0.28) }
    }
    component Bracket: Item {
        property bool atRight: false
        property bool atBottom: false
        width: 9; height: 9
        Rectangle { width: 9; height: 1; y: parent.atBottom ? 8 : 0; color: Theme.accent; opacity: 0.9 }
        Rectangle { width: 1; height: 9; x: parent.atRight ? 8 : 0; color: Theme.accent; opacity: 0.9 }
    }

    component Heading: Item {
        id: hd
        property string glyph
        property string text
        default property alias extra: side.data
        height: 24
        Text { id: g; text: hd.glyph; font.family: Theme.font; font.pixelSize: 14; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
        Say { x: g.width + 8; height: parent.height; caps: true; text: hd.text; color: Theme.fg; replay: kb.replay }
        Row { id: side; anchors.right: parent.right; height: parent.height; spacing: 10 }
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.alpha(Theme.accent, 0.25) }
    }

    component Chip: Rectangle {
        property alias text: label.text
        width: label.implicitWidth + 10
        height: 18
        color: Theme.alpha(Theme.accent, 0.06)
        border.width: 1
        border.color: Theme.alpha(Theme.accent, 0.3)
        Say {
            id: label
            anchors.centerIn: parent
            replay: kb.replay
            font.pixelSize: 10
            color: Theme.accent
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
            spacing: 14
            Repeater {
                model: list.model
                Column {
                    id: sec
                    required property var modelData
                    width: col.width
                    spacing: 2
                    Heading { width: sec.width; glyph: sec.modelData.glyph; text: sec.modelData.title }
                    Item { width: 1; height: 4 }
                    Repeater {
                        model: sec.modelData.rows
                        Item {
                            id: row
                            required property var modelData
                            width: sec.width
                            height: 22
                            Row {
                                id: chips
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3
                                Repeater { model: row.modelData.keys; Chip { required property string modelData; text: modelData } }
                            }
                            Say {
                                anchors.left: chips.right
                                anchors.leftMargin: 10
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideRight
                                replay: kb.replay
                                text: row.modelData.desc
                                font.pixelSize: 11
                                color: Theme.alpha(Theme.fg, 0.8)
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
        anchors.right: true
        margins.right: kb.edgeGap
        implicitWidth: kb.w
        implicitHeight: Math.round((screen?.height ?? 1080) * kb.heightRatio)
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "space-keybinds"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        Item {
            anchors.fill: parent
            opacity: Math.min(1, kb.t * 1.5)
            transform: Translate { x: (1 - kb.t) * 60 }

            Frame { anchors.fill: parent }

            Heading {
                id: head
                x: 18; y: 14
                width: parent.width - 36
                glyph: "󰌌"
                text: "keybinds"
                Say { height: parent.height; caps: true; replay: kb.replay; text: KeybindsShared.context; color: Theme.accent }
                Say {
                    height: parent.height
                    caps: true
                    replay: kb.replay
                    text: kb.wide ? "[ less ]" : "[ all ]"
                    color: more.containsMouse ? Theme.fg : Theme.dim
                    MouseArea { id: more; anchors.fill: parent; hoverEnabled: true; onClicked: kb.show(!kb.wide) }
                }
            }

            Row {
                x: 18
                anchors.top: head.bottom
                anchors.topMargin: 14
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 14
                width: parent.width - 36
                spacing: 24

                Sections {
                    width: kb.wide ? (parent.width - parent.spacing) / 2 : parent.width
                    height: parent.height
                    model: KeybindsShared.now
                }
                Column {
                    visible: kb.wide
                    width: (parent.width - parent.spacing) / 2
                    height: parent.height
                    spacing: 10
                    Say { id: away; height: 16; caps: true; replay: kb.replay; text: "not active here"; color: Theme.dim }
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
