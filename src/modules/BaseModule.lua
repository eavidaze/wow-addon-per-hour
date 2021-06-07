-- definition
BaseModule = {}

function BaseModule:SendTo(contextModule, chatType)

    -- chatType = chatType:upper()
    local addonNamePrepend = "Per Hour || "

    local dottedLine = "................"
    local dottedLineLength = string.len(dottedLine)
    local perHourLabel = contextModule.ElementPerHourText:GetText()
    local perMinuteLabel = contextModule.ElementPerMinuteText:GetText()

    local function GetDottedLineByWordSize(wordSize)
        return string.sub(dottedLine, 0, dottedLineLength - wordSize)
    end
    
    
    local greetingsMessage = addonNamePrepend.."A performance tracker AddOn!"
    local trackingMessage = addonNamePrepend.."Tracking: ....... "..contextModule.Name
    local perHourMessage = addonNamePrepend..perHourLabel..": "..GetDottedLineByWordSize(string.len(perHourLabel)-1).." "..Utils:DisplayRoundedNumber(contextModule.ElementPerHour, 0)
    local perMinuteMessage = addonNamePrepend..perMinuteLabel..": "..GetDottedLineByWordSize(string.len(perMinuteLabel)).." "..Utils:DisplayRoundedNumber(contextModule.ElementPerMinute, 0)
    local forMessage = addonNamePrepend.."Duration: ......... "..Utils:DisplayTimer(contextModule.Time).."s"
    local totalMessage = addonNamePrepend.."Total earned: ... "..Utils:DisplayNumber(contextModule.Element)
    
    SendChatMessage(greetingsMessage, chatType)
    SendChatMessage(trackingMessage, chatType)
    SendChatMessage(perHourMessage, chatType)
    SendChatMessage(perMinuteMessage, chatType)
    SendChatMessage(forMessage, chatType)
    SendChatMessage(totalMessage, chatType)
    
    if contextModule.CustomSendToMessages ~= nil then
        for key,value in pairs(contextModule.CustomSendToMessages) do
            SendChatMessage(addonNamePrepend..value(), chatType)
        end
    end

    Utils:AddonMessage("Results sent to "..chatType:lower().." successfully.")
end

function BaseModule:RefreshDisplayedValues(contextModule)
    contextModule.TimeValue:SetText(Utils:DisplayTimer(contextModule.Time))
    contextModule.ElementValue:SetText(Utils:DisplayNumber(contextModule.Element))
    contextModule.ElementPerHourValue:SetText(Utils:DisplayRoundedNumber(contextModule.ElementPerHour, 0))
    contextModule.ElementPerMinuteValue:SetText(Utils:DisplayRoundedNumber(contextModule.ElementPerMinute, 0))
end

-- public functions
function BaseModule:ResetModule(contextModule)
    -- control values
    contextModule.HasStarted = false
    contextModule.HasPaused = false

    contextModule.StartedAt = 0
    contextModule.PausedAt = 0
    contextModule.PausedTime = 0

    contextModule.TimeSinceLastUpdate = 0

    -- displayable values
    contextModule.Time = 0
    contextModule.Element = 0
    contextModule.ElementPerHour = 0
    contextModule.ElementPerMinute = 0
    
    -- run custom
    if contextModule.CustomReset~=nil then
        contextModule.CustomReset()
    end

    -- reset the button
    if contextModule.ToggleStartButtom~=nil then
        contextModule.ToggleStartButtom:SetText("Start")
    end
    
    BaseModule:RefreshDisplayedValues(contextModule)
end

