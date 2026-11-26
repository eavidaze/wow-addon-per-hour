local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent",function(self,_,name)
    if name ~= PerHour.AddonName then return end
    self:UnregisterEvent("ADDON_LOADED")
    PerHour.Stores.Settings:Init()
    PerHour.Stores.Sessions:Init()
    for _, module in pairs(PerHour.Modules) do module.View = {} end
    PerHour.Session:ResetModules()
    PerHour.Capture:Init()
    PerHour.Dashboard:Init()
    PerHour.MinimapButton:Init()
end)
