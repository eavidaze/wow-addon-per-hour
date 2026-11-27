return function(t,fresh)
    fresh()
    local equal,near=t.equal,t.near
    local panels,view,renderers=PerHour.SessionPanels,PerHour.DetailsView,PerHour.SessionRows
    PerHour.Session:Start(); t.tick(1); t.finish()
    local record=PerHour.Stores.Sessions:GetHistory()[1]
    record.events={}; local income=0
    for index=1,30 do
        local amount=index*100; income=income+amount
        record.events[#record.events+1]={source="loot_item",direction=1,itemID=500+index,itemLink=t.gold.link(500+index),
            quantity=1,amount=amount,unitPrice=amount,priceSource="vendor",timestamp=GetServerTime()+index}
    end
    record.events[#record.events+1]={source="repair",direction=-1,amount=-450,timestamp=GetServerTime()+31}
    record.gold={coins=0,items=income,expenses=450}; record.metrics.Gold.total=income-450
    panels:ShowDetails(record,false)
    local details=panels.Details
    equal(details.SessionRows[#details.SessionRows].id,"session:Visited areas","Visited areas is the final card row")
    equal(details.TableHeaderRows[1].kind,"goldSum","the sum is fixed above the Gold column header")
    equal(details.TableHeaderRows[1].value,"Sum: 4g 65s 0c","Income sums all displayed recorded values")
    equal(details.TableHeaderRows[2].columns,"event","Gold column names are fixed below the sum")
    equal(details.TableHeader:GetParent(),details.TabBox,"pinned headers remain inside the table border")
    equal(details.TableHeaderHeight,48,"Gold reserves one sum row and one column-header row")
    equal(details.ScrollBox.points.TOPLEFT[5],-56,"scrolling content begins below both fixed rows")
    equal(details.ScrollBox:GetHeight() >= 240,true,"headers retain a useful content viewport")
    for _,data in ipairs(details.Rows) do
        equal(data.kind ~= "header" and not data.header and not data.pinned,true,"only table content enters the ScrollBox")
    end
    local anchor=details.TableHeader.point
    details.ScrollBox:ScrollToOffset(60)
    equal(details.TableHeader.point,anchor,"scrolling leaves the pinned header anchor unchanged")
    local first
    details.ScrollBox:ForEachFrame(function(row) if not first then first=row end end)
    equal(rawget(first.Body,"Direction"),nil,"Income/Expenses omit redundant direction arrows")
    details.Tabs.Buttons.Expenses:Click()
    equal(details.TableHeaderRows[1].value,"Sum: 0g 4s 50c","Expenses sums costs independently of net Gold")
    near(details.ScrollBox:GetDerivedScrollOffset(),0,"changing grids resets only their content viewport")
    details.Tabs.Buttons.Income:Click()
    record.events[#record.events+1]={source="loot_item",direction=1,itemID=600,itemLink=t.gold.link(600),
        quantity=2,amount=0,pending=true,timestamp=GetServerTime()+40}
    record.eventsLimited=true; panels:RefreshDetails()
    equal(details.TableHeaderRows[1].value,"Sum: 4g 65s 0c *","the sum flags unresolved and retained-only subtotals")
    equal(record.metrics.Gold.total,income-450,"table sums never replace the preserved session metric")
    details.TableHeaderFrames[1].Body:GetScript("OnEnter")(details.TableHeaderFrames[1].Body)
    equal(table.concat(GameTooltip.singleLines,"\n"):find("1,000",1,true) ~= nil,true,"the fixed sum explains retained-event limits")
    details.TableHeaderFrames[1].Body:GetScript("OnLeave")(details.TableHeaderFrames[1].Body)
    record.events=nil; record.detailsExpired=true; record.eventsLimited=false
    panels:RefreshDetails()
    equal(details.TableHeaderRows[1].value,"Sum: —","expired details do not invent a zero sum")
    equal(details.TableHeaderHeight,48,"empty/expired tables keep their headers")

    panels:ShowHistory()
    equal(panels.History.TableHeaderRows[1].columns,"history","History also pins its column header")
    equal(panels.History.Rows[1].kind,"history","History ScrollBox contains records rather than its header")
    PerHour.Session:Start(); t.finish()
    local history=PerHour.Stores.Sessions:GetHistory()
    panels.Selected={[history[1].id]=history[1],[history[2].id]=history[2]}; panels:ShowComparison()
    equal(panels.Comparison.TableHeaderRows[1].id,"compare:header","Compare pins its record headings")
    equal(panels.Comparison.Rows[1].label,"Experience","Compare scrolls only its metric content")

    local rep=t.copy(record)
    rep.duration=90; rep.paused=false; rep.reputationFaction=72
    rep.reputation={[72]={id=72,name="Stormwind",duration=60,total=120,partial=true}}
    rep.segments={{name="An obsolete segment",start=0,duration=60,total=999}}
    local rows=view:BuildMetricRows(rep,true,"Reputation")
    equal(#rows,3,"Reputation is one header, one faction and one untracked row")
    equal(table.concat(rows[1].values," / "),"Faction / Duration / Rate / Total","Reputation uses the agreed four columns")
    equal(rows[2].values[2],"1m 0s","faction duration uses measured time")
    equal(rows[2].values[4],"120","the faction's aggregate total is preserved")
    equal(rows[2].colors[1],PerHour.Theme.green.text,"the currently tracked faction is green while running")
    equal(rows[2].tooltip.lines[2],"Partial reputation capture.","partial capture stays accessible without a Status column")
    equal(rows[3].values[1],"No faction","untracked time is an ordinary grid row")
    equal(rows[3].values[2],"30s","untracked duration excludes faction tracking intervals")
    equal(rows[3].values[3],"—","untracked time has no invented rate")
    equal(rows[3].values[4],"—","untracked time has no invented reputation total")
    rep.paused=true
    equal(view:BuildMetricRows(rep,true,"Reputation")[2].colors[1],PerHour.Theme.gold.text,"the tracked faction becomes gold when paused")
    equal(view:BuildMetricRows(rep,false,"Reputation")[2].colors[1],PerHour.Theme.text,"archived factions use normal value color")
    rep.reputation={}; rep.duration=0
    local empty=view:BuildMetricRows(rep,false,"Reputation")
    equal(#empty,2,"an empty reputation table retains its header and No faction row")
    equal(empty[2].values[2],"0s","an idle untracked duration is zero without fake reputation")

    record.reputation={[72]={id=72,name="Stormwind",duration=1,total=120}}; record.duration=1
    panels:ShowDetails(record,false); details.Tabs.Buttons.Reputation:Click()
    equal(details.TableHeaderHeight,24,"Reputation has just one fixed column-header row")
    equal(details.TableHeaderRows[1].values[1],"Faction","Reputation replaces the Gold summary/header pool")
    equal(details.TableHeaderFrames[2]:IsShown(),false,"switching grids hides surplus pooled header frames")
    local frame=CreateFrame("Frame",nil,UIParent); frame:SetSize(690,28)
    renderers:Initialize(frame,rows[2],panels)
    equal(table.concat(frame.Body.Cells[1].textColor,","),table.concat(PerHour.Theme.green.text,","),"faction color reaches the rendered grid cell")
end
