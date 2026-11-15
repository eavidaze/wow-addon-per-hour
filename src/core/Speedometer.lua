local Components = PerHour.Components
local Theme = PerHour.Theme
local RADIUS, CENTER_Y = 78, -42
local ANIMATION_SECONDS = 0.2
local TEXTURE_PATH = "Interface\\AddOns\\" .. PerHour.AddonName .. "\\src\\textures\\"

local function Point(fraction, radius)
    local angle = math.pi * (1 - fraction)
    return math.cos(angle) * radius, CENTER_Y + math.sin(angle) * radius
end

local function CreateArtwork(frame, layer, filename, r, g, b, alpha)
    local texture = frame:CreateTexture(nil, layer)
    texture:SetTexture(TEXTURE_PATH .. filename, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "LINEAR")
    texture:SetSize(256, 256)
    texture:SetPoint("CENTER", frame, "CENTER", 0, CENTER_Y)
    texture:SetVertexColor(r, g, b, alpha or 1)
    texture:SetSnapToPixelGrid(false)
    texture:SetTexelSnappingBias(0)
    return texture
end

local function CreateShadow(frame, layer, filename)
    local texture = CreateArtwork(frame, layer, filename, unpack(Theme.speedometer.shadow))
    texture:SetPoint("CENTER", frame, "CENTER", 1, CENTER_Y - 1)
    return texture
end

local function DrawNeedle(frame, fraction)
    local rotation = math.pi * (1 - fraction)
    frame.Needle:SetRotation(rotation)
    frame.NeedleShadow:SetRotation(rotation)
    frame.Fraction = fraction
end

-- A presentation of the existing session rate; no tracking or rate calculation lives here.
function Components:CreateSpeedometerDisplay(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(210, 110)
    local r, g, b = unpack(Theme.gold.text)
    frame.DialShadow = CreateShadow(frame, "BACKGROUND", "SpeedometerDial.tga")
    frame.NeedleShadow = CreateShadow(frame, "BORDER", "SpeedometerNeedle.tga")
    frame.Needle = CreateArtwork(frame, "ARTWORK", "SpeedometerNeedle.tga", unpack(Theme.speedometer.needle))
    -- The dial includes the center cap, which covers the base of the rotating needle.
    frame.Dial = CreateArtwork(frame, "OVERLAY", "SpeedometerDial.tga", r, g, b)
    frame.Labels = {}
    for index = 0, 4 do
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetTextColor(unpack(Theme.text))
        local x, y = Point(index / 4, RADIUS + 16)
        label:SetPoint("CENTER", frame, "CENTER", x, y)
        frame.Labels[index + 1] = label
    end
    frame.Target, frame.Fraction = 0, 0
    DrawNeedle(frame, 0)

    function frame:SetRate(value, maximum)
        if self.Maximum ~= maximum then
            self.Maximum = maximum
            for index, label in ipairs(self.Labels) do
                local mark = maximum * (index - 1) / 4
                label:SetText(mark >= 1000 and string.format("%gk", mark / 1000)
                    or string.format("%g", Utils:RoundValue(mark, 1)))
            end
        end
        local target = math.max(0, math.min(1, value / maximum))
        if target == self.Target then return end
        self.Target = target
        if not self:IsVisible() then
            self:SetScript("OnUpdate", nil)
            DrawNeedle(self, target)
            return
        end
        local start, elapsed = self.Fraction, 0
        self:SetScript("OnUpdate", function(display, delta)
            elapsed = math.min(ANIMATION_SECONDS, elapsed + delta)
            DrawNeedle(display, start + (display.Target - start) * elapsed / ANIMATION_SECONDS)
            if elapsed >= ANIMATION_SECONDS then display:SetScript("OnUpdate", nil) end
        end)
    end
    frame:SetScript("OnHide", function(self)
        self:SetScript("OnUpdate", nil)
        DrawNeedle(self, self.Target)
    end)
    return frame
end
