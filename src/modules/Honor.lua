local Module = {
    Name = "Honor",
    TagName = "honor",
    ShortName = "hon",
    RegisteredEvents = { "CURRENCY_DISPLAY_UPDATE" },
}
PerHour.Modules.Honor = Module

local HONOR_CURRENCY_ID = 1792

-- Forever awards spendable Honor Points, separate from UnitHonor's honor-level XP.
-- Use the event's gain, not the balance, so spending cannot hide later earnings.
Module.CustomOnEvent = function(self, event, currencyID, quantity, quantityChange)
    local state = Module
    if event ~= "CURRENCY_DISPLAY_UPDATE" or not state.HasStarted or state.HasPaused
        or state.PendingRestore or not PerHour.Session.InWorld then
        return
    end
    if not Utils:IsReadableNumber(currencyID) or currencyID ~= HONOR_CURRENCY_ID then return end
    if not Utils:IsReadableNumber(quantityChange) or not (quantityChange > 0 and quantityChange < math.huge) then
        return
    end

    state.Element = state.Element + quantityChange
    BaseModule:UpdateRates(Module)
end
