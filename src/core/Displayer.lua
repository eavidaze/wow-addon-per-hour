-- import
local PerHour = PerHour
local Utils = Utils
local BaseModule = BaseModule
local Modules = PerHour.Modules

-- class declaration
PerHour.Displayer = {}
Displayer = PerHour.Displayer

-- private properties - addon
local Padding = 2
local function PaddingTop(padding) return padding*-1 end
local function PaddingBottom(padding) return padding end
local function PaddingLeft(padding) return padding*-1 end
local function PaddingRight(padding) return padding end
local Margin = 5
local function GetMarginTop() return Margin*-1 end
local function GetMarginBottom() return Margin end

local FrameWidth = 140
local FrameHeight = 150

local STATIC_UPDATE_INTERVAL = 1

-- private display functions


-- private buttons functions
local function ToggleStartOnClick(contextModule)
    
    if contextModule.HasStarted and not contextModule.HasPaused then
        -- if started and not paused > then pause
        contextModule.HasPaused = true
        -- and set the pause time
        contextModule.PausedAt = GetTime()

        contextModule.ToggleStartButtom:SetText("Start")
        Utils:AddonMessage(contextModule.Name.." paused.")

    elseif contextModule.HasStarted and contextModule.HasPaused then
        -- if started and paused
        -- unpause
        contextModule.HasPaused = false
        -- and sum the time paused
        contextModule.PausedTime = contextModule.PausedTime + GetTime() - contextModule.PausedAt

        contextModule.ToggleStartButtom:SetText("Pause")
        Utils:AddonMessage(contextModule.Name.." was unpaused.")

    elseif not contextModule.HasStarted then
        -- if not started
        -- start
        contextModule.HasStarted = true
        -- and set the start time
        contextModule.StartedAt = GetTime()

        contextModule.ToggleStartButtom:SetText("Pause")
        
        local startedMessage = " started."
        if contextModule.CustomStartedMessage~=nil then
            startedMessage = contextModule.CustomStartedMessage()
        end
        Utils:AddonMessage(contextModule.Name..startedMessage)
        
    else

    end
    
end

local function ButtonResetOnClick(contextModule)
    BaseModule:ResetModule(contextModule)
    Utils:AddonMessage(contextModule.Name.." reseted.")
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
    
    -- Frame:Show() or Frame:Hide() will be later
    -- we have a config for that #display0192364

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
    timeValue:SetPoint("TOP", timeText, "BOTTOM", 0, PaddingTop(Padding))

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
    elementValue:SetPoint("TOP", elementText, "BOTTOM", 0, PaddingTop(Padding))

    -- element/h        |   [center]   |
    local elementPerHourText = Frame:CreateFontString(Frame, "OVERLAY", "GameFontHighlightSmall")
    elementPerHourText:SetPoint("TOP", 0, -39)
    elementPerHourText:SetText(contextModule.ShortName.."/h")
    -- element/h value  |   [center]   |
    local elementPerHourValue = Frame:CreateFontString(Frame, "OVERLAY", "GameFontNormal")
    elementPerHourValue:SetPoint("TOP", elementPerHourText, "BOTTOM", 0, PaddingTop(Padding))
    elementPerHourValue:SetFont("Fonts\\ARIALN.TTF", 32)

    -- element/m        | [left]       |
    local elementPerMinuteText = Frame:CreateFontString(Frame, "OVERLAY", "GameFontHighlightSmall")
    elementPerMinuteText:SetPoint("TOP", (FrameWidth/4)*-1, -91)
    elementPerMinuteText:SetText(contextModule.ShortName.."/m")
    -- element/m value  | [left]       |
    local elementPerMinuteValue = Frame:CreateFontString(Frame, "OVERLAY", "GameFontNormal")
    elementPerMinuteValue:SetPoint("TOP", elementPerMinuteText, "BOTTOM", 0, PaddingTop(Padding))

    -- set module texts
    contextModule.TimeText = timeText
    contextModule.ElementText = elementText
    contextModule.ElementPerHourText = elementPerHourText
    contextModule.ElementPerMinuteText = elementPerMinuteText

    -- set module values
    contextModule.TimeValue = timeValue
    contextModule.ElementValue = elementValue
    contextModule.ElementPerHourValue = elementPerHourValue
    contextModule.ElementPerMinuteValue = elementPerMinuteValue
end

