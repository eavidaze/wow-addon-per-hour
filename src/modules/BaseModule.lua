BaseModule = {}
local STATUS = {
    idle={key="idle",action="Start",label="Not started"},
    running={key="running",action="Pause",label="Running"},
    paused={key="paused",action="Resume",label="Paused"},
}
function BaseModule:GetTrackingStatus()
    local current = PerHour.Session.Current
    return not current and STATUS.idle or (current.paused and STATUS.paused or STATUS.running)
end
function BaseModule:GetEstimate(module)
    local status = self:GetTrackingStatus()
    if status.key ~= "running" then return status.label end
    local state = module.State
    if state.PendingRestore or state.Available == false or not PerHour.Session.InWorld then return "No estimate available" end
    local goal, remaining, reached = module.CustomGetEstimateGoal()
    if reached then return reached end
    if not goal or not Utils:IsFiniteNumber(remaining) or remaining <= 0 then return "No estimate available" end
    if state.Time < 60 then return "Estimating…" end
    if state.Element <= 0 then return "No estimate available" end
    local minutes = math.max(1, math.ceil(remaining / (state.Element / state.Time) / 60))
    if not Utils:IsFiniteNumber(minutes) then return "No estimate available" end
    local hours = math.floor(minutes/60)
    return goal .. " in " .. (hours > 0 and hours .. "h" or "")
        .. (minutes%60 > 0 and (hours > 0 and " " or "") .. minutes%60 .. "m" or "")
end
function BaseModule:RefreshDisplayedValues()
    if PerHour.Dashboard then PerHour.Dashboard:RequestRefresh() end
end
function BaseModule:UpdateRates()
    if PerHour.Session and not PerHour.Session.Sampling then PerHour.Session:Touch(); PerHour.Session:UpdateRates() end
    self:RefreshDisplayedValues()
end
function BaseModule:ResetModule(module)
    module.State = {
        Element=0, Time=0, ElementPerMinute=0, ElementPerHour=0,
        HasStarted=false, HasPaused=false, UpdatedAt=GetTime(), Available=true,
    }
    if module.CustomReset then module.CustomReset() end
end
function BaseModule:SendTo(module, channel)
    if not PerHour.Session.Current or PerHour.Session.CheckingPlayed then return end
    PerHour.Session:Sample()
    local state = module.State
    if state.Available == false then return end
    local format = module.FormatValue or function(value) return Utils:DisplayRoundedNumber(value, 0) end
    local total, perHour = format(state.Element), format(state.ElementPerHour)
    local duration = Utils:DisplayTimer(state.Time)
    local message = module.CustomFormatAnnouncement and module.CustomFormatAnnouncement(total,duration,perHour)
        or string.format("%s %s/h - %s (%s %s total)",perHour,module.ShortName,duration,total,module.ShortName)
    if state.Partial then message = message .. " [Partial]" end
    if module.Name == "Gold" and next(state.PendingPrices) then message = message .. " [Pending]" end
    C_ChatInfo.SendChatMessage("[Per Hour] " .. message, channel:upper())
end

