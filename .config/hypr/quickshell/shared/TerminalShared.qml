pragma Singleton

import Quickshell

// The one place the shell names its terminal. binds.lua and
// ~/.config/pypr/config.toml name it separately.
Singleton {
    readonly property string name: "ghostty"

    // pypr scratchpads run ghostty as com.hanle.<name>
    readonly property var ghosttyClasses: ["ghostty", "com.mitchellh.ghostty"]
    function isGhostty(cls) {
        return ghosttyClasses.includes(cls) || /^com\.hanle\./.test(cls || "")
    }

    // argv that runs `argv` in a new terminal window.
    // opts.title sets the window title, opts.hold keeps it open after exit.
    function command(argv, opts) {
        const o = opts || {}
        const flags = []
        if (o.title) flags.push("--title=" + o.title)
        if (o.hold) flags.push("--wait-after-command=true")
        return [name].concat(flags, ["-e"], argv)
    }
}
