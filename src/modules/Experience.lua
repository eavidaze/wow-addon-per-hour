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
Module.RegisteredEvents = {}

-- custom properties
Module.LastMaxXp = 0
Module.LastXp = 0
Module.LastLevel = 0

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
    if Module.LastLevel ~= 0 and (currentLevel < Module.LastLevel
        or (currentLevel == Module.LastLevel and currentXp < Module.LastXp)) then
        return
    end

    if Module.LastLevel ~= 0 then
        if currentLevel > Module.LastLevel then
            xpReceived = Module.LastMaxXp - Module.LastXp + currentXp
        else
            xpReceived = math.max(0, currentXp - Module.LastXp)
        end
    end

    -- update lasts
    Module.LastMaxXp = currentMaxXp
    Module.LastXp = currentXp
    Module.LastLevel = currentLevel
    
    -- Element is the amount of XP
    if not Module.HasPaused then
        Module.Element = Module.Element + xpReceived
    end
    return true
end

Module.CustomReset = function()
    Module.LastMaxXp = 0
    Module.LastXp = 0
    Module.LastLevel = 0
end

-- Snapshot at the click, so the first gain after Start is included.
Module.CustomStart = function()
    Module.CustomReset()
    Module.CustomOnUpdate()
end
