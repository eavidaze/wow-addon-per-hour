local Module = { Name="Reputation", TagName="reputation", ShortName="rep", RegisteredEvents={"UPDATE_FACTION"} }
PerHour.Modules.Reputation = Module
local STANDINGS = { "Hated", "Hostile", "Unfriendly", "Neutral", "Friendly", "Honored", "Revered", "Exalted" }
function Module:HasTrackedFaction()
    local data = C_Reputation.GetWatchedFactionData()
    return data ~= nil and Utils:IsFiniteNumber(data.factionID) and data.factionID > 0
end
local function GetWatchedFaction()
    local data = C_Reputation.GetWatchedFactionData()
    if data and not (issecretvalue and (issecretvalue(data.name) or issecretvalue(data.factionID)))
        and Utils:IsFiniteNumber(data.currentStanding) and Utils:IsFiniteNumber(data.factionID) then return data end
    return nil, data ~= nil
end
Module.CustomGetEstimateGoal = function()
    local data = GetWatchedFaction()
    if not data or not Utils:IsFiniteNumber(data.factionID) or data.factionID <= 0
        or data.factionID ~= Module.State.LastFactionID then return end
    -- Friendship, renown and paragon do not use the standard standing ladder.
    if C_Reputation.IsMajorFaction and C_Reputation.IsMajorFaction(data.factionID) then return end
    if C_Reputation.IsFactionParagon and C_Reputation.IsFactionParagon(data.factionID) then return end
    if C_GossipInfo and C_GossipInfo.GetFriendshipReputation then
        local friendship = C_GossipInfo.GetFriendshipReputation(data.factionID)
        if friendship and (not Utils:IsFiniteNumber(friendship.friendshipFactionID)
            or friendship.friendshipFactionID > 0) then return end
    end
    local reaction = data.reaction
    if not Utils:IsFiniteNumber(reaction) or not STANDINGS[reaction] then return end
    if reaction == #STANDINGS then return nil, nil, "Exalted reached" end
    if not Utils:IsFiniteNumber(data.currentStanding)
        or not Utils:IsFiniteNumber(data.currentReactionThreshold)
        or not Utils:IsFiniteNumber(data.nextReactionThreshold)
        or data.currentStanding < data.currentReactionThreshold
        or data.currentStanding >= data.nextReactionThreshold then return end
    return STANDINGS[reaction + 1], data.nextReactionThreshold - data.currentStanding
end

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
    local state = Module.State
    state.Factions, state.Segments = {}, {}
    state.LastFactionID, state.LastReputationValue, state.CurrentSegment = nil, nil, nil
    state.LastReputationName, state.FactionTime, state.Available = "", 0, false
end
local function SetFaction(data)
    local state = Module.State
    local id = data and data.factionID
    if id ~= state.LastFactionID then
        state.LastFactionID, state.CurrentSegment = id, nil
        if id then
            state.Factions[id] = state.Factions[id] or { id=id, name=data.name, total=0, duration=0 }
            local segment = { id=id, name=data.name, start=PerHour.Session.Current.duration, duration=0, total=0 }
            state.Segments[#state.Segments+1] = segment
            state.CurrentSegment = segment
        end
        state.LastReputationValue = nil
    end
    state.Available = data ~= nil
    state.LastReputationName = data and data.name or ""
    local summary = id and state.Factions[id]
    state.Element, state.FactionTime = summary and summary.total or 0, summary and summary.duration or 0
    state.Partial = summary and summary.partial == true or false
    state.Time = state.FactionTime
end
function Module:AccumulateTime(delta)
    local state = self.State
    local summary = state.LastFactionID and state.Factions[state.LastFactionID]
    if summary and state.Available and state.HasStarted then
        summary.duration = summary.duration + delta
        if state.CurrentSegment then state.CurrentSegment.duration = state.CurrentSegment.duration + delta end
        state.FactionTime = summary.duration
    end
end
Module.CustomStart = function()
    local data,unavailable = GetWatchedFaction()
    if unavailable then Module.State.LastReputationValue=nil; return false end
    SetFaction(data)
    Module.State.LastReputationValue = data and data.currentStanding
    return true
end
Module.CustomOnUpdate = function()
    local state = Module.State
    local data,unavailable = GetWatchedFaction()
    if unavailable then state.LastReputationValue=nil; return false end
    SetFaction(data)
    if not data then return true end
    local summary = state.Factions[data.factionID]
    if state.LastReputationValue and not state.HasPaused and not state.PendingRestore then
        local gained = data.currentStanding - state.LastReputationValue
        summary.total = summary.total + gained
        if state.CurrentSegment then state.CurrentSegment.total = state.CurrentSegment.total + gained end
    end
    state.LastReputationValue = data.currentStanding
    state.Element, state.FactionTime, state.Time = summary.total, summary.duration, summary.duration
    return true
end
Module.CustomOnEvent = function(_, event)
    if event == "UPDATE_FACTION" then return Module.CustomOnUpdate() end
end
Module.CustomSaveSession = function()
    return { factions=Module.State.Factions, segments=Module.State.Segments, factionID=Module.State.LastFactionID }
end
Module.CustomRestoreSession = function(context)
    if type(context) ~= "table" or type(context.factions) ~= "table" or type(context.segments) ~= "table" then return false end
    for id, faction in pairs(context.factions) do
        if not Utils:IsFiniteNumber(id) or id <= 0 or type(faction) ~= "table"
            or type(faction.name) ~= "string" or not Utils:IsFiniteNumber(faction.total)
            or not Utils:IsFiniteNumber(faction.duration) or faction.duration < 0 then return false end
    end
    for _, segment in ipairs(context.segments) do
        if type(segment) ~= "table" or not context.factions[segment.id]
            or not Utils:IsFiniteNumber(segment.start) or segment.start < 0
            or not Utils:IsFiniteNumber(segment.duration) or segment.duration < 0
            or not Utils:IsFiniteNumber(segment.total) then return false end
    end
    local state = Module.State
    state.Factions, state.Segments, state.LastFactionID = context.factions, context.segments, context.factionID
    local summary = state.LastFactionID and state.Factions[state.LastFactionID]
    state.LastReputationName = summary and summary.name or ""
    state.FactionTime = summary and summary.duration or 0
    local last = state.Segments[#state.Segments]
    state.CurrentSegment = last and last.id == state.LastFactionID and last or nil
    return true
end
Module.CustomGetContext = function() return Module.State.LastReputationName ~= "" and Module.State.LastReputationName or "No tracked faction" end
Module.CustomFormatAnnouncement = function(total,duration,perHour)
    return string.format("%s rep/h - %s (%s rep total) - %s", perHour,duration,total,Module.State.LastReputationName)
end
