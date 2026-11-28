local Components = PerHour.Components
local Theme = PerHour.Theme
local Geometry = {
    TextureSize=128, Radius=32, LabelSize=10, LabelHeight=12, LabelGap=6, Padding=2,
    ArcWidth=2, MajorTickLength=5, MinorTickLength=3,
    NeedleInset=7, NeedleBaseWidth=4, NeedleTipWidth=1.5, CapRadius=2.5,
    EdgeCoverage=0.8, ArcTexture="SpeedometerArc.tga", NeedleTexture="SpeedometerPointer.tga",
}
local LABEL_ANCHORS = {"RIGHT","BOTTOMRIGHT","BOTTOM","BOTTOMLEFT","LEFT"}
Components.SpeedometerGeometry = Geometry
local OVERLOAD_CYCLE, OVERLOAD_BURST, OVERLOAD_BEATS = 1.8, 0.36, 12
local TEXTURE_PATH = "Interface\\AddOns\\" .. PerHour.AddonName .. "\\src\\textures\\"

local function Point(fraction, radius, centerY)
    local angle = math.pi * (1 - fraction)
    return math.cos(angle) * radius, centerY + math.sin(angle) * radius
end

local function CreateArtwork(frame, layer, filename, color)
    local texture = frame:CreateTexture(nil, layer)
    texture:SetTexture(TEXTURE_PATH .. filename, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE", "LINEAR")
    texture:SetVertexColor(unpack(color))
    texture:SetSnapToPixelGrid(false)
    texture:SetTexelSnappingBias(0)
    return texture
end

local function CreateShadow(frame, layer, filename)
    local texture = CreateArtwork(frame, layer, filename, Theme.speedometer.shadow)
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
    frame:SetSize(120, 70)
    frame.DialShadow = CreateShadow(frame, "BACKGROUND", Geometry.ArcTexture)
    frame.NeedleShadow = CreateShadow(frame, "BORDER", Geometry.NeedleTexture)
    frame.Needle = CreateArtwork(frame, "ARTWORK", Geometry.NeedleTexture, Theme.speedometer.needle)
    -- The dial's center cap covers the base of the needle.
    frame.Dial = CreateArtwork(frame, "OVERLAY", Geometry.ArcTexture, Theme.gold.text)
    frame.Labels = {}
    for index = 0, 4 do
        local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        local font,_,flags = label:GetFont()
        label:SetFont(font,Geometry.LabelSize,flags)
        label:SetTextColor(unpack(Theme.text))
        label:SetWordWrap(false)
        label:SetText("0")
        frame.Labels[index + 1] = label
    end
    frame.Target, frame.Fraction, frame.Overloaded = 0, 0, false
    frame.EffectActive = false
    frame.OverloadAnimation = false
    frame.OverloadShadowAnimation = false
    frame.Needle:SetRotation(math.pi)
    frame.NeedleShadow:SetRotation(math.pi)

    function frame:SetDisplayWidth(width)
        width = math.floor(width+0.5)
        if self.DisplayWidth == width and not self.LayoutDirty then return end
        self.DisplayWidth,self.LayoutDirty = width,false
        local radius = width/2-Geometry.Padding
        for index,label in ipairs(self.Labels) do
            local labelWidth = math.ceil(label:GetStringWidth())
            -- A single anchor and automatic width keep native FontString ellipsis off.
            label:SetWidth(0)
            label:SetHeight(Geometry.LabelHeight)
            local cosine = math.abs(math.cos(math.pi*(1-(index-1)/4)))
            if cosine > 0.001 then
                radius=math.min(radius,(width/2-Geometry.Padding-labelWidth)/cosine-Geometry.LabelGap)
            end
        end
        radius=math.max(16,radius)
        local bottom = -Geometry.LabelHeight/2-Geometry.Padding
        local top = radius+Geometry.LabelGap+Geometry.LabelHeight+Geometry.Padding
        local height = math.ceil(top-bottom)
        local centerY = -height/2-bottom
        self.Radius,self.CenterY = radius,centerY
        self:SetSize(width,height)
        local artworkSize = Geometry.TextureSize*radius/Geometry.Radius
        for _,texture in ipairs({self.Dial,self.Needle,self.DialShadow,self.NeedleShadow}) do
            texture:SetSize(artworkSize,artworkSize)
            local shadow = texture == self.DialShadow or texture == self.NeedleShadow
            texture:SetPoint("CENTER",self,"CENTER",shadow and 1 or 0,centerY-(shadow and 1 or 0))
        end
        for index,label in ipairs(self.Labels) do
            local x,y = Point((index-1)/4,radius+Geometry.LabelGap,centerY)
            label:ClearAllPoints()
            label:SetPoint(LABEL_ANCHORS[index],self,"CENTER",x,y)
        end
    end

    function frame:SetRate(value, maximum)
        if self.Maximum ~= maximum then
            self.Maximum = maximum
            for index, label in ipairs(self.Labels) do
                label:SetWidth(0)
                label:SetText(Utils:DisplayCompactNumber(maximum * (index - 1) / 4))
            end
            self.LayoutDirty = true
            self:SetDisplayWidth(self:GetWidth())
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
    frame:SetDisplayWidth(frame:GetWidth())
    return frame
end
