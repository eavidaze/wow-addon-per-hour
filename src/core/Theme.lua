local Theme = {
    -- Different source textures need different tints to share the close button's antique gold.
    gold = {
        text = { 1, 0.82, 0 },
        buttonTint = { 0.65, 0.50, 0.70 }, ringTint = { 0.75, 0.58, 0.35 },
    },
    text = { 1, 1, 1 },
    circularBackground = { 0.08, 0.08, 0.08, 1 },
    toggle = { on = { 0.2, 1, 0.2 }, off = { 0.5, 0.5, 0.5 } },
    motion = { fadeIn = 0.08, fadeOut = 0.08 },
}

function Theme:GoldText(text)
    local r, g, b = unpack(self.gold.text)
    return string.format("|cff%02x%02x%02x%s|r", math.floor(r * 255 + 0.5),
        math.floor(g * 255 + 0.5), math.floor(b * 255 + 0.5), text)
end

PerHour.Theme = Theme
