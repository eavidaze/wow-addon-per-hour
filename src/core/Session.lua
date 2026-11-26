local Session = { InWorld=false, Restored=false, CheckingPlayed=false, Sampling=false, LoginAt=GetTime() }
PerHour.Session = Session
local Store = PerHour.Stores.Sessions
local function Now() return GetServerTime() end
local function Map()
    local id = C_Map and C_Map.GetBestMapForUnit("player")
    local info = id and C_Map.GetMapInfo(id)
    return (info and info.name) or (GetZoneText and GetZoneText()) or "Unknown area", id
end
function Session:MarkPartial(module, reason)
    local state = module.State
    state.Partial, state.Issue = true, reason or "Capture was interrupted."
    if module.Name == "Reputation" and state.Factions and state.LastFactionID then
        local faction = state.Factions[state.LastFactionID]
        if faction then faction.partial = true end
    end
end
function Session:Touch()
    local current = self.Current
    local now = GetTime()
    if current and not current.paused and not self.CheckingPlayed and self.InWorld then
        local delta = math.max(0, now - (self.UpdatedAt or now))
        current.duration = current.duration + delta
        if PerHour.Modules.Reputation.AccumulateTime then PerHour.Modules.Reputation:AccumulateTime(delta) end
    end
    self.UpdatedAt = now
    for _, module in pairs(PerHour.Modules) do
        if module.State then
            module.State.Time = module.Name == "Reputation" and module.State.FactionTime or (current and current.duration or 0)
            module.State.Time = module.State.Time or 0
            module.State.UpdatedAt = now
        end
    end
end
function Session:Call(module, hook, ...)
    if module.State.Disabled then return false end
    if not module[hook] then return true end
    local ok, ready = pcall(module[hook], ...)
    if not ok or ready == false then
        module.State.Available = false
        self:MarkPartial(module, "Metric data temporarily unavailable.")
        return false
    end
    if ready == true and module.Name ~= "Reputation" then module.State.Available = true end
    return true
end
function Session:UpdateRates()
    for _, module in pairs(PerHour.Modules) do
        local state = module.State
        state.ElementPerMinute = state.Time > 0 and state.Element * 60 / state.Time or 0
        state.ElementPerHour = state.ElementPerMinute * 60
    end
end
function Session:Sample(periodic)
    if not self.Current or self.Sampling or self.CheckingPlayed or not self.InWorld then return end
    self.Sampling = true
    self:Touch()
    for _, name in ipairs(PerHour.MetricOrder) do
        local module = PerHour.Modules[name]
        self:Call(module, "CustomOnUpdate", periodic and module.View.TrackerFrame or nil, 0)
    end
    self:Touch()
    self:UpdateRates()
    self.Sampling = false
end
function Session:Refresh()
    self:UpdateRates()
    if PerHour.Dashboard then PerHour.Dashboard:RefreshDisplays() end
    if PerHour.SessionPanels then PerHour.SessionPanels:Invalidate() end
end
function Session:ResetModules()
    for _, name in ipairs(PerHour.MetricOrder) do BaseModule:ResetModule(PerHour.Modules[name], true) end
end
function Session:Rebase()
    for _, module in pairs(PerHour.Modules) do module.State.HasPaused = true end
    self:Call(PerHour.Modules.Experience, "CustomStart")
    self:Call(PerHour.Modules.Reputation, "CustomStart")
    self:Call(PerHour.Modules.Gold, "CustomTrackingChanged")
    self.UpdatedAt = GetTime()
    for _, module in pairs(PerHour.Modules) do
        module.State.HasPaused = self.Current.paused or self.CheckingPlayed
        module.State.PendingRestore = self.CheckingPlayed and true or nil
    end
    self:Touch()
end
function Session:Start()
    if self.Current or not self.InWorld then return false end
    self:ResetModules()
    Store:BindCharacter()
    Store.Data.sequence = (tonumber(Store.Data.sequence) or 0) + 1
    local map, mapID = Map()
    local level, maximum, xp = UnitLevel("player"), UnitXPMax("player"), UnitXP("player")
    self.Current = {
        id=Store.Character .. ":" .. Now() .. ":" .. Store.Data.sequence,
        name="Session in " .. map, map=map, mapID=mapID, zones={map},
        startedAt=Now(), duration=0, paused=false,
        character=Store.Character, startLevel=Utils:IsFiniteNumber(level) and level or 0,
        startXpPercent=Utils:IsFiniteNumber(maximum) and maximum > 0 and Utils:IsFiniteNumber(xp) and xp >= 0 and xp <= maximum
            and math.floor(xp / maximum * 100) or nil,
    }
    local cap = GetMaxPlayerLevel and GetMaxPlayerLevel()
    self.Current.startAtMaxLevel = Utils:IsFiniteNumber(level) and Utils:IsFiniteNumber(cap) and level >= cap
    self.Issue = nil
    self.CheckingPlayed = false
    self.UpdatedAt = GetTime()
    for _, module in pairs(PerHour.Modules) do
        module.State.HasStarted, module.State.HasPaused = true, true
    end
    self:Call(PerHour.Modules.Gold, "CustomStart")
    self:Rebase()
    self:Save()
    self:Refresh()
    return true
