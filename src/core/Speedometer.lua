local Components = PerHour.Components
local Theme = PerHour.Theme
local RADIUS, CENTER_Y = 78, -42
local ANIMATION_SECONDS = 0.2
local OVERLOAD_CYCLE, OVERLOAD_BURST = 1.8, 0.36
local OVERLOAD_SHAKE = math.rad(1.5)
local OVERLOAD_STRONG_SHAKE = math.rad(3)
local OVERLOAD_BEATS_PER_SECOND = 32
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

local function DrawNeedle(frame, fraction, shake)
    local rotation = math.pi * (1 - fraction) + (shake or 0)
    frame.Needle:SetRotation(rotation)
    frame.NeedleShadow:SetRotation(rotation)
    frame.NeedleGlow:SetRotation(rotation)
    frame.Fraction = fraction
end

local function CreateOverloadAnimation(glow)
    local group = glow:CreateAnimationGroup()
    group:SetLooping("REPEAT")
    -- Two short flashes, then a dark pause. Native alpha animations handle the glow.
    local steps = {
        { 0, 0.9, 0.04, 0 }, { 0.9, 0, 0.08, 0 },
        { 0, 0.7, 0.04, 0.08 }, { 0.7, 0, 0.12, 0 },
        { 0, 0, OVERLOAD_CYCLE - OVERLOAD_BURST, 0 },
    }
    for order, step in ipairs(steps) do
        local animation = group:CreateAnimation("Alpha")
        animation:SetOrder(order)
        animation:SetFromAlpha(step[1])
        animation:SetToAlpha(step[2])
        animation:SetDuration(step[3])
        animation:SetStartDelay(step[4])
    end
    return group
end

local function StopOverload(frame)
    if frame.EffectActive then frame.OverloadAnimation:Stop() end
    frame.EffectActive, frame.OverloadElapsed = false, 0
    frame.NeedleGlow:SetAlpha(0)
    frame.NeedleGlow:Hide()
    DrawNeedle(frame, frame.Fraction)
end

local function StartOverload(frame)
    if frame.EffectActive then return end
    frame.EffectActive, frame.OverloadElapsed = true, 0
    frame.NeedleGlow:SetAlpha(0)
    frame.NeedleGlow:Show()
    frame.OverloadAnimation:Play()
end

local function UpdateNeedle(frame, delta)
    local fraction = frame.Fraction
    if frame.MoveElapsed < ANIMATION_SECONDS then
        frame.MoveElapsed = math.min(ANIMATION_SECONDS, frame.MoveElapsed + delta)
        fraction = frame.StartFraction + (frame.Target - frame.StartFraction) * frame.MoveElapsed / ANIMATION_SECONDS
    end
    local shake = 0
    if frame.EffectActive then
        frame.OverloadElapsed = (frame.OverloadElapsed + delta) % OVERLOAD_CYCLE
        if frame.OverloadElapsed < OVERLOAD_BURST then
            -- Bounce inward from the end stop; the needle never crosses below the dial.
            local beat = math.floor(frame.OverloadElapsed * OVERLOAD_BEATS_PER_SECOND)
            -- Beats 2, 6 and 10 are stronger; change amplitude at each return to the stop.
            local amplitude = beat % 4 == 1 and OVERLOAD_STRONG_SHAKE or OVERLOAD_SHAKE
            shake = amplitude * math.abs(math.sin(frame.OverloadElapsed * math.pi * OVERLOAD_BEATS_PER_SECOND))
        end
    end
    DrawNeedle(frame, fraction, shake)
    if frame.MoveElapsed >= ANIMATION_SECONDS and not frame.EffectActive then frame:SetScript("OnUpdate", nil) end
end

-- A presentation of the existing session rate; no tracking or rate calculation lives here.
function Components:CreateSpeedometerDisplay(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(210, 110)
    local r, g, b = unpack(Theme.gold.text)
    frame.DialShadow = CreateShadow(frame, "BACKGROUND", "SpeedometerDial.tga")
    frame.NeedleShadow = CreateShadow(frame, "BORDER", "SpeedometerNeedle.tga")
    frame.Needle = CreateArtwork(frame, "ARTWORK", "SpeedometerNeedle.tga", unpack(Theme.speedometer.needle))
    frame.NeedleGlow = CreateArtwork(frame, "ARTWORK", "SpeedometerNeedle.tga", unpack(Theme.speedometer.overload))
    frame.NeedleGlow:SetBlendMode("ADD")
    frame.NeedleGlow:SetAlpha(0)
    frame.NeedleGlow:Hide()
    frame.OverloadAnimation = CreateOverloadAnimation(frame.NeedleGlow)
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
    frame.StartFraction, frame.MoveElapsed = 0, ANIMATION_SECONDS
    frame.Overloaded, frame.EffectActive, frame.OverloadElapsed = false, false, 0
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
        self.Overloaded = value > maximum
        if target ~= self.Target then
            self.StartFraction, self.MoveElapsed = self.Fraction, 0
            self.Target = target
        end
        if not self:IsVisible() then
            self:SetScript("OnUpdate", nil)
            self.MoveElapsed = ANIMATION_SECONDS
            StopOverload(self)
            DrawNeedle(self, target)
            return
        end
        if self.Overloaded then StartOverload(self) else StopOverload(self) end
        if self.MoveElapsed < ANIMATION_SECONDS or self.EffectActive then
            self:SetScript("OnUpdate", UpdateNeedle)
        else
            self:SetScript("OnUpdate", nil)
        end
    end
    frame:SetScript("OnHide", function(self)
        self:SetScript("OnUpdate", nil)
        self.MoveElapsed = ANIMATION_SECONDS
        StopOverload(self)
        DrawNeedle(self, self.Target)
    end)
    frame:SetScript("OnShow", function(self)
        if self.Overloaded and self:IsVisible() then
            StartOverload(self)
            self:SetScript("OnUpdate", UpdateNeedle)
        end
    end)
    return frame
end
