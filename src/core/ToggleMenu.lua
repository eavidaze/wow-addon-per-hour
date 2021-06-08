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

-- private point referecens array
local PointRefereces = {}

-- 2px top padding + (2 titles * TitleHeight) + 2px padding + ( MenuItems * ElementHeight ) + 2px bottom padding
local FrameHeight = 2+(2*TitleHeight)+2+(Utils:GetTableSize(Modules)*ElementHeight)+2
-- | 2px padding | element | 2px padding |
local FrameWidth = ElementWidth + 4

local ToggleMenuFrame = CreateFrame("Frame", PerHour.AddonName .. "-toggle-frame", UIParent)
ToggleMenu.Frame = ToggleMenuFrame

-- private functions
local function RenderFrame()
    -- set frame size
    ToggleMenuFrame:SetFrameStrata("HIGH")
    ToggleMenuFrame:SetWidth(FrameWidth)
    ToggleMenuFrame:SetHeight(FrameHeight)

    -- set it movable
    ToggleMenuFrame:SetMovable(true)
    ToggleMenuFrame:SetClampedToScreen(true)
    ToggleMenuFrame:SetScript("OnMouseDown", function(self, button)
        self:StartMoving()
    end)
    ToggleMenuFrame:SetScript("OnMouseUp", function(self, button)
        self:StopMovingOrSizing()
    end)

    -- set texture
    local FrameTexture = ToggleMenuFrame:CreateTexture(nil,"BACKGROUND")
    FrameTexture:SetColorTexture(0,0,0,0.2)
    FrameTexture:SetAllPoints(ToggleMenuFrame)

    ToggleMenuFrame:SetPoint("CENTER",0,0)
    ToggleMenuFrame:Show()
end

local function RenderButton(contextModule)
    local pointReference = PointRefereces[#PointRefereces]
    local name = contextModule.Name
    local frame = contextModule.Frame
    
    local toggleButton = CreateFrame("Button", "$parent-".. contextModule.TagName .. "-button", ToggleMenuFrame, "UIMenuButtonStretchTemplate")
    toggleButton:SetWidth(ElementWidth)
    toggleButton:SetHeight(ElementHeight)
    toggleButton:SetPoint("TOP", pointReference, "BOTTOM", 0, FirstMenuElementOffset)
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
    
    table.insert(PointRefereces, toggleButton)
    FirstMenuElementOffset = 0
end

local function RenderElements()
    -- render toggle menu title
    local titlePerHonor = ToggleMenuFrame:CreateFontString(ToggleMenuFrame, nil, "GameFontHighlightSmall")
    titlePerHonor:SetHeight(TitleHeight)
    titlePerHonor:SetPoint("TOP", 0, -2)
    titlePerHonor:SetText("Per Hour")
    
    local titleToggle = ToggleMenuFrame:CreateFontString(ToggleMenuFrame, nil, "GameFontNormalSmall")
    titleToggle:SetHeight(TitleHeight)
    titleToggle:SetPoint("TOP", titlePerHonor, "BOTTOM")
    titleToggle:SetText("Toggle Menu")

    table.insert(PointRefereces, titleToggle)

    for key,contextModule in pairs(Modules) do
        -- for each module registred, we render a button
        RenderButton(contextModule)
        
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

ToggleMenuFrame:RegisterEvent("ADDON_LOADED")
ToggleMenuFrame:SetScript("OnEvent", ToggleMenu.OnEvent)
