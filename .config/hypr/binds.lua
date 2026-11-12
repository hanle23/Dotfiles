local terminal = "ghostty"
local fileManager = "thunar"
local mainMod = "SUPER"
local osd = "~/.config/hypr/utilities/session/osd.sh "

local function pop_out()
    local w = hl.get_active_window()
    if not w then return end
    local target = "address:" .. w.address
    if w.floating then
        hl.dispatch(hl.dsp.window.float({ action = "disable", window = target }))
        return
    end
    hl.dispatch(hl.dsp.window.float({ action = "enable", window = target }))
    local m = w.monitor
    if not m then return end
    local sw, sh = m.width / m.scale, m.height / m.scale
    if m.transform % 2 == 1 then sw, sh = sh, sw end
    local width, height
    if sw >= sh then
        width = sw * 0.6
        height = math.min(width * 10 / 16, sh * 0.7)
    else
        width = sw * 0.85
        height = math.min(width * 5 / 4, sh * 0.6)
    end
    hl.dispatch(hl.dsp.window.resize({ x = math.floor(width), y = math.floor(height), relative = false, window = target }))
    hl.dispatch(hl.dsp.window.center({ window = target }))
end

local native_super_classes = { ["ghostty"] = true, ["com.mitchellh.ghostty"] = true }
local terminals = { ["Alacritty"] = true, ["foot"] = true, ["org.wezfurlong.wezterm"] = true }

-- pypr scratchpads run ghostty under com.hanle.* classes (see ~/.config/pypr/config.toml)
local function is_native_super(class)
    return native_super_classes[class] or (class ~= nil and class:find("^com%.hanle%.") ~= nil)
end

local function app_shortcut(mods, key, term_mods)
    return function()
        local w = hl.get_active_window()
        if not w or is_native_super(w.class) then return end
        if terminals[w.class] then
            if not term_mods then return end
            mods = term_mods
        end
        hl.dispatch(hl.dsp.send_shortcut({ mods = mods, key = key }))
    end
end

local function delete_to_line_start()
    local w = hl.get_active_window()
    if not w or is_native_super(w.class) or terminals[w.class] then return end
    hl.dispatch(hl.dsp.send_shortcut({ mods = "SHIFT", key = "Home" }))
    hl.dispatch(hl.dsp.send_shortcut({ mods = "", key = "Delete" }))
end

local function toggle_magic_window()
    local w = hl.get_active_window()
    if not w then return end
    if w.workspace and w.workspace.special then
        local ws = w.monitor and w.monitor.active_workspace
        if ws then hl.dispatch(hl.dsp.window.move({ workspace = ws.id })) end
        return
    end
    hl.dispatch(hl.dsp.window.move({ workspace = "special:magic" }))
end

local function cycle(next)
    return function()
        hl.dispatch(hl.dsp.window.cycle_next({ next = next }))
        hl.dispatch(hl.dsp.window.bring_to_top())
    end
end

local function d(text, opts)
    opts = opts or {}
    opts.description = text
    return opts
end
local function pass(text) return d(text, { non_consuming = true }) end

hl.bind(mainMod .. " + semicolon", hl.dsp.exec_cmd(terminal), d("Apps · Terminal"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager), d("Apps · File manager"))
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("pypr toggle term"), d("Apps · Dropdown terminal"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("pypr toggle packages"), d("Apps · Packages scratchpad"))
hl.bind("ALT + G", hl.dsp.exec_cmd("pypr toggle music"), d("Apps · Music scratchpad"))
hl.bind("ALT + T", hl.dsp.exec_cmd("pypr toggle taskbar"), d("Apps · Taskbar scratchpad"))

