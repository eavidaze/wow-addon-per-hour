local Components = PerHour.Components
local SettingsPanel = {}
PerHour.SettingsPanel = SettingsPanel

function SettingsPanel:RefreshReputation(rebuild)
    local field = self.ReputationField
    if not field or self.RefreshingReputation then return end
    self.RefreshingReputation = true
    if rebuild then
        -- Expanding/restoring headers also emits UPDATE_FACTION; do not rebuild for those events.
        self.ReputationEventsPending = true
        self.ReputationOptions = PerHour.Modules.Reputation:GetTrackableFactions()
        C_Timer.After(0, function() self.ReputationEventsPending = false end)
    end
    local data = C_Reputation.GetWatchedFactionData()
    local value = data and data.factionID or 0
    local found = false
    for _, option in ipairs(self.ReputationOptions) do
        if option.value == value then found = true; break end
    end
    if not found then table.insert(self.ReputationOptions, { value = value, label = data.name }) end
    field:SetOptions(self.ReputationOptions, value)
    self.RefreshingReputation = false
end

function SettingsPanel:RefreshSpeedometerFields()
    local enabled = PerHour.Stores.Settings:GetSpeedometerEnabled()
    local rate = PerHour.Stores.Settings:GetRate()
    self.SpeedometerHourField:SetShown(enabled and rate == "hour")
    self.SpeedometerMinuteField:SetShown(enabled and rate == "minute")
end

function SettingsPanel:Refresh()
    if not self.Frame then return end
    self.RateField:SetValue(PerHour.Stores.Settings:GetRate(), true)
    self.SpeedometerField:SetValue(PerHour.Stores.Settings:GetSpeedometerEnabled(), true)
    self.SpeedometerHourField:SetValue(PerHour.Stores.Settings:GetSpeedometerMaximum("hour"), true)
    self.SpeedometerMinuteField:SetValue(PerHour.Stores.Settings:GetSpeedometerMaximum("minute"), true)
    for name, field in pairs(self.ModuleFields) do
        field:SetValue(PerHour.Modules[name].Settings:Get("isShown"), true)
    end
    self:RefreshSpeedometerFields()
    self:RefreshReputation()
end

function SettingsPanel:Show()
    if not self.Frame then
        local frame = Components:CreatePanel(UIParent, {
            name = "PerHourSettingsPanel",
            title = "Per Hour Settings",
            titleSize = "default",
            titleBox = true,
            width = 560,
            form = true,
            contentSpacing = 12,
            draggable = true,
            actions = {
                { key = "close", text = "Close", fullWidth = false, widthFraction = 0.3, align = "CENTER",
                    onClick = function(panel) panel:Hide() end },
            },
        })
        frame:SetFrameStrata("DIALOG")
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        local general = Components:CreateFormGroup(frame.Content, { title = "General" })
        self.RateField = general:AddField({
            type = "select", label = "Rate", value = PerHour.Stores.Settings:GetRate(),
            options = {
                { value = "hour", label = "Per hour" },
                { value = "minute", label = "Per minute" },
            },
            onChanged = function(value)
                PerHour.Stores.Settings:SetRate(value)
                self:RefreshSpeedometerFields()
                PerHour.TrackerPanels:RefreshDisplays()
            end,
        })
        self.SpeedometerField = general:AddField({
            type = "checkbox", label = "Show speedometer",
            value = PerHour.Stores.Settings:GetSpeedometerEnabled(),
            onChanged = function(enabled)
                PerHour.Stores.Settings:SetSpeedometerEnabled(enabled)
                self:RefreshSpeedometerFields()
                PerHour.TrackerPanels:RefreshDisplays()
            end,
        })
        self.SpeedometerHourField = self.SpeedometerField:AddSubfield({
            type = "slider", label = "Maximum per hour", min = 10000, max = 100000, step = 1000,
            format = function(value) return Utils:DisplayCompactNumber(value) end,
            value = PerHour.Stores.Settings:GetSpeedometerMaximum("hour"),
            onChanged = function(value)
                PerHour.Stores.Settings:SetSpeedometerMaximum("hour", value)
                PerHour.TrackerPanels:RefreshDisplays()
            end,
        })
        self.SpeedometerMinuteField = self.SpeedometerField:AddSubfield({
            type = "slider", label = "Maximum per minute", min = 160, max = 1600, step = 10, format = "%.0f",
            value = PerHour.Stores.Settings:GetSpeedometerMaximum("minute"),
            onChanged = function(value)
                PerHour.Stores.Settings:SetSpeedometerMaximum("minute", value)
                PerHour.TrackerPanels:RefreshDisplays()
            end,
        })
        self:RefreshSpeedometerFields()
        frame:AddField(general)
        local panels = Components:CreateFormGroup(frame.Content, { title = "Show trackers" })
        local modules = {}
        for _, module in pairs(PerHour.Modules) do table.insert(modules, module) end
        table.sort(modules, function(a, b) return a.Name < b.Name end)
        self.ModuleFields = {}
        for _, context in ipairs(modules) do
            local module = context
            local row = panels:AddField({
                type = "checkbox", label = module.Name,
                value = module.Settings:Get("isShown"),
                onChanged = function(shown)
                    module.Settings:Set("isShown", shown)
                    module.View.Frame:SetShown(shown)
                    self:Refresh()
                end,
            })
            self.ModuleFields[module.Name] = row
            if module.Name == "Reputation" then
                self.ReputationOptions = { { value = 0, label = "None" } }
                self.ReputationField = row:AddSubfield({
                    type = "select", label = "Tracked faction", value = 0,
                    options = self.ReputationOptions, maxMenuHeight = 300,
                    onChanged = function(value)
                        if value == 0 then C_Reputation.SetWatchedFactionByIndex(0)
                        else C_Reputation.SetWatchedFactionByID(value) end
                        self:RefreshReputation()
                    end,
                })
            end
            -- Keep controls current when the minimap menu or panel X changes visibility.
            module.View.Frame:HookScript("OnShow", function() self:Refresh() end)
            module.View.Frame:HookScript("OnHide", function() self:Refresh() end)
        end
        frame:AddField(panels)
        self.Frame = frame
        frame:RegisterEvent("UPDATE_FACTION")
        frame:SetScript("OnEvent", function()
            if frame:IsShown() then self:RefreshReputation(not self.ReputationEventsPending) end
        end)
    end
    self:RefreshReputation(true)
    self:Refresh()
    self.Frame:Show()
    self.Frame:Raise()
end
