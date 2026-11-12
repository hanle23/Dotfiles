hl.monitor({ output = "DP-4", mode = "2560x1440@165", position = "1440x560", scale = 1.00, vrr = 2})
hl.monitor({ output = "DP-6", mode = "2560x1440@60", position = "0x0", scale = 1.00,transform = 3, cm = "srgb" })

return {
    defaults = {
        boot = { enabled = true, black_ms = 2500 },
        cursor = { theme = "Bibata-Modern-Ice", size = 12 },
    },
    sensitivity = 0,
    accel_profile = "flat",
}
