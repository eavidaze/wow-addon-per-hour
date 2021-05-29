-- -- class
TogglePerHour = {}
TogglePerHour.AddonName = select(1, ...)

-- private properties
local elementWidth = 96
local elementHeight = 22
local totalElements = 3

local Frame = CreateFrame("Frame", TogglePerHour.AddonName .. "-toggle-frame", UIParent)
TogglePerHour.Frame = Frame

-- private functions
local function SetupFrameFrame()
    -- set frame size
    Frame:SetFrameStrata("HIGH")
    Frame:SetWidth(elementWidth)
    Frame:SetHeight(elementHeight * totalElements)

    -- set it movable
    Frame:SetMovable(true)
    Frame:SetClampedToScreen(true)
    Frame:SetScript("OnMouseDown", function(self, button)
        self:StartMoving()
    end)
    Frame:SetScript("OnMouseUp", function(self, button)
        self:StopMovingOrSizing()
    end)

    -- set texture
    local FrameTexture = Frame:CreateTexture(nil,"BACKGROUND")
    FrameTexture:SetColorTexture(0,0,0,0.5)
    FrameTexture:SetAllPoints(Frame)

    Frame:SetPoint("CENTER",0,0)
    Frame:Show()
end

local function SetupElements()
    -- create title
    local titlePerHonor = Frame:CreateFontString(Frame, "OVERLAY", "GameTooltipText")
    titlePerHonor:SetHeight(elementHeight)
    titlePerHonor:SetPoint("TOP")
    titlePerHonor:SetText("Per Hour™")

    -- create the XP per hour toggle button
    local toggleXpPerHour = CreateFrame("Button", "toggleXpPerHour", Frame, 'UIPanelButtonTemplate')
    toggleXpPerHour:SetWidth(elementWidth)
    toggleXpPerHour:SetHeight(elementHeight)
    toggleXpPerHour:SetPoint("TOP", titlePerHonor, "BOTTOM")
    toggleXpPerHour:SetText("Experience")
    toggleXpPerHour:RegisterForClicks("AnyUp")
    toggleXpPerHour:SetScript("OnClick", function(self, button, down)
        DEFAULT_CHAT_FRAME:AddMessage("Experience Per Hour™ is not implemented yet.")
    end)

    -- create the honor per hour toggle button
    local toggleHonorPerHour = CreateFrame("Button", "toggleHonorPerHour", Frame, 'UIPanelButtonTemplate')
    toggleHonorPerHour:SetWidth(elementWidth)
    toggleHonorPerHour:SetHeight(elementHeight)
    toggleHonorPerHour:SetPoint("TOP", toggleXpPerHour, "BOTTOM")
    toggleHonorPerHour:SetText("Honor")
    toggleHonorPerHour:RegisterForClicks("AnyUp")
    toggleHonorPerHour:SetScript("OnClick", function(self, button, down)
        Honor:Toggle()
    end)
end

-- public functions
function TogglePerHour:Init(event, name)
    if name ~= TogglePerHour.AddonName then
        return
    end
    
    SetupFrameFrame()
    SetupElements()

    DEFAULT_CHAT_FRAME:AddMessage("Per Hour™: " .. name)
end

Frame:RegisterEvent("ADDON_LOADED")
Frame:SetScript("OnEvent", TogglePerHour.Init)