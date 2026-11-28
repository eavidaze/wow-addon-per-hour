local Components,Format,Theme = PerHour.Components,PerHour.Format,PerHour.Theme
local Rows = { Extents={event=26,history=28,header=24,summary=52} }
PerHour.SessionRows = Rows
local HISTORY={name=36,nameWidth=338,duration=478,gold=564,rename=576}
local HISTORY_CONTROL_SIZE=24
local ITEM_ICON_SCALE=0.5
local ITEM_ICON_SIZE=37*ITEM_ICON_SCALE -- Match the native ItemButton at the event rows' scale.
-- The divider leaves 25 px of content; use a 24 px band to avoid half-pixel centers.
local HISTORY_CENTER_Y=-HISTORY_CONTROL_SIZE/2
local SOURCES = {
    loot_money={label="Dropped",icon="Interface\\Icons\\INV_Misc_Bag_10"},
    quest_money={label="Reward",icon="Interface\\Icons\\INV_Misc_Bag_10"},
    loot_item={label="Item looted"},item_reward={label="Item reward"},
    consumable={label="Consumable used"},quest_turnin={label="Quest turn-in"},
    repair={label="Repair",icon="Interface\\Icons\\Trade_BlackSmithing"},
    transport={label="Transport",icon="Interface\\Minimap\\Tracking\\FlightMaster"},
    item_income={label="Items received"},item_expense={label="Items spent"},
}

local function Text(parent,font,wrap)
    local label=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight")
    label:SetJustifyH("LEFT"); label:SetWordWrap(wrap == true)
    return label
end
local function HideTooltip(owner)
    if not owner or GameTooltip:IsOwned(owner) then GameTooltip:Hide() end
end
local function SummaryTooltip(body)
    local data=body.Data
    GameTooltip:SetOwner(body,"ANCHOR_RIGHT")
    GameTooltip:SetText(data.label or "Session")
    if data.left then GameTooltip:AddLine(data.left,1,1,1,true) end
    if data.right then GameTooltip:AddLine(data.right,1,1,1,true) end
    GameTooltip:Show()
end
local function EventValue(entry)
    if entry.grouped and entry.resolvedCount > 0 then
        return Format:Money(entry.amount)..((entry.pending or entry.excluded) and " *" or "")
    end
    return entry.excluded and "Not included · frozen" or entry.pending and "Pending" or Format:Money(entry.amount)
