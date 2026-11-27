local Panels = { Selected={} }
PerHour.SessionPanels = Panels
local Components, Format, Store = PerHour.Components, PerHour.Format, PerHour.Stores.Sessions
local function Text(parent,font)
    local text = parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight")
    text:SetJustifyH("LEFT"); text:SetWordWrap(true)
    return text
end
local function DialogText(parent)
    local text=Text(parent)
    local font,_,flags=text:GetFont()
    text:SetFont(font,14,flags)
    text:SetJustifyH("CENTER"); text:SetJustifyV("MIDDLE")
    return text
end
local function CreateDialog(name,title,message,actions,withName)
    local dialog=Components:CreatePanel(UIParent,{name=name,title=title,titleBox=true,width=480,height=240,
        draggable=true,actions=actions})
    dialog:SetFrameStrata("FULLSCREEN_DIALOG"); dialog:SetPoint("CENTER",UIParent,"CENTER",0,0)
    dialog.Message=DialogText(dialog.Content)
    dialog.Message:SetText(message)
    if withName then
        local body=CreateFrame("Frame",nil,dialog.Content)
        body:SetSize(414,124); body:SetPoint("CENTER")
        dialog.Message:SetPoint("TOPLEFT",body,"TOPLEFT",0,0)
        dialog.Message:SetPoint("TOPRIGHT",body,"TOPRIGHT",0,0); dialog.Message:SetHeight(44)
        local input=CreateFrame("EditBox",nil,body,"InputBoxTemplate")
        dialog.NameInput=input
        input:SetSize(400,32); input:SetPoint("TOP",body,"TOP",0,-56)
        input:SetAutoFocus(false); input:SetMaxLetters(80)
        input:SetFontObject("GameFontHighlight")
        local font,_,flags=input:GetFont()
        input:SetFont(font,14,flags); input:SetJustifyH("CENTER")
        input:SetScript("OnEscapePressed",function() dialog:Hide() end)
        dialog.Error=Text(body,"GameFontHighlightSmall")
        dialog.Error:SetJustifyH("CENTER"); dialog.Error:SetTextColor(unpack(PerHour.Theme.red.text))
        dialog.Error:SetPoint("TOPLEFT",body,"TOPLEFT",0,-96)
        dialog.Error:SetPoint("TOPRIGHT",body,"TOPRIGHT",0,-96); dialog.Error:SetHeight(28)
        dialog.Error:SetText("Enter a session title (1–80 characters).")
        dialog.Error:Hide()
        input:SetScript("OnTextChanged",function() dialog.Error:Hide() end)
        dialog:HookScript("OnHide",function() input:ClearFocus() end)
    else
        dialog.Message:SetAllPoints(dialog.Content)
    end
    if UISpecialFrames then table.insert(UISpecialFrames,name) end
    return dialog
end
local function ShowNameDialog(dialog,name)
    dialog.NameInput:SetText(name); dialog.Error:Hide()
    dialog:Show(); dialog:Raise(); dialog.NameInput:SetFocus(); dialog.NameInput:HighlightText()
end
local function DialogName(dialog)
    local name=Store.ValidName(dialog.NameInput:GetText())
    if not name then dialog.Error:Show(); dialog.NameInput:SetFocus() end
    return name
end
function Panels:CreateWindow(name,title,options)
    local panel = Components:CreatePanel(UIParent,{name=name,title=title,titleBox=true,
        width=options and options.width or 760,height=options and options.height or 600,
        draggable=true,contentSpacing=12})
    panel.Rows = {}
    panel:Hide(); panel:SetFrameStrata("DIALOG"); panel:SetPoint("CENTER",UIParent,"CENTER",0,0)
    if UISpecialFrames then table.insert(UISpecialFrames,name) end
    panel.Context = Text(panel.Content,"GameFontHighlightSmall")
    panel.Context:SetPoint("TOPLEFT"); panel.Context:SetWidth(690); panel.Context:SetHeight(52)
    panel.Notice = Text(panel.Content,"GameFontHighlightSmall")
    panel.Notice:SetPoint("BOTTOMLEFT"); panel.Notice:SetWidth(690); panel.Notice:SetHeight(30)
    panel.Notice:SetTextColor(1,0.8,0)
    local topInset=options and options.context == false and 0 or 60
    panel.Context:SetShown(topInset > 0)
    Components:CreateSessionList(panel,self,topInset)
    panel:HookScript("OnHide",function() GameTooltip:Hide() end)
    return panel
