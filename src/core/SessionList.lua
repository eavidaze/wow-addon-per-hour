local Components,Rows = PerHour.Components,PerHour.SessionRows
local function IsHeader(data) return data.kind == "header" or data.header or data.pinned end

function Components:GetSessionListHeaderHeight(rows)
    local height=0
    for _,data in ipairs(rows) do
        if not IsHeader(data) then break end
        height=height+Rows:GetExtent(data)
    end
    return height
end

function Components:CreateSessionList(panel,owner,topInset)
    topInset=topInset or 60
    panel.Rows = {}
    panel.TableHeader=CreateFrame("Frame",nil,panel.Content)
    panel.TableHeaderFrames,panel.TableHeaderRows,panel.TableHeaderHeight={}, {},0
    panel.ListOwner=owner
    panel.ScrollBox=CreateFrame("Frame",nil,panel.Content,"WowScrollBoxList")
    panel.ScrollBox:SetSize(690,476-topInset)
    panel.ScrollBox:SetPoint("TOPLEFT",panel.Content,"TOPLEFT",0,-topInset)
    panel.ScrollBox:SetPoint("BOTTOMRIGHT",panel.Content,"BOTTOMRIGHT",-22,34)
    panel.ScrollBar=CreateFrame("EventFrame",nil,panel.Content,"MinimalScrollBar")
    panel.ScrollBar:SetPoint("TOPLEFT",panel.ScrollBox,"TOPRIGHT",6,0)
    panel.ScrollBar:SetPoint("BOTTOMLEFT",panel.ScrollBox,"BOTTOMRIGHT",6,0)
    local view=CreateScrollBoxListLinearView()
    view:SetElementExtentCalculator(function(_,data) return Rows:GetExtent(data) end)
    view:SetElementInitializer("Frame",function(row,data) Rows:Initialize(row,data,owner) end)
    ScrollUtil.InitScrollBoxListWithScrollBar(panel.ScrollBox,panel.ScrollBar,view)
    self:LayoutSessionList(panel,{parent=panel.Content,left=0,top=topInset,right=-22,bottom=34,height=476-topInset})
end

function Components:LayoutSessionList(panel,layout)
    panel.ListLayout=layout or panel.ListLayout
    layout=panel.ListLayout
    local height=panel.TableHeaderHeight
    local width=layout.width or 690
    panel.TableHeader:SetParent(layout.parent)
    panel.TableHeader:ClearAllPoints(); panel.TableHeader:SetSize(width,height)
    panel.TableHeader:SetPoint("TOPLEFT",layout.parent,"TOPLEFT",layout.left,-layout.top)
    panel.TableHeader:SetPoint("TOPRIGHT",layout.parent,"TOPRIGHT",layout.right,-layout.top)
    panel.TableHeader:SetShown(height > 0)
    panel.ScrollBox:ClearAllPoints(); panel.ScrollBox:SetSize(width,math.max(1,layout.height-height))
    panel.ScrollBox:SetPoint("TOPLEFT",layout.parent,"TOPLEFT",layout.left,-layout.top-height)
    panel.ScrollBox:SetPoint("BOTTOMRIGHT",layout.parent,"BOTTOMRIGHT",layout.right,layout.bottom)
end

function Components:SetSessionListRows(panel,rows,key)
    local headers,content={},{}
    local inHeader=true
    for _,data in ipairs(rows) do
        if inHeader and IsHeader(data) then headers[#headers+1]=data
        else inHeader=false; content[#content+1]=data end
    end
    rows=content
    local height=0
    for index,data in ipairs(headers) do
        local frame=panel.TableHeaderFrames[index]
        if not frame then frame=CreateFrame("Frame",nil,panel.TableHeader); panel.TableHeaderFrames[index]=frame end
        frame:ClearAllPoints(); frame:SetSize(panel.ListLayout.width or 690,Rows:GetExtent(data))
        frame:SetPoint("TOPLEFT",panel.TableHeader,"TOPLEFT",0,-height)
        frame:SetPoint("TOPRIGHT",panel.TableHeader,"TOPRIGHT",0,-height)
        Rows:Initialize(frame,data,panel.ListOwner); frame:Show()
        height=height+Rows:GetExtent(data)
    end
    for index=#headers+1,#panel.TableHeaderFrames do panel.TableHeaderFrames[index]:Hide() end
    panel.TableHeaderRows,panel.TableHeaderHeight=headers,height
    self:LayoutSessionList(panel)
    local offset=panel.ScrollBox:GetDerivedScrollOffset()
    if key ~= panel.ListKey then offset=0
    elseif offset > 0 then
        local start,anchor=0,1
        for index,item in ipairs(panel.Rows) do
            anchor=index
            if start+Rows:GetExtent(item) > offset then break end
            start=start+Rows:GetExtent(item)
        end
        local fraction=offset-start
        local positions,position={},0
        for _,item in ipairs(rows) do
            if item.id then positions[item.id]={offset=position,height=Rows:GetExtent(item)} end
            position=position+Rows:GetExtent(item)
        end
        local target
        for index=anchor,#panel.Rows do
            local item=panel.Rows[index]
            if item.id and positions[item.id] then target=positions[item.id]; break end
        end
        if not target then
            for index=anchor-1,1,-1 do
                local item=panel.Rows[index]
                if item.id and positions[item.id] then target=positions[item.id]; break end
            end
        end
        offset=target and target.offset+math.min(fraction,target.height-1) or 0
    end
    panel.Rows,panel.ListKey=rows,key
    panel.ScrollBox:SetDataProvider(CreateDataProvider(rows),ScrollBoxConstants.RetainScrollPosition)
    panel.ScrollBox:ScrollToOffset(offset,ScrollBoxConstants.NoScrollInterpolation)
end
