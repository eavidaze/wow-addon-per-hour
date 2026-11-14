local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
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
    PerHour.Displayer:RestorePositions()
    PerHour.ToggleMenu:Init(PerHour.MinimapButton)
    PerHour.MinimapButton:Init()
end)
