local Module = {
    Name = "Honor",
    TagName = "honor",
    ShortName = "hon",
    RegisteredEvents = {},
}
PerHour.Modules.Honor = Module

Module.CustomReset = function()
    Module.State.LastHonor = nil
    Module.State.LastHonorMax = nil
    Module.State.LastHonorLevel = nil
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
    if Module.State.LastHonor ~= nil and (level < Module.State.LastHonorLevel
        or (level == Module.State.LastHonorLevel and current < Module.State.LastHonor)) then
        return
    end

    local received = 0
    if Module.State.LastHonor ~= nil then
        if level > Module.State.LastHonorLevel then
            received = Module.State.LastHonorMax - Module.State.LastHonor + current
        else
            received = math.max(0, current - Module.State.LastHonor)
        end
    end
    Module.State.LastHonor = current
    Module.State.LastHonorMax = maximum
    Module.State.LastHonorLevel = level

    if not Module.State.HasPaused then
        Module.State.Element = Module.State.Element + received
    end
    return true
end

Module.CustomStart = function()
    Module.CustomReset()
    Module.CustomOnUpdate()
end
