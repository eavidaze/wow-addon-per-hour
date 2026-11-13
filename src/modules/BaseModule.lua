-- definition
BaseModule = {}

function BaseModule:SendTo(contextModule, chatType)
    chatType = chatType:upper()
    local SendChatMessage = C_ChatInfo.SendChatMessage

    -- chatType = chatType:upper()
    local addonNamePrepend = "Per Hour || "

    local dottedLine = "................"
    local dottedLineLength = string.len(dottedLine)
    local perHourLabel = contextModule.ShortName .. "/h"
    local perMinuteLabel = contextModule.ShortName .. "/min"

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
    PerHour.Displayer:RefreshRate(contextModule)
    PerHour.Displayer:RefreshTrackingState(contextModule)
    PerHour.Displayer:RefreshRestoreStatus(contextModule)
    PerHour.Displayer:RefreshTooltip(contextModule)
end

function BaseModule:UpdateRates(contextModule)
    local now = GetTime()
    if contextModule.HasStarted and not contextModule.HasPaused then
        contextModule.Time = contextModule.Time + math.max(0, now - contextModule.UpdatedAt)
    end
    contextModule.UpdatedAt = now
    local perMinute = 0
    if contextModule.Time > 0 then
        perMinute = contextModule.Element / (contextModule.Time / 60)
    end
    contextModule.ElementPerMinute = Utils:RoundValue(perMinute, 2)
    contextModule.ElementPerHour = Utils:RoundValue(perMinute * 60, 2)
    self:RefreshDisplayedValues(contextModule)
end

-- public functions
function BaseModule:ResetModule(contextModule)
    -- control values
    contextModule.HasStarted = false
    contextModule.HasPaused = false
    contextModule.PendingRestore = nil
    contextModule.RestoreStatus = nil
    contextModule.RestoreIssue = nil

    contextModule.UpdatedAt = GetTime()

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

    -- Session loads after the initial panel reset, before saved sessions are restored.
    if PerHour.Session then PerHour.Session:Clear(contextModule) end

    BaseModule:RefreshDisplayedValues(contextModule)
end