end
local function EventTooltip(body,owner,quest)
    local entry=body.Data.event
    local source=SOURCES[entry.source] or {label=entry.source}
    local money=entry.source == "loot_money" or entry.source == "quest_money"
    if quest and not entry.questID and not (entry.questCount and entry.questCount > 0)
        or not quest and not entry.itemLink and not money then return end
    GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
    if quest and entry.questID then GameTooltip:SetHyperlink("quest:"..entry.questID)
    elseif quest then GameTooltip:SetText("Quests"); GameTooltip:AddLine(entry.questCount.." quests in this group",1,1,1)
    elseif entry.itemLink then GameTooltip:SetHyperlink(entry.itemLink)
    else GameTooltip:SetText(source.label); GameTooltip:AddLine(Format:Money(entry.amount),1,1,1) end
    if entry.grouped then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Recorded summary:",unpack(Theme.gold.text))
        GameTooltip:AddDoubleLine("Count",tostring(entry.quantity))
        if entry.itemID then GameTooltip:AddDoubleLine("Events",tostring(entry.eventCount)) end
        GameTooltip:AddDoubleLine("Last",Format:Date(entry.timestamp))
        GameTooltip:AddDoubleLine("Recorded value",EventValue(entry))
        if entry.unitPrice then GameTooltip:AddDoubleLine("Unit value",Format:Money(entry.unitPrice)) end
        if entry.priceSource then GameTooltip:AddDoubleLine("Price source",PerHour.Pricing:SourceLabel(entry.priceSource,entry.priceMetric)) end
        if entry.pendingCount > 0 then GameTooltip:AddLine(entry.pendingCount.." events pending; unresolved values not included.",1,0.8,0,true) end
        if entry.excludedCount > 0 then GameTooltip:AddLine(entry.excludedCount.." events not included · frozen.",1,0.8,0,true) end
        local sources={}
        for name in pairs(entry.sources) do sources[#sources+1]=(SOURCES[name] or {label=name}).label end
        table.sort(sources)
        GameTooltip:AddLine(table.concat(sources," · "),1,1,1,true)
        for index=1,math.min(6,#entry.valuations) do
            local part=entry.valuations[index]
            GameTooltip:AddLine(part.quantity.." x "..(part.unitPrice and Format:Money(part.unitPrice) or "Not included")
                .." · "..(part.unitPrice and PerHour.Pricing:SourceLabel(part.priceSource,part.priceMetric) or entry.excluded and "Frozen" or "Pending")
                ..(part.acquired == false and " · Existing stock" or ""),1,1,1,true)
        end
        if #entry.valuations > 6 then GameTooltip:AddLine((#entry.valuations-6).." more recorded quotes",1,1,1) end
        GameTooltip:Show(); return
    end
    if not quest and entry.itemID then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Per Hour valuation:",unpack(Theme.gold.text))
        GameTooltip:AddLine(source.label.." · "..Format:Date(entry.timestamp),1,1,1,true)
        if entry.quantity then GameTooltip:AddDoubleLine("Quantity",tostring(entry.quantity)) end
        if entry.unitPrice then GameTooltip:AddDoubleLine("Unit value",Format:Money(entry.unitPrice)) end
        GameTooltip:AddDoubleLine("Price source",PerHour.Pricing:EntrySourceLabel(entry))
        GameTooltip:AddDoubleLine("Recorded value",entry.excluded and "Not included · frozen"
            or entry.pending and "Pending" or Format:Money(entry.amount))
        for _,part in ipairs(entry.valuations or {}) do
            GameTooltip:AddLine(tostring(part.quantity).." x "..(part.unitPrice and Format:Money(part.unitPrice) or "Pending")
                .." · "..PerHour.Pricing:SourceLabel(part.priceSource,part.priceMetric),1,1,1,true)
        end
    end
    GameTooltip:Show()
end

local function SetupSummary(body)
    body.Label,body.Left,body.Right=Text(body,"GameFontNormal",true),Text(body,nil,true),Text(body,nil,true)
    for index,label in ipairs({body.Label,body.Left,body.Right}) do
        label:SetPoint("TOPLEFT",body,"TOPLEFT",({8,170,432})[index],-4)
        label:SetSize(index == 1 and 150 or 248,44)
    end
    body:EnableMouse(true)
    body:SetScript("OnEnter",SummaryTooltip)
    body:SetScript("OnLeave",HideTooltip)
    body:SetScript("OnHide",HideTooltip)
end
local function UpdateSummary(body,data)
    body.Label:SetText(data.label or ""); body.Left:SetText(data.left or ""); body.Right:SetText(data.right or "")
end

local function SetupHistory(body,owner)
    body.Select=CreateFrame("CheckButton",nil,body,"UICheckButtonTemplate")
    body.Select:SetSize(HISTORY_CONTROL_SIZE,HISTORY_CONTROL_SIZE)
    body.Select:SetPoint("LEFT",body,"TOPLEFT",4,HISTORY_CENTER_Y)
    body.Open=CreateFrame("Button",nil,body)
    body.Open:SetSize(HISTORY.nameWidth+28,HISTORY_CONTROL_SIZE)
    body.Open:SetPoint("LEFT",body,"TOPLEFT",HISTORY.name,HISTORY_CENTER_Y)
    body.Open.Icon=body.Open:CreateTexture(nil,"ARTWORK")
    body.Open.Icon:SetSize(ITEM_ICON_SIZE,ITEM_ICON_SIZE)
    body.Open.Icon:SetPoint("LEFT",body.Open,"LEFT",(HISTORY_CONTROL_SIZE-ITEM_ICON_SIZE)/2,0)
    body.Open.Icon:SetTexture(Theme.icons.sessionDetails)
    local highlight=body.Open:CreateTexture(nil,"HIGHLIGHT")
    highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    highlight:SetAllPoints(body.Open.Icon)
    body.Open:SetHighlightTexture(highlight,"ADD")
    body.Name=Text(body.Open)
    body.Name:SetTextColor(unpack(Theme.text))
    body.Name:SetJustifyV("MIDDLE")
    body.Name:SetPoint("LEFT",body.Open,"LEFT",28,0); body.Name:SetSize(HISTORY.nameWidth,16)
    body.Duration=Text(body); body.Duration:SetJustifyH("RIGHT")
    body.Duration:SetPoint("RIGHT",body,"TOPLEFT",HISTORY.duration,HISTORY_CENTER_Y)
    body.Duration:SetSize(64,16); body.Duration:SetJustifyV("MIDDLE")
    body.Result=Text(body); body.Result:SetJustifyH("RIGHT")
    body.Result:SetPoint("RIGHT",body,"TOPLEFT",HISTORY.gold,HISTORY_CENTER_Y)
    body.Result:SetSize(74,16); body.Result:SetJustifyV("MIDDLE")
    body.Rename=Components:CreateRenameButton(body)
    body.Rename:SetPoint("LEFT",body,"TOPLEFT",HISTORY.rename,HISTORY_CENTER_Y)
    body.Delete=CreateFrame("Button",nil,body,"UIPanelCloseButton")
    body.Delete:SetSize(HISTORY_CONTROL_SIZE,HISTORY_CONTROL_SIZE)
    body.Delete:SetPoint("LEFT",body.Rename,"RIGHT",6,0)
    body.Delete:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT"); GameTooltip:SetText("Delete session")
        GameTooltip:AddLine(body.Data.record.name,1,1,1,true); GameTooltip:Show()
    end)
    body.Delete:SetScript("OnLeave",HideTooltip); body.Delete:SetScript("OnHide",HideTooltip)
    body.Select:SetScript("OnClick",function(self)
        local record=body.Data.record
        if self:GetChecked() then
            local count=0; for _ in pairs(owner.Selected) do count=count+1 end
            if count >= 2 then
                self:SetChecked(false); owner.History.Notice:SetText("Deselect a session before choosing another."); return
            end
            owner.Selected[record.id]=record
        else owner.Selected[record.id]=nil end
        owner:RefreshSelection()
    end)
    body.Open:SetScript("OnClick",function() owner:ShowDetails(body.Data.record,false) end)
    body.Rename:SetScript("OnClick",function() owner:ShowRename(body.Data.record,false) end)
    body.Delete:SetScript("OnClick",function() owner:ShowDelete(body.Data.record) end)
end
local function UpdateHistory(body,data,owner)
    local record=data.record
    Format:FitText(body.Name,record.name); body.Select:SetChecked(owner.Selected[record.id] ~= nil)
    body.Duration:SetText(Format:Duration(record.duration))
    local gold=record.metrics.Gold
    body.Result:SetText(gold.available == false and "Unavailable" or (gold.total < 0 and "- " or "")..Format:Money(gold.total,true))
    body.Result:SetTextColor(unpack(gold.total < 0 and Theme.red.text or Theme.text))
    if GameTooltip:IsOwned(body.Delete) then body.Delete:GetScript("OnEnter")(body.Delete) end
end

local function SetupEvent(body)
    body.Time=Text(body,"GameFontHighlightSmall"); body.Time:SetPoint("LEFT",body,"LEFT",8,0); body.Time:SetWidth(64)
    body.IconSlot=CreateFrame("Frame",nil,body)
    body.IconSlot:SetSize(20,20); body.IconSlot:SetPoint("LEFT",body,"LEFT",80,0)
    body.Icon=CreateFrame("ItemButton",nil,body.IconSlot)
    body.Icon:SetScale(ITEM_ICON_SCALE); body.Icon:SetPoint("CENTER")
    body.Quest=CreateFrame("Button",nil,body)
    body.Quest:SetSize(18,23); body.Quest:SetPoint("LEFT",body,"LEFT",104,0)
    body.Quest.Icon=body.Quest:CreateTexture(nil,"ARTWORK")
    body.Quest.Icon:SetSize(16,16); body.Quest.Icon:SetPoint("CENTER"); body.Quest.Icon:SetAtlas("QuestNormal")
    body.Name=Text(body); body.Name:SetPoint("LEFT",body,"LEFT",130,0)
    body.Count=Text(body); body.Count:SetJustifyH("RIGHT")
    body.Value=Text(body); body.Value:SetJustifyH("RIGHT"); body.Value:SetPoint("RIGHT",body,"RIGHT",-8,0)
    for _,region in ipairs({body.Icon,body.Quest}) do
        region:SetScript("OnEnter",function(self) EventTooltip(body,self,self == body.Quest) end)
        region:SetScript("OnLeave",HideTooltip); region:SetScript("OnHide",HideTooltip)
        region:SetMouseClickEnabled(false)
    end
end
local function UpdateEvent(body,data)
    local entry=data.event
    local source=SOURCES[entry.source] or {label=entry.source}
    body.Time:SetText(entry.timestamp and date("%H:%M:%S",entry.timestamp) or "—")
    body.Quest:SetShown(entry.questID ~= nil or (entry.questCount or 0) > 0)
    body.Name:SetTextColor(unpack(Theme.text)); body.Icon:SetItemButtonCount(0)
    local name
    if entry.itemID then
        local itemName,link,quality,_,_,_,_,_,_,icon=C_Item.GetItemInfo(entry.itemLink or entry.itemID)
        name=itemName or RETRIEVING_ITEM_INFO or "Loading item..."
        if quality then
            local r,g,b=C_Item.GetItemQualityColor(quality)
            body.Name:SetTextColor(r,g,b)
        end
        body.Icon:SetItemButtonTexture(icon or C_Item.GetItemIconByID(entry.itemID) or "Interface\\Icons\\INV_Misc_QuestionMark")
        body.Icon:SetItemButtonQuality(quality,link or entry.itemLink)
    else
        name=source.label
        body.Icon:SetItemButtonQuality()
        body.Icon:SetItemButtonTexture(source.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
    end
    body.Name:SetText(name)
    body.Count:SetText(Utils:DisplayRoundedNumber(entry.quantity or 1,0))
    body.Value:SetText(EventValue(entry))
    body.Value:SetTextColor(unpack(entry.direction < 0 and (not entry.pending or (entry.resolvedCount or 0) > 0) and Theme.red.text or Theme.text))
    local valueWidth=math.max(168,math.ceil(body.Value:GetStringWidth()))
    local countWidth=math.max(52,math.ceil(body.Count:GetStringWidth()))
    body.Count:ClearAllPoints(); body.Count:SetPoint("RIGHT",body,"RIGHT",-valueWidth-20,0); body.Count:SetWidth(countWidth)
    body.Name:ClearAllPoints(); body.Name:SetPoint("LEFT",body,"LEFT",130,0)
    body.Name:SetPoint("RIGHT",body,"RIGHT",-valueWidth-20-countWidth-12,0)
    if GameTooltip:IsOwned(body.Icon) then EventTooltip(body,body.Icon,false)
    elseif GameTooltip:IsOwned(body.Quest) then EventTooltip(body,body.Quest,true) end
end

local function SetupHeader(body)
    body.Label,body.Middle,body.Value,body.Actions=Text(body,"GameFontNormal"),Text(body,"GameFontNormal"),
        Text(body,"GameFontNormal"),Text(body,"GameFontNormal")
end
local function UpdateHeader(body,data)
    local history=data.columns == "history"
    for _,label in ipairs({body.Label,body.Middle,body.Value,body.Actions}) do label:ClearAllPoints(); label:SetWidth(0) end
    body.Label:SetText(history and "Session" or "Last"); body.Label:SetPoint("LEFT",body,"LEFT",history and HISTORY.name or 8,0)
    body.Middle:SetText(history and "Duration" or "Description")
    body.Middle:SetPoint(history and "RIGHT" or "LEFT",body,"LEFT",history and HISTORY.duration or 80,0)
    body.Value:SetText(history and "Gold est." or "Total")
    body.Value:SetPoint("RIGHT",body,history and "LEFT" or "RIGHT",history and HISTORY.gold or -8,0)
    body.Actions:SetText(history and "Actions" or "Count")
    body.Actions:SetPoint(history and "LEFT" or "RIGHT",body,history and "LEFT" or "RIGHT",history and HISTORY.rename or -188,0)
end
local TYPES={summary={SetupSummary,UpdateSummary},history={SetupHistory,UpdateHistory},event={SetupEvent,UpdateEvent},header={SetupHeader,UpdateHeader}}
function Rows:GetKind(data) return data.kind or (data.event and "event") or "summary" end
function Rows:GetExtent(data) return data.height or self.Extents[self:GetKind(data)] end
function Rows:RegisterType(kind,extent,setup,update)
    self.Extents[kind],TYPES[kind]=extent,{setup,update}
end
function Rows:Initialize(row,data,owner)
    if not rawget(row,"Bodies") then row.Bodies={} end
    local kind=self:GetKind(data)
    local body=row.Bodies[kind]
    if not body then
        body=CreateFrame("Frame",nil,row)
        body:SetPoint("TOPLEFT",row,"TOPLEFT",0,0)
        TYPES[kind][1](body,owner); row.Bodies[kind]=body
    end
    body:SetPoint("BOTTOMRIGHT",row,"BOTTOMRIGHT",0,data.divider == false and 0 or Theme.rowDivider.height)
    local previous=rawget(body,"Data")
    if kind == "event" and previous and previous.id ~= data.id
        and (GameTooltip:IsOwned(body.Icon) or GameTooltip:IsOwned(body.Quest)) then HideTooltip() end
    body.Data=data; TYPES[kind][2](body,data,owner)
    for name,other in pairs(row.Bodies) do other:SetShown(name == kind) end
    if not rawget(row,"Divider") then
        row.Divider=row:CreateTexture(nil,"BACKGROUND")
        row.Divider:SetPoint("BOTTOMLEFT"); row.Divider:SetPoint("BOTTOMRIGHT"); row.Divider:SetHeight(Theme.rowDivider.height)
        row.Divider:SetColorTexture(unpack(Theme.rowDivider.color)); row.Divider:SetAlpha(Theme.rowDivider.alpha)
    end
    row.Divider:SetShown(data.divider ~= false)
    row.Data,row.Body=data,body
end
