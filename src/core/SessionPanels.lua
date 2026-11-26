local Panels = { Selected={} }
PerHour.SessionPanels = Panels
local Components, Format, Store = PerHour.Components, PerHour.Format, PerHour.Stores.Sessions
local EXTENT = 64
local SOURCE = {loot_money="Looted money",loot_item="Item looted",item_reward="Item reward",
    quest_money="Quest reward",consumable="Consumable used",quest_turnin="Quest turn-in",repair="Repair",transport="Transport"}
local function Text(parent,font)
    local text = parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight")
    text:SetJustifyH("LEFT"); text:SetWordWrap(true)
    return text
end
local function EventTooltip(row,owner,quest)
    local data = row.Data
    GameTooltip:SetOwner(owner or row,"ANCHOR_RIGHT")
    if quest and data.event and data.event.questID then
        GameTooltip:SetHyperlink("quest:"..data.event.questID); GameTooltip:Show(); return
    elseif data.event and data.event.itemLink then GameTooltip:SetHyperlink(data.event.itemLink)
    else GameTooltip:SetText(data.label or "Session") end
    if data.event then
        local entry = data.event
        GameTooltip:AddLine(SOURCE[entry.source] or entry.source,1,1,1)
        GameTooltip:AddLine(Format:Date(entry.timestamp),1,1,1)
        if entry.quantity then GameTooltip:AddLine("Quantity: " .. entry.quantity,1,1,1) end
        GameTooltip:AddLine(entry.excluded and "Not included · frozen" or entry.pending and "Price pending"
            or PerHour.Pricing:EntrySourceLabel(entry),1,0.8,0,true)
        if entry.unitPrice then GameTooltip:AddLine("Unit value: " .. Format:Amount("Gold",entry.unitPrice),1,1,1) end
        GameTooltip:AddDoubleLine("Price source",entry.excluded and "Not included" or PerHour.Pricing:EntrySourceLabel(entry))
        GameTooltip:AddDoubleLine("Recorded value",entry.excluded and "—" or entry.pending and "Pending" or Format:Amount("Gold",math.abs(entry.amount)))
        if entry.valuations then
            for _, part in ipairs(entry.valuations) do
                GameTooltip:AddLine(tostring(part.quantity) .. " x " .. (part.unitPrice and Format:Amount("Gold",part.unitPrice) or "Pending")
                    .. " · " .. tostring(part.priceSource or "Pending"),1,1,1,true)
            end
        end
        if entry.questID then GameTooltip:AddLine("Quest ID: " .. entry.questID,1,1,1) end
    else
        if data.left then GameTooltip:AddLine(data.left,1,1,1,true) end
        if data.right then GameTooltip:AddLine(data.right,1,1,1,true) end
        if data.record then
            GameTooltip:AddLine(Format:Title(data.record),1,1,1,true)
            GameTooltip:AddLine(data.record.map .. " · " .. Format:Date(data.record.startedAt),1,1,1,true)
        end
    end
    GameTooltip:Show()
