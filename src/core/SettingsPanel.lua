local Components = PerHour.Components
local SettingsPanel = {}
PerHour.SettingsPanel = SettingsPanel

function SettingsPanel:Refresh()
    if not self.Frame then return end
    for name, field in pairs(self.ModuleFields) do
        field:SetValue(PerHour.Modules[name].Settings:Get("isShown"), true)
    end
    local angle = PerHour.Stores.Settings:GetMinimapAngle()
    local fullCircle = 2 * math.pi
    if angle < 0 or angle > fullCircle then angle = angle % fullCircle end
    self.AngleField:SetValue(math.deg(angle), true)
end

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
        local panels = Components:CreateFormGroup(frame.Content, { title = "Panels" })
        local modules = {}
        for _, module in pairs(PerHour.Modules) do table.insert(modules, module) end
        table.sort(modules, function(a, b) return a.Name < b.Name end)
        self.ModuleFields = {}
        for _, context in ipairs(modules) do
            local module = context
            self.ModuleFields[module.Name] = panels:AddField({
                type = "checkbox", label = "Show " .. module.Name,
                value = module.Settings:Get("isShown"),
                onChanged = function(shown)
                    module.Settings:Set("isShown", shown)
                    module.Frame:SetShown(shown)
                    self:Refresh()
                end,
            })
            -- Keep controls current when the minimap menu or panel X changes visibility.
            module.Frame:HookScript("OnShow", function() self:Refresh() end)
            module.Frame:HookScript("OnHide", function() self:Refresh() end)
        end
        frame:AddField(panels)
        local minimap = Components:CreateFormGroup(frame.Content, { title = "Minimap" })
        self.AngleField = minimap:AddField({
            type = "slider", label = "Button position", value = 0,
            min = 0, max = 360, step = 1, suffix = " deg",
            onChanged = function(degrees) PerHour.MinimapButton:SetAngle(math.rad(degrees)) end,
        })
        frame:AddField(minimap)
        self.Frame = frame
    end
    self:Refresh()
    self.Frame:Show()
    self.Frame:Raise()
end
