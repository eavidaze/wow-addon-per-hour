-- import
local PerHour = PerHour
local Utils = Utils

-- declaretion
local Module = {}
PerHour.Modules.Experience = Module

-- properties
Module.Name = "Experience"
Module.TagName = "experience"
Module.ShortName = "xp"
Module.AnnouncementUnit = "xp"
Module.RegisteredEvents = { "PLAYER_XP_UPDATE" }

Module.CustomGetEstimateGoal = function()
    local currentLevel = UnitLevel("player")
    if not Utils:IsFiniteNumber(currentLevel) or currentLevel <= 0 then return end
    local maxLevel = GetMaxPlayerLevel and GetMaxPlayerLevel()
    if Utils:IsFiniteNumber(maxLevel) and maxLevel > 0 and currentLevel >= maxLevel then
        return nil, nil, "Max level reached"
    end
    local currentXp, maxXp = UnitXP("player"), UnitXPMax("player")
    if not Utils:IsFiniteNumber(currentXp) or not Utils:IsFiniteNumber(maxXp)
        or currentXp < 0 or maxXp <= currentXp then return end
    -- A lower XP value at the same level can be an incomplete level-up snapshot.
    if Module.State.LastLevel == currentLevel and currentXp < Module.State.LastXp then return end
    return "Level " .. (currentLevel + 1), maxXp - currentXp
end

-- custom functions
Module.CustomOnUpdate = function(self, elapsed)
    local currentMaxXp = UnitXPMax("player")
    local currentXp = UnitXP("player")
    local currentLevel = UnitLevel("player")

    if not Utils:IsFiniteNumber(currentXp) or not Utils:IsFiniteNumber(currentMaxXp)
        or not Utils:IsFiniteNumber(currentLevel) then
        Module.State.LastLevel = 0
        return false
    end

    -- Loading screens may expose empty or incomplete player progress.
    -- Keep the last valid snapshot so restored XP is not counted again.
    local maximum = GetMaxPlayerLevel and GetMaxPlayerLevel()
    local capped = Utils:IsFiniteNumber(maximum) and currentLevel >= maximum
    if (currentMaxXp <= 0 and not capped) or currentLevel <= 0 or currentXp < 0 then
        Module.State.LastLevel = 0
        return false
    end
    local xpReceived = 0
    if Module.State.LastLevel ~= 0 and (currentLevel < Module.State.LastLevel
        or (currentLevel == Module.State.LastLevel and currentXp < Module.State.LastXp)) then
        return
    end

    if Module.State.LastLevel ~= 0 then
        if currentLevel > Module.State.LastLevel then
            xpReceived = Module.State.LastMaxXp - Module.State.LastXp + currentXp
            if currentLevel > Module.State.LastLevel + 1 then
                PerHour.Session:MarkPartial(Module,"Some level-up progress could not be observed.")
            end
        else
            xpReceived = math.max(0, currentXp - Module.State.LastXp)
        end
    end

    -- update lasts
    Module.State.LastMaxXp = currentMaxXp
    Module.State.LastXp = currentXp
    Module.State.LastLevel = currentLevel
    Module.State.Available = true
    
    -- Element is the amount of XP
    if not Module.State.HasPaused then
        Module.State.Element = Module.State.Element + xpReceived
    end
    return true
end

Module.CustomOnEvent = function(self, event, unit)
    if event ~= "PLAYER_XP_UPDATE" or (issecretvalue and issecretvalue(unit)) or unit ~= "player" then return end
    return Module.CustomOnUpdate(self, 0)
end

Module.CustomReset = function()
    Module.State.LastMaxXp = 0
    Module.State.LastXp = 0
    Module.State.LastLevel = 0
end

-- Snapshot at the click, so the first gain after Start is included.
Module.CustomStart = function()
    Module.CustomReset()
    return Module.CustomOnUpdate()
end
