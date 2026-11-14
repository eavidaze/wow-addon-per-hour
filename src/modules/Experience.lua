-- import
local PerHour = PerHour
local Utils = Utils

-- declaretion
local Module = {}
PerHour.Modules.Experience = Module

-- properties
Module.Name = "Experience"
Module.TagName = "experience"
Module.ShortName = "XP"
Module.AnnouncementUnit = "XP"
Module.RegisteredEvents = {}

-- custom functions
Module.CustomOnUpdate = function(self, elapsed)
    local currentMaxXp = UnitXPMax("player")
    local currentXp = UnitXP("player")
    local currentLevel = UnitLevel("player")

    if not Utils:IsReadableNumber(currentXp) or not Utils:IsReadableNumber(currentMaxXp)
        or not Utils:IsReadableNumber(currentLevel) then
        return
    end

    -- Loading screens may expose empty or incomplete player progress.
    -- Keep the last valid snapshot so restored XP is not counted again.
    if currentMaxXp <= 0 or currentLevel <= 0 or currentXp < 0 then
        return
    end
    local xpReceived = 0
    if Module.State.LastLevel ~= 0 and (currentLevel < Module.State.LastLevel
        or (currentLevel == Module.State.LastLevel and currentXp < Module.State.LastXp)) then
        return
    end

    if Module.State.LastLevel ~= 0 then
        if currentLevel > Module.State.LastLevel then
            xpReceived = Module.State.LastMaxXp - Module.State.LastXp + currentXp
        else
            xpReceived = math.max(0, currentXp - Module.State.LastXp)
        end
    end

    -- update lasts
    Module.State.LastMaxXp = currentMaxXp
    Module.State.LastXp = currentXp
    Module.State.LastLevel = currentLevel
    
    -- Element is the amount of XP
    if not Module.State.HasPaused then
        Module.State.Element = Module.State.Element + xpReceived
    end
    return true
end

Module.CustomReset = function()
    Module.State.LastMaxXp = 0
    Module.State.LastXp = 0
    Module.State.LastLevel = 0
end

-- Snapshot at the click, so the first gain after Start is included.
Module.CustomStart = function()
    Module.CustomReset()
    Module.CustomOnUpdate()
end
