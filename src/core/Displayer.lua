-- import
local PerHour = PerHour
local Utils = Utils
local BaseModule = BaseModule
local Modules = PerHour.Modules

-- class declaration
PerHour.Displayer = {}
Displayer = PerHour.Displayer

-- private properties
local Padding = 2
local PaddingIcon = 7
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
    elementPerMinuteText:SetText(contextModule.ShortName.."/min")
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

local function RenderSendTo(contextModule, sendToButton)

    local sendToOptionHeight = 16
    local sendOptionWidth = (FrameWidth-(Margin*4))/2

    local sendToOptions = {
        "Say",
        "Yell",
        "Party",
        "Guild",
        "Raid",
    }

    local sendToOptionsLength = Utils:RoundValue(Utils:GetTableSize(sendToOptions) / 2, 0)
    local sendToFrameHeight = (sendToOptionsLength * sendToOptionHeight) + (sendToOptionHeight + Margin * 2)
    
    -- FRAME
    local sendToFrame = CreateFrame("Frame", "SendToFrame"..contextModule.TagName, sendToButton)
    sendToFrame:SetWidth(FrameWidth)
    sendToFrame:SetHeight(sendToFrameHeight)
    sendToFrame:SetPoint("BOTTOMRIGHT", sendToButton, "TOPRIGHT", PaddingRight(PaddingIcon + Margin), PaddingBottom(0))
    sendToFrame:Hide()
    sendToFrame:SetScript('OnEnter', function(self, motion) if motion then self:Show() end end)
    sendToFrame:SetScript('OnLeave', function(self) self:Hide() end)

    -- set button show/hide on mouse over
    sendToButton:SetScript('OnEnter', function() sendToFrame:Show() end)
    sendToButton:SetScript('OnLeave', function() sendToFrame:Hide() end)

    local function setColorGold(texture)
        texture:SetColorTexture(0.9,0.7,0,1)
        -- texture:SetColorTexture(1,0.85,0,1)
    end

    local sendToFrameBorder=CreateFrame("frame",nil,sendToFrame)
    sendToFrameBorder:SetAllPoints(sendToFrame)
    -- sendToFrameBorder:SetFrameStrata("BACKGROUND")
    -- sendToFrameBorder:SetFrameLevel(1)
    sendToFrameBorder.left=sendToFrameBorder:CreateTexture(nil,"BORDER")
    sendToFrameBorder.left:SetPoint("BOTTOMLEFT",sendToFrameBorder,"BOTTOMLEFT",-2,-1)
    sendToFrameBorder.left:SetPoint("TOPRIGHT",sendToFrameBorder,"TOPLEFT",-1,1)
    setColorGold(sendToFrameBorder.left)
    sendToFrameBorder.right=sendToFrameBorder:CreateTexture(nil,"BORDER")
    sendToFrameBorder.right:SetPoint("BOTTOMLEFT",sendToFrameBorder,"BOTTOMRIGHT",1,-1)
    sendToFrameBorder.right:SetPoint("TOPRIGHT",sendToFrameBorder,"TOPRIGHT",2,1)
    setColorGold(sendToFrameBorder.right)
    sendToFrameBorder.top=sendToFrameBorder:CreateTexture(nil,"BORDER")
    sendToFrameBorder.top:SetPoint("BOTTOMLEFT",sendToFrameBorder,"TOPLEFT",-1,1)
    sendToFrameBorder.top:SetPoint("TOPRIGHT",sendToFrameBorder,"TOPRIGHT",1,2)
    setColorGold(sendToFrameBorder.top)
    sendToFrameBorder.bottom=sendToFrameBorder:CreateTexture(nil,"BORDER")
    sendToFrameBorder.bottom:SetPoint("BOTTOMLEFT",sendToFrameBorder,"BOTTOMLEFT",-1,-1)
    sendToFrameBorder.bottom:SetPoint("TOPRIGHT",sendToFrameBorder,"BOTTOMRIGHT",1,-2)
    setColorGold(sendToFrameBorder.bottom)

    local sendToFrameTexture = sendToFrame:CreateTexture(nil, "BACKGROUND")
    sendToFrameTexture:SetColorTexture(0,0,0,1)
    sendToFrameTexture:SetAllPoints(sendToFrame)
    
    -- TITLE
    local sendToTitle = sendToFrame:CreateFontString(sendToFrame, nil, "GameFontHighlightSmall")
    sendToTitle:SetHeight(sendToOptionHeight)
    sendToTitle:SetPoint("TOPLEFT", PaddingRight(Margin), PaddingTop(Padding))
    sendToTitle:SetText("Send to:")

    local pointLeftReference = nil
    local pointRightReference = nil
    local pointIndex = 1
    local firstSendToOptionPadding = sendToOptionHeight+(Padding*2)
    
    for key,thisOpt in pairs(sendToOptions) do

        -- for each module registred, we render a button
        local sendOption = CreateFrame("Button", "SendOption"..thisOpt, sendToFrame, "OptionsListButtonTemplate")
        sendOption:SetWidth(sendOptionWidth)
        sendOption:SetHeight(sendToOptionHeight)
        sendOption:SetText(thisOpt)
        sendOption:RegisterForClicks("AnyUp")
        sendOption:SetScript("OnClick", function(self, button, down) -- TRY: OnMouseUp
            BaseModule:SendTo(contextModule, thisOpt)
            sendToFrame:Hide()
        end)
        sendOption:SetScript('OnEnter', function() sendToFrame:Show() end)
        sendOption:SetScript('OnLeave', function() sendToFrame:Hide() end)

        local function sideDeciderToPoint(pointReference, sideDecider)
            if pointReference == nil then
                sendOption:SetPoint("TOP", (FrameWidth/4)*sideDecider, PaddingTop(firstSendToOptionPadding))
            else
                sendOption:SetPoint("TOP", pointReference, "BOTTOM", 0, PaddingTop(Padding))
            end
        end

        if pointIndex % 2 == 0 then
            -- RIGHT
            sideDeciderToPoint(pointRightReference, 1)
            pointRightReference = sendOption
        else -- LEFT
            sideDeciderToPoint(pointLeftReference, -1)
            pointLeftReference = sendOption
        end
        
        pointIndex = pointIndex + 1
    end

    -- submenu items end
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
    sendToButton:SetPoint("BOTTOMRIGHT", resetButtom, "TOPRIGHT", PaddingLeft(PaddingIcon), PaddingBottom(Padding))
    sendToButton:SetNormalTexture([[Interface\AddOns\per-hour\src\textures\announcement_gold_dark]])
    sendToButton:SetHighlightTexture([[Interface\AddOns\per-hour\src\textures\announcement_gold_dark]])
    
    RenderSendTo(contextModule, sendToButton)
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