hl.bind(mainMod .. " + C", app_shortcut("CTRL", "C", "CTRL SHIFT"), pass("Edit · Copy"))
hl.bind(mainMod .. " + X", app_shortcut("CTRL", "X", nil), d("Edit · Cut"))
hl.bind(mainMod .. " + V", app_shortcut("CTRL", "V", "CTRL SHIFT"), pass("Edit · Paste"))
hl.bind(mainMod .. " + A", app_shortcut("CTRL", "A", nil), pass("Edit · Select all"))
hl.bind(mainMod .. " + Z", app_shortcut("CTRL", "Z", nil), d("Edit · Undo"))
hl.bind(mainMod .. " + SHIFT + Z", app_shortcut("CTRL SHIFT", "Z", nil), d("Edit · Redo"))
hl.bind(mainMod .. " + S", app_shortcut("CTRL", "S", nil), d("Edit · Save"))
hl.bind(mainMod .. " + SHIFT + S", app_shortcut("CTRL SHIFT", "S", nil), d("Edit · Save as"))
hl.bind(mainMod .. " + F", app_shortcut("CTRL", "F", nil), pass("Edit · Find"))
hl.bind(mainMod .. " + G", app_shortcut("CTRL", "G", nil), pass("Edit · Find next"))
hl.bind(mainMod .. " + SHIFT + G", app_shortcut("CTRL SHIFT", "G", nil), pass("Edit · Find previous"))
hl.bind(mainMod .. " + T", app_shortcut("CTRL", "T", nil), pass("Edit · New tab"))
hl.bind(mainMod .. " + SHIFT + T", app_shortcut("CTRL SHIFT", "T", nil), d("Edit · Reopen closed tab"))
hl.bind(mainMod .. " + W", app_shortcut("CTRL", "W", nil), pass("Edit · Close tab"))
hl.bind(mainMod .. " + N", app_shortcut("CTRL", "N", nil), pass("Edit · New window"))
hl.bind(mainMod .. " + R", app_shortcut("CTRL", "R", nil), d("Edit · Reload"))
hl.bind(mainMod .. " + O", app_shortcut("CTRL", "O", nil), d("Edit · Open file"))
hl.bind(mainMod .. " + L", app_shortcut("CTRL", "L", nil), d("Edit · Address bar"))
hl.bind(mainMod .. " + P", app_shortcut("CTRL", "P", nil), d("Edit · Quick open / print"))
hl.bind(mainMod .. " + B", app_shortcut("CTRL", "B", nil), d("Edit · Bold"))
hl.bind(mainMod .. " + I", app_shortcut("CTRL", "I", nil), d("Edit · Italic"))
hl.bind(mainMod .. " + U", app_shortcut("CTRL", "U", nil), d("Edit · Underline"))
hl.bind(mainMod .. " + K", app_shortcut("CTRL", "K", nil), d("Edit · Insert link"))
hl.bind(mainMod .. " + slash", app_shortcut("CTRL", "slash", nil), d("Edit · Toggle comment"))
hl.bind(mainMod .. " + comma", app_shortcut("CTRL", "comma", nil), d("Edit · App settings"))
hl.bind(mainMod .. " + equal", app_shortcut("CTRL", "equal", nil), pass("Edit · Zoom in"))
hl.bind(mainMod .. " + minus", app_shortcut("CTRL", "minus", nil), pass("Edit · Zoom out"))
hl.bind(mainMod .. " + SHIFT + bracketleft", app_shortcut("CTRL", "Prior", nil), pass("Edit · Previous tab"))
hl.bind(mainMod .. " + SHIFT + bracketright", app_shortcut("CTRL", "Next", nil), pass("Edit · Next tab"))
hl.bind(mainMod .. " + BackSpace", delete_to_line_start, pass("Edit · Delete to line start"))

hl.bind(mainMod .. " + Q", hl.dsp.window.close(), d("Window · Close"))
hl.bind(mainMod .. " + TAB", cycle(true), d("Window · Cycle next"))
hl.bind(mainMod .. " + SHIFT + TAB", cycle(false), d("Window · Cycle previous"))
hl.bind(mainMod .. " + SHIFT + V", pop_out, d("Window · Pop out / tile"))
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"), d("Window · Toggle split"))
hl.bind("CTRL + ALT + RETURN", hl.dsp.window.fullscreen(), d("Window · Fullscreen"))
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }), d("Window · Focus"))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }), d("Window · Focus"))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }), d("Window · Focus"))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }), d("Window · Focus"))
hl.bind("ALT + left", hl.dsp.window.move({ direction = "left" }), d("Window · Move"))
hl.bind("ALT + right", hl.dsp.window.move({ direction = "right" }), d("Window · Move"))
hl.bind("ALT + up", hl.dsp.window.move({ direction = "up" }), d("Window · Move"))
hl.bind("ALT + down", hl.dsp.window.move({ direction = "down" }), d("Window · Move"))
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), d("Window · Drag", { mouse = true }))
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), d("Window · Resize", { mouse = true }))

for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }), d("Workspace · Go to"))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }), d("Workspace · Send window to"))
end
hl.bind(mainMod .. " + D", hl.dsp.workspace.toggle_special("magic"), d("Workspace · Toggle special"))
hl.bind(mainMod .. " + SHIFT + D", toggle_magic_window, d("Workspace · Window in / out of special"))

hl.bind("XF86AudioMute", hl.dsp.exec_cmd(osd .. "vol-mute"), d("Media · Mute", { locked = true }))
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(osd .. "mic-mute"), d("Media · Mute mic", { locked = true }))
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(osd .. "vol-up"), d("Media · Volume up", { locked = true, repeating = true }))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(osd .. "vol-down"), d("Media · Volume down", { locked = true, repeating = true }))
hl.bind("Caps_Lock", hl.dsp.exec_cmd(osd .. "caps"), d("Media · Caps Lock indicator", { locked = true }))
hl.bind("CAPS + Caps_Lock", hl.dsp.exec_cmd(osd .. "caps"), d("Media · Caps Lock indicator", { locked = true }))
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(osd .. "bright-up"), d("Media · Brightness up", { locked = true, repeating = true }))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(osd .. "bright-down"), d("Media · Brightness down", { locked = true, repeating = true }))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(osd .. "play"), d("Media · Play / pause", { locked = true }))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(osd .. "next"), d("Media · Next track", { locked = true }))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(osd .. "prev"), d("Media · Previous track", { locked = true }))

hl.bind("CTRL + Print", hl.dsp.exec_cmd("hyprshot -m region -o ~/Screenshots/"), d("Screenshot · Region"))
hl.bind("Print", hl.dsp.exec_cmd("hyprshot -m window -o ~/Screenshots/"), d("Screenshot · Window"))
hl.bind("ALT + Print", hl.dsp.exec_cmd("hyprshot -m active -m output -o ~/Screenshots/"), d("Screenshot · Monitor"))
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