local function RenderButtons(contextModule)
    local Frame = contextModule.Frame

    -- configure buttons
    local toggleStartButtom = CreateFrame("Button", "StartXPPerHour", Frame, "UIGoldBorderButtonTemplate")
    contextModule.ToggleStartButtom = toggleStartButtom
    toggleStartButtom:SetWidth(FrameWidth - (Margin * 2))
    toggleStartButtom:SetHeight(22)
    toggleStartButtom:SetPoint("BOTTOM", 0, GetMarginBottom())
    toggleStartButtom:SetText("Start") -- when save state, we gonna change this
    toggleStartButtom:RegisterForClicks("AnyUp")
    toggleStartButtom:SetScript("OnClick", function(self, button, down)
        ToggleStartOnClick(contextModule)
    end)
    
    local resetButtom = CreateFrame("Button", "ResetXPPerHour", Frame, "UIMenuButtonStretchTemplate")
    resetButtom:SetWidth((FrameWidth/2) - Margin)
    resetButtom:SetHeight(20)
    resetButtom:SetPoint("BOTTOMRIGHT", toggleStartButtom, "TOPRIGHT", 0, PaddingBottom(Padding))
    resetButtom:SetText("Reset")
    resetButtom:RegisterForClicks("AnyUp")
    resetButtom:SetScript("OnClick", function(self, button, down)
        ButtonResetOnClick(contextModule)
    end)

    local sendToButton = CreateFrame("Button", "sendPerHour", Frame, "SecureActionButtonTemplate")
    sendToButton:SetSize(14,14)
    sendToButton:SetPoint("BOTTOMRIGHT", resetButtom, "TOPRIGHT", PaddingLeft(7), PaddingBottom(5))
    sendToButton:SetNormalTexture([[Interface\AddOns\PerHour\src\textures\announcement_gold_dark]])
    sendToButton:SetHighlightTexture([[Interface\AddOns\PerHour\src\textures\announcement_gold_dark]])
    
    sendToOptionSize = 15
    local sendToOptions = {
        "Say",
        "Party",
        "Guid",
        "Raid",
    }
    
    -- submenu
    local sendToMenu = CreateFrame("Frame", "hoverxxx"..contextModule.TagName, sendToButton)
    sendToMenu:SetSize(70,(Utils:GetTableSize(sendToOptions) + 1) * sendToOptionSize)
    sendToMenu:SetPoint("BOTTOMRIGHT", sendToButton, "TOPRIGHT", PaddingRight(5), PaddingBottom(0))
    sendToMenu:Hide()
    sendToMenu:SetScript('OnEnter', function(self, motion)
        if motion then
            sendToMenu:Show()
        end
        Utils:Print("menu show"..tostring(motion))
    end)
    sendToMenu:SetScript('OnLeave', function()
        sendToMenu:Hide()
        Utils:Print("menu hide")
    end)
    
    local sendToMenuTexture = sendToMenu:CreateTexture(nil, "BACKGROUND")
    sendToMenuTexture:SetColorTexture(0,0,0,1)
    sendToMenuTexture:SetAllPoints(sendToMenu)
    -- submenu end
    
    -- submenu items

    -- render submenu title
    local sendToTitle = sendToMenu:CreateFontString(sendToMenu, nil, "GameFontHighlightSmall")
    sendToTitle:SetHeight(sendToOptionSize)
    sendToTitle:SetPoint("TOP", 0, 0)
    sendToTitle:SetText("Send to:")

    local pointReference = sendToTitle

    for key,thisOpt in ipairs(sendToOptions) do
        -- for each module registred, we render a button
        local sendOption = CreateFrame("Button", "SendOption"..thisOpt, sendToMenu, "OptionsListButtonTemplate")
        sendOption:SetWidth(60)
        sendOption:SetHeight(sendToOptionSize)
        sendOption:SetPoint("TOP", pointReference, "BOTTOM", 0, 0)
        sendOption:SetText(thisOpt)
        sendOption:SetScript('OnEnter', function()
            sendToMenu:Show()
            Utils:Print(thisOpt.." bt show")
        end)
        sendOption:SetScript('OnLeave', function()
            sendToMenu:Hide()
            Utils:Print(thisOpt.." bt hide")
        end)
        sendOption:RegisterForClicks("AnyUp")
        sendOption:SetScript("OnClick", function(self, button, down)
            Utils:Print("send to: "..thisOpt)
            sendToMenu:Hide()
        end)

        pointReference = sendOption
    end
    -- submenu items end

    sendToButton:SetScript('OnEnter', function()
        sendToMenu:Show()
        Utils:Print("icon show")
    end)
    sendToButton:SetScript('OnLeave', function()
        sendToMenu:Hide()
        Utils:Print("icon hide")
    end)

    -- local Frame = CreateFrame("Frame", PerHour.AddonName .. "-" .. contextModule.TagName .. "-frame", UIParent)
    -- contextModule.Frame = Frame
    
    -- -- set frame size
    -- Frame:SetFrameStrata("HIGH")
    -- Frame:SetWidth(FrameWidth)
    -- Frame:SetHeight(FrameHeight)
    
    -- -- set texture
    -- local FrameTexture = Frame:CreateTexture(nil,"BACKGROUND")
    -- FrameTexture:SetColorTexture(0,0,0,0.2)
    -- FrameTexture:SetAllPoints(Frame)
end

local function RegisterScripts(contextModule)
    local Frame = contextModule.Frame
    
    Frame:SetScript("OnEvent", function(self, event, ...)
        if contextModule.HasStarted then
            -- run custom
            if contextModule.CustomOnEvent~=nil then
                contextModule.CustomOnEvent(self, event, ...)
            end
        end
    end)

    Frame:SetScript("OnUpdate", function(self, elapsed)
        if contextModule.HasStarted then
            -- check if displayer is started

            contextModule.TimeSinceLastUpdate = contextModule.TimeSinceLastUpdate + elapsed
            if (contextModule.TimeSinceLastUpdate > STATIC_UPDATE_INTERVAL) then
                contextModule.TimeSinceLastUpdate = 0

                -- run custom
                if contextModule.CustomOnUpdate~=nil then
                    contextModule.CustomOnUpdate(self, elapsed)
                end

                if contextModule.HasStarted and not contextModule.HasPaused then
                    -- check if the custom event does not stop the displayer
                    contextModule.Time = GetTime() - contextModule.StartedAt - contextModule.PausedTime
                    local elementPerMinute = contextModule.Element / (contextModule.Time / 60)
                    contextModule.ElementPerMinute = Utils:RoundValue(elementPerMinute, 2)
                    contextModule.ElementPerHour = Utils:RoundValue(elementPerMinute * 60, 2)
                    
                    BaseModule:RefreshDisplayedValues(contextModule)
                end
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
function Displayer:Init()
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
    -- Frame:SetScript("OnEvent", Displayer.OnEvent)
end

Displayer:Init()