end
function Panels:SetRows(panel,rows,key)
    Components:SetSessionListRows(panel,rows,key)
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
    self.History.Notice:SetText(count .. "/2 sessions selected. Click a session icon or title for Details."
        .. (Store.InvalidHistory and " Unreadable records were preserved but not included." or ""))
end
function Panels:RefreshHistory()
    local rows = {{kind="header",columns="history",id="history:header"}}
    for _,record in ipairs(self:HistoryRecords()) do
        rows[#rows+1]={kind="history",id=record.id,record=record}
    end
    if #rows == 1 then rows[#rows+1]={label="No saved sessions",left="Use Start, then Sessions > Finish Session."} end
    self:SetRows(self.History,rows,self.Character)
    self.History.Context:SetText("Select two sessions to compare. Each session keeps its own measurement period.")
    self:RefreshSelection()
end
function Panels:ShowHistory()
    if not Store.Character then return end
    self.Character = self.Character or Store.Character
    if not self.History then
        self.History = self:CreateWindow("PerHourHistory","History")
        Components:CreatePanelActions(self.History,{{key="compare",text="Compare",
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
function Panels:RefreshDetails()
    local record = self.CurrentDetails and PerHour.Session:GetSnapshot(true) or self.Record
    if self.CurrentDetails and (not record or record.id ~= self.DetailID) then
        self.Details:Hide(); return
    end
    if not self.CurrentDetails and not self:Exists(record,false) then self.Details:Hide(); return end
    local notice = record.detailsExpired and "Details not available; preserved summaries remain complete."
        or record.eventsLimited and "Grouped from the latest 1,000 events; totals include all accepted events."
        or "Item prices: TSM > Auctionator > Vendor; vendor minimum."
    if record.metrics.Gold.incomplete then notice="Incomplete · frozen at Finish. Unresolved values were not included.\n"..notice end
    if self.CurrentDetails then
        notice=(PerHour.Session.CheckingPlayed and "Verifying saved session. " or record.needsReview and "Review preserved totals before Resume. "
            or record.paused and "Session paused. " or "Session running. ")..notice
    else
        notice="Finished "..Format:Date(record.finishedAt)..". "..notice
    end
    self.Details.Notice:SetText(notice)
    self.Details.Actions.finish:SetShown(self.CurrentDetails == true)
    self.Details:LayoutActions()
    Components:UpdateDetailsPanel(self.Details,record,self.CurrentDetails,self)
end
function Panels:ShowCurrent()
    local record = PerHour.Session:GetSnapshot(true)
    if record then self:ShowDetails(record,true) end
end
function Panels:SessionFinished(record)
    if self.FinishTarget == record.id and self.FinishDialog then self.FinishDialog:Hide() end
    if self.CurrentDetails and self.DetailID == record.id then
        self.CurrentDetails,self.Record = false,record
    end
end
function Panels:ShowDetails(record,current)
    if not self:Exists(record,current) then return end
    self.Record,self.CurrentDetails,self.DetailID=record,current,record.id
    if not self.Details then
        self.Details=self:CreateWindow("PerHourSessionDetails","Session Details",{context=false})
        Components:SetupDetailsPanel(self.Details,self)
        self.Details:RegisterEvent("GET_ITEM_INFO_RECEIVED")
        self.Details:RegisterEvent("ITEM_DATA_LOAD_RESULT")
        self.Details:RegisterEvent("QUEST_DATA_LOAD_RESULT")
        self.Details:SetScript("OnEvent",function() self:Invalidate() end)
        Components:CreatePanelActions(self.Details,{
            {key="finish",text="Finish Session",onClick=function()
                local current=PerHour.Session.Current
                if self.CurrentDetails and current and current.id == self.DetailID then PerHour.Session:Finish() end
            end},
            {key="announce",tooltip=function() return "Announce" end,
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
    if not self.Comparison then
        self.Comparison=self:CreateWindow("PerHourComparison","Compare Sessions",{context=false,width=700,height=320})
    end
    self:RefreshComparison(); self.Comparison:Show(); self.Comparison:Raise()
end
function Panels:RefreshComparison()
    local first,second=unpack(self.ComparisonRecords)
    if not self:Exists(first,false) or not self:Exists(second,false) then self.Comparison:Hide(); return end
    local rows=PerHour.ComparisonView:BuildRows(first,second)
    PerHour.ComparisonView:LayoutPanel(self.Comparison,rows)
    self.Comparison.Notice:SetText("Rates per hour. Reputation uses time tracked for each faction.")
    self:SetRows(self.Comparison,rows,first.id..":"..second.id)
end
function Panels:ShowRename(record,current)
    if not self:Exists(record,current) then return end
    self.RenameTarget,self.RenameCurrent=record,current
    if not self.RenameDialog then
        local dialog=CreateDialog("PerHourRename","Rename Session","Choose a title for this session.",{
                {key="save",text="Save Name",onClick=function() self:SaveName() end},
                {key="cancel",text="Cancel",onClick=function(panel) panel:Hide() end},
            },true)
        self.RenameDialog=dialog
        self.NameInput=dialog.NameInput
        self.NameInput:SetScript("OnEnterPressed",function() self:SaveName() end)
    end
    ShowNameDialog(self.RenameDialog,current and PerHour.Session.Current.name or record.name)
end
function Panels:SaveName()
    if not self:Exists(self.RenameTarget,self.RenameCurrent) then self.RenameDialog:Hide(); return end
    local name=DialogName(self.RenameDialog)
    if not name then return end
    local ok=self.RenameCurrent and PerHour.Session:Rename(name)
        or not self.RenameCurrent and Store:Rename(self.RenameTarget,name)
    if not ok then return end
    self.RenameDialog:Hide(); self:Invalidate()
end
function Panels:ShowDelete(record)
    if not self:Exists(record,false) then return end
    self.DeleteTarget=record
    if not self.DeleteDialog then
        self.DeleteDialog=CreateDialog("PerHourDelete","Delete Session","",{
                {key="delete",text="Delete Session",onClick=function()
                    local target=self.DeleteTarget
                    for _,owner in ipairs(Store:GetCharacters()) do if Store:Delete(target,owner.value) then break end end
                    self.Selected[target.id]=nil; self.DeleteDialog:Hide(); self:Invalidate()
                end},
                {key="cancel",text="Cancel",onClick=function(panel) panel:Hide() end},
            })
        self.DeleteText=self.DeleteDialog.Message
    end
    self.DeleteText:SetText("Permanently delete this session from History?\n\n"..Format:Title(record))
    self.DeleteDialog:Show(); self.DeleteDialog:Raise()
end
function Panels:ShowFinish(record)
    if not self:Exists(record,true) then return end
    if not self.FinishDialog then
        self.FinishDialog=CreateDialog("PerHourFinish","Finish Session","Choose a title and save this session to History.",{
                {key="finish",text="Finish Session",onClick=function() self:FinishWithName() end},
                {key="cancel",text="Cancel",onClick=function(panel) panel:Hide() end},
            },true)
        self.FinishText=self.FinishDialog.Message
        self.FinishNameInput=self.FinishDialog.NameInput
        self.FinishNameInput:SetScript("OnEnterPressed",function() self:FinishWithName() end)
        self.FinishDialog:HookScript("OnHide",function() self.FinishTarget=nil end)
    end
    self.FinishTarget=record.id
    ShowNameDialog(self.FinishDialog,PerHour.Session.Current.name)
end
function Panels:FinishWithName()
    local target,current=self.FinishTarget,PerHour.Session.Current
    if not current or current.id ~= target then self.FinishDialog:Hide(); return end
    local name=DialogName(self.FinishDialog)
    if not name then return end
    if PerHour.Session:Rename(name) then PerHour.Session:Finish(target) end
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
