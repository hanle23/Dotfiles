require("binds")
local mod = "SUPER"
local util = "~/.config/hypr/utilities/"
local space = function(name) return hl.dsp.exec_cmd(util .. "session/shells.sh space toggle " .. name) end

hl.bind(mod .. " + SUPER_L", space("launcher"), { release = true, description = "Shell · Launcher" })
hl.bind(mod .. " + grave", space("overview"), { description = "Shell · Overview" })
hl.bind(mod .. " + SHIFT + L", hl.dsp.exec_cmd(util .. "session/lock.sh"), { description = "Shell · Lock" })
hl.bind(mod .. " + SHIFT + ESCAPE", hl.dsp.exit(), { description = "Shell · Log out" })
hl.bind(mod .. " + ESCAPE", hl.dsp.exec_cmd("~/.config/hypr/quickshell/shared/spotify.sh toggle"), { description = "Media · Spotify" })
hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }), { description = "Workspace · Next" })
hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }), { description = "Workspace · Previous" })
hl.bind("ALT + TAB", space("home"), { description = "Shell · Home" })
hl.bind("ALT + W", space("world"), { description = "Shell · Switch world" })
hl.bind("ALT + D", space("widgets"), { description = "Shell · Edit widgets" })
hl.bind("ALT + S", space("settings"), { description = "Shell · Settings" })
hl.bind("ALT + A", space("bar"), { description = "Shell · Toggle bar" })
hl.bind(mod .. " + SHIFT + slash", space("keybinds"), { description = "Shell · Keybind sidebar" })
hl.bind("ALT + SHIFT + slash", space("keybinds-all"), { description = "Shell · Keybind sidebar (all)" })
