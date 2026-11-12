local Module = {
    Name = "Reputation",
    TagName = "reputation",
    ShortName = "Rep",
    RegisteredEvents = {},
}
PerHour.Modules.Reputation = Module

local MISSING_FACTION_GRACE_SECONDS = 10

local function GetWatchedFaction()
    local data = C_Reputation.GetWatchedFactionData()
    if data and not (issecretvalue and (issecretvalue(data.name) or issecretvalue(data.factionID)))
        and Utils:IsReadableNumber(data.currentStanding) then
        return data
    end
end

Module.CustomReset = function()
    Module.LastReputationName = ""
    Module.LastFactionID = nil
    Module.LastReputationValue = nil
    Module.MissingFactionTime = 0
end

local function Snapshot(data)
    Module.LastReputationName = data.name
    Module.LastFactionID = data.factionID
    Module.LastReputationValue = data.currentStanding
    Module.MissingFactionTime = 0
end

Module.CustomGetContext = function()
    return Module.LastReputationName ~= "" and Module.LastReputationName or "No active session"
end

Module.CustomStart = function()
    local data = GetWatchedFaction()
    if not data then
        Utils:AddonMessage("Select a watched reputation before starting the tracker.")
        return false
    end
    Snapshot(data)
end

Module.CustomOnUpdate = function(self, elapsed)
    local data = GetWatchedFaction()
    if not data then
        -- The watched faction can temporarily disappear during a loading screen.
        Module.MissingFactionTime = Module.MissingFactionTime + elapsed
        if Module.MissingFactionTime >= MISSING_FACTION_GRACE_SECONDS then
            Utils:AddonMessage("Select a watched reputation before starting the tracker.")
            BaseModule:ResetModule(Module)
        end
        return
    end

    if Module.LastFactionID and Module.LastFactionID ~= data.factionID then
        Utils:AddonMessage("Watched reputation changed; reputation tracker reset.")
        BaseModule:ResetModule(Module)
        return
    end

    if Module.LastReputationValue ~= nil and not Module.HasPaused then
        Module.Element = Module.Element + data.currentStanding - Module.LastReputationValue
    end
    Snapshot(data)
end

Module.CustomStartedMessage = function()
    return " ["..Module.LastReputationName.."] monitoring started."
end

Module.CustomSendToMessages = {
    function() return "Reputation: ...... "..Module.LastReputationName end,
}
