local Components = PerHour.Components
local SettingsPanel = {}
PerHour.SettingsPanel = SettingsPanel

function SettingsPanel:Refresh()
    if not self.Frame then return end
    for name, field in pairs(self.ModuleFields) do
        field:SetValue(PerHour.Modules[name].Settings:Get("isShown"), true)
        self.RateFields[name]:SetValue(PerHour.Modules[name].Settings:Get("rate"), true)
    end
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
            closeAlwaysVisible = true,
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
            -- Keep controls current when the minimap menu or panel X changes visibility.
            module.View.Frame:HookScript("OnShow", function() self:Refresh() end)
            module.View.Frame:HookScript("OnHide", function() self:Refresh() end)
        end
        frame:AddField(panels)
        self.Frame = frame
    end
    self:Refresh()
    self.Frame:Show()
    self.Frame:Raise()
end
