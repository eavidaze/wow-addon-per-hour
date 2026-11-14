local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
    if event == "PLAYER_ENTERING_WORLD" then
        self:UnregisterEvent("PLAYER_ENTERING_WORLD")
        PerHour.Displayer:RestorePositions()
        return
    end
    if name ~= PerHour.AddonName then return end
    self:UnregisterEvent("ADDON_LOADED")

    PerHour.Stores.Settings:Init()
    PerHour.Stores.Sessions:Init()
    for name, module in pairs(PerHour.Modules) do
        module.State = {}
        module.View = {}
        module.Settings = PerHour.Stores.Settings:ForModule(name)
        module.Store = PerHour.Stores.Sessions:ForModule(name)
    end

    PerHour.Displayer:Init()
    PerHour.ToggleMenu:Init(PerHour.MinimapButton)
    PerHour.MinimapButton:Init()
    -- Loading can expose temporary screen dimensions; do not clamp saved positions yet.
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
end)
