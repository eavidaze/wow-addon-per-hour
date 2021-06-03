-- import
local PerHour = PerHour
local Utils = Utils
local Modules = PerHour.Modules
local Settings = PerHour.Settings

-- class declaration
ToggleMenu = {}
PerHour.ToggleMenu = ToggleMenu

-- private
local TitleHeight = 15
local ElementWidth = 96
local ElementHeight = 22
local FirstMenuElementOffset = -2

-- 2px top padding + (2 titles * TitleHeight) + 2px padding + ( MenuItems * ElementHeight ) + 2px bottom padding
local FrameHeight = 2+(2*TitleHeight)+2+(Utils:GetTableSize(Modules)*ElementHeight)+2
-- | 2px padding | element | 2px padding |
local FrameWidth = ElementWidth + 4

local Frame = CreateFrame("Frame", PerHour.AddonName .. "-toggle-frame", UIParent)
ToggleMenu.Frame = Frame

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
    toggleButton:SetPoint("TOP", referanceFrame, "BOTTOM", 0, FirstMenuElementOffset)
    toggleButton:SetText(name)
    toggleButton:RegisterForClicks("AnyUp")
    toggleButton:SetScript("OnClick", function(self, button, down)
        if (frame:IsShown()) then
            contextModule:SetIsShown(false)
            frame:Hide()
            Utils:AddonMessage(name .. " hide.")
        else
            contextModule:SetIsShown(true)
            frame:Show()
            Utils:AddonMessage(name .. " show.")
        end
    end)
    FirstMenuElementOffset = 0
    return toggleButton
end

local function RenderElements()
    -- render toggle menu title
    local titlePerHonor = Frame:CreateFontString(Frame, nil, "GameFontNormalSmall")
    titlePerHonor:SetHeight(TitleHeight)
    titlePerHonor:SetPoint("TOP", 0, -2)
    titlePerHonor:SetText("Per Hour™")
    
    local titleToggle = Frame:CreateFontString(Frame, nil, "GameFontHighlightSmall")
    titleToggle:SetHeight(TitleHeight)
    titleToggle:SetPoint("TOP", titlePerHonor, "BOTTOM")
    titleToggle:SetText("Toggle Menu")

    local pointReference = titleToggle

    for key,contextModule in pairs(Modules) do
        -- for each module registred, we render a button
        pointReference = RenderButton(contextModule, pointReference)
        
        -- here we check if it is displayed or not #display0192364
        if contextModule:IsShown() then
            contextModule.Frame:Show()
        else
            contextModule.Frame:Hide()
        end
        
    end
end

-- public functions
function ToggleMenu:OnEvent(event, name)
    if name ~= PerHour.AddonName then
        return
    end
    Settings:Init()
    RenderFrame()
    RenderElements()
end

Frame:RegisterEvent("ADDON_LOADED")
Frame:SetScript("OnEvent", ToggleMenu.OnEvent)
