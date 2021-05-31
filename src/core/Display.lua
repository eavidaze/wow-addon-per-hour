-- import
local PerHour = PerHour
local Utils = Utils
local Modules = PerHour.Modules

-- class declaration
DisplayPerHour = {}
PerHour.DisplayPerHour = DisplayPerHour

-- private properties - addon
local Padding = 2
local function GetPaddingTop() return Padding*-1 end
local function GetPaddingBottom() return Padding end
local Margin = 5
local function GetMarginTop() return Margin*-1 end
local function GetMarginBottom() return Margin end

local FrameWidth = 140
local FrameHeight = 150

local STATIC_UPDATE_INTERVAL = 1

-- private display functions
local function UpdateDisplayedValues(contextModule)
    contextModule.TimeValue:SetText(Utils:DisplayTimer(contextModule.Time))
    contextModule.ElementValue:SetText(Utils:DisplayNumber(contextModule.Element))
    contextModule.ElementPerHourValue:SetText(Utils:DisplayRoundedNumber(contextModule.ElementPerHour, 1))
    contextModule.ElementPerMinuteValue:SetText(Utils:DisplayRoundedNumber(contextModule.ElementPerMinute, 1))
end

-- private buttons functions
local function ButtonStartOnClick(contextModule)
    -- if not started or was paused
    if not contextModule.HasStarted or contextModule.HasPaused then

        -- if not was paused, have to set the new start time
        if not contextModule.HasStarted then
            contextModule.StartedAt = GetTime()
            DEFAULT_CHAT_FRAME:AddMessage("Honor Per Hour™ started.")
        else -- else I just have to calc the time paused
            contextModule.PausedTime = contextModule.PausedTime + GetTime() - contextModule.PausedAt
            DEFAULT_CHAT_FRAME:AddMessage("Honor Per Hour™ was unpaused.")
        end

        contextModule.HasStarted = true
        contextModule.HasPaused = false
        
        -- not yet
        -- Honor:SetValuesAlpha(1)
    else
        DEFAULT_CHAT_FRAME:AddMessage("Honor Per Hour™ has already started.")
    end
end

local function ButtonPauseOnClick(contextModule)
    
    if not contextModule.HasPaused then
        contextModule.HasPaused = true
        contextModule.PausedAt = GetTime()
        
        -- not yet
        -- Honor:SetValuesAlpha(0.5)
        DEFAULT_CHAT_FRAME:AddMessage("Honor Per Hour™ has paused.")
    else
        DEFAULT_CHAT_FRAME:AddMessage("Honor Per Hour™ has already been paused.")
    end

end

local function ButtonResetOnClick(contextModule)
    -- define values
    contextModule.Time = 0
    contextModule.Element = 0
    contextModule.ElementPerHour = 0
    contextModule.ElementPerMinute = 0
    
    -- define controls
    contextModule.HasStarted = false
    contextModule.HasPaused = false

    contextModule.StartedAt = 0
    contextModule.PausedAt = 0
    contextModule.PausedTime = 0

    contextModule.TimeSinceLastUpdate = 0
    
    UpdateDisplayedValues(contextModule)
    DEFAULT_CHAT_FRAME:AddMessage("Honor Per Hour™ is clear.")
end

-- private render functions
local function RenderFrame(contextModule)
    -- create frame
    local Frame = CreateFrame("Frame", PerHour.AddonName .. "-" .. contextModule.TagName .. "-frame", UIParent)
    contextModule.Frame = Frame
    
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
    Frame:SetPoint("CENTER",0,0)
    Frame:Show()
    -- Frame:Hide()

    -- set texture
    local FrameTexture = Frame:CreateTexture(nil,"BACKGROUND")
    FrameTexture:SetColorTexture(0,0,0,0.2)
    FrameTexture:SetAllPoints(Frame)
end

