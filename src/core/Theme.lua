local GREEN_TEXT = { 0.2, 1, 0.2 }
local GRAY_TEXT = { 0.5, 0.5, 0.5 }
local YELLOW_TEXT = { 1, 0.8, 0 }
local RED_TEXT = { 1, 0.1, 0.1 } -- Blizzard's standard RED_FONT_COLOR.
local Theme = {
    -- Different source textures need different tints to share the close button's antique gold.
    gold = {
        text = { 1, 0.82, 0 },
        buttonTint = { 0.65, 0.50, 0.70 }, ringTint = { 0.75, 0.58, 0.35 },
    },
    green = { text = GREEN_TEXT },
    gray = { text = GRAY_TEXT },
    yellow = { text = YELLOW_TEXT },
    red = { text = RED_TEXT },
    text = { 1, 1, 1 },
    rowDivider = { color = { 0.72, 0.45, 0.40 }, height = 3, alpha = 0.1 },
    circularBackground = { 0.08, 0.08, 0.08, 1 },
    toggle = { on = GREEN_TEXT, off = GRAY_TEXT },
    trackerStatus = { idle = GRAY_TEXT, running = GREEN_TEXT, paused = YELLOW_TEXT },
    speedometer = {
        needle = { 0.72, 0.12, 0.10 }, shadow = { 0, 0, 0, 0.45 },
        overload = { 1, 0.9, 0.55 },
    },
}

function Theme:GoldText(text)
    local r, g, b = unpack(self.gold.text)
    return string.format("|cff%02x%02x%02x%s|r", math.floor(r * 255 + 0.5),
        math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5), text)
end

PerHour.Theme = Theme