end
local function InitializeRow(row,data)
    if not rawget(row,"Initialized") then
        row.Initialized = true
        row.Label, row.Left, row.Right = Text(row), Text(row), Text(row)
        row.Label:SetTextColor(unpack(PerHour.Theme.gold.text))
        row.Label:SetPoint("TOPLEFT",row,"TOPLEFT",4,-4); row.Label:SetWidth(155)
        row.Left:SetPoint("TOPLEFT",row,"TOPLEFT",166,-4); row.Left:SetWidth(250)
        row.Right:SetPoint("TOPLEFT",row,"TOPLEFT",430,-4); row.Right:SetWidth(250)
        for _, text in ipairs({row.Label,row.Left,row.Right}) do text:SetHeight(54) end
        row.Divider = row:CreateTexture(nil,"BACKGROUND")
        row.Divider:SetColorTexture(0.72,0.45,0.4,0.2)
        row.Divider:SetHeight(2); row.Divider:SetPoint("BOTTOMLEFT"); row.Divider:SetPoint("BOTTOMRIGHT")
        row.Select = CreateFrame("CheckButton",nil,row,"UICheckButtonTemplate")
        row.Select:SetSize(24,24); row.Select:SetPoint("LEFT",row,"LEFT",0,8)
        row.Open = Components:CreateButton(row,"",26)
        row.Open:SetWidth(410); row.Open:SetPoint("TOPLEFT",row,"TOPLEFT",28,-3)
        row.Rename = Components:CreateButton(row,"Rename",24)
        row.Rename:SetWidth(86); row.Rename:SetPoint("TOPRIGHT",row,"TOPRIGHT",-92,-3)
        row.Delete = Components:CreateButton(row,"Delete",24)
        row.Delete:SetWidth(86); row.Delete:SetPoint("TOPRIGHT",row,"TOPRIGHT",0,-3)
        row.Context = Text(row,"GameFontHighlightSmall")
        row.Context:SetPoint("TOPLEFT",row,"TOPLEFT",28,-33); row.Context:SetWidth(650); row.Context:SetHeight(26)
        row.Icon=CreateFrame("ItemButton",nil,row)
        row.Icon:SetScale(0.5); row.Icon:SetPoint("TOPLEFT",row,"TOPLEFT",164,-4)
        row.Quest=CreateFrame("Button",nil,row)
        row.Quest:SetSize(18,20); row.Quest:SetPoint("TOPLEFT",row,"TOPLEFT",135,-4)
        row.Quest.Icon=row.Quest:CreateTexture(nil,"ARTWORK")
        row.Quest.Icon:SetAllPoints(row.Quest); row.Quest.Icon:SetAtlas("QuestNormal")
        row.Icon:SetScript("OnEnter",function(self) EventTooltip(row,self) end)
        row.Quest:SetScript("OnEnter",function(self) EventTooltip(row,self,true) end)
        for _,owner in ipairs({row.Icon,row.Quest}) do
            owner:SetScript("OnLeave",function() GameTooltip:Hide() end)
            owner:SetScript("OnHide",function() GameTooltip:Hide() end)
            owner:SetMouseClickEnabled(false)
        end
        row.Select:SetScript("OnClick",function(self)
            local item = row.Data.record
            if self:GetChecked() then
                local count=0; for _ in pairs(Panels.Selected) do count=count+1 end
                if count >= 2 then self:SetChecked(false); Panels.History.Notice:SetText("Deselect a session before choosing another."); return end
                Panels.Selected[item.id]=item
            else Panels.Selected[item.id]=nil end
            Panels:RefreshSelection()
        end)
        row.Open:SetScript("OnClick",function() Panels:ShowDetails(row.Data.record,false) end)
        row.Rename:SetScript("OnClick",function() Panels:ShowRename(row.Data.record,false) end)
        row.Delete:SetScript("OnClick",function() Panels:ShowDelete(row.Data.record) end)
        row:SetScript("OnEnter",EventTooltip)
        row.Open:SetScript("OnEnter",function() EventTooltip(row) end)
        row:SetScript("OnLeave",function() GameTooltip:Hide() end)
        row.Open:SetScript("OnLeave",function() GameTooltip:Hide() end)
        row:EnableMouse(true)
    end
    row.Data = data
    local entry=data.event
    row.Icon:SetShown(entry and entry.itemID ~= nil)
    row.Quest:SetShown(entry and entry.questID ~= nil)
    row.Left:ClearAllPoints()
    row.Left:SetPoint("TOPLEFT",row,"TOPLEFT",entry and entry.itemID and 190 or 166,-4)
    row.Left:SetWidth(entry and entry.itemID and 224 or 250)
    row.Right:SetTextColor(unpack(entry and entry.direction < 0 and PerHour.Theme.red.text or PerHour.Theme.text))
    if entry and entry.itemID then
        row.Icon:SetItemButtonTexture(C_Item.GetItemIconByID(entry.itemID) or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.Icon:SetItemButtonCount(0)
        local _,link,quality=C_Item.GetItemInfo(entry.itemLink or entry.itemID)
        row.Icon:SetItemButtonQuality(quality,link or entry.itemLink)
    end
    local history = data.kind == "history"
    for _, control in ipairs({row.Select,row.Open,row.Rename,row.Delete,row.Context}) do control:SetShown(history) end
    for _, control in ipairs({row.Label,row.Left,row.Right}) do control:SetShown(not history) end
    if history then
        row.Select:SetChecked(Panels.Selected[data.record.id] ~= nil)
        row.Open:SetText(data.record.name)
        row.Context:SetText(data.left)
    else
        row.Label:SetText(data.label or "")
        row.Left:SetText(data.left or "")
        row.Right:SetText(data.right or "")
    end
end
function Panels:CreateWindow(name,title)
    local panel = Components:CreatePanel(UIParent,{name=name,title=title,titleBox=true,width=760,height=600,
        draggable=true,contentSpacing=12})
    panel.Rows = {}
    panel:Hide(); panel:SetFrameStrata("DIALOG"); panel:SetPoint("CENTER",UIParent,"CENTER",0,0)
    if UISpecialFrames then table.insert(UISpecialFrames,name) end
    panel.Context = Text(panel.Content,"GameFontHighlightSmall")
    panel.Context:SetPoint("TOPLEFT"); panel.Context:SetWidth(690); panel.Context:SetHeight(72)
    panel.Notice = Text(panel.Content,"GameFontHighlightSmall")
    panel.Notice:SetPoint("BOTTOMLEFT"); panel.Notice:SetWidth(690); panel.Notice:SetHeight(30)
    panel.Notice:SetTextColor(1,0.8,0)
    panel.ScrollBox = CreateFrame("Frame",nil,panel.Content,"WowScrollBoxList")
    panel.ScrollBox:SetSize(690,396)
    panel.ScrollBox:SetPoint("TOPLEFT",panel.Content,"TOPLEFT",0,-76)
    panel.ScrollBox:SetPoint("BOTTOMRIGHT",panel.Content,"BOTTOMRIGHT",-22,34)
    panel.ScrollBar = CreateFrame("EventFrame",nil,panel.Content,"MinimalScrollBar")
    panel.ScrollBar:SetPoint("TOPLEFT",panel.ScrollBox,"TOPRIGHT",6,0)
    panel.ScrollBar:SetPoint("BOTTOMLEFT",panel.ScrollBox,"BOTTOMRIGHT",6,0)
    local view = CreateScrollBoxListLinearView()
    view:SetElementExtent(EXTENT); view:SetElementInitializer("Frame",InitializeRow)
    ScrollUtil.InitScrollBoxListWithScrollBar(panel.ScrollBox,panel.ScrollBar,view)
    panel:HookScript("OnHide",function() GameTooltip:Hide() end)
    panel:HookScript("OnShow",function() panel:SetScale(math.min(1,(UIParent:GetHeight()-60)/panel:GetHeight())) end)
    return panel
end
function Panels:SetRows(panel,rows)
    local offset = panel.ScrollBox:GetDerivedScrollOffset()
    local old = panel.Rows and panel.Rows[math.floor(offset/EXTENT)+1]
    if old and old.id then
        for index,item in ipairs(rows) do if item.id == old.id then offset=(index-1)*EXTENT+offset%EXTENT; break end end
    end
    panel.Rows = rows
    panel.ScrollBox:SetDataProvider(CreateDataProvider(rows),ScrollBoxConstants.RetainScrollPosition)
    panel.ScrollBox:ScrollToOffset(offset,ScrollBoxConstants.NoScrollInterpolation)
end
function Panels:Exists(record,current)
    if current then return PerHour.Session.Current and PerHour.Session.Current.id == record.id end
    for _, character in ipairs(Store:GetCharacters()) do
        for _, saved in ipairs(Store:GetHistory(character.value)) do if saved == record then return true end end
    end
    return false
end
function Panels:HistoryRecords()
    if self.Character ~= "all" then return Store:GetHistory(self.Character) end
    local result = {}
    for _, owner in ipairs(Store:GetCharacters()) do
        for _, record in ipairs(Store:GetHistory(owner.value)) do result[#result+1]=record end
    end
    table.sort(result,function(a,b) return (a.finishedAt or a.startedAt) > (b.finishedAt or b.startedAt) end)
    return result
end
function Panels:RefreshSelection()
    local count=0
    for _,record in pairs(self.Selected) do
        if self:Exists(record,false) then count=count+1 else self.Selected[record.id]=nil end
    end
    self.History.Actions.compare:SetEnabled(count == 2)
    self.History.Notice:SetText(count .. "/2 sessions selected. Select session names for Details."
        .. (Store.InvalidHistory and " Unreadable records were preserved but not included." or ""))
end
function Panels:RefreshHistory()
    local rows = {}
    for _, record in ipairs(self:HistoryRecords()) do
        rows[#rows+1] = {kind="history",id=record.id,record=record,
            left=Format:Character(record).." · "..Format:Date(record.startedAt) .. " · " .. record.map .. " · " .. Utils:DisplayTimer(record.duration)
                .. " · Gold " .. Format:Amount("Gold",record.metrics.Gold.total) .. " " .. Format:Flags(record.metrics.Gold)}
    end
    if #rows == 0 then rows[1]={label="No saved sessions",left="Use Start, then Sessions > Finish and Reset."} end
    self:SetRows(self.History,rows)
    self.History.Context:SetText("Select two sessions to compare. Each session keeps its own measurement period.")
    self:RefreshSelection()
end
function Panels:ShowHistory()
    if not Store.Character then return end
    self.Character = self.Character or Store.Character
    if not self.History then
        self.History = self:CreateWindow("PerHourHistory","History")
        Components:CreatePanelActions(self.History,{{key="compare",text="Compare",widthFraction=0.4,align="CENTER",
            onClick=function() self:ShowComparison() end}})
        self.History.Context:SetWidth(330)
        local options={{value="all",label="All characters"}}
        for _, owner in ipairs(Store:GetCharacters()) do options[#options+1]=owner end
        self.CharacterSelector=Components:CreateFormField(self.History.Content,{type="select",label="Character",controlWidth=240,
            value=self.Character,options=options,onChanged=function(value) self.Character=value; self:RefreshHistory() end})
        self.CharacterSelector:SetSize(340,32)
        self.CharacterSelector:SetPoint("TOPRIGHT",self.History.Content,"TOPRIGHT",0,0)
    end
    local options={{value="all",label="All characters"}}
    for _,owner in ipairs(Store:GetCharacters()) do options[#options+1]=owner end
    self.CharacterSelector:SetOptions(options,self.Character)
    self:RefreshHistory(); self.History:Show(); self.History:Raise()
end
local function MetricText(name,metric)
    if not metric then return "—\nUnavailable" end
    return (metric.available == false and metric.total == 0 and "—" or Format:Amount(name,metric.total))
        .. "\n" .. Format:RateText(name,metric) .. "\n" .. Format:Flags(metric)
end
local function Factions(record)
    local rows = {}
    for _, faction in pairs(record.reputation or {}) do rows[#rows+1]=faction end
    table.sort(rows,function(a,b) return a.name < b.name end)
    return rows
end
local function FactionMetric(record,faction)
    return {total=faction.total,duration=faction.duration,available=true,
        partial=faction.partial}
end
function Panels:RefreshDetails()
    local record = self.CurrentDetails and PerHour.Session:GetSnapshot(true) or self.Record
    if self.CurrentDetails and (not record or record.id ~= self.DetailID) then
        self.Details:Hide(); return
    end
    if not self.CurrentDetails and not self:Exists(record,false) then self.Details:Hide(); return end
    self.Details.Context:SetText(Format:Title(record) .. "\n" .. Format:Character(record).." · "..record.map .. " · Started " .. Format:Date(record.startedAt)
        .. " · Duration " .. Utils:DisplayTimer(record.duration))
    local rows = {}
    if #record.zones > 1 then rows[#rows+1]={id="zones",label="Visited areas",left=table.concat(record.zones," · ")} end
    for _,name in ipairs({"Experience","Honor"}) do
        rows[#rows+1]={id=name,label=name,left=MetricText(name,record.metrics[name]),right=record.metrics[name].issue}
    end
    local tracked=0
    for _,faction in ipairs(Factions(record)) do
        tracked=tracked+faction.duration
        local active=self.CurrentDetails and record.reputationFaction == faction.id
        rows[#rows+1]={id="rep:"..faction.id,label="Reputation\n"..faction.name,
            left=MetricText("Reputation",FactionMetric(record,faction)),right="Tracked "..Utils:DisplayTimer(faction.duration)
                .. "\n" .. (active and (record.paused and "Paused" or "Tracking") or "Previously tracked")}
    end
    rows[#rows+1]={label="Reputation context",left="Time without a tracked faction: "..Utils:DisplayTimer(math.max(0,record.duration-tracked)),
        right=next(record.reputation or {}) and "Rates use each faction's tracked time." or "No faction tracked in this session."}
    rows[#rows+1]={id="Gold",label="Gold estimated net",left=MetricText("Gold",record.metrics.Gold),right=record.metrics.Gold.issue}
    rows[#rows+1]={label="Gold composition",left="Coins "..Format:Amount("Gold",record.gold.coins)
        .. "\nItems "..Format:Amount("Gold",record.gold.items),right="Expenses "..Format:Amount("Gold",record.gold.expenses)}
    if record.segments then
        for index,segment in ipairs(record.segments) do
            rows[#rows+1]={id="segment:"..index,label="Tracking segment\n"..segment.name,
                left=Utils:DisplayTimer(segment.start).."–"..Utils:DisplayTimer(segment.start+segment.duration),
                right=Format:Amount("Reputation",segment.total).." rep"}
        end
    end
    for index=#(record.events or {}),1,-1 do
        local entry=record.events[index]
        local itemName=entry.itemID and C_Item.GetItemInfo(entry.itemID)
        local stamp=entry.timestamp and date("%H:%M:%S",entry.timestamp) or "—"
        rows[#rows+1]={id=entry.id or ("event:"..index),event=entry,
            label=stamp.."\n"..(SOURCE[entry.source] or entry.source),
            left=(itemName or entry.itemLink or "")..(entry.quantity and " x"..entry.quantity or ""),
            right=entry.excluded and "—\nNot included · frozen" or entry.pending and "—\nPending"
                or Format:Amount("Gold",entry.amount).."\n"..PerHour.Pricing:EntrySourceLabel(entry)}
    end
    local notice = record.detailsExpired and "Details not available; preserved summaries remain complete."
        or record.eventsLimited and "Only the latest 1,000 events are shown; totals include all accepted events."
        or "Item prices: TSM > Auctionator > Vendor; vendor minimum."
    if record.metrics.Gold.incomplete then notice="Incomplete · frozen at Finish. Unresolved values were not included.\n"..notice end
    if self.CurrentDetails then
        notice=(PerHour.Session.CheckingPlayed and "Verifying saved session. " or record.needsReview and "Review preserved totals before Resume. "
            or record.paused and "Session paused. " or "Session running. ")..notice
    else
        notice="Finished "..Format:Date(record.finishedAt)..". "..notice
    end
    self.Details.Notice:SetText(notice)
    self:SetRows(self.Details,rows)
end
function Panels:ShowCurrent()
    local record = PerHour.Session:GetSnapshot(true)
    if record then self:ShowDetails(record,true) end
end
function Panels:SessionFinished(record)
    if self.CurrentDetails and self.DetailID == record.id then
        self.CurrentDetails,self.Record = false,record
    end
end
function Panels:ShowDetails(record,current)
    if not self:Exists(record,current) then return end
    self.Record,self.CurrentDetails,self.DetailID=record,current,record.id
    if not self.Details then
        self.Details=self:CreateWindow("PerHourSessionDetails","Session Details")
        self.Details:RegisterEvent("GET_ITEM_INFO_RECEIVED")
        self.Details:RegisterEvent("ITEM_DATA_LOAD_RESULT")
        self.Details:SetScript("OnEvent",function() self:Invalidate() end)
        Components:CreatePanelActions(self.Details,{
            {key="rename",text="Rename",onClick=function() self:ShowRename(self.Record,self.CurrentDetails) end},
            {key="announce",type="icon",texture="Interface\\Buttons\\UI-GuildButton-PublicNote-Up",
                menu=function(_,root)
                    if not self.CurrentDetails then root:CreateTitle("Archived session"); return end
                    for _,name in ipairs(PerHour.MetricOrder) do
                        local module=PerHour.Modules[name]
                        local metric=root:CreateButton(name)
                        for _,channel in ipairs({"Say","Yell","Party","Guild","Raid"}) do
                            metric:CreateButton(channel,function() BaseModule:SendTo(module,channel) end)
                        end
                    end
                end},
        })
    end
    self:RefreshDetails(); self.Details:Show(); self.Details:Raise()
end
function Panels:ShowComparison()
    local chosen={}
    for _,record in pairs(self.Selected) do if self:Exists(record,false) then chosen[#chosen+1]=record end end
    if #chosen ~= 2 then return end
    table.sort(chosen,function(a,b) return a.id < b.id end)
    self.ComparisonRecords=chosen
    if not self.Comparison then self.Comparison=self:CreateWindow("PerHourComparison","Compare Sessions") end
    self:RefreshComparison(); self.Comparison:Show(); self.Comparison:Raise()
end
function Panels:RefreshComparison()
    local first,second=unpack(self.ComparisonRecords)
    if not self:Exists(first,false) or not self:Exists(second,false) then self.Comparison:Hide(); return end
    self.Comparison.Context:SetText("Results use the same totals, measured times and rates as Session Details.")
    local function Heading(record) return record.name.."\n"..Format:Character(record).."\n"..Format:Date(record.startedAt).." · "..Utils:DisplayTimer(record.duration) end
    local rows={{label="Session",left=Heading(first),right=Heading(second)}}
    for _,name in ipairs({"Experience","Gold","Honor"}) do
        rows[#rows+1]={label=name,left=MetricText(name,first.metrics[name]),right=MetricText(name,second.metrics[name])}
    end
    local factions={}
    for _,record in ipairs({first,second}) do
        for id,faction in pairs(record.reputation or {}) do factions[id]=faction.name end
    end
    local ids={}; for id in pairs(factions) do ids[#ids+1]=id end; table.sort(ids)
    for _,id in ipairs(ids) do
        local function Reading(record)
            local faction=record.reputation and record.reputation[id]
            return faction and MetricText("Reputation",FactionMetric(record,faction)).."\nTracked "..Utils:DisplayTimer(faction.duration) or "—\nNot tracked"
        end
        rows[#rows+1]={label="Reputation\n"..factions[id],left=Reading(first),right=Reading(second)}
    end
    self.Comparison.Notice:SetText("Missing data is not zero. Each faction uses its own tracked time.")
    self:SetRows(self.Comparison,rows)
end
function Panels:ShowRename(record,current)
    if not self:Exists(record,current) then return end
    self.RenameTarget,self.RenameCurrent=record,current
    if not self.RenameDialog then
        local dialog=Components:CreatePanel(UIParent,{name="PerHourRename",title="Rename Session",titleBox=true,width=480,height=180,draggable=true,
            actions={
                {key="save",text="Save Name",onClick=function() self:SaveName() end},
                {key="cancel",text="Cancel",onClick=function(panel) panel:Hide() end},
            }})
        dialog:SetFrameStrata("FULLSCREEN_DIALOG"); dialog:SetPoint("CENTER",UIParent,"CENTER",0,0)
        self.RenameDialog=dialog
        self.NameInput=CreateFrame("EditBox",nil,dialog.Content,"InputBoxTemplate")
        self.NameInput:SetSize(400,24); self.NameInput:SetPoint("CENTER"); self.NameInput:SetAutoFocus(false)
        self.NameInput:SetMaxLetters(80)
        self.NameInput:SetScript("OnEnterPressed",function() self:SaveName() end)
        self.NameInput:SetScript("OnEscapePressed",function() dialog:Hide() end)
        dialog:HookScript("OnHide",function() self.NameInput:ClearFocus() end)
        if UISpecialFrames then table.insert(UISpecialFrames,"PerHourRename") end
    end
    self.NameInput:SetText(current and PerHour.Session.Current.name or record.name)
    self.RenameDialog:Show(); self.RenameDialog:Raise(); self.NameInput:SetFocus(); self.NameInput:HighlightText()
end
function Panels:SaveName()
    if not self:Exists(self.RenameTarget,self.RenameCurrent) then self.RenameDialog:Hide(); return end
    local ok=self.RenameCurrent and PerHour.Session:Rename(self.NameInput:GetText())
        or not self.RenameCurrent and Store:Rename(self.RenameTarget,self.NameInput:GetText())
    if not ok then Utils:AddonMessage("Use a non-empty session name, up to 80 characters."); return end
    self.RenameDialog:Hide(); self:Invalidate()
end
function Panels:ShowDelete(record)
    if not self:Exists(record,false) then return end
    self.DeleteTarget=record
    if not self.DeleteDialog then
        self.DeleteDialog=Components:CreatePanel(UIParent,{name="PerHourDelete",title="Delete Session",titleBox=true,width=480,height=200,draggable=true,
            actions={
                {key="delete",text="Delete Session",onClick=function()
                    local target=self.DeleteTarget
                    for _,owner in ipairs(Store:GetCharacters()) do if Store:Delete(target,owner.value) then break end end
                    self.Selected[target.id]=nil; self.DeleteDialog:Hide(); self:Invalidate()
                end},
                {key="cancel",text="Cancel",onClick=function(panel) panel:Hide() end},
            }})
        self.DeleteDialog:SetFrameStrata("FULLSCREEN_DIALOG"); self.DeleteDialog:SetPoint("CENTER",UIParent,"CENTER",0,0)
        self.DeleteText=Text(self.DeleteDialog.Content)
        self.DeleteText:SetAllPoints(self.DeleteDialog.Content)
        if UISpecialFrames then table.insert(UISpecialFrames,"PerHourDelete") end
    end
    self.DeleteText:SetText("Delete this session from History?\n"..Format:Title(record))
    self.DeleteDialog:Show(); self.DeleteDialog:Raise()
end
function Panels:Invalidate()
    if self.RefreshScheduled then return end
    local visible=(self.History and self.History:IsShown()) or (self.Details and self.Details:IsShown())
        or (self.Comparison and self.Comparison:IsShown())
    if not visible then return end
    self.RefreshScheduled=true
    C_Timer.After(0,function()
        self.RefreshScheduled=false
        if self.History and self.History:IsShown() then self:RefreshHistory() end
        if self.Details and self.Details:IsShown() then self:RefreshDetails() end
        if self.Comparison and self.Comparison:IsShown() then self:RefreshComparison() end
    end)
end
