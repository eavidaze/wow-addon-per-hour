local Session = { InWorld = false, LoginAt = GetTime(), CheckingPlayed = true }
PerHour.Session = Session

local PLAYED_TOLERANCE_SECONDS = 30
local PLAYED_TIMEOUT_SECONDS = 10

local function IsFiniteNumber(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function IsValidPlayedTime(value)
    return Utils:IsReadableNumber(value) and IsFiniteNumber(value) and value >= 0
end

local function SetRestoreStatus(module, status, issue)
    module.State.RestoreStatus = status
    module.State.RestoreIssue = issue
    BaseModule:RefreshDisplayedValues(module)
end

function Session:Save()
    local sessions = {}
    local onlyPending = true
    for name, module in pairs(PerHour.Modules) do
        if module.State.HasStarted then
            local pending = module.State.PendingRestore
            if not pending then onlyPending = false end
            -- Include progress since the last tracker update, even when its panel is hidden.
            if not pending and module.CustomOnUpdate then module.CustomOnUpdate(nil, 0) end
            if module.State.HasStarted then
                BaseModule:UpdateRates(module)
                local paused = module.State.HasPaused
                if pending then paused = pending.paused end
                sessions[name] = {
                    total = module.State.Element,
                    duration = module.State.Time,
                    paused = paused,
                    context = module.CustomSaveSession and module.CustomSaveSession() or nil,
                    needsReview = module.State.RestoreStatus == "error" or (pending and pending.needsReview) or false,
                }
            end
        end
    end
    -- Extrapolate the server sample to the same instant as the saved module totals.
    local playedAtSave
    if onlyPending then playedAtSave = self.SavedPlayedTime end
    if self.PlayedAtLogin then playedAtSave = self.PlayedAtLogin + GetTime() - self.LoginAt end
    PerHour.Stores.Sessions:SaveAll(sessions, playedAtSave)
end

function Session:ValidateRestore(module)
    local data = module.State.PendingRestore
    if not data then return true end
    if self.CheckingPlayed then return false end

    local issue = data.needsReview and "This session contains unverified progress." or self.PlayedIssue
    -- Establish fresh counters while paused so missing progress is never added to the totals.
    local ready = not module.CustomOnUpdate or module.CustomOnUpdate(nil, 0)
    if module.State.HasStarted and not ready and not issue then return false end
    module.State.PendingRestore = nil
    module.State.UpdatedAt = GetTime()
    if module.State.HasStarted then
        module.State.HasPaused = data.paused or issue ~= nil
        BaseModule:UpdateRates(module)
    else
        issue = "The tracked reputation changed."
    end
    SetRestoreStatus(module, issue and "error" or "success", issue)
    return true
end

local function FinishPlayedCheck(total, issue)
    -- Keep one reference at login; later saves extrapolate from that same instant.
    if total then Session.PlayedAtLogin = total - (GetTime() - Session.LoginAt) end
    if not Session.CheckingPlayed then return end
    if not issue then
        if not IsValidPlayedTime(Session.SavedPlayedTime) then
            issue = "No saved played-time reference is available."
        elseif math.abs(Session.PlayedAtLogin - Session.SavedPlayedTime) > PLAYED_TOLERANCE_SECONDS then
            issue = "Played time differs from the last save by more than 30 seconds."
        end
    end
    Session.CheckingPlayed = false
    Session.PlayedIssue = issue
    for _, module in pairs(PerHour.Modules) do Session:ValidateRestore(module) end
end

function Session:Restore()
    self.SavedPlayedTime = PerHour.Stores.Sessions:GetPlayedAtSave()

    for _, module in pairs(PerHour.Modules) do
        local data, invalid = module.Store:ReadSession()
        if data then
            module.State.Element = data.total
            module.State.Time = data.duration
            module.State.HasStarted = true
            module.State.HasPaused = true
            module.State.UpdatedAt = GetTime()
            module.State.PendingRestore = data

            if module.CustomRestoreSession and module.CustomRestoreSession(data.context) == false then
                BaseModule:ResetModule(module)
                SetRestoreStatus(module, "error", "The saved session could not be read.")
            else
                SetRestoreStatus(module, "pending")
            end
        else
            module.Store:ClearSession()
            if invalid then SetRestoreStatus(module, "error", "The saved session could not be read.") end
        end
    end
    C_Timer.After(PLAYED_TIMEOUT_SECONDS, function()
        if Session.CheckingPlayed then FinishPlayedCheck(nil, "Could not verify played time.") end
    end)
    if type(RequestTimePlayed) ~= "function" or not pcall(RequestTimePlayed) then
        FinishPlayedCheck(nil, "Played time is unavailable.")
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LEAVING_WORLD")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("TIME_PLAYED_MSG")
frame:SetScript("OnEvent", function(self, event, totalPlayed)
    if event == "PLAYER_ENTERING_WORLD" then
        Session.InWorld = true
        if not Session.Restored then
            Session.Restored = true
            Session:Restore()
        end
    elseif event == "PLAYER_LEAVING_WORLD" then
        -- Capture progress before logout tears down player APIs.
        if Session.InWorld then Session:Save() end
        Session.InWorld = false
    elseif event == "TIME_PLAYED_MSG" then
        if Session.InWorld and IsValidPlayedTime(totalPlayed) then FinishPlayedCheck(totalPlayed) end
    elseif Session.InWorld then
        -- Fallback for reload/logout paths without PLAYER_LEAVING_WORLD.
        Session:Save()
    end
end)
