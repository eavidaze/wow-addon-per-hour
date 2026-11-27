local Dashboard = {}
PerHour.Dashboard = Dashboard
local Components, Format, Settings = PerHour.Components, PerHour.Format, PerHour.Stores.Settings
local function Pixel(value) return math.floor(value+0.5) end
local DISPLAY_STYLES = {
    large={value=28,unit=12,height=29}, medium={value=18,unit=10,height=19},
    small={value=14,unit=10,height=15}, extraSmall={value=10,unit=9,height=11},
}
local DISPLAY_HEIGHTS = {DISPLAY_STYLES.large.height,DISPLAY_STYLES.medium.height,
    DISPLAY_STYLES.small.height,DISPLAY_STYLES.small.height}
local DISPLAY_GAP, XS_HEIGHT = 5, DISPLAY_STYLES.extraSmall.height
local STACK_GAP = 10
local READOUT_GAP, READOUT_PADDING = 1, 2

function Dashboard:GetConfiguredOrder()
    local result = {}
    local maximum = GetMaxPlayerLevel and GetMaxPlayerLevel()
    local level = UnitLevel("player")
    local capped = Utils:IsFiniteNumber(level) and Utils:IsFiniteNumber(maximum) and level >= maximum
    for _, name in ipairs(Settings:GetOrder()) do
        if name ~= "Experience" or not capped then result[#result+1] = name end
    end
    return result, capped
end
function Dashboard:GetVisibleOrder()
    local configured,capped = self:GetConfiguredOrder()
    local result = {}
    local tracked = PerHour.Modules.Reputation:HasTrackedFaction()
    for _, name in ipairs(configured) do
        if name ~= "Reputation" or tracked then result[#result+1] = name end
    end
    return result,capped
end
local function Metric(module)
    if module.Name == "Reputation" and not module:HasTrackedFaction() then
        return {total=0,duration=0,available=false}
    end
    if not PerHour.Session.Current then return {total=0,duration=0,available=true} end
    local state = module.State
    return { total=state.Element, duration=state.Time, available=state.HasStarted and state.Available ~= false,
        partial=state.Partial, issue=state.Issue, pending=module.Name == "Gold" and next(state.PendingPrices) ~= nil }
end
local function Tooltip(display)
    local name = display.Metric
    if not name then
        if not display.TooltipTitle then return end
        GameTooltip:SetOwner(display,"ANCHOR_RIGHT")
        GameTooltip:SetText(display.TooltipTitle)
        GameTooltip:AddLine(display.Value.FullText or "",1,1,1)
        GameTooltip:Show()
        return
    end
    local module = PerHour.Modules[name]
    local metric = Metric(module)
    GameTooltip:SetOwner(display,"ANCHOR_RIGHT")
    GameTooltip:SetText(name)
    GameTooltip:AddDoubleLine("Total",metric.available and Format:Amount(name,metric.total) or "—")
    local oppositePeriod = Settings:GetRate() == "minute" and "hour" or "minute"
    GameTooltip:AddDoubleLine("Rate",Format:RateText(name,metric,oppositePeriod))
    GameTooltip:Show()
end
local function Display(parent, style)
    local frame = CreateFrame("Button",nil,parent)
    frame.Leading = false
    frame.Value = frame:CreateFontString(nil,"OVERLAY","GameFontNormalHuge")
    local font,_,flags = frame.Value:GetFont()
    frame.Value:SetFont(font,style.value,flags)
    frame.Value:SetTextColor(unpack(PerHour.Theme.gold.text))
    frame.Value:SetJustifyH("CENTER")
    frame.Value:SetWordWrap(false)
    frame.Value:SetHeight(0)
    frame.Unit = frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
    frame.Unit:SetFont(font,style.unit,flags)
    frame.Unit:SetTextColor(unpack(PerHour.Theme.gold.text))
    frame.Unit:SetJustifyH("LEFT")
    frame.Unit:SetWordWrap(false)
    frame.Unit:SetWidth(0)
    frame.Unit:SetHeight(0)
    frame:SetScript("OnEnter",Tooltip)
    frame:SetScript("OnLeave",function() GameTooltip:Hide() end)
    frame:SetScript("OnClick",function() if PerHour.Session.Current then PerHour.SessionPanels:ShowCurrent() end end)
    function frame:MeasureReading(reading,unit,valueSize,unitSize)
        local oldValue,oldUnit = self.Value:GetText(),self.Unit:GetText()
        local valueFont,oldValueSize,valueFlags = self.Value:GetFont()
        local unitFont,oldUnitSize,unitFlags = self.Unit:GetFont()
        if valueSize then self.Value:SetFont(valueFont,valueSize,valueFlags) end
        if unitSize then self.Unit:SetFont(unitFont,unitSize,unitFlags) end
        self.Value:SetText(reading); self.Unit:SetText(unit or "")
        local width = self.Value:GetStringWidth()+(unit and self.Unit:GetStringWidth()+READOUT_GAP or 0)+READOUT_PADDING
            +(self.Leading and self.Leading:GetWidth()+4 or 0)
        self.Value:SetText(oldValue or ""); self.Unit:SetText(oldUnit or "")
        if valueSize then self.Value:SetFont(valueFont,oldValueSize,valueFlags) end
        if unitSize then self.Unit:SetFont(unitFont,oldUnitSize,unitFlags) end
        return math.ceil(width)
    end
    function frame:SetReading(reading,unit)
        if self.Value.FullText == reading and self.Unit:GetText() == (unit or "") then return end
        self.Unit:SetText(unit or "")
        local unitWidth = unit and self.Unit:GetStringWidth() or 0
        local gap = unit and READOUT_GAP or 0
        self.Value:ClearAllPoints()
        self.Value:SetWidth(0)
        self.Value:SetText(reading)
        self.Value.FullText = reading
        local valueWidth = math.ceil(self.Value:GetStringWidth())
        local leadingWidth = self.Leading and self.Leading:GetWidth()+4 or 0
        -- Keep native auto sizing: measured advance widths can clip glyphs at
        -- fractional UI scales and trigger the client's ellipsis rendering.
        self.Value:SetPoint("LEFT",self,"CENTER",-(leadingWidth+valueWidth+gap+unitWidth)/2+leadingWidth,0)
        if self.Leading then
            self.Leading:ClearAllPoints()
            self.Leading:SetPoint("RIGHT",self.Value,"LEFT",-4,0)
        end
        self.Unit:ClearAllPoints()
        self.Unit:SetPoint("BOTTOMLEFT",self.Value,"BOTTOMRIGHT",gap,0)
    end
    function frame:SetMetric(name)
        self.Metric = name
        local module = PerHour.Modules[name]
        local metric = Metric(module)
        self:SetReading(Format:RateReading(name,metric))
    end
    return frame
end
function Dashboard:MeasureDisplays()
    -- Keep the primary/gauge width on its established font reference, independent
    -- of the compact text preset. Measure once using the client's actual fonts.
    local referenceFonts = {{35,14},{24,12},{17,10},{17,10}}
    local side = 65
    for index,display in ipairs(self.Displays) do
        for _,reading in ipairs({"8888","88.8k"}) do
            for _,name in ipairs(PerHour.MetricOrder) do
                for _,suffix in ipairs({"/h","/m"}) do
                    local sizes = referenceFonts[index]
                    local required = display:MeasureReading(reading,PerHour.Modules[name].ShortName..suffix,sizes[1],sizes[2])
                    if index == 1 then required=required*25/36 end
                    side=math.max(side,math.ceil(required))
                end
            end
        end
    end
    local referenceWidth = Pixel(math.max(side,self.Duration:MeasureReading("88h 88m"))*0.847)
    self.PrimaryWidth = math.ceil(referenceWidth*36/25)
    self.SideWidth = Pixel(referenceWidth*DISPLAY_STYLES.medium.value/24)
end
function Dashboard:SaveDraggingPositions()
    local frame = self.Frame
    if not frame or not frame.PositionReady then return end
    if frame.Dragging then frame:StopMovingOrSizing(); frame.Dragging = false end
    Settings:SetPosition({point="TOPLEFT",relativePoint="BOTTOMLEFT",x=frame:GetLeft(),y=frame:GetTop()})
end
function Dashboard:RestorePositions()
    local position = Settings:GetPosition()
    if position then
        self.Frame:ClearAllPoints()
        self.Frame:SetPoint(position.point,UIParent,position.relativePoint,position.x,position.y)
    end
    self.Frame.PositionReady = true
    self.Frame:SetShown(Settings:Get("shown"))
end
function Dashboard:Show()
    Settings:Set("shown",true)
    self.Frame:Show(); self.Frame:Raise(); self:RefreshDisplays()
end
function Dashboard:Toggle()
    if self.Frame:IsShown() then Settings:Set("shown",false); self.Frame:Hide() else self:Show() end
end
function Dashboard:RefreshScheduler() PerHour.Capture:RefreshScheduler() end
function Dashboard:RequestRefresh()
    if self.RefreshScheduled then return end
    self.RefreshScheduled = true
    C_Timer.After(0,function() self.RefreshScheduled=false; self:RefreshDisplays() end)
end
function Dashboard:RefreshDisplays()
    if not self.Frame then return end
    self:RefreshScheduler()
    local order,capped = self:GetVisibleOrder()
    if self.Capped ~= capped then
        self.Capped = capped
        if PerHour.SettingsPanel.Frame and PerHour.SettingsPanel.Frame:IsShown() then PerHour.SettingsPanel:Refresh() end
    end
    if self.Frame:IsVisible() then
        local mode = Settings:Get("panelType")
        local gauge = Settings:GetSpeedometerEnabled() and not capped
        local experienceEstimate = Settings:GetEstimatesEnabled("Experience") and not capped
        local reputationEstimate = Settings:GetEstimatesEnabled("Reputation")
        local count = math.min(#order,mode == "full" and 4 or mode == "extended" and 2 or 1)
        local duration = mode ~= "focused" and Settings:Get("showDuration")
        local side = self.SideWidth
        local center = gauge and self.PrimaryWidth or Pixel(self.PrimaryWidth*0.85)
        self.ExperienceEstimate:SetSize(center,XS_HEIGHT)
        self.ReputationEstimate:SetSize(center,XS_HEIGHT)
        local xp = PerHour.Modules.Experience.State
        self.Speedometer:SetRate(Settings:GetRate() == "minute" and xp.ElementPerMinute or xp.ElementPerHour,
            Settings:GetSpeedometerMaximum(Settings:GetRate()))
        self.Speedometer:SetDisplayWidth(self.PrimaryWidth)
        local gaugeWidth = self.Speedometer:GetWidth()
        self.SpeedometerArea:SetSize(gaugeWidth,self.Speedometer:GetHeight())
        local left,right = -center/2,center/2
        local bottom,top = -DISPLAY_HEIGHTS[1]/2,DISPLAY_HEIGHTS[1]/2
        if count >= 2 then left=left-DISPLAY_GAP-side end
        if count >= 3 then right=right+DISPLAY_GAP+side end
        local secondaryY = duration and -(STACK_GAP+XS_HEIGHT)/2 or 0
        -- Reserve the Full composition height so changing panel type cannot move the frame vertically.
        local leftHeight = #order >= 2 and DISPLAY_HEIGHTS[2]+(Settings:Get("showDuration") and STACK_GAP+XS_HEIGHT or 0) or 0
        local rightHeight = #order == 4 and DISPLAY_HEIGHTS[3]+STACK_GAP+DISPLAY_HEIGHTS[4]
            or #order >= 3 and DISPLAY_HEIGHTS[3] or 0
        if experienceEstimate then top=math.max(top,DISPLAY_HEIGHTS[1]/2+2+XS_HEIGHT) end
        if reputationEstimate then bottom=bottom-2-XS_HEIGHT end
        if gauge then
            left,right = math.min(left,-gaugeWidth/2),math.max(right,gaugeWidth/2)
            top=math.max(top,DISPLAY_HEIGHTS[1]/2+16+self.SpeedometerArea:GetHeight())
        end
        local primaryY = -(top+bottom)/2
        local contentHeight = math.max(top-bottom,leftHeight,rightHeight)
        local insets = self.Frame.ContentInsets
        self.Frame:SetSize(math.max(right-left,self.Frame.ActionBar:GetWidth(),self.Frame.TitleText:GetStringWidth())
            +insets.left+insets.right,contentHeight+insets.top+insets.bottom)
        local primary = self.Displays[1]
        primary:SetSize(center,DISPLAY_HEIGHTS[1]); primary:ClearAllPoints()
        primary:SetPoint("CENTER",self.Frame.Content,"CENTER",-(left+right)/2,primaryY)
        for index,display in ipairs(self.Displays) do
            display:SetShown(index <= count and order[index] ~= nil)
            if index == 2 then
                display:SetSize(side,DISPLAY_HEIGHTS[index]); display:ClearAllPoints()
                display:SetPoint("RIGHT",primary,"LEFT",-DISPLAY_GAP,secondaryY-primaryY)
            elseif index > 2 then
                display:SetSize(side,DISPLAY_HEIGHTS[index]); display:ClearAllPoints()
                local offset = count == 4 and (DISPLAY_HEIGHTS[index]+STACK_GAP)/2 or 0
                display:SetPoint("LEFT",primary,"RIGHT",DISPLAY_GAP,(index == 3 and offset or -offset)-primaryY)
            end
            if order[index] then display:SetMetric(order[index]) end
        end
        self.Duration:SetShown(duration)
        self.Duration:SetSize(side,XS_HEIGHT)
        self.Duration:SetReading(Format:Duration(PerHour.Session.Current and PerHour.Session.Current.duration or 0))
        local status = BaseModule:GetTrackingStatus()
        self.Duration.Value:SetTextColor(unpack(PerHour.Theme.trackerStatus[status.key]))
        self.Duration:ClearAllPoints(); self.Duration:SetPoint("BOTTOM",self.Displays[2],"TOP",0,STACK_GAP)
        self.SpeedometerArea:SetShown(gauge)
        self.SpeedometerArea:ClearAllPoints(); self.SpeedometerArea:SetPoint("BOTTOM",primary,"TOP",0,16)
        self.ExperienceEstimate:SetShown(experienceEstimate)
        self.ExperienceEstimate:ClearAllPoints(); self.ExperienceEstimate:SetPoint("BOTTOM",primary,"TOP",0,2)
        self.ExperienceEstimate:SetReading(BaseModule:GetEstimate(PerHour.Modules.Experience))
        self.ReputationEstimate:SetShown(reputationEstimate)
        self.ReputationEstimate:ClearAllPoints(); self.ReputationEstimate:SetPoint("TOP",primary,"BOTTOM",0,-2)
        self.ReputationEstimate:SetReading(BaseModule:GetEstimate(PerHour.Modules.Reputation))
        self.Frame.Actions.primary:SetText(status.action)
        self.Frame.Actions.primary.Indicator:SetVertexColor(unpack(PerHour.Theme.trackerStatus[status.key]))
        self.Frame.Actions.primary:SetEnabled(not PerHour.Session.CheckingPlayed)
        local current = PerHour.Session.Current
        self.Notice:SetText(PerHour.Session.CheckingPlayed and "Verifying saved session…"
            or current and current.needsReview and "Review preserved totals before Resume."
            or PerHour.Session.Issue or "")
    end
    if PerHour.SessionPanels then PerHour.SessionPanels:Invalidate() end
end
function Dashboard:Init()
    local frame = Components:CreatePanel(UIParent,{
        name="PerHourDashboard",title="Per Hour",titleBox=true,titleSize="small",width=480,height=160,
        contentSpacing=4,
        draggable=true,onClose=function() Settings:Set("shown",false) end,
        actions={
            {key="settings",type="icon",texture="Interface\\Icons\\Trade_Engineering",tooltip=function() return "Settings" end,
                onClick=function() PerHour.SettingsPanel:Show() end},
            {key="primary",type="status",text="Start",width=96,onClick=function() PerHour.Session:Toggle() end},
            {key="sessions",tooltip=function() return "Sessions" end,
                menu=function(_,root)
                    root:CreateButton("History",function() PerHour.SessionPanels:ShowHistory() end)
                    if PerHour.Session.Current then
                        root:CreateButton("Current Session",function() PerHour.SessionPanels:ShowCurrent() end)
                        root:CreateDivider()
                        local finish=root:CreateFrame()
                        finish:SetData("Finish Session")
                        finish:AddInitializer(function(container,description)
                            -- Keep the normal panel action outside the menu's frame pool.
                            -- Only its temporary container is reset/recycled by the menu.
                            if not self.FinishMenuButton then
                                self.FinishMenuButton=Components:CreateButton(self.Frame,"Finish Session")
                            end
                            local button=self.FinishMenuButton
                            button:SetParent(container)
                            button:ClearAllPoints(); button:SetPoint("CENTER",container,"CENTER",0,0)
                            button:SetScript("OnClick",function(_,buttonName)
                                description:Pick(MenuInputContext.MouseButton,buttonName)
                            end)
                            container:SetScript("OnHide",function()
                                button:Hide(); button:SetParent(self.Frame)
                            end)
                            button:Show()
                            return button:GetWidth(),button:GetHeight()
                        end)
                        finish:SetResponder(function()
                            PerHour.Session:Finish()
                            return MenuResponse.CloseAll
                        end)
                    end
                end},
        },
    })
    self.Frame = frame
    frame:RegisterEvent("UPDATE_FACTION")
    frame:SetScript("OnEvent",function() self:RequestRefresh() end)
    frame.PositionReady = false
    frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
    self.Displays = {Display(frame.Content,DISPLAY_STYLES.large),Display(frame.Content,DISPLAY_STYLES.medium),
        Display(frame.Content,DISPLAY_STYLES.small),Display(frame.Content,DISPLAY_STYLES.small)}
    self.Duration = Display(frame.Content,DISPLAY_STYLES.extraSmall)
    self.Duration.TooltipTitle = "Duration"
    self:MeasureDisplays()
    self.ExperienceEstimate = Display(frame.Content,DISPLAY_STYLES.extraSmall)
    self.ExperienceEstimate.TooltipTitle = "Experience estimate"
    self.ReputationEstimate = Display(frame.Content,DISPLAY_STYLES.extraSmall)
    self.ReputationEstimate.TooltipTitle = "Reputation estimate"
    self.SpeedometerArea = CreateFrame("Frame",nil,frame.Content)
    self.Speedometer = Components:CreateSpeedometerDisplay(self.SpeedometerArea)
    self.Speedometer:SetPoint("CENTER",self.SpeedometerArea,"CENTER",0,0)
    self.Notice = frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    self.Notice:SetPoint("TOP",frame,"BOTTOM",0,-6)
    self.Notice:SetTextColor(1,0.8,0)
    frame:HookScript("OnDragStart",function() frame.Dragging=true end)
    frame:HookScript("OnDragStop",function() self:SaveDraggingPositions() end)
    frame:HookScript("OnHide",function() self:SaveDraggingPositions(); GameTooltip:Hide() end)
    frame:HookScript("OnShow",function() self:RefreshDisplays() end)
    Components:SetupCloseButtonHover(frame)
    frame:SetShown(Settings:Get("shown"))
    self:RefreshDisplays()
end
