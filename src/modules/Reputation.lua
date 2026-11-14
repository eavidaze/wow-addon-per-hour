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

-- Expand only while reading so collapsed and inactive groups remain selectable.
function Module:GetTrackableFactions()
    local options, seen, expanded = {}, {}, {}
    local index = 1
    while index <= C_Reputation.GetNumFactions() do
        local data = C_Reputation.GetFactionDataByIndex(index)
        if data then
            if data.isHeader and data.isCollapsed then
                table.insert(expanded, index)
                C_Reputation.ExpandFactionHeader(index)
            end
            if (not data.isHeader or data.isHeaderWithRep) and data.factionID > 0
                and not seen[data.factionID] then
                table.insert(options, { value = data.factionID, label = data.name })
                seen[data.factionID] = true
            end
        end
        index = index + 1
    end
    -- Restore nested headers before their parents, keeping the original indices valid.
    for i = #expanded, 1, -1 do C_Reputation.CollapseFactionHeader(expanded[i]) end
    table.sort(options, function(a, b) return a.label < b.label end)
    table.insert(options, 1, { value = 0, label = "None" })
    return options
end

Module.CustomReset = function()
    Module.State.LastReputationName = ""
    Module.State.LastFactionID = nil
    Module.State.LastReputationValue = nil
    Module.State.MissingFactionTime = 0
end

local function Snapshot(data)
    Module.State.LastReputationName = data.name
    Module.State.LastFactionID = data.factionID
    Module.State.LastReputationValue = data.currentStanding
    Module.State.MissingFactionTime = 0
end

Module.CustomGetContext = function()
    return Module.State.LastReputationName ~= "" and Module.State.LastReputationName or "No active session"
end

Module.CustomSaveSession = function()
    return { factionID = Module.State.LastFactionID, name = Module.State.LastReputationName }
end

Module.CustomRestoreSession = function(context)
    if type(context) ~= "table" or type(context.factionID) ~= "number" or type(context.name) ~= "string" then
        return false
    end
    Module.State.LastFactionID = context.factionID
    Module.State.LastReputationName = context.name
end

Module.CustomStart = function()
    local data = GetWatchedFaction()
    if not data then
        Utils:AddonMessage("Select a watched reputation before starting the tracker.")
        return false
    end
    Snapshot(data)
    return true
end

Module.CustomOnUpdate = function(self, elapsed)
    local data = GetWatchedFaction()
    if not data then
        -- The watched faction can temporarily disappear during a loading screen.
        Module.State.MissingFactionTime = Module.State.MissingFactionTime + elapsed
        if Module.State.MissingFactionTime >= MISSING_FACTION_GRACE_SECONDS then
            Utils:AddonMessage("Select a watched reputation before starting the tracker.")
            BaseModule:ResetModule(Module)
        end
        return
    end

    if Module.State.LastFactionID and Module.State.LastFactionID ~= data.factionID then
        Utils:AddonMessage("Watched reputation changed; reputation tracker reset.")
        BaseModule:ResetModule(Module)
        return
    end

    if Module.State.LastReputationValue ~= nil and not Module.State.HasPaused then
        Module.State.Element = Module.State.Element + data.currentStanding - Module.State.LastReputationValue
    end
    Snapshot(data)
    return true
end

Module.CustomStartedMessage = function()
    return " ["..Module.State.LastReputationName.."] monitoring started."
end

Module.CustomFormatAnnouncement = function(total, duration, perHour)
    local message = string.format("%s rep/h - %s (%s rep total)", perHour, duration, total)
    if Module.State.LastReputationName ~= "" then
        message = message .. " - " .. Module.State.LastReputationName
    end
    return message
end
