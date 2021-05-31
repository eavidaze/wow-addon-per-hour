-- import
local PerHour = PerHour
local Utils = Utils
local Modules = PerHour.Modules

-- class declaration
TogglePerHour = {}
PerHour.TogglePerHour = TogglePerHour

-- private
-- local ToggleMenuItems = PerHour.ToggleMenuItems
local ElementWidth = 96
local ElementHeight = 22

-- ( ( title + MenuItems ) * ElementHeight ) + 2px bottom padding
local FrameHeight = ((1 + Utils:GetTableSize(Modules)) * ElementHeight) + 2
-- | 2px padding | element | 2px padding |
local FrameWidth = ElementWidth + 4

local Frame = CreateFrame("Frame", PerHour.AddonName .. "-toggle-frame", UIParent)
TogglePerHour.Frame = Frame

-- private functions
local function RenderFrame()
    -- set frame size
    Frame:SetFrameStrata("HIGH")
    Frame:SetWidth(FrameWidth)
    Frame:SetHeight(FrameHeight)

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
    FrameTexture:SetColorTexture(0,0,0,0.2)
    FrameTexture:SetAllPoints(Frame)

    Frame:SetPoint("CENTER",0,0)
    Frame:Show()
end

local function RenderButton(contextModule, referanceFrame)
    local name = contextModule.Name
    local frame = contextModule.Frame
    local toggleButton = CreateFrame("Button", "Toggle".. name .. "PerHour", Frame, 'UIGoldBorderButtonTemplate')
    toggleButton:SetWidth(ElementWidth)
    toggleButton:SetHeight(ElementHeight)
    toggleButton:SetPoint("TOP", referanceFrame, "BOTTOM")
    toggleButton:SetText(name)
    toggleButton:RegisterForClicks("AnyUp")
    toggleButton:SetScript("OnClick", function(self, button, down)
        if (frame:IsShown()) then
            frame:Hide()
            DEFAULT_CHAT_FRAME:AddMessage(name .. " Hide.")
        else
            frame:Show()
            DEFAULT_CHAT_FRAME:AddMessage(name .. " Show.")
        end
    end)
    return toggleButton
end

local function RenderElements()
    -- render title
    local titlePerHonor = Frame:CreateFontString(Frame, "OVERLAY", "GameTooltipText")
    titlePerHonor:SetHeight(ElementHeight)
    titlePerHonor:SetPoint("TOP")
    titlePerHonor:SetText("Per Hour™")

    local pointReference = titlePerHonor

    for key,contextModule in pairs(Modules) do
        pointReference = RenderButton(contextModule, pointReference)
    end
    
    -- for toggleName, toggleFunction in pairs(ToggleMenuItems) do
    --     pointReference = RenderButton(toggleName, toggleFunction, pointReference)
    -- end

end

-- public functions
function TogglePerHour:OnEvent(event, name)
    if name ~= PerHour.AddonName then
        return
    end
    RenderFrame()
    RenderElements()
end

Frame:RegisterEvent("ADDON_LOADED")
Frame:SetScript("OnEvent", TogglePerHour.OnEvent)
