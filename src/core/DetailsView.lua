local Rows,Format,Theme,Components=PerHour.SessionRows,PerHour.Format,PerHour.Theme,PerHour.Components
local View={}
PerHour.DetailsView=View
local PAD,GAP,KEY_WIDTH,COLUMN_WIDTH = 8,20,104,327
local VALUE_WIDTH=COLUMN_WIDTH-KEY_WIDTH-12
local WIDE_VALUE_WIDTH=558
local SESSION_VALUE_WIDTH=WIDE_VALUE_WIDTH-Components.RenameButtonSize.width-8
local REPUTATION_COLUMNS={
    {label="Faction",width=282},{label="Duration",width=112,right=true},
    {label="Rate",width=146,right=true},{label="Total",width=146,right=true},
}

local function Text(parent,font)
    local label=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight")
    label:SetJustifyH("LEFT"); label:SetJustifyV("TOP"); label:SetWordWrap(true); label:SetNonSpaceWrap(true)
    return label
end
local measureFrame,measures
local function Measure(text,width,font)
    if not measureFrame then
        measureFrame=CreateFrame("Frame",nil,UIParent); measureFrame:Hide(); measures={}
    end
    font=font or "GameFontHighlight"
    if not measures[font] then measures[font]=Text(measureFrame,font) end
    local label=measures[font]
    label:SetWidth(width); label:SetHeight(0); label:SetText(text)
    return math.ceil(label:GetStringHeight())
