-- definition
BaseModule = {}

local function FormatAnnouncementDuration(time)
    local hours = math.floor(time / 3600)
    local minutes = math.floor((time % 3600) / 60)
    local seconds = math.floor(time % 60)
    local parts = {}
    if hours > 0 then table.insert(parts, hours .. "h") end
    if minutes > 0 then table.insert(parts, minutes .. "m") end
    if seconds > 0 or #parts == 0 then table.insert(parts, seconds .. "s") end
    return table.concat(parts, " ")
end

function BaseModule:SendTo(contextModule, chatType)
    chatType = chatType:upper()
    local state = contextModule.State
    local total = Utils:DisplayNumber(state.Element)
    local duration = FormatAnnouncementDuration(state.Time)
    local perHour = Utils:DisplayRoundedNumber(state.ElementPerHour, 0)
    local message
    if contextModule.CustomFormatAnnouncement then
        message = contextModule.CustomFormatAnnouncement(total, duration, perHour)
    else
        local unit = contextModule.AnnouncementUnit or contextModule.Name
        message = string.format("%s %s/h - %s (%s %s total)", perHour, unit, duration, total, unit)
    end
    C_ChatInfo.SendChatMessage("[Per Hour] " .. message, chatType)
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

