local Module = {
    Name = "Honor",
    TagName = "honor",
    ShortName = "hon",
    RegisteredEvents = {},
}
PerHour.Modules.Honor = Module

Module.CustomReset = function()
    Module.LastHonor = nil
    Module.LastHonorMax = nil
    Module.LastHonorLevel = nil
end

-- Forever exposes honor progression through the modern UnitHonor APIs.
-- Read the player's progress rather than parsing localized combat messages.
Module.CustomOnUpdate = function()
    local current = UnitHonor("player")
    local maximum = UnitHonorMax("player")
    local level = UnitHonorLevel("player")
    if not Utils:IsReadableNumber(current) or not Utils:IsReadableNumber(maximum)
        or not Utils:IsReadableNumber(level) then
        return
    end
    if current < 0 or maximum <= 0 or level < 0 then return end
    if Module.LastHonor ~= nil and (level < Module.LastHonorLevel
        or (level == Module.LastHonorLevel and current < Module.LastHonor)) then
        return
    end

    local received = 0
    if Module.LastHonor ~= nil then
        if level > Module.LastHonorLevel then
            received = Module.LastHonorMax - Module.LastHonor + current
        else
            received = math.max(0, current - Module.LastHonor)
        end
    end
    Module.LastHonor = current
    Module.LastHonorMax = maximum
    Module.LastHonorLevel = level

    if not Module.HasPaused then
        Module.Element = Module.Element + received
    end
    return true
end

Module.CustomStart = function()
    Module.CustomReset()
    Module.CustomOnUpdate()
end