end
local function Fields(rows,id,fields)
    local index=1
    while index <= #fields do
        local pair={fields[index]}
        local wide=fields[index].wide == true
        if not wide and fields[index+1] and not fields[index+1].wide then pair[2]=fields[index+1] end
        local height=24
        for _,field in ipairs(pair) do
            field.value=tostring(field.value or "—")
            height=math.max(height,Measure(field.value,wide and WIDE_VALUE_WIDTH or VALUE_WIDTH)+8,
                Measure(field.key,KEY_WIDTH,"GameFontHighlightSmall")+8)
        end
        rows[#rows+1]={kind="detailsFields",id=id..":"..fields[index].key,fields=pair,wide=wide,height=height,divider=false}
        index=index+#pair
    end
end
local function Grid(rows,id,columns,values,colors,header)
    if header then values={}; for _,column in ipairs(columns) do values[#values+1]=column.label end end
    local height=header and 24 or 28
    for index,value in ipairs(values) do height=math.max(height,Measure(value,columns[index].width-12)+8) end
    local data={kind="detailsGrid",id=id,columns=columns,values=values,colors=colors,header=header,height=height}
    rows[#rows+1]=data
    return data
end
local function Total(name,metric)
    return metric.available == false and metric.total == 0 and "—" or Format:Amount(name,metric.total)
end
local function Duration(seconds) return Utils:DisplayTimer(math.floor(seconds)) end

local function ShowDataTooltip(body)
    local tooltip=body.Data and body.Data.tooltip
    if not tooltip then return end
    GameTooltip:SetOwner(body,"ANCHOR_RIGHT"); GameTooltip:SetText(tooltip.title)
    for _,line in ipairs(tooltip.lines) do GameTooltip:AddLine(line,1,1,1,true) end
    GameTooltip:Show()
end
local function SetupDataTooltip(body)
    body:SetScript("OnEnter",ShowDataTooltip)
    body:SetScript("OnLeave",function(self) if GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
    body:SetScript("OnHide",function(self) if GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
    body:SetMouseClickEnabled(false)
end
local function RefreshDataTooltip(body,data)
    body:SetMouseMotionEnabled(data.tooltip ~= nil)
    if GameTooltip:IsOwned(body) then
        if data.tooltip then ShowDataTooltip(body) else GameTooltip:Hide() end
    end
end

local function MetricFields(record,name)
    local metric=record.metrics[name]
    local rate=Format:Rate(metric)
    local suffix=PerHour.Stores.Settings:GetRate() == "minute" and " / Minute" or " / Hour"
    local tooltip={"Rate: "..Format:RateText(name,metric),"Total: "..Total(name,metric),"Measured: "..Duration(metric.duration)}
    local flags=Format:Flags(metric)
    if flags ~= "" then tooltip[#tooltip+1]=flags end
    if metric.issue then tooltip[#tooltip+1]=metric.issue end
    local rateText=rate and Format:TruncatedCompact(rate,1) or "—"
    local totalText=metric.available == false and metric.total == 0 and "—" or Format:TruncatedCompact(metric.total,0)
    if name == "Gold" then
        rateText=Format:RateText(name,metric)
        if totalText ~= "—" then
            totalText=Format:Amount(name,metric.total).." (inc - exp)"
        end
        tooltip[#tooltip+1]="Coins: "..Format:Amount(name,record.gold.coins)
        tooltip[#tooltip+1]="Items (est.): "..Format:Amount(name,record.gold.items)
        tooltip[#tooltip+1]="Expenses: "..Format:Amount(name,record.gold.expenses)
        if (metric.pendingCount or 0) > 0 then
            tooltip[#tooltip+1]=(metric.incomplete and "Excluded prices: " or "Pending prices: ")..metric.pendingCount
        end
    end
    local context={title=name,lines=tooltip}
    return {key=name..suffix,value=rateText,tooltip=context},
        {key="Total "..name,value=totalText,tooltip=context}
end

function View:BuildSessionRows(record,current)
    local rows={}
    local running=current and not record.paused and not record.needsReview and not PerHour.Session.CheckingPlayed
    rows[#rows+1]={kind="detailsSession",id="session:heading",value=record.name,record=record,current=current,
        color=running and Theme.green.text or Theme.gold.text,
        height=math.max(32,Measure(record.name,SESSION_VALUE_WIDTH)+16),divider=false}
    local level=record.startLevel > 0 and tostring(record.startLevel) or "Unavailable"
    local xp=record.startAtMaxLevel and "Max level" or record.startXpPercent and record.startXpPercent.."% xp" or "XP unavailable"
    Fields(rows,"session",{
        {key="Character",value=Format:Character(record)},
        {key="Level",value=level.." ("..xp..")"},
        {key="Started",value=Format:Date(record.startedAt)},
        {key="Duration",value=Format:MeasuredDuration(record.duration)},
    })
    for _,name in ipairs({"Experience","Honor","Gold"}) do
        if name ~= "Experience" or self:HasExperience(record) then
            local rate,total=MetricFields(record,name)
            Fields(rows,"metric",{rate,total})
        end
    end
    Fields(rows,"session",{{key="Visited areas",value=#record.zones > 0 and table.concat(record.zones," • ") or record.map,wide=true}})
    return rows
end

function View:HasExperience(record)
    return not record.startAtMaxLevel and record.startLevel < 60
end

local function Reputation(rows,record,current)
    local factions,tracked={},0
    for _,faction in pairs(record.reputation or {}) do factions[#factions+1]=faction; tracked=tracked+faction.duration end
    table.sort(factions,function(a,b) return a.name < b.name end)
    Grid(rows,"rep:columns",REPUTATION_COLUMNS,nil,nil,true)
    for _,faction in ipairs(factions) do
        local metric={total=faction.total,duration=faction.duration,available=true,partial=faction.partial}
        local active=current and record.reputationFaction == faction.id
        local running=active and not record.paused and not record.needsReview and not PerHour.Session.CheckingPlayed
        local color=active and (running and Theme.green.text or Theme.gold.text) or Theme.text
        local row=Grid(rows,"rep:"..faction.id,REPUTATION_COLUMNS,{faction.name,Format:MeasuredDuration(faction.duration),
            Format:RateText("Reputation",metric),Format:Amount("Reputation",faction.total)},{[1]=color})
        row.tooltip={title=faction.name,lines={"Rate uses only the time tracked for this faction."}}
        if faction.partial then row.tooltip.lines[#row.tooltip.lines+1]="Partial reputation capture." end
    end
    local untracked=math.max(0,record.duration-tracked)
    if untracked > 0 or #factions == 0 then
        Grid(rows,"rep:untracked",REPUTATION_COLUMNS,{"No faction",Format:MeasuredDuration(untracked),"—","—"})
    end
end

local function Gold(rows,record,flow)
    local groups=PerHour.GoldGroups:Build(record.events,flow)
    local sum,known,missing=0,0,false
    for _,group in ipairs(groups) do
        sum=sum+math.abs(group.amount); known=known+group.resolvedCount
        missing=missing or group.pending or group.excluded
    end
    local value=(record.detailsExpired or (#groups > 0 and known == 0)) and "—" or Format:Money(sum)
    if missing or record.eventsLimited then value=value.." *" end
    local lines={"Sum of recorded values shown in this table."}
    if missing then lines[#lines+1]="Pending or frozen excluded values are not included." end
    if record.eventsLimited then lines[#lines+1]="Only the latest 1,000 events contribute; the session summary includes all events." end
    if record.detailsExpired then lines[#lines+1]="Detailed events expired; the preserved session summary is unchanged." end
    rows[#rows+1]={kind="goldSum",id="sum:"..flow,value="Sum: "..value,pinned=true,divider=false,
        color=flow == "Expenses" and Theme.red.text or Theme.text,tooltip={title=flow,lines=lines}}
    rows[#rows+1]={kind="header",columns="event",id="events:header"}
    if #groups > 0 then
        for _,group in ipairs(groups) do
            rows[#rows+1]={id=group.id,event=group}
        end
    else
        Fields(rows,"events",{{key="Events",value=record.detailsExpired and "Details expired; summary preserved"
            or flow == "Expenses" and "No expenses recorded" or "No income recorded",wide=true}})
    end
end

function View:BuildMetricRows(record,current,name)
    local rows={}
    if name == "Reputation" then Reputation(rows,record,current)
    elseif name == "Income" or name == "Expenses" then Gold(rows,record,name) end
    return rows
end

Rows:RegisterType("detailsSession",32,function(body,owner)
    body.Title=Text(body,"GameFontNormal")
    body.Title:SetPoint("TOPLEFT",body,"TOPLEFT",PAD,-8); body.Title:SetWidth(KEY_WIDTH)
    body.Title:SetText("Session")
    body.Value=Text(body)
    body.Value:SetPoint("TOPLEFT",body,"TOPLEFT",PAD+KEY_WIDTH+12,-8)
    body.Value:SetWidth(SESSION_VALUE_WIDTH)
    body.Rename=Components:CreateRenameButton(body)
    body.Rename:SetPoint("TOPRIGHT",body,"TOPRIGHT",-PAD,-3)
    body.Rename:SetScript("OnClick",function() owner:ShowRename(body.Data.record,body.Data.current) end)
end,function(body,data)
    body.Value:SetHeight(data.height-16); body.Value:SetText(data.value)
    body.Value:SetTextColor(unpack(data.color))
end)

Rows:RegisterType("goldSum",24,function(body)
    body.Value=Text(body)
    body.Value:SetPoint("RIGHT",body,"RIGHT",-8,0)
    body.Value:SetSize(674,16); body.Value:SetJustifyH("RIGHT"); body.Value:SetJustifyV("MIDDLE")
    body.Value:SetWordWrap(false)
    SetupDataTooltip(body)
end,function(body,data)
    body.Value:SetText(data.value); body.Value:SetTextColor(unpack(data.color))
    RefreshDataTooltip(body,data)
end)

Rows:RegisterType("detailsFields",24,function(body) body.Fields={} end,function(body,data)
    for index,field in ipairs(data.fields) do
        local controls=body.Fields[index]
        if not controls then
            controls={key=Text(body,"GameFontHighlightSmall"),value=Text(body)}
            controls.key:SetTextColor(unpack(Theme.gold.subtleText)); body.Fields[index]=controls
            controls.hover=CreateFrame("Frame",nil,body)
            controls.hover:SetScript("OnEnter",function(self)
                local tooltip=self.Tooltip
                if not tooltip then return end
                GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText(tooltip.title)
                for _,line in ipairs(tooltip.lines) do GameTooltip:AddLine(line,1,1,1,true) end
                GameTooltip:Show()
            end)
            controls.hover:SetScript("OnLeave",function(self) if GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
            controls.hover:SetScript("OnHide",function(self) if GameTooltip:IsOwned(self) then GameTooltip:Hide() end end)
            controls.hover:SetMouseClickEnabled(false)
            controls.hover:SetMouseMotionEnabled(true)
        end
        local x=PAD+(index-1)*(COLUMN_WIDTH+GAP)
        for _,label in ipairs({controls.key,controls.value}) do label:ClearAllPoints(); label:SetHeight(data.height-8); label:Show() end
        controls.key:SetPoint("TOPLEFT",body,"TOPLEFT",x,-4); controls.key:SetWidth(KEY_WIDTH); controls.key:SetText(field.key)
        controls.value:SetPoint("TOPLEFT",body,"TOPLEFT",x+KEY_WIDTH+12,-4)
        controls.value:SetWidth(data.wide and WIDE_VALUE_WIDTH or VALUE_WIDTH); controls.value:SetText(field.value)
        controls.value:SetJustifyH(field.align or "LEFT")
        controls.value:SetTextColor(unpack(field.color or Theme.text))
        controls.hover:ClearAllPoints(); controls.hover:SetPoint("TOPLEFT",body,"TOPLEFT",x,0)
        controls.hover:SetSize(data.wide and 674 or COLUMN_WIDTH,data.height)
        controls.hover.Tooltip=field.tooltip
        controls.hover:SetShown(field.tooltip ~= nil)
        if GameTooltip:IsOwned(controls.hover) then
            if field.tooltip then controls.hover:GetScript("OnEnter")(controls.hover) else GameTooltip:Hide() end
        end
    end
    for index=#data.fields+1,#body.Fields do
        body.Fields[index].key:Hide(); body.Fields[index].value:Hide(); body.Fields[index].hover:Hide()
    end
end)

Rows:RegisterType("detailsGrid",28,function(body) body.Cells={}; SetupDataTooltip(body) end,function(body,data)
    local x=PAD
    for index,column in ipairs(data.columns) do
        local label=body.Cells[index]
        if not label then label=Text(body); body.Cells[index]=label end
        label:ClearAllPoints(); label:SetPoint("TOPLEFT",body,"TOPLEFT",x,-4)
        label:SetSize(column.width-12,data.height-8); label:SetJustifyH(column.right and "RIGHT" or "LEFT")
        label:SetTextColor(unpack(data.header and Theme.gold.subtleText or data.colors and data.colors[index] or Theme.text))
        label:SetText(data.values[index] or "—"); label:Show()
        x=x+column.width
    end
    for index=#data.columns+1,#body.Cells do body.Cells[index]:Hide() end
    RefreshDataTooltip(body,data)
end)
