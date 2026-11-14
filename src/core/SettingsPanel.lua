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

function SettingsPanel:Refresh()
    if not self.Frame then return end
    for name, field in pairs(self.ModuleFields) do
        field:SetValue(PerHour.Modules[name].Settings:Get("isShown"), true)
        self.RateFields[name]:SetValue(PerHour.Modules[name].Settings:Get("rate"), true)
    end
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
        local panels = Components:CreateFormGroup(frame.Content, { title = "Panels" })
        local modules = {}
        for _, module in pairs(PerHour.Modules) do table.insert(modules, module) end
        table.sort(modules, function(a, b) return a.Name < b.Name end)
        self.ModuleFields = {}
        self.RateFields = {}
        for _, context in ipairs(modules) do
            local module = context
            local row = panels:AddField({
                type = "group", label = module.Name,
                fields = {
                    {
                        type = "checkbox", label = "Show " .. module.Name,
                        value = module.Settings:Get("isShown"),
                        onChanged = function(shown)
                            module.Settings:Set("isShown", shown)
                            module.View.Frame:SetShown(shown)
                            self:Refresh()
                        end,
                    },
                    {
                        type = "select", value = module.Settings:Get("rate"),
                        options = {
                            { value = "hour", label = "Per hour" },
                            { value = "minute", label = "Per minute" },
                        },
                        onChanged = function(value)
                            module.Settings:Set("rate", value)
                            PerHour.Displayer:RefreshRate(module)
                        end,
                    },
                },
            })
            self.ModuleFields[module.Name] = row.Fields[1]
            self.RateFields[module.Name] = row.Fields[2]
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
