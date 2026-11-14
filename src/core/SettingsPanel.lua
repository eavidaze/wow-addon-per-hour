local Components = PerHour.Components
local SettingsPanel = {}
PerHour.SettingsPanel = SettingsPanel

function SettingsPanel:Show()
    if not self.Frame then
        local frame = Components:CreatePanel(UIParent, {
            name = "PerHourSettingsPanel",
            title = "Per Hour Settings",
            width = 560,
            form = true,
            closeAlwaysVisible = true,
            draggable = true,
            actions = {
                { key = "close", text = "Close", fullWidth = false, widthFraction = 0.3, align = "CENTER",
                    onClick = function(panel) panel:Hide() end },
            },
        })
        frame:SetFrameStrata("DIALOG")
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        frame:AddField(Components:CreateFormGroup(frame.Content, {
            title = "Tracking",
            fields = {
                { type = "checkbox", label = "Example option", value = false },
                { type = "select", label = "Display rate", value = "hour", options = {
                    { value = "hour", label = "Per hour" },
                    { value = "minute", label = "Per minute" },
                } },
                { type = "text", label = "Session name", value = "Example session" },
            },
        }))
        frame:AddField(Components:CreateFormGroup(frame.Content, {
            title = "Appearance",
            fields = {
                { type = "slider", label = "Panel opacity", value = 80, min = 25, max = 100, step = 5, suffix = "%" },
                { type = "slider", label = "Decimal places", value = 1, min = 0, max = 3, step = 1 },
            },
        }))
        self.Frame = frame
    end
    self.Frame:Show()
    self.Frame:Raise()
end
