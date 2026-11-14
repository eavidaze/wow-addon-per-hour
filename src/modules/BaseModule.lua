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
    local perHourMessage = addonNamePrepend..perHourLabel..": "..GetDottedLineByWordSize(string.len(perHourLabel)-1).." "..Utils:DisplayRoundedNumber(contextModule.State.ElementPerHour, 0)
    local perMinuteMessage = addonNamePrepend..perMinuteLabel..": "..GetDottedLineByWordSize(string.len(perMinuteLabel)).." "..Utils:DisplayRoundedNumber(contextModule.State.ElementPerMinute, 0)
    local forMessage = addonNamePrepend.."Duration: ......... "..Utils:DisplayTimer(contextModule.State.Time).."s"
    local totalMessage = addonNamePrepend.."Total earned: ... "..Utils:DisplayNumber(contextModule.State.Element)
    
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
    if contextModule.State.HasStarted and not contextModule.State.HasPaused then
        contextModule.State.Time = contextModule.State.Time + math.max(0, now - contextModule.State.UpdatedAt)
    end
    contextModule.State.UpdatedAt = now
    local perMinute = 0
    if contextModule.State.Time > 0 then
        perMinute = contextModule.State.Element / (contextModule.State.Time / 60)
    end
    contextModule.State.ElementPerMinute = Utils:RoundValue(perMinute, 2)
    contextModule.State.ElementPerHour = Utils:RoundValue(perMinute * 60, 2)
    self:RefreshDisplayedValues(contextModule)
end

-- public functions
function BaseModule:ResetModule(contextModule, preserveSavedSession)
    -- control values
    contextModule.State.HasStarted = false
    contextModule.State.HasPaused = false
    contextModule.State.PendingRestore = nil
    contextModule.State.RestoreStatus = nil
    contextModule.State.RestoreIssue = nil

    contextModule.State.UpdatedAt = GetTime()

    contextModule.State.TimeSinceLastUpdate = 0

    -- displayable values
    contextModule.State.Time = 0
    contextModule.State.Element = 0
    contextModule.State.ElementPerHour = 0
    contextModule.State.ElementPerMinute = 0
    
    -- run custom
    if contextModule.CustomReset~=nil then
        contextModule.CustomReset()
    end

    -- Panel initialization resets runtime state without erasing a session awaiting restore.
    if not preserveSavedSession then contextModule.Store:ClearSession() end

    BaseModule:RefreshDisplayedValues(contextModule)
end

