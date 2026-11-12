pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Collects every keybind the shell knows about and splits it by what is
// reachable from the focused window right now.
Singleton {
    id: root

    readonly property var terminals: ["ghostty", "com.mitchellh.ghostty", "Alacritty", "foot", "org.wezfurlong.wezterm", "kitty"]
    readonly property var order: ["Edit", "Ghostty", "Neovim", "Window", "Workspace", "Apps", "Shell", "Screenshot", "Media", "Other"]
    readonly property var glyphs: ({
        Edit: "󰏫", Ghostty: "󰆍", "Ghostty defaults": "󰆍", Neovim: "", Window: "󰖯", Workspace: "󰕰",
        Apps: "󰀻", Shell: "󰕮", Screenshot: "󰹑", Media: "󰝚", Other: "󰌌"
    })

    property string appId: ""
    property string title: ""
    function track() {
        const t = ToplevelManager.activeToplevel
        if (!t) return
        appId = t.appId ?? ""
        title = t.title ?? ""
    }
    Connections { target: ToplevelManager; function onActiveToplevelChanged() { root.track() } }
    Connections { target: ToplevelManager.activeToplevel; ignoreUnknownSignals: true; function onTitleChanged() { root.track() } }
    Component.onCompleted: { track(); refresh() }

    readonly property bool inTerminal: terminals.includes(appId) || TerminalShared.isGhostty(appId)
    readonly property bool inGhostty: TerminalShared.isGhostty(appId)
    readonly property bool inNvim: inTerminal && /\bN?VIM$/i.test(title)
    readonly property string context: !appId ? "desktop" : inNvim ? appId.split(".").pop() + " · nvim" : appId.split(".").pop()

    function live(group) {
        if (group === "Edit") return !!appId && !inTerminal
        if (group === "Ghostty") return inGhostty
        if (group === "Ghostty defaults") return false
        if (group === "Neovim") return inNvim
        return true
    }

    function refresh() {
        hypr.running = true
        ghost.running = true
    }
    Connections {
        target: Hyprland
        function onRawEvent(event) { if (event.name === "configreloaded") hypr.running = true }
    }

    // ---- key labels -------------------------------------------------------

    readonly property var names: ({
        semicolon: ";", slash: "/", comma: ",", period: ".", equal: "=", minus: "-", plus: "+", grave: "`",
        bracketleft: "[", bracketright: "]", bracket_left: "[", bracket_right: "]", backslash: "\\", apostrophe: "'",
        BackSpace: "⌫", backspace: "⌫", RETURN: "Enter", Return: "Enter", enter: "Enter", TAB: "Tab", tab: "Tab",
        SPACE: "Space", space: "Space", ESCAPE: "Esc", Escape: "Esc", escape: "Esc", Print: "PrtSc", Caps_Lock: "Caps",
        left: "←", right: "→", up: "↑", down: "↓", arrow_left: "←", arrow_right: "→", arrow_up: "↑", arrow_down: "↓",
        page_up: "PgUp", page_down: "PgDn", Prior: "PgUp", Next: "PgDn", home: "Home", end: "End", insert: "Ins", delete: "Del",
        SUPER_L: "Super", "mouse:272": "LMB", "mouse:273": "RMB", mouse_down: "Scroll ↓", mouse_up: "Scroll ↑",
        XF86AudioMute: "Mute", XF86AudioMicMute: "Mic mute", XF86AudioRaiseVolume: "Vol +", XF86AudioLowerVolume: "Vol −",
        XF86MonBrightnessUp: "Bright +", XF86MonBrightnessDown: "Bright −", XF86AudioPlay: "Play", XF86AudioNext: "Next", XF86AudioPrev: "Prev",
        super: "Super", ctrl: "Ctrl", control: "Ctrl", alt: "Alt", shift: "Shift"
    })
    function key(k) {
        if (names[k] !== undefined) return names[k]
        return k.length === 1 ? k.toUpperCase() : k.charAt(0).toUpperCase() + k.slice(1)
    }
    function mods(mask) {
        const out = []
        if (mask & 64) out.push("Super")
        if (mask & 4) out.push("Ctrl")
        if (mask & 8) out.push("Alt")
        if (mask & 1) out.push("Shift")
        if (mask & 2) out.push("Caps")
        return out
    }

    // Rows with the same group, description and modifiers fold into one row.
    function fold(list) {
        const out = [], seen = {}
        for (const b of list) {
            const id = b.group + "|" + b.desc + "|" + b.mods.join("+")
            if (!seen[id]) { seen[id] = { group: b.group, desc: b.desc, mods: b.mods, last: [] }; out.push(seen[id]) }
            if (!seen[id].last.includes(b.last)) seen[id].last.push(b.last)
        }
        const done = {}
        return out.map(r => {
            let last = r.last.join("/")
            if (r.last.every(k => /^\d$/.test(k)) && r.last.length > 2) last = "0–9"
            else if (r.last.every(k => /^[←→↑↓]$/.test(k))) last = r.last.join(" ")
            const keys = r.mods.includes(last) ? r.mods : r.mods.concat([last])
            return { group: r.group, desc: r.desc, keys: keys }
        }).filter(r => {
            const id = r.desc + "|" + r.keys.join("+")
            return done[id] ? false : (done[id] = true)
        })
    }

    // ---- Hyprland --------------------------------------------------------

    property var hyprRows: []
    Process {
        id: hypr
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.hyprRows = root.fold(JSON.parse(text).filter(b => b.submap === "").map(b => {
                        const m = (b.description || "").match(/^(.+?)\s+·\s+(.+)$/)
                        return {
                            group: m ? m[1] : "Other",
                            desc: m ? m[2] : (b.description || b.dispatcher.replace(/^HL\.Dispatcher\((.*)\)$/, "$1").replace(/_/g, " ")),
                            mods: root.mods(b.modmask),
                            last: root.key(b.key)
                        }
                    }))
                } catch (e) { console.warn("keybinds: hyprctl", e) }
            }
        }
    }

    // ---- Ghostty ---------------------------------------------------------

    FileView {
        id: ghostConf
        path: HyprShared.home + "/.config/ghostty/config.ghostty"
        watchChanges: true
        printErrors: false
        onFileChanged: { reload(); ghost.running = true }
    }
    readonly property var ghostMine: (ghostConf.text().match(/^\s*keybind\s*=\s*.+$/gm) || [])
        .map(l => l.replace(/^\s*keybind\s*=\s*/, "").replace(/=[a-z_]+(:[^=]*)?\s*$/, "").trim())
    readonly property var ghostNames: ({
        close_surface: "Close tab / split", start_search: "Search", copy_to_clipboard: "Copy", paste_from_clipboard: "Paste",
        paste_from_selection: "Paste selection", select_all: "Select all", increase_font_size: "Font bigger",
        decrease_font_size: "Font smaller", reset_font_size: "Font reset", goto_tab: "Go to tab", goto_split: "Focus split",
        toggle_command_palette: "Command palette", toggle_fullscreen: "Fullscreen"
    })
    readonly property var ghostArgs: ["copy_to_clipboard", "paste_from_clipboard", "text", "csi", "esc", "increase_font_size", "decrease_font_size", "open_config"]
    property var ghostRows: []
    Process {
        id: ghost
        command: ["ghostty", "+list-keybinds"]
        stdout: StdioCollector {
            onStreamFinished: {
                const rows = []
                for (const line of text.split("\n")) {
                    const m = line.match(/^keybind = (.+)=([a-z_]+)(?::([^=]*))?$/)
                    if (!m) continue
                    let trig = m[1].replace(/^(?:[a-z]+:)+(?=.*\+|[a-z])/, "")
                    if (trig.includes(">")) continue
                    let last
                    if (trig.endsWith("++")) { last = "+"; trig = trig.slice(0, -2) }
                    else { const p = trig.split("+"); last = p.pop(); trig = p.join("+") }
                    const ms = trig ? trig.split("+").map(root.key) : []
                    let desc = root.ghostNames[m[2]] ?? m[2].replace(/_/g, " ")
                    desc = desc.charAt(0).toUpperCase() + desc.slice(1)
                    if (m[2] === "text") desc = "Send text"
                    else if (m[3] && !root.ghostArgs.includes(m[2])) desc += " " + m[3].replace(/,/g, " ")
                    rows.push({ group: root.ghostMine.includes(m[1]) ? "Ghostty" : "Ghostty defaults", desc: desc, mods: ms, last: root.key(last.replace(/^digit_/i, "")) })
                }
                root.ghostRows = root.fold(rows)
            }
        }
    }

    // ---- Neovim (from KEYBINDS.md) ---------------------------------------

    FileView {
        id: nvimDoc
        path: HyprShared.home + "/.config/nvim/KEYBINDS.md"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
    }
    readonly property var nvimSections: {
        const out = []
        let cur = null
        for (const line of nvimDoc.text().split("\n")) {
            const h = line.match(/^##\s+(.+)$/)
            if (h) { cur = { title: h[1].replace(/\s*\(.*\)\s*$/, ""), rows: [] }; out.push(cur); continue }
            const b = line.match(/^-\s+((?:`[^`]+`[\s,/or]*)+):\s*(.+)$/)
            if (!b || !cur) continue
            const keys = (b[1].match(/`[^`]+`/g) || []).map(k => k.slice(1, -1).replace(/<leader>/gi, "␣"))
            cur.rows.push({ keys: [keys.join(" / ")], desc: b[2].replace(/`/g, "") })
        }
        return out.filter(s => s.rows.length)
    }

    // ---- sections -------------------------------------------------------

    readonly property var sections: {
        const by = {}
        for (const r of hyprRows) (by[r.group] = by[r.group] || []).push(r)
        const out = []
        for (const g of order) {
            if (g === "Ghostty") {
                for (const t of ["Ghostty", "Ghostty defaults"]) {
                    const rows = ghostRows.filter(r => r.group === t)
                    if (rows.length) out.push({ group: t, title: t, rows: rows })
                }
                continue
            }
            if (g === "Neovim") { for (const s of nvimSections) out.push({ group: g, title: "Neovim · " + s.title, rows: s.rows }); continue }
            if (by[g]) out.push({ group: g, title: g, rows: by[g] })
        }
        for (const g in by) if (!order.includes(g)) out.push({ group: g, title: g, rows: by[g] })
        return out.map(s => Object.assign(s, { glyph: glyphs[s.group] ?? glyphs.Other }))
    }
    readonly property var now: sections.filter(s => live(s.group))
    readonly property var elsewhere: sections.filter(s => !live(s.group))
}
