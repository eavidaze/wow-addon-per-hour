local Rows,Format,Theme=PerHour.SessionRows,PerHour.Format,PerHour.Theme
local View={}
PerHour.ComparisonView=View

-- The viewport starts 15 px inside the 700 px panel: vs. is centered at x=335.
local COLUMNS={
    {width=112,align="LEFT"}, {width=203,align="RIGHT"},
    {width=24,align="CENTER"}, {width=293,align="LEFT"},
}

local function Winner(left,right)
    if left > right then return 2 end
    if right > left then return 4 end
end
local function Advantage(left,right,winner)
    if not winner or not left or not right then return end
    local baseline=winner == 2 and right or left
    if baseline == 0 then return end
    local percent=math.abs(left-right)/math.abs(baseline)*100
    if Utils:IsFiniteNumber(percent) then return percent end
end
local function PercentText(percent)
    return (percent < 0.1 and "<0.1" or Utils:DisplayRoundedNumber(percent,percent < 100 and 1 or 0)).."%"
end
local function Rate(name,metric)
    local rate=Format:Rate(metric,"hour") or 0
    rate=rate/(PerHour.Modules[name].RateDivisor or 1)
    return Format:TruncatedCompact(rate,1).." "..Format:Unit(name,"hour")
end
local function MetricTooltip(label,name,metric)
    local rate=Format:RateText(name,metric,"minute")
    if rate == "—" then rate="0/m" end
    return {title=label,lines={"Rate per min.: "..rate,"Total: "..Format:Amount(name,metric and metric.total or 0)}}
end
local function SessionTooltip(record)
    return {title=record.name,lines={Format:Character(record),"Started: "..Format:Date(record.startedAt),
        "Duration: "..Format:MeasuredDuration(record.duration)}}
end
local function MetricRow(id,label,name,left,right)
    local leftRate,rightRate=Format:Rate(left,"hour"),Format:Rate(right,"hour")
    local winner=Winner(leftRate or 0,rightRate or 0)
    return {kind="comparison",id=id,label=label,values={label,Rate(name,left),"vs.",Rate(name,right)},
        winner=winner,advantage=Advantage(leftRate,rightRate,winner),
        tooltips={[1]={title=label,lines={"Rates per hour."}},
            [2]=MetricTooltip(label,name,left),[4]=MetricTooltip(label,name,right)}}