local function RenderElements(contextModule)
    local Frame = contextModule.Frame

    -- time             | [left]       |
    local timeText = Frame:CreateFontString(Frame, "OVERLAY", "GameFontHighlightSmall")
    timeText:SetPoint("TOP", (FrameWidth/4)*-1, GetMarginTop())
    timeText:SetText("TIME")
    -- time valeu       | [left]       |
    local timeValue = Frame:CreateFontString(Frame, "OVERLAY", "GameFontNormal")
    timeValue:SetPoint("TOP", timeText, "BOTTOM", 0, GetPaddingTop())

    -- element          |       [right] |
    local elementText = Frame:CreateFontString(Frame, "OVERLAY", "GameFontHighlightSmall")
    elementText:SetPoint("TOP", (FrameWidth/4), GetMarginTop())
    if string.len(contextModule.Name) <= 6 then
        elementText:SetText(contextModule.Name:upper())
    else
        elementText:SetText(contextModule.ShortName:upper())
    end
    -- element value    |       [right] |
    local elementValue = Frame:CreateFontString(Frame, "OVERLAY", "GameFontNormal")
    elementValue:SetPoint("TOP", elementText, "BOTTOM", 0, GetPaddingTop())

    -- element/h        |   [center]   |
    local elementPerHourText = Frame:CreateFontString(Frame, "OVERLAY", "GameFontHighlightSmall")
    elementPerHourText:SetPoint("TOP", 0, -39)
    elementPerHourText:SetText(contextModule.ShortName.."/h")
    -- element/h value  |   [center]   |
    local elementPerHourValue = Frame:CreateFontString(Frame, "OVERLAY", "GameFontNormal")
    elementPerHourValue:SetPoint("TOP", elementPerHourText, "BOTTOM", 0, GetPaddingTop())
    elementPerHourValue:SetFont("Fonts\\ARIALN.TTF", 32)

    -- element/m        | [left]       |
    local elementPerMinuteText = Frame:CreateFontString(Frame, "OVERLAY", "GameFontHighlightSmall")
    elementPerMinuteText:SetPoint("TOP", (FrameWidth/4)*-1, -91)
    elementPerMinuteText:SetText(contextModule.ShortName.."/m")
    -- element/m value  | [left]       |
    local elementPerMinuteValue = Frame:CreateFontString(Frame, "OVERLAY", "GameFontNormal")
    elementPerMinuteValue:SetPoint("TOP", elementPerMinuteText, "BOTTOM", 0, GetPaddingTop())

    contextModule.TimeValue = timeValue
    contextModule.ElementValue = elementValue
    contextModule.ElementPerHourValue = elementPerHourValue
    contextModule.ElementPerMinuteValue = elementPerMinuteValue
end

local function RenderButtons(contextModule)
    local Frame = contextModule.Frame

    -- configure buttons
    local startButtom = CreateFrame("Button", "StartXPPerHour", Frame, "UIGoldBorderButtonTemplate")
    startButtom:SetWidth(FrameWidth - (Margin * 2))
    startButtom:SetHeight(22)
    startButtom:SetPoint("BOTTOM", 0, GetMarginBottom())
    startButtom:SetText("Start")
    startButtom:RegisterForClicks("AnyUp")
    startButtom:SetScript("OnClick", function(self, button, down)
        if self:GetText() == "Start" then
            self:SetText("Pause")
            ButtonStartOnClick(contextModule)
        else
            self:SetText("Start")
            ButtonPauseOnClick(contextModule)
        end
    end)
    
    local resetButtom = CreateFrame("Button", "ResetXPPerHour", Frame, "UIMenuButtonStretchTemplate")
    resetButtom:SetWidth((FrameWidth/2) - Margin)
    resetButtom:SetHeight(22)
    resetButtom:SetPoint("BOTTOMRIGHT", startButtom, "TOPRIGHT", 0, GetPaddingBottom())
    resetButtom:SetText("Reset")
    resetButtom:RegisterForClicks("AnyUp")
    resetButtom:SetScript("OnClick", function(self, button, down)
        ButtonResetOnClick(contextModule)
    end)
end

local function RegisterScripts(contextModule)
    local Frame = contextModule.Frame
    
    Frame:SetScript("OnEvent", function(self, event, ...)
        contextModule:CustomOnEvent(self, event, ...)
    end)

    Frame:SetScript("OnUpdate", function(self, elapsed)
        if contextModule.HasStarted and not contextModule.HasPaused then
            contextModule.TimeSinceLastUpdate = contextModule.TimeSinceLastUpdate + elapsed
            if (contextModule.TimeSinceLastUpdate > STATIC_UPDATE_INTERVAL) then
                contextModule.TimeSinceLastUpdate = 0

                contextModule.Time = GetTime() - contextModule.StartedAt - contextModule.PausedTime

                local elementPerMinute = contextModule.Element / (contextModule.Time / 60)
                
                contextModule.ElementPerMinute = Utils:RoundValue(elementPerMinute, 2)
                contextModule.ElementPerHour = Utils:RoundValue(elementPerMinute * 60, 2)
                
                UpdateDisplayedValues(contextModule)
            end
        end
    end)
end

local function RegisterEvents(contextModule)
    local Frame = contextModule.Frame
    Frame:RegisterEvent("ADDON_LOADED")
    for k,value in pairs(contextModule.RegisteredEvents) do
        Frame:RegisterEvent(value)
    end
end

-- public functions
function DisplayPerHour:Init()
    -- for each module I render 1 addon
    for key,contextModule in pairs(Modules) do
        
        RenderFrame(contextModule)
        RenderElements(contextModule)
        RenderButtons(contextModule)
        RegisterScripts(contextModule)
        RegisterEvents(contextModule)

        -- startup addon
        ButtonResetOnClick(contextModule)
    end
    -- Frame:SetScript("OnEvent", DisplayPerHour.OnEvent)
end

DisplayPerHour:Init()