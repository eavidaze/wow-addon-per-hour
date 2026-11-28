return function(t,fresh)
    fresh()
    local equal,near=t.equal,t.near
    local panels,rows=PerHour.SessionPanels,PerHour.SessionRows
    local function visibleRow(panel,predicate)
        local found
        panel.ScrollBox:ForEachFrame(function(row) if predicate(row.Data) then found=row end end)
        return assert(found,"expected visible list row")
    end
    t.gold.items[901]={price=123,quality=3}
    PerHour.Session:Start()
    t.event("CHAT_MSG_LOOT",string.format(LOOT_ITEM_SELF_MULTIPLE,t.gold.link(901),2))
    t.event("CHAT_MSG_MONEY","You loot 1 Copper")
    panels:ShowCurrent()
    local details=panels.Details
    details.ScrollBox:ScrollToOffset(details.ScrollBox:GetDerivedScrollRange())
    local item=visibleRow(details,function(data) return data.event and data.event.itemID == 901 end)
    local itemIconSize=item.Body.Icon:GetWidth()*item.Body.Icon:GetScale()
    equal(item:GetHeight(),26,"item events use the former compact row height")
    equal(item.Body.Name:GetText(),"Item 901","item names omit the quantity suffix")
    equal(item.Body.Count:GetText(),"2","item quantity has its own Count column")
    equal(item.Body.Icon.iconTexture,100901,"rarity coloring allows the item icon to finish rendering")
    equal(table.concat(item.Body.Name.textColor,","),"0,0.44,0.87","item name retains its rarity color")
    equal(item.Body.Value:GetText(),"0g 2s 46c","event value preserves exact copper")
    equal(item.Body.Quest:IsShown(),false,"ordinary loot has no quest marker")
    equal(rawget(item.Body,"Select"),nil,"event rows do not allocate History controls")
    item.Body.Icon.scripts.OnEnter(item.Body.Icon)
    equal(GameTooltip.hyperlink,t.gold.link(901),"native item tooltip is bound to the icon")
    equal(GameTooltip.lines["Price source"],"Vendor","quote source stays available in the tooltip")
    local money=visibleRow(details,function(data) return data.event and data.event.source == "loot_money" end)
    equal(money.Body.Name:GetText(),"Dropped","dropped coins have a concise grouped source label")
    equal(money.Body.Icon.iconTexture,"Interface\\Icons\\INV_Misc_Bag_10","money retains the native loot bag")
    equal(money.Body.Value:GetText(),"0g 0s 1c","single copper remains visible")

    t.finish()
    for _=1,24 do PerHour.Session:Start(); t.tick(1); t.finish() end
    panels:ShowHistory()
    local history=panels.History
    local saved=PerHour.Stores.Sessions:GetHistory()
    local sessionRow=visibleRow(history,function(data) return data.record == saved[1] end)
    equal(sessionRow:GetHeight(),28,"sessions use a compact single-line row")
    equal(rawget(sessionRow.Body,"Context"),nil,"sessions omit subtitle controls")
    equal(sessionRow.Body.Delete.template,panels.History.CloseButton.template,"Delete uses the same native X as panel Close")
    equal(sessionRow.Body.Delete:GetWidth(),24,"the Delete icon fits the single-line row")
    equal(sessionRow.Body.Name:GetText(),saved[1].name,"session title retains its plain text appearance")
    equal(sessionRow.Body.Name:GetParent(),sessionRow.Body.Open,"icon and title share a single Details button")
    equal(select(4,sessionRow.Body.Open:GetPoint()),36,"Details opens from the first Session column")
    equal(sessionRow.Body.Open.Icon.texture,"Interface\\Icons\\INV_Misc_Note_06","Details uses the requested view icon")
    near(sessionRow.Body.Open.Icon:GetWidth(),itemIconSize,"session icons match the item icons' displayed size")
    equal(rawget(sessionRow.Body,"Icon"),nil,"session rows do not allocate event item icons")
    local sample=PerHour.Copy(saved[1])
    local compact=CreateFrame("Frame",nil,UIParent); compact:SetSize(690,28)
    for _,case in ipairs({{0,"0c"},{99,"99c"},{100,"1s"},{9999,"99s"},{10000,"1g"},{585959,"58g"},{-585959,"- 58g"}}) do
        sample.metrics.Gold.total=case[1]
        rows:Initialize(compact,{kind="history",record=sample},panels)
        equal(compact.Body.Result:GetText(),case[2],"History shows only the largest coin unit for "..case[1])
        equal(sample.metrics.Gold.total,case[1],"compact money never changes the recorded total")
    end
    -- Supply the height that the client's two anchors resolve above the 3 px divider.
    compact.Body:SetSize(690,25)
    local center=compact.Body:GetTop()-12
    for _,control in ipairs({compact.Body.Select,compact.Body.Open.Icon,compact.Body.Rename,compact.Body.Delete}) do
        near(control:GetTop()-control:GetHeight()/2,center,"History icons and actions share the same vertical center")
        if control ~= compact.Body.Open.Icon then
            equal(control:GetTop(),math.floor(control:GetTop()),"History controls avoid half-pixel placement")
        end
    end
    equal(compact.Body:GetScript("OnEnter"),nil,"History rows do not show a session tooltip")
    compact.Body.Delete.scripts.OnEnter(compact.Body.Delete)
    equal(GameTooltip:GetText(),"Delete session","the X explains its action on hover")
    compact.Body.Delete.scripts.OnLeave(compact.Body.Delete)
    sessionRow.Body.Open:Click()
    equal(panels.DetailID,saved[1].id,"view icon opens its own session")
    panels.Details:Hide()
    sessionRow.Body.Name:GetParent():Click()
    equal(panels.Details:IsShown(),true,"clicking the title opens the same Details window")
    equal(panels.DetailID,saved[1].id,"the title opens the same session as the icon")
    equal(sessionRow.Body.Name:GetParent():GetScript("OnEnter"),nil,"title and icon keep their shared click area without a tooltip")
    rows:Initialize(compact,{kind="history",record=saved[2]},panels)
    compact.Body.Name:GetParent():Click()
    equal(panels.DetailID,saved[2].id,"a recycled title button targets its newly bound session")
    sessionRow.Body.Select:Click()
    equal(panels.Selected[saved[1].id],saved[1],"checkbox selects its own session")
    local other=visibleRow(history,function(data) return data.record == saved[2] end)
    other.Body.Select:Click()
    equal(history.Actions.compare.enabled,true,"two selected rows enable Compare")
    local third=visibleRow(history,function(data) return data.record == saved[3] end)
    third.Body.Select:Click()
    equal(panels.Selected[saved[3].id],nil,"compact rows preserve the two-session selection limit")
    sessionRow.Body.Rename:Click()
    equal(panels.RenameTarget,saved[1],"Rename acts on the row's record")
    sessionRow.Body.Delete:Click()
    equal(panels.DeleteTarget,saved[1],"Delete keeps explicit confirmation for the row's record")

    history.ScrollBox:ScrollToOffset(3*28+7)
    local anchor=visibleRow(history,function(data) return data.record == saved[4] end).Data.id
    PerHour.Session:Start(); t.tick(1); t.finish(); panels:RefreshHistory()
    near(history.ScrollBox:GetDerivedScrollOffset(),4*28+7,"new sessions preserve the reader's partially visible row")
    equal(history.ScrollBox.pool[1].Data.id,anchor,"stable session identity anchors the viewport")
    equal(history.ScrollBox.pool[1].Body.Select:GetChecked(),false,"recycled controls do not inherit the previous selection")

    panels:ShowDetails(saved[1],false)
    details.ScrollBox:ScrollToOffset(50)
    panels:ShowDetails(saved[2],false)
    near(details.ScrollBox:GetDerivedScrollOffset(),0,"changing sessions resets the Details viewport")

    local mixed={}
    for index=1,40 do
        mixed[#mixed+1]={id="row:"..index,label="Metric",left="Value"}
        mixed[#mixed+1]={id="event:"..index,event={source="loot_money",direction=1,amount=index,timestamp=GetServerTime()}}
    end
    panels:SetRows(details,mixed,"mixed")
    details.ScrollBox:ScrollToOffset(52+26+9)
    local anchored=details.ScrollBox.pool[1].Data.id
    local refreshed={{kind="header",columns="event",id="new-header"}}
    for _,item in ipairs(mixed) do refreshed[#refreshed+1]=item end
    panels:SetRows(details,refreshed,"mixed")
    near(details.ScrollBox:GetDerivedScrollOffset(),52+26+9,"a pinned header preserves the content pixel offset")
    equal(details.ScrollBox.pool[1].Data.id,anchored,"mixed-height updates retain the same visible record")
    local count=0; details.ScrollBox:ForEachFrame(function() count=count+1 end)
    equal(count < #mixed,true,"only the visible viewport has UI rows")
    equal(rows:GetExtent({event={}}),26,"native extent calculator classifies events")

    local recycled=CreateFrame("Frame",nil,UIParent)
    recycled:SetSize(690,26)
    rows:Initialize(recycled,{id="single",event={source="loot_item",itemID=901,itemLink=t.gold.link(901),
        quantity=1,direction=1,amount=123,questID=77}},panels)
    local oldBody=recycled.Body
    equal(oldBody.Name:GetText(),"Item 901","single items omit x1")
    oldBody.Icon.scripts.OnEnter(oldBody.Icon)
    recycled:SetSize(690,52)
    rows:Initialize(recycled,{id="summary",label="Gold",left="Total"},panels)
    equal(oldBody:IsShown(),false,"recycling a row hides all old event controls")
    equal(GameTooltip:IsShown(),false,"recycled event controls cannot leave an old tooltip open")
    recycled:SetSize(690,26)
    rows:Initialize(recycled,{id="coins",event={source="loot_money",direction=1,amount=1}},panels)
    equal(recycled.Body.Quest:IsShown(),false,"reused event rows reset quest visibility")
    equal(table.concat(recycled.Body.Name.textColor,","),"1,1,1","coin labels do not inherit item rarity colors")
end
