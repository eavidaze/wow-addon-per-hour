local Components = PerHour.Components
local Theme = PerHour.Theme
local RADIUS, CENTER_Y = 78, -42
local OVERLOAD_CYCLE, OVERLOAD_BURST, OVERLOAD_BEATS = 1.8, 0.36, 12
local TEXTURE_PATH = "Interface\\AddOns\\" .. PerHour.AddonName .. "\\src\\textures\\"

local function Point(fraction, radius)
    local angle = math.pi * (1 - fraction)
    return math.cos(angle) * radius, CENTER_Y + math.sin(angle) * radius
end

local function CreateArtwork(frame, layer, filename, color)
    local texture = frame:CreateTexture(nil, layer)
    texture:SetTexture(TEXTURE_PATH .. filename, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "LINEAR")
    texture:SetSize(256, 256)
    texture:SetPoint("CENTER", frame, "CENTER", 0, CENTER_Y)
    texture:SetVertexColor(unpack(color))
    texture:SetSnapToPixelGrid(false)
    texture:SetTexelSnappingBias(0)
    return texture
end

local function CreateShadow(frame, layer, filename)
    local texture = CreateArtwork(frame, layer, filename, Theme.speedometer.shadow)
    texture:SetPoint("CENTER", frame, "CENTER", 1, CENTER_Y - 1)
    return texture
end

local function CreateOverloadAnimation(needle)
    local group = needle:CreateAnimationGroup()
    group:SetLooping("REPEAT")
    for beat = 1, OVERLOAD_BEATS do
        local degrees = beat % 4 == 2 and 3 or 1.5
        for step = 1, 2 do
            local rotation = group:CreateAnimation("Rotation")
            rotation:SetOrder((beat - 1) * 2 + step)
            rotation:SetOrigin("CENTER", 0, 0)
            rotation:SetDegrees(step == 1 and degrees or -degrees)
            rotation:SetDuration(OVERLOAD_BURST / OVERLOAD_BEATS / 2)
        end
    end
    -- Balanced rotations return to the end stop before the native resting phase.
    local rest = group:CreateAnimation("Rotation")
    rest:SetOrder(OVERLOAD_BEATS * 2 + 1)
    rest:SetOrigin("CENTER", 0, 0)
    rest:SetDegrees(0)
    rest:SetDuration(OVERLOAD_CYCLE - OVERLOAD_BURST)
    return group
end

local function RefreshOverload(frame)
    local active = frame.Overloaded and frame:IsVisible()
    if frame.EffectActive == active then return end
    frame.EffectActive = active
    if active then
        frame.OverloadAnimation:Play()
        frame.OverloadShadowAnimation:Play()
    else
        frame.OverloadAnimation:Stop()
        frame.OverloadShadowAnimation:Stop()
    end
end

-- Shadow layers share the native motion, without Lua OnUpdate or runtime timers.
function Components:CreateSpeedometerDisplay(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(210, 110)
    frame.DialShadow = CreateShadow(frame, "BACKGROUND", "SpeedometerDial.tga")
    frame.NeedleShadow = CreateShadow(frame, "BORDER", "SpeedometerNeedle.tga")
    frame.Needle = CreateArtwork(frame, "ARTWORK", "SpeedometerNeedle.tga", Theme.speedometer.needle)
    -- The dial's center cap covers the base of the needle.
    frame.Dial = CreateArtwork(frame, "OVERLAY", "SpeedometerDial.tga", Theme.gold.text)
    frame.Labels = {}
    for index = 0, 4 do
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetTextColor(unpack(Theme.text))
        local x, y = Point(index / 4, RADIUS + 16)
        label:SetPoint("CENTER", frame, "CENTER", x, y)
        frame.Labels[index + 1] = label
    end
    frame.Target, frame.Fraction, frame.Overloaded = 0, 0, false
    frame.EffectActive = false
    frame.OverloadAnimation = false
    frame.OverloadShadowAnimation = false
    frame.Needle:SetRotation(math.pi)
    frame.NeedleShadow:SetRotation(math.pi)

    function frame:SetRate(value, maximum)
        if self.Maximum ~= maximum then
            self.Maximum = maximum
            for index, label in ipairs(self.Labels) do
                label:SetText(Utils:DisplayCompactNumber(maximum * (index - 1) / 4))
            end
        end
        local fraction = math.max(0, math.min(1, value / maximum))
        if fraction ~= self.Fraction then
            self.Target, self.Fraction = fraction, fraction
            self.Needle:SetRotation(math.pi * (1 - fraction))
            self.NeedleShadow:SetRotation(math.pi * (1 - fraction))
        end
        local overloaded = value > maximum
        if self.Overloaded ~= overloaded then
            self.Overloaded = overloaded
            self.Needle:SetVertexColor(unpack(overloaded and Theme.speedometer.overload or Theme.speedometer.needle))
            if overloaded and not self.OverloadAnimation then
                self.OverloadAnimation = CreateOverloadAnimation(self.Needle)
                self.OverloadShadowAnimation = CreateOverloadAnimation(self.NeedleShadow)
            end
        end
        RefreshOverload(self)
    end
    frame:SetScript("OnHide", RefreshOverload)
    frame:SetScript("OnShow", RefreshOverload)
    return frame
end
