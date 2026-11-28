local Components,View,Rows=PerHour.Components,PerHour.DetailsView,PerHour.SessionRows

function Components:SetupDetailsPanel(panel,owner)
    panel.SessionHeader=CreateFrame("Frame",nil,panel.Content)
    panel.SessionHeader:SetPoint("TOPLEFT",panel.Content,"TOPLEFT",0,0)
    panel.SessionHeader:SetWidth(690)
    panel.SessionFrames={}
    panel.Tabs=self:CreateTabs(panel.Content,{"Income","Expenses","Reputation"},function()
        owner:RefreshDetails()
    end)
    panel.Tabs:SetPoint("TOPLEFT",panel.SessionHeader,"BOTTOMLEFT",0,-8)
    panel.Tabs:SetWidth(690)
    panel.TabBox=self:CreateTabBox(panel.Content)
    panel.TabBox:SetPoint("TOPLEFT",panel.Tabs,"BOTTOMLEFT",0,0)
    panel.TabBox:SetPoint("BOTTOMRIGHT",panel.Content,"BOTTOMRIGHT",0,34)
    panel.DetailsRecordID=false
end

function Components:UpdateDetailsPanel(panel,record,current,owner)
    panel.SessionRows=View:BuildSessionRows(record,current)
    local height=0
    for index,data in ipairs(panel.SessionRows) do
        local frame=panel.SessionFrames[index]
        if not frame then
            frame=CreateFrame("Frame",nil,panel.SessionHeader)
            panel.SessionFrames[index]=frame
        end
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT",panel.SessionHeader,"TOPLEFT",0,-height)
        frame:SetSize(690,Rows:GetExtent(data))
        Rows:Initialize(frame,data,owner)
        frame:Show()
        height=height+Rows:GetExtent(data)
    end
    for index=#panel.SessionRows+1,#panel.SessionFrames do panel.SessionFrames[index]:Hide() end
    panel.SessionHeader:SetHeight(height)
    if panel.DetailsRecordID ~= record.id or not panel.Tabs.Buttons[panel.Tabs.SelectedKey]:IsShown() then
        panel.Tabs:Select("Income")
        panel.DetailsRecordID=record.id
    end
    local inset=height+8+panel.Tabs:GetHeight()
    local metricRows=View:BuildMetricRows(record,current,panel.Tabs.SelectedKey)
    local headers=self:GetSessionListHeaderHeight(metricRows)
    -- Grow for wrapped metadata, retaining a useful tab viewport; PanelWindows fits the screen.
    panel:SetHeight(math.max(600,panel.ContentInsets.top+panel.ContentInsets.bottom+inset+34+16+headers+240))
    self:LayoutSessionList(panel,{parent=panel.TabBox,left=8,top=8,right=-22,bottom=8,
        height=panel:GetHeight()-panel.ContentInsets.top-panel.ContentInsets.bottom-inset-34-16})
    self:SetSessionListRows(panel,metricRows,record.id..":"..panel.Tabs.SelectedKey)
end