end
function Session:Pause()
    if not self.Current or self.Current.paused or self.CheckingPlayed then return false end
    self:Sample()
    self.Current.paused = true
    for _, module in pairs(PerHour.Modules) do module.State.HasPaused = true end
    self:Call(PerHour.Modules.Gold, "CustomTrackingChanged")
    self:Save()
    self:Refresh()
    return true
end
function Session:Resume()
    if not self.Current or not self.Current.paused or self.CheckingPlayed or not self.InWorld then return false end
    self.Current.needsReview = nil
    self.Current.paused = false
    self:Rebase()
    self:Save()
    self:Refresh()
    return true
end
function Session:Toggle()
    if not self.Current then return self:Start()
    elseif self.Current.paused then return self:Resume()
    else return self:Pause() end
end
function Session:Context()
    if not self.Current then return end
    local map = Map()
    for _, existing in ipairs(self.Current.zones) do if existing == map then return end end
    self.Current.zones[#self.Current.zones+1] = map
end
function Session:GetSnapshot(details)
    if not self.Current then return end
    local record = PerHour.Copy(self.Current)
    record.metrics = {}
    for _, name in ipairs(PerHour.MetricOrder) do
        local state = PerHour.Modules[name].State
        record.metrics[name] = {
            total=state.Element, duration=state.Time, available=state.Available ~= false,
            partial=state.Partial == true, issue=state.Issue,
        }
    end
    local gold = PerHour.Modules.Gold.State
    local coins, items, expenses, pending = 0, 0, 0, 0
    for _, entry in ipairs(gold.History) do
        if entry.pending then pending = pending + 1
        elseif entry.direction < 0 then expenses = expenses - entry.amount
        elseif entry.itemID then items = items + entry.amount
        else coins = coins + entry.amount end
    end
    record.gold = gold.RecoveredSummary and PerHour.Copy(gold.RecoveredSummary) or { coins=coins, items=items, expenses=expenses }
    record.metrics.Gold.pending = pending > 0
    record.metrics.Gold.pendingCount = pending
    local rep = PerHour.Modules.Reputation.State
    record.reputation = PerHour.Copy(rep.RecoveredFactions or rep.Factions)
    record.reputationFaction = PerHour.Modules.Reputation.State.LastFactionID
    if details then
        record.events = {}
        local first = math.max(1, #gold.History - Store.EventLimit + 1)
        for index=first,#gold.History do record.events[#record.events+1] = PerHour.Copy(gold.History[index]) end
        record.eventsLimited = first > 1
        record.segments = PerHour.Copy(PerHour.Modules.Reputation.State.Segments)
    end
    return record
end
function Session:Save()
    if PerHour.Dashboard then PerHour.Dashboard:SaveDraggingPositions() end
    if PerHour.MinimapButton then PerHour.MinimapButton:SaveDragPosition() end
    if not self.Current then return end
    self:Sample()
    local checkpoint = { record=self:GetSnapshot(false), modules={}, disabled={}, playedAtSave=self.SavedPlayedTime }
    for name, module in pairs(PerHour.Modules) do
        checkpoint.disabled[name] = module.State.Disabled == true
        checkpoint.modules[name] = not module.State.Disabled and module.CustomSaveSession and module.CustomSaveSession() or {}
    end
    if self.PlayedAtLogin then checkpoint.playedAtSave = self.PlayedAtLogin + GetTime() - self.LoginAt end
    Store:SaveCurrent(checkpoint)
end
function Session:Finish()
    if not self.Current then return false end
    if self.CheckingPlayed then
        -- Finish never waits for a verification/price reply to archive preserved data.
        self.CheckingPlayed = false
        for _, module in pairs(PerHour.Modules) do
            self:MarkPartial(module, "Finalized before continuity verification completed.")
            module.State.PendingRestore = nil
        end
    else self:Sample() end
    local record = self:GetSnapshot(true)
    record.finishedAt, record.paused = Now(), nil
    local gold = PerHour.Modules.Gold.State
    record.metrics.Gold.incomplete = gold.Disabled == true or record.metrics.Gold.pending or next(gold.QuestDeliveries) ~= nil
        or gold.Expense ~= nil or next(gold.Casts) ~= nil
    for _, entry in ipairs(record.events) do
        if entry.pending then entry.pending, entry.excluded = nil, true end
    end
    record.metrics.Gold.pending = false
    local archived = Store:Archive(record)
    if PerHour.SessionPanels then PerHour.SessionPanels:SessionFinished(archived) end
    self.Current = nil
    self:ResetModules()
    self:Refresh()
    return record
end
function Session:Rename(name)
    local valid = Store.ValidName(name)
    if not self.Current or not valid then return false end
    self.Current.name = valid
    self:Save()
    self:Refresh()
    return true
end
function Session:FinishVerification(total, issue)
    if Utils:IsFiniteNumber(total) and total >= 0 then
        self.PlayedAtLogin = total - (GetTime() - self.LoginAt)
    end
    if not self.CheckingPlayed then return end
    if not issue and (not Utils:IsFiniteNumber(self.SavedPlayedTime)
        or math.abs(self.PlayedAtLogin - self.SavedPlayedTime) > 30) then
        issue = "Continuity could not be verified; review the preserved totals before Resume."
    end
    self.CheckingPlayed = false
    if not self.Current then return end
    if issue or self.Current.needsReview then
        self.Current.paused, self.Current.needsReview = true, true
        for _, module in pairs(PerHour.Modules) do self:MarkPartial(module, issue or "Unverified progress.") end
    else self.Current.paused = self.RestorePaused end
    for _, module in pairs(PerHour.Modules) do module.State.PendingRestore = nil end
    self:Rebase()
    self:Call(PerHour.Modules.Gold, "CustomRestoreFinished")
    self:Refresh()
end
function Session:Restore(isReload)
    Store:BindCharacter()
    local checkpoint = Store:ReadCurrent()
    if checkpoint and (type(checkpoint) ~= "table" or not Store:IsRecord(checkpoint.record)
        or type(checkpoint.modules) ~= "table") then
        Store:Quarantine(checkpoint, "Saved session could not be read.")
        self.Issue = "Saved session could not be read. Recoverable data was preserved."
        checkpoint = nil
    end
    if checkpoint then
        local record = checkpoint.record
        self.Current = PerHour.Copy(record)
        self.Current.metrics, self.Current.gold, self.Current.reputation = nil, nil, nil
        self.RestorePaused = not isReload or record.paused == true
        self.Current.paused, self.CheckingPlayed = true, true
        self.SavedPlayedTime = checkpoint.playedAtSave
        for name, module in pairs(PerHour.Modules) do
            local metric = record.metrics[name]
            module.State.Element, module.State.Time = metric.total, metric.duration
            module.State.HasStarted, module.State.HasPaused, module.State.PendingRestore = true, true, true
            module.State.Available, module.State.Partial, module.State.Issue = metric.available, metric.partial, metric.issue
            if module.CustomRestoreSession then
                local disabled = type(checkpoint.disabled) == "table" and checkpoint.disabled[name] == true
                local ok, ready = false, false
                if not disabled then ok,ready=pcall(module.CustomRestoreSession, checkpoint.modules[name]) end
                if not ok or ready == false then
                    if not disabled then Store:Quarantine(checkpoint, name .. " context could not be read.") end
                    self:MarkPartial(module, "Saved metric details could not be read.")
                    module.State.Available = false
                    -- Preserve readable summaries; isolate the damaged metric for this session.
                    module.CustomReset()
                    module.State.Element = metric.total
                    module.State.Disabled = true
                    if name == "Gold" then module.State.RecoveredSummary = PerHour.Copy(record.gold)
                    elseif name == "Reputation" then
                        module.State.RecoveredFactions = PerHour.Copy(record.reputation)
                        for _,faction in pairs(module.State.RecoveredFactions or {}) do faction.partial=true end
                    end
                    module.State.HasStarted, module.State.HasPaused, module.State.PendingRestore = true, true, true
                end
            end
        end
    end
    self.UpdatedAt = GetTime()
    local token = {}
    self.VerificationToken = token
    C_Timer.After(10, function()
        if self.VerificationToken == token and self.CheckingPlayed then
            self:FinishVerification(nil, "Continuity check timed out. Review the saved totals before Resume.")
        end
    end)
    if type(RequestTimePlayed) ~= "function" or not pcall(RequestTimePlayed) then
        self:FinishVerification(nil, "Continuity verification is unavailable.")
    end
end

local frame = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_LEAVING_WORLD", "PLAYER_LOGOUT",
    "TIME_PLAYED_MSG", "ZONE_CHANGED_NEW_AREA" }) do frame:RegisterEvent(event) end
frame:SetScript("OnEvent", function(_, event, first, second)
    if event == "PLAYER_ENTERING_WORLD" then
        Session.InWorld = true
        Session.UpdatedAt = GetTime()
        if not Session.Restored then
            Session.Restored = true
            Session:Restore(second == true)
            PerHour.Dashboard:RestorePositions()
        elseif Session.Current then Session:Rebase() end
        Session:Context()
        Session:Refresh()
    elseif event == "PLAYER_LEAVING_WORLD" then
        Session:Save()
        Session.InWorld = false
        Session:Refresh()
    elseif event == "PLAYER_LOGOUT" then Session:Save()
    elseif event == "TIME_PLAYED_MSG" and Session.InWorld and Utils:IsFiniteNumber(first) and first >= 0 then
        Session:FinishVerification(first)
    elseif event == "ZONE_CHANGED_NEW_AREA" then Session:Sample(); Session:Context(); Session:Refresh() end
end)
