local Components, Settings = PerHour.Components, PerHour.Stores.Settings
local Panel = {}
PerHour.SettingsPanel = Panel
function Panel:RefreshReputation(rebuild)
    if not self.ReputationField or self.ReadingFactions then return end
    self.ReadingFactions = true
    if rebuild then self.ReputationOptions = PerHour.Modules.Reputation:GetTrackableFactions() end
    local data = C_Reputation.GetWatchedFactionData()
    local id = data and data.factionID or 0
    local found = false
    for _, option in ipairs(self.ReputationOptions) do if option.value == id then found = true end end
    if not found and data then self.ReputationOptions[#self.ReputationOptions+1] = {value=id,label=data.name} end
    self.ReputationField:SetOptions(self.ReputationOptions,id)
    self.ReadingFactions = false
end
function Panel:Apply()
    self:Refresh()
    PerHour.Dashboard:RefreshDisplays()
end
function Panel:Swap(firstName, secondName)
    local first,second
    for index,name in ipairs(Settings:GetOrder()) do
        if name == firstName then first=index end
        if name == secondName then second=index end
    end
    if first and second then Settings:Swap(first,second); self:Apply() end
end
function Panel:Refresh()
    if not self.Frame or self.Refreshing then return end
    self.Refreshing = true
    self.PanelType:SetValue(Settings:Get("panelType"),true)
    self.Rate:SetValue(Settings:GetRate(),true)
    self.Duration:SetValue(Settings:Get("showDuration"),true)
    self.Estimates:SetValue(Settings:GetEstimatesEnabled(),true)
    self.Source:SetValue(Settings:Get("estimateSource"),true)
    self.Source:SetShown(Settings:GetEstimatesEnabled())
    self.Gauge:SetValue(Settings:GetSpeedometerEnabled(),true)
    self.Scale:SetValue(Settings:GetSpeedometerLevel(),true)
    self.Scale:SetShown(Settings:GetSpeedometerEnabled())
    local order = PerHour.Dashboard:GetConfiguredOrder()
    local options = {}
    for _, name in ipairs(order) do options[#options+1] = {value=name,label=name} end
    for index,field in ipairs(self.Positions) do
        field:SetShown(order[index] ~= nil)
        if order[index] then field.Metric=order[index]; field:SetOptions(options,order[index]) end
    end
    self:RefreshReputation()
    self.Refreshing = false
end
function Panel:Show()
    if not self.Frame then
        local frame = Components:CreatePanel(UIParent,{
            name="PerHourSettingsPanel",title="Per Hour Settings",titleBox=true,width=560,
            form=true,contentSpacing=12,draggable=true,
            actions={{key="close",text="Close",widthFraction=0.3,align="CENTER",onClick=function(panel) panel:Hide() end}},
        })
        self.Frame = frame
        frame:SetFrameStrata("DIALOG")
        frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
        if UISpecialFrames then table.insert(UISpecialFrames,"PerHourSettingsPanel") end
        local general = Components:CreateFormGroup(frame.Content,{title="General"})
        self.PanelType = general:AddField({type="select",label="Panel type",value=Settings:Get("panelType"),
            options={{value="focused",label="Focused"},{value="extended",label="Extended"},{value="full",label="Full"}},
            onChanged=function(value) Settings:Set("panelType",value); self:Apply() end})
        self.Rate = general:AddField({type="select",label="Rate",value=Settings:GetRate(),
            options={{value="hour",label="Per hour"},{value="minute",label="Per minute"}},
            onChanged=function(value) Settings:SetRate(value); self:Apply() end})
        local estimates = general:AddField({type="group",label="Show estimates",fields={
            {type="checkbox",label="Show estimates",value=Settings:GetEstimatesEnabled(),
                onChanged=function(value) Settings:SetEstimatesEnabled(value); self:Apply() end},
            {type="select",label="Estimate source",controlWidth=260,value=Settings:Get("estimateSource"),
                options={{value="Experience",label="Experience"},{value="Reputation",label="Reputation"}},
                onChanged=function(value) Settings:Set("estimateSource",value); self:Apply() end},
        }})
        self.Estimates,self.Source = estimates.Fields[1],estimates.Fields[2]
        frame:AddField(general)
        local metrics = Components:CreateFormGroup(frame.Content,{title="Metrics"})
        self.Positions = {}
        for index,label in ipairs({"Primary","Secondary","Tertiary upper","Tertiary lower"}) do
            local field
            field = metrics:AddField({type="select",label=label,value=Settings:GetOrder()[index],
                options={{value="Experience",label="Experience"},{value="Gold",label="Gold"},
                    {value="Honor",label="Honor"},{value="Reputation",label="Reputation"}},
                onChanged=function(value) self:Swap(field.Metric,value) end})
            self.Positions[index] = field
            local grip = CreateFrame("Button",nil,field)
            field.Grip = grip
            grip:SetSize(20,28)
            grip:SetPoint("RIGHT",field.ControlArea,"LEFT",-4,0)
            grip.Text = grip:CreateFontString(nil,"OVERLAY","GameFontNormal")
            grip.Text:SetPoint("CENTER"); grip.Text:SetText("≡")
            grip:RegisterForDrag("LeftButton")
            grip:SetScript("OnDragStart",function() self.Dragged=field.Metric; grip.Text:SetText("●") end)
            grip:SetScript("OnDragStop",function()
                local source = self.Dragged
                self.Dragged=nil; grip.Text:SetText("≡")
                if not source then return end
                for _, destination in ipairs(self.Positions) do
                    if destination:IsShown() and destination:IsMouseOver() then self:Swap(source,destination.Metric); break end
                end
            end)
            Components:SetButtonTooltip(grip,function() return "Drag to swap metrics, or use the selector." end)
        end
        self.Duration = metrics:AddField({type="checkbox",label="Show duration",value=Settings:Get("showDuration"),
            onChanged=function(value) Settings:Set("showDuration",value); self:Apply() end})
        frame:AddField(metrics)
        local experience = Components:CreateFormGroup(frame.Content,{title="Experience"})
        local gauge = experience:AddField({type="group",label="Show speedometer",fields={
            {type="checkbox",label="Show speedometer",value=Settings:GetSpeedometerEnabled(),
                onChanged=function(value) Settings:SetSpeedometerEnabled(value); self:Apply() end},
            {type="slider",fill=true,min=1,max=10,step=1,value=Settings:GetSpeedometerLevel(),
                format=function(value) return PerHour.Format:Compact(PerHour.SpeedometerScales:GetMaximum(value,Settings:GetRate()))
                    .. (Settings:GetRate() == "minute" and "/m" or "/h") end,
                onChanged=function(value) Settings:SetSpeedometerLevel(value); self:Apply() end},
        }})
        self.Gauge,self.Scale = gauge.Fields[1],gauge.Fields[2]
        frame:AddField(experience)
        local reputation = Components:CreateFormGroup(frame.Content,{title="Reputation"})
        self.ReputationOptions = {{value=0,label="None"}}
        self.ReputationField = reputation:AddField({type="select",label="Tracked faction",value=0,
            options=self.ReputationOptions,maxMenuHeight=300,onChanged=function(value)
                if value == 0 then C_Reputation.SetWatchedFactionByIndex(0) else C_Reputation.SetWatchedFactionByID(value) end
                self:RefreshReputation(); PerHour.Dashboard:RequestRefresh()
            end})
        frame:AddField(reputation)
        frame:RegisterEvent("UPDATE_FACTION")
        frame:SetScript("OnEvent",function() if frame:IsShown() then self:RefreshReputation() end end)
        frame:HookScript("OnShow",function()
            frame:SetScale(math.min(1,(UIParent:GetHeight()-60)/frame:GetHeight()))
        end)
    end
    self:RefreshReputation(true)
    self:Refresh()
    self.Frame:SetScale(math.min(1,(UIParent:GetHeight()-60)/self.Frame:GetHeight()))
    self.Frame:Show(); self.Frame:Raise()
end
