return function(t,fresh)
    fresh()
    local equal,near=t.equal,t.near
    local groups,view,rows=PerHour.GoldGroups,PerHour.DetailsView,PerHour.SessionRows
    local link=t.gold.link(901)
    local events={
        {source="loot_item",direction=1,itemID=901,itemLink=link,quantity=2,amount=200,unitPrice=100,priceSource="vendor",timestamp=100},
        {source="item_reward",direction=1,itemID=901,itemLink=link,quantity=3,amount=450,unitPrice=150,priceSource="tsm",priceMetric="DBMarket",timestamp=200,questID=10},
        {source="loot_item",direction=1,itemID=901,itemLink=link,quantity=4,amount=0,pending=true,timestamp=300},
        {source="loot_money",direction=1,amount=90,timestamp=150},
        {source="loot_money",direction=1,amount=40,timestamp=250},
        {source="quest_money",direction=1,amount=500,timestamp=190,questID=10},
        {source="quest_money",direction=1,amount=60,timestamp=290,questID=11},
        {source="loot_item",direction=1,itemID=902,itemLink=t.gold.link(902),quantity=1,amount=900,unitPrice=900,priceSource="vendor",timestamp=50},
        {source="consumable",direction=-1,itemID=901,itemLink=link,quantity=1,amount=-100,timestamp=210,
            valuations={{quantity=1,unitPrice=100,priceSource="vendor",acquired=true}}},
        {source="quest_turnin",direction=-1,itemID=901,itemLink=link,quantity=2,amount=-300,timestamp=310,questID=12,
            valuations={{quantity=2,unitPrice=150,priceSource="tsm",priceMetric="DBMarket",acquired=false}}},
        {source="repair",direction=-1,amount=-400,timestamp=280},
        {source="repair",direction=-1,amount=-500,timestamp=320},
    }
    local function item(data,id)
        for _,entry in ipairs(data) do if entry.itemID == id then return entry end end
        error("Missing grouped item "..id)
    end
    local function source(data,name)
        for _,entry in ipairs(data) do if entry.source == name then return entry end end
        error("Missing grouped source "..name)
    end
    local income=groups:Build(events,"Income")
    equal(#income,4,"Income merges repeated items and keeps Dropped/Reward coins separate")
    equal(income[1].itemID,902,"Income sorts by highest accumulated recorded value")
    local herbs=item(income,901)
    equal(herbs.amount,650,"different recorded quotes are summed rather than repriced")
    equal(herbs.quantity,9,"Count sums item units across loot, rewards and pending entries")
    equal(herbs.eventCount,3,"the group retains the underlying event count")
    equal(herbs.timestamp,300,"Last is the most recent occurrence, including unresolved entries")
    equal(herbs.pendingCount,1,"unresolved members remain explicitly pending")
    equal(herbs.priceSource,"mixed","mixed price provenance remains explicit")
    equal(herbs.unitPrice,nil,"different prices do not produce a fictitious single unit price")
    local pendingFirst=groups:Build({events[3],events[1]},"Income")[1]
    equal(pendingFirst.priceSource,"vendor","pending members do not invent mixed known price sources")
    equal(pendingFirst.unitPrice,nil,"unknown members do not inherit a known member's unit quote")
    equal(source(income,"loot_money").amount,130,"Dropped coins stack by source")
    equal(source(income,"loot_money").quantity,2,"Count for coins counts drops")
    equal(source(income,"quest_money").amount,560,"Reward coins stack separately")
    equal(source(income,"quest_money").questCount,2,"merged rewards retain distinct quest identities")
    equal(source(income,"quest_money").questID,nil,"multiple quests do not impersonate one native quest tooltip")
    local expenses=groups:Build(events,"Expenses")
    equal(#expenses,2,"Expenses merges repeated costs separately from income")
    equal(expenses[1].source,"repair","Expenses sorts by largest cost, not descending signed value")
    equal(expenses[1].amount,-900,"repair expenses retain their signed recorded sum")
    equal(item(expenses,901).quantity,3,"expense Count sums consumed and delivered units")
    equal(item(expenses,901).valuations[2].acquired,false,"expense quote groups preserve old-stock provenance")
    equal(events[1].quantity,2,"aggregation never mutates recorded quantities")
    equal(events[2].amount,450,"aggregation never mutates recorded prices or values")
    equal(events[9].valuations[1].quantity,1,"aggregation never mutates FIFO valuation parts")

    local stableID=herbs.id
    events[3].pending=nil; events[3].amount=400; events[3].unitPrice=100; events[3].priceSource="vendor"
    income=groups:Build(events,"Income")
    equal(income[1].id,stableID,"resolving a price reorders the group without changing its identity")
    equal(income[1].amount,1050,"only newly recorded values update the displayed subtotal")
    equal(income[1].pending,false,"resolved groups clear their pending flag")
    local excluded={source="loot_item",direction=1,itemID=901,itemLink=link,quantity=5,amount=999,excluded=true,timestamp=400}
    events[#events+1]=excluded
    herbs=item(groups:Build(events,"Income"),901)
    equal(herbs.amount,1050,"frozen excluded values never enter a displayed subtotal")
    equal(herbs.excludedCount,1,"mixed known/frozen groups retain the warning")
    equal(excluded.amount,999,"frozen input remains untouched")
    local variant=t.copy(events[1]); variant.itemLink=link:gsub("item:901:","item:901:9:")
    local variants=groups:Build({events[1],variant},"Income")
    equal(#variants,2,"different item-link variants retain distinct native tooltips")
    local tied=groups:Build({{source="loot_money",direction=1,amount=100,timestamp=1},
        {source="quest_money",direction=1,amount=100,timestamp=2}},"Income")
    equal(tied[1].source,"quest_money","ties prefer the most recent occurrence")

    PerHour.Session:Start()
    local record=PerHour.Session:GetSnapshot(true)
    record.events=events; record.metrics.Gold.total=12345
    local data=view:BuildMetricRows(record,false,"Income")
    equal(record.metrics.Gold.total,12345,"building grouped rows never recalculates the session summary")
    local frame=CreateFrame("Frame",nil,UIParent); frame:SetSize(690,26)
    t.gold.items[901]={price=100}
    rows:Initialize(frame,{event=herbs,id=herbs.id},PerHour.SessionPanels)
    equal(frame.Body.Name:GetText(),"Item 901","grouped item names have no stack suffix")
    equal(frame.Body.Count:GetText(),"14","the Count column includes all observed units")
    equal(frame.Body.Time:GetText(),date("%H:%M:%S",400),"Last displays the latest occurrence")
    equal(frame.Body.Value:GetText(),"0g 10s 50c *","known value remains visible alongside the frozen-member marker")
    frame.Body.Icon:GetScript("OnEnter")(frame.Body.Icon)
    equal(GameTooltip.hyperlink,link,"grouped items retain their native item tooltip")
    equal(GameTooltip.lines["Price source"],"Mixed recorded prices","group tooltips expose mixed recorded quotes")
    frame.Body.Icon:GetScript("OnLeave")(frame.Body.Icon)
    local unknown=groups:Build({{source="loot_item",direction=1,itemID=901,itemLink=link,quantity=1,amount=0,pending=true}},"Income")[1]
    rows:Initialize(frame,{event=unknown,id=unknown.id},PerHour.SessionPanels)
    equal(frame.Body.Value:GetText(),"Pending","an entirely unresolved group is not shown as zero")
    unknown=groups:Build({excluded},"Income")[1]
    rows:Initialize(frame,{event=unknown,id=unknown.id},PerHour.SessionPanels)
    equal(frame.Body.Value:GetText(),"Not included · frozen","entirely excluded groups retain the frozen label")
    rows:Initialize(frame,data[2],PerHour.SessionPanels)
    equal(frame.Body.Label:GetText(),"Last","the time column is renamed Last")
    equal(frame.Body.Actions:GetText(),"Count","the header names the quantity column")

    local panels=PerHour.SessionPanels
    panels:ShowCurrent()
    local details=panels.Details
    equal(details.Tabs.Buttons.Gold,nil,"the original Gold tab is split into Income and Expenses")
    equal(details.Tabs.SelectedKey,"Income","Details starts on Income")
    details.Tabs.Buttons.Expenses:Click()
    equal(details.Rows[1].fields[1].value,"No expenses recorded","Expenses has a separate empty state")
    panels:RefreshDetails()
    equal(details.Tabs.SelectedKey,"Expenses","live refresh retains the Gold split selection")
    details.Tabs.Buttons.Reputation:Click()
    equal(details.Tabs.SelectedKey,"Reputation","Reputation remains a separate peer tab")
    details.Tabs.Buttons.Expenses:Click()
    equal(details.Tabs.SelectedKey,"Expenses","Expenses remains directly selectable beside Reputation")
    near(details.ScrollBox:GetDerivedScrollOffset(),0,"changing Gold splits resets the viewport")
    t.finish(); PerHour.Session:Start(); panels:ShowCurrent()
    equal(details.Tabs.SelectedKey,"Income","a different session resets the split to Income")
end