end
function View:BuildRows(first,second)
    local rows={{kind="comparison",id="compare:header",header=true,height=28,
        values={"",first.name,"",second.name},tooltips={[2]=SessionTooltip(first),[4]=SessionTooltip(second)}}}
    for _,name in ipairs({"Experience","Gold","Honor"}) do
        rows[#rows+1]=MetricRow("compare:"..name,name,name,first.metrics[name],second.metrics[name])
    end
    local factions,ordered={},{}
    for _,record in ipairs({first,second}) do
        for id,faction in pairs(record.reputation or {}) do
            if not factions[id] then
                factions[id]={id=id,name=faction.name}; ordered[#ordered+1]=factions[id]
            end
        end
    end
    table.sort(ordered,function(a,b) return a.name == b.name and a.id < b.id or a.name < b.name end)
    local function Faction(record,id)
        local faction=record.reputation and record.reputation[id]
        if faction then return {total=faction.total,duration=faction.duration,available=true,partial=faction.partial} end
    end
    for _,faction in ipairs(ordered) do
        rows[#rows+1]=MetricRow("compare:rep:"..faction.id,faction.name,"Reputation",
            Faction(first,faction.id),Faction(second,faction.id))
    end
    return rows
end

function View:LayoutPanel(panel,rows)
    local height=0
    for _,row in ipairs(rows) do height=height+Rows:GetExtent(row) end
    local overhead=panel.ContentInsets.top+panel.ContentInsets.bottom+34
    panel:SetHeight(math.max(320,math.min(520,overhead+height)))
    local width=panel:GetWidth()-panel.ContentInsets.left-panel.ContentInsets.right-22
    panel.Notice:SetWidth(width)
    PerHour.Components:LayoutSessionList(panel,{parent=panel.Content,left=0,top=0,right=-22,bottom=34,
        width=width,height=panel:GetHeight()-overhead})
end

local function HideTooltip(cell)
    if GameTooltip:IsOwned(cell) then GameTooltip:Hide() end
end
local function ShowTooltip(cell)
    local tooltip=cell.Tooltip
    if not tooltip then return end
    GameTooltip:SetOwner(cell,"ANCHOR_RIGHT"); GameTooltip:SetText(tooltip.title)
    for _,line in ipairs(tooltip.lines) do GameTooltip:AddLine(line,1,1,1,true) end
    GameTooltip:Show()
end
Rows:RegisterType("comparison",32,function(body)
    body.Cells,body.Hovers,body.Advantages={},{},{}
    local x=8
    for index,column in ipairs(COLUMNS) do
        local text=body:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        text:SetPoint("TOPLEFT",body,"TOPLEFT",x+(index == 3 and 0 or 6),-4)
        text:SetSize(column.width-(index == 3 and 0 or 12),16)
        text:SetJustifyH(column.align); text:SetJustifyV("MIDDLE")
        text:SetWordWrap(false); body.Cells[index]=text
        if index == 2 or index == 4 then
            local badge=CreateFrame("Frame",nil,body)
            badge:SetHeight(20)
            badge.Arrow=badge:CreateTexture(nil,"ARTWORK")
            badge.Arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
            badge.Arrow:SetTexCoord(0,0.5625,1,0)
            badge.Arrow:SetSize(9,8); badge.Arrow:SetPoint("LEFT",badge,"LEFT",0,0)
            badge.Arrow:SetVertexColor(unpack(Theme.green.text))
            badge.Text=badge:CreateFontString(nil,"OVERLAY","GameFontHighlight")
            badge.Text:SetPoint("LEFT",badge.Arrow,"RIGHT",4,0)
            badge.Text:SetJustifyH("LEFT"); badge.Text:SetWordWrap(false)
            badge.Text:SetTextColor(unpack(Theme.green.text))
            badge:Hide(); body.Advantages[index]=badge
        end
        if index ~= 3 then
            local hover=CreateFrame("Frame",nil,body)
            hover:SetPoint("TOPLEFT",body,"TOPLEFT",x,0); hover:SetSize(column.width,24)
            hover:SetMouseClickEnabled(false); hover:SetMouseMotionEnabled(true)
            hover:SetScript("OnEnter",ShowTooltip); hover:SetScript("OnLeave",HideTooltip)
            hover:SetScript("OnHide",HideTooltip); body.Hovers[index]=hover
        end
        x=x+column.width
    end
end,function(body,data)
    local x=8
    local labelWidth=COLUMNS[1].width-12
    for index,text in ipairs(body.Cells) do
        text:SetFontObject(not data.header and index == 1 and "GameFontHighlightSmall" or "GameFontHighlight")
        local font,_,flags=text:GetFont()
        text:SetFont(font,data.header and 16 or index == 1 and 10 or index == 3 and 12 or 14,flags)
        text:SetHeight(20)
        text:SetTextColor(unpack((data.header or data.winner == index) and Theme.gold.text
            or (index == 1 or index == 3) and Theme.gold.subtleText or Theme.text))
        local column=COLUMNS[index]
        local width=column.width-(index == 3 and 0 or 12)
        local badge=body.Advantages[index]
        local badgeWidth=0
        if badge then
            badge:Hide()
            if not data.header and data.winner == index and data.advantage then
                local caption=PercentText(data.advantage)
                badge.Text:SetWidth(0)
                badge.Text:SetText(caption)
                badgeWidth=badge.Text:GetUnboundedStringWidth()+13
                badge.Text:SetWidth(badgeWidth-13)
                badge:SetWidth(badgeWidth)
                badge:Show()
            end
        end
        text:ClearAllPoints()
        if not data.header and (index == 2 or index == 4) then
            -- Readings and advantages use their full measured width, never ellipsis.
            text:SetWidth(0); text:SetText(data.values[index])
            local readingWidth=text:GetUnboundedStringWidth()
            text:SetWidth(readingWidth)
            local left=index == 2 and x+column.width-6-readingWidth or x+6
            text:SetPoint("TOPLEFT",body,"TOPLEFT",left,-4)
            if index == 2 then
                local groupLeft=left-(badgeWidth > 0 and badgeWidth+6 or 0)
                labelWidth=math.min(labelWidth,math.max(1,groupLeft-20))
            end
        else
            text:SetPoint("TOPLEFT",body,"TOPLEFT",x+(index == 3 and 0 or 6),-4)
            text:SetWidth(width)
            Format:FitText(text,data.values[index])
        end
        if badgeWidth > 0 then
            local readingWidth=math.min(text:GetStringWidth(),text:GetWidth())
            badge:ClearAllPoints()
            if index == 2 then badge:SetPoint("RIGHT",text,"RIGHT",-readingWidth-6,0)
            else badge:SetPoint("LEFT",text,"LEFT",readingWidth+6,0) end
        end
        local hover=body.Hovers[index]
        if hover then
            hover:SetHeight(data.header and 24 or 28)
            hover.Tooltip=data.tooltips[index]
            hover:SetMouseMotionEnabled(hover.Tooltip ~= nil)
            if GameTooltip:IsOwned(hover) then
                if hover.Tooltip then ShowTooltip(hover) else HideTooltip(hover) end
            end
        end
        x=x+column.width
    end
    if not data.header then
        body.Cells[1]:SetWidth(labelWidth)
        Format:FitText(body.Cells[1],data.values[1])
    end
end)
