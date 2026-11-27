return function(t,fresh)
    fresh()
    local equal,near=t.equal,t.near
    local session,store,panels,view=PerHour.Session,PerHour.Stores.Sessions,PerHour.SessionPanels,PerHour.ComparisonView
    session:Start(); t.tick(1800); t.finish()
    local first=store:GetHistory()[1]
    session:Start(); t.tick(1800); t.finish()
    local second=store:GetHistory()[1]
    first.name,second.name="Blackrock Depths","Mount Hyjal"
    first.metrics.Experience.total,second.metrics.Experience.total=12000,15000
    first.metrics.Gold.total,second.metrics.Gold.total=90000,-55000
    first.metrics.Honor.total=300
    second.metrics.Honor.available=false
    first.metrics.Gold.incomplete=true
    first.reputation={[529]={id=529,name="Argent Dawn",total=400,duration=1800,partial=true}}
    second.reputation={
        [529]={id=529,name="Argent Dawn",total=600,duration=1800},
        [576]={id=576,name="Timbermaw Hold",total=250,duration=1800},
    }
    -- Faction rates must use their own tracked time rather than this session duration.
    first.duration,second.duration=3600,7200
    PerHour.Stores.Settings:SetRate("minute")
    panels.Selected={[first.id]=first,[second.id]=second}; panels:ShowComparison()
    local panel=panels.Comparison
    equal(panel:GetWidth(),700,"Compare uses the agreed compact width")
    equal(panel:GetHeight(),320,"Compare fits its five metric rows and fixed header in the compact minimum height")
    equal(panel.ScrollBox:GetDerivedScrollRange(),0,"a short comparison fits without scrolling")
    equal(panels.ComparisonRecords[1],first,"column identity follows the selected record IDs")
    equal(panel.Context:IsShown(),false,"Compare starts directly with its column headings")
    local header=panel.TableHeaderRows[1]
    equal(table.concat(header.values,"|"),"|Blackrock Depths||Mount Hyjal","only the session titles label the fixed grid headings")
    equal(panel.TableHeaderHeight,28,"the larger session titles fit in one fixed header row")
    equal(#panel.Rows,5,"only base metrics and distinct factions occupy comparison rows")
    local expected={
        {"Experience","24k xp/h","vs.","30k xp/h"},
        {"Gold","18 g/h","vs.","-11 g/h"},
        {"Honor","600 hon/h","vs.","0 hon/h"},
        {"Argent Dawn","800 rep/h","vs.","1.2k rep/h"},
        {"Timbermaw Hold","0 rep/h","vs.","500 rep/h"},
    }
    local winners={4,2,2,4,4}
    for index,row in ipairs(panel.Rows) do
        equal(table.concat(row.values,"|"),table.concat(expected[index],"|"),"Compare row "..index.." contains the requested readings")
        equal(PerHour.SessionRows:GetExtent(row),32,"Compare gives the larger readings one 32 px row")
        equal(row.winner,winners[index],"Compare independently identifies the greater reading in row "..index)
        equal(row.label ~= "Duration",true,"Duration is not part of the metric duel")
    end
    equal(PerHour.Stores.Settings:GetRate(),"minute","hourly comparison leaves the user's rate preference unchanged")
    equal(first.metrics.Gold.total,90000,"comparison formatting preserves stored copper totals")
    local frame=CreateFrame("Frame",nil,UIParent); frame:SetSize(panel.ScrollBox:GetWidth(),32)
    PerHour.SessionRows:Initialize(frame,panel.Rows[1],panels)
    local body=frame.Body
    equal(select(2,body.Cells[2]:GetFont()),14,"the first reading uses the larger font")
    equal(select(2,body.Cells[4]:GetFont()),14,"the second reading uses the larger font")
    equal(select(4,body.Cells[4]:GetPoint())+body.Cells[4]:GetWidth() <= panel.ScrollBox:GetWidth(),true,
        "all comparison columns stay inside the compact viewport")
    equal(table.concat(body.Cells[4].textColor,","),table.concat(PerHour.Theme.gold.text,","),"the greater rate renders in gold")
    equal(table.concat(body.Cells[2].textColor,","),table.concat(PerHour.Theme.text,","),"the lower rate remains white")
    equal(body.Cells[2].justifyH,"RIGHT","the first session reading faces the comparison separator")
    equal(body.Cells[4].justifyH,"LEFT","the second session reading faces the comparison separator")
    equal(body.Cells[3]:GetWidth(),24,"vs. uses the requested narrow column")
    equal(body.Cells[3]:GetText(),"vs.","vs. fits in its column without truncation")
    near(panel.ContentInsets.left+select(4,body.Cells[3]:GetPoint())+body.Cells[3]:GetWidth()/2,
        panel:GetWidth()/2,"vs. marks the panel's center, including the space reserved for the scrollbar")
    equal(body.Advantages[4]:IsShown(),true,"the winning rate has an improvement badge")
    equal(body.Advantages[4].Text:GetText(),"25%","improvement is relative to the opposing hourly rate")
    equal(body.Advantages[2]:IsShown(),false,"the losing rate has no improvement badge")
    equal(table.concat(body.Advantages[4].Text.textColor,","),table.concat(PerHour.Theme.green.text,","),"the improvement percentage is green")
    equal(body.Advantages[4].Arrow:GetWidth(),9,"the upward indicator is a compact triangle")
    near(select(4,body.Cells[4]:GetPoint())-(select(4,body.Cells[2]:GetPoint())+body.Cells[2]:GetWidth()),36,
        "the gap between values is just vs. plus 6 px padding on either side")
    local hover=body.Hovers[2]
    hover:GetScript("OnEnter")(hover)
    equal(GameTooltip.text,"Experience","the metric tooltip identifies the metric")
    equal(table.concat(GameTooltip.singleLines,"|"),"Rate per min.: 400 xp/m|Total: 12,000","the metric tooltip contains only the inverse minute rate and total")
    hover:GetScript("OnLeave")(hover)
    PerHour.SessionRows:Initialize(frame,panel.Rows[2],panels)
    equal(body.Advantages[4]:IsShown(),false,"recycling a row removes its former right-side badge")
    equal(body.Advantages[2]:IsShown(),true,"a left-side winner places its improvement before the reading")
    equal(body.Advantages[2].Text:GetText(),"264%","advantages above 100 percent have no decimal places")
    hover:GetScript("OnEnter")(hover)
    equal(table.concat(GameTooltip.singleLines,"|"),"Rate per min.: 0.3 g/m|Total: 9g 0s 0c","Gold keeps fractional minute rates and native coin totals without warnings")
    PerHour.SessionRows:Initialize(frame,panel.Rows[5],panels)
    equal(body.Advantages[2]:IsShown(),false,"a recycled zero-baseline duel clears the previous badge")
    equal(body.Advantages[4]:IsShown(),false,"a missing opposing faction has no percentage baseline")
    equal(GameTooltip.text,"Timbermaw Hold","recycled cells refresh the metric tooltip title")
    equal(table.concat(GameTooltip.singleLines,"|"),"Rate per min.: 0/m|Total: 0","absent factions keep the same two-line tooltip with zero readings")
    hover:GetScript("OnLeave")(hover)

    local heading=panel.TableHeaderFrames[1].Body
    equal(heading.Cells[1]:GetText(),"","the metric column has no title")
    equal(select(2,heading.Cells[2]:GetFont()),16,"the first session title is larger than the metric readings")
    equal(select(2,heading.Cells[4]:GetFont()),16,"the second session title uses the same larger font")
    first.name=string.rep("Long session title ",5)
    panels:RefreshComparison()
    equal(heading.Cells[2]:GetText() ~= first.name,true,"long session titles truncate within their column")
    heading.Hovers[2]:GetScript("OnEnter")(heading.Hovers[2])
    equal(GameTooltip.text,first.name,"header tooltip retains the complete session title")
    equal(table.concat(GameTooltip.singleLines,"|"):find("Duration: 1h 0m 0s",1,true) ~= nil,true,"header tooltip retains measured session context")
    heading.Hovers[2]:GetScript("OnLeave")(heading.Hovers[2])
    local anchor=panel.TableHeader.point
    panel.ScrollBox:ScrollToOffset(28)
    equal(panel.TableHeader.point,anchor,"scrolling leaves the comparison headings fixed")
    for index=1,20 do
        local id=2000+index
        first.reputation[id]={id=id,name="Additional faction "..index,total=index,duration=60}
    end
    panels:RefreshComparison()
    equal(panel:GetHeight(),520,"many factions cap the panel height")
    equal(panel.ScrollBox:GetDerivedScrollRange() > 0,true,"overflowing factions scroll within the capped panel")
    local fixedHeading=panel.TableHeader.point
    panel.ScrollBox:ScrollToOffset(panel.ScrollBox:GetDerivedScrollRange())
    local sawLastFaction=false
    panel.ScrollBox:ForEachFrame(function(row) if row.Data.label == "Timbermaw Hold" then sawLastFaction=true end end)
    equal(sawLastFaction,true,"the final faction remains reachable after scrolling a long comparison")
    equal(panel.TableHeader.point,fixedHeading,"long comparison headings remain fixed while scrolling")
    for index=1,20 do first.reputation[2000+index]=nil end
    panels:RefreshComparison()
    equal(panel:GetHeight(),320,"a shorter comparison shrinks back to fit its rows")
    equal(panel.ScrollBox:GetDerivedScrollOffset(),0,"shrinking clamps the former scroll offset to the new content")
    local fullReading=t.copy(panel.Rows[2])
    fullReading.values[2],fullReading.values[4]="123.4M g/h","45 g/h"
    fullReading.winner,fullReading.advantage=2,173.1
    body.Advantages[2].Text:SetWidth(12); body.Cells[2]:SetWidth(12)
    PerHour.SessionRows:Initialize(frame,fullReading,panels)
    equal(body.Cells[2]:GetText(),"123.4M g/h","the full winning rate is never replaced with ellipsis")
    equal(body.Advantages[2].Text:GetText(),"173%","the full percentage is never replaced with ellipsis")
    equal(body.Cells[2]:GetWidth(),body.Cells[2]:GetUnboundedStringWidth(),"the reading reserves its full natural text width")
    equal(body.Advantages[2].Text:GetWidth(),body.Advantages[2].Text:GetUnboundedStringWidth(),"the badge reserves its full natural text width")
    near(select(4,body.Cells[2]:GetPoint())+body.Cells[2]:GetWidth(),select(4,body.Cells[3]:GetPoint())-6,
        "full readings keep their edge aligned to the centered vs. column")
    local percentage=t.copy(panel.Rows[2]); percentage.winner=2
    for _,case in ipairs({{5.64,"5.6%"},{99.4,"99.4%"},{99.96,"100%"},{100,"100%"},{100.4,"100%"},{100.6,"101%"}}) do
        percentage.advantage=case[1]
        PerHour.SessionRows:Initialize(frame,percentage,panels)
        equal(body.Advantages[2].Text:GetText(),case[2],"percentage formatting follows the 100 percent boundary for "..case[1])
    end

    local duelLeft,duelRight=t.copy(first),t.copy(second)
    duelRight.metrics.Experience.duration=2250
    local duel=view:BuildRows(duelLeft,duelRight)
    equal(duel[2].winner,nil,"equal rates tie even with different totals")
    PerHour.SessionRows:Initialize(frame,duel[2],panels)
    for _,index in ipairs({2,4}) do
        equal(table.concat(body.Cells[index].textColor,","),table.concat(PerHour.Theme.text,","),"a recycled tie clears either previous winner highlight")
        equal(body.Advantages[index]:IsShown(),false,"a tied row clears either previous improvement badge")
    end
    duelLeft.metrics.Gold.total=-90000
    equal(view:BuildRows(duelLeft,duelRight)[3].winner,4,"the smaller Gold loss wins a negative-rate duel")
    near(view:BuildRows(duelLeft,duelRight)[3].advantage,35000/90000*100,"negative Gold compares the reduction in loss")
    duelLeft.metrics.Gold.total,duelRight.metrics.Gold.total=-20000,-10000
    near(view:BuildRows(duelLeft,duelRight)[3].advantage,50,"halving a loss is a 50 percent improvement")
    duelLeft.metrics.Honor.total,duelRight.metrics.Honor.total=300.01,300.02
    duelRight.metrics.Honor.available=true
    duel=view:BuildRows(duelLeft,duelRight)
    equal(duel[4].values[2],duel[4].values[4],"compact display can hide a small rate difference")
    equal(duel[4].winner,4,"winner selection uses the full rate before display truncation")
    near(duel[4].advantage,(600.04-600.02)/600.02*100,"percentage calculation uses the full rates before display truncation")
    PerHour.SessionRows:Initialize(frame,duel[4],panels)
    equal(body.Advantages[4].Text:GetText(),"<0.1%","a tiny improvement is not mislabeled as zero percent")
    duelLeft.metrics.Gold.total,duelRight.metrics.Gold.total=0,10000
    equal(view:BuildRows(duelLeft,duelRight)[3].advantage,nil,"a measured zero baseline has no percentage")

    first.metrics.Experience.duration=0
    first.reputation[72]={id=72,name="A faction",total=0,duration=0}
    second.reputation[73]={id=73,name="A faction",total=0,duration=30}
    local rows=view:BuildRows(first,second)
    equal(rows[2].values[2],"0 xp/h","a zero-duration metric retains its spaced hourly unit")
    equal(table.concat(rows[2].tooltips[2].lines,"|"),"Rate per min.: 0/m|Total: 12,000","zero-duration readings keep the total without extra explanations")
    equal(rows[5].id,"compare:rep:72","factions are sorted by name with ID as the tie-breaker")
    equal(rows[6].id,"compare:rep:73","equal faction names retain their distinct identities")
    equal(rows[5].values[2],"0 rep/h","a zero-duration faction retains its spaced hourly unit")
    equal(rows[5].winner,nil,"zero and absent faction readings tie")
    equal(rows[5].advantage,nil,"absent and zero values never produce an improvement percentage")
    equal(rows[6].values[4],"0 rep/h","a measured zero gain also retains its spaced hourly unit")
    first.reputation,second.reputation={},{}
    panels:RefreshComparison()
    equal(panel:GetHeight(),320,"comparisons without factions keep the compact minimum height")
    local withoutFactions=view:BuildRows(first,second)
    equal(#withoutFactions,4,"sessions without reputation keep only the header and three base metrics")
    store:Delete(second); panels:RefreshComparison()
    equal(panel:IsShown(),false,"a removed session closes its outstanding comparison")
end
