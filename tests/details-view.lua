return function(t,fresh)
    local equal,near=t.equal,t.near
    fresh()
    PerHour.Session:Start(); t.tick(60)
    t.progress({xp=250}); t.event("PLAYER_XP_UPDATE","player")
    t.honor(25); t.event("CHAT_MSG_MONEY","You loot 1 Gold")
    t.faction({name="Stormwind",factionID=72,currentStanding=50})
    t.tick(60)
    t.faction({name="Ironforge",factionID=47,currentStanding=100})
    t.tick(30)
    t.faction({name="Ironforge",factionID=47,currentStanding=125})
    t.faction(nil); t.tick(10)
    local panels,view,renderers=PerHour.SessionPanels,PerHour.DetailsView,PerHour.SessionRows
    panels:ShowCurrent()
    local details=panels.Details
    local rows=details.Rows
    local sessionRows=details.SessionRows
    local function byID(data,id)
        for _,row in ipairs(data) do if row.id==id then return row end end
        error("Missing Details row: "..id)
    end
    local function field(data,prefix,key,attribute)
        for _,row in ipairs(data) do
            if row.id and row.id:sub(1,#prefix)==prefix then
                for _,value in ipairs(row.fields or {}) do if value.key==key then return value[attribute or "value"] end end
            end
        end
        error("Missing Details field: "..key)
    end
    equal(panels.Details.Context:IsShown(),false,"Details does not duplicate its metadata in a concatenated header")
    equal(select(5,panels.Details.TabBox:GetPoint()),34,"Details tab box retains its footer clearance")
    equal(sessionRows[1].value,panels.Record.name,"the heading shows only the session name")
    equal(table.concat(details.SessionFrames[1].Body.Value.textColor,","),table.concat(PerHour.Theme.green.text,","),"the running session title is green")
    equal(field(sessionRows,"session:","Duration"),"2m 40s","measured duration stays precise to seconds")
    equal(field(sessionRows,"session:","Character"),PerHour.Format:Character(panels.Record),"Character shows only the character identity")
    equal(byID(sessionRows,"session:Character").fields[2].value,"10 (10% xp)","Level includes the requested XP text beside Character")
    equal(byID(sessionRows,"session:Started").fields[2].key,"Duration","Started and Duration share the same row")
    equal(field(sessionRows,"session:","Visited areas"),panels.Record.map,"a single area remains visible without a redundant starting-map field")
    equal(field(sessionRows,"metric:","Total Experience"),"150","XP total stays in the fixed card")
    equal(field(sessionRows,"metric:","Total Honor"),"25","Honor total stays in the fixed card")
    local gold=field(sessionRows,"metric:","Total Gold")
    equal(gold,"1g 0s 0c (inc - exp)","Gold shows only the net total without a color override")
    equal(#byID(sessionRows,"metric:Experience / Hour").fields,2,"rate and total share a two-column row")
    equal(field(sessionRows,"metric:","Experience / Hour"),"3.3k","rates truncate to one compact decimal")
    equal(details.TableHeaderRows[2].columns,"event","Gold columns are pinned outside the scroll body")
    for index=1,#rows do equal(rows[index].event ~= nil,true,"Gold tab contains only event rows") end
    equal(details.Tabs.SelectedKey,"Income","Details opens on Income")
    equal(details.Tabs.Buttons.Income.template,"MinimalTabTemplate","tabs reuse the actual Options template")
    equal(details.Background.template,"FlatPanelBackgroundTemplate","panels reuse the native Options background")
    equal(details.Border.Bg:IsShown(),false,"the translucent background is replaced")
    equal(details.SessionHeader:GetParent(),details.Content,"metadata lives outside the ScrollBox")
    equal(details.ScrollBox.points.TOPLEFT[2],details.TabBox,"the tab viewport stays inside its fixed border")
    equal(details.TabBox:GetFrameLevel() < details.ScrollBox:GetFrameLevel(),true,
        "tab shading renders behind the scroll content")
    equal(details.ScrollBox:GetEffectiveAlpha(),1,"tab shading does not reduce content opacity")
    local headerAnchor=details.SessionHeader.point
    details.ScrollBox:ScrollToOffset(details.ScrollBox:GetDerivedScrollRange())
    equal(details.SessionHeader.point,headerAnchor,"scrolling tab content leaves session data fixed")
    equal(details.Tabs.Buttons.Experience,nil,"XP no longer needs a tab")
    equal(details.Tabs.Buttons.Honor,nil,"Honor no longer needs a tab")
    details.SessionFrames[1].Body.Rename:Click()
    equal(panels.RenameTarget.id,panels.DetailID,"inline Rename targets the displayed session")
    equal(panels.RenameCurrent,true,"inline Rename retains live-session routing")
    panels.NameInput:SetText("Renamed live session"); panels.RenameDialog.Actions.save:Click(); t.tick(0)
    equal(details.SessionRows[1].value,"Renamed live session","saving an inline rename refreshes the heading")
    details.Tabs.Buttons.Reputation:Click()
    rows=details.Rows
    equal(byID(rows,"rep:untracked").values[2],"10s","untracked reputation time remains a grid row")
    equal(byID(rows,"rep:47").values[2],"30s","reputation grid uses each faction's tracked time")
    equal(#byID(rows,"rep:47").columns,4,"reputation has one Faction / Duration / Rate / Total grid")
    equal(#rows,3,"two factions and untracked time replace the interval sections")
    panels:RefreshDetails()
    equal(details.Tabs.SelectedKey,"Reputation","live refresh retains the selected tab")
    details.Tabs.Buttons.Income:Click()
    near(details.ScrollBox:GetDerivedScrollOffset(),0,"changing tabs starts the new content at the top")
    PerHour.Stores.Settings:SetRate("minute"); panels:RefreshDetails()
    equal(byID(details.SessionRows,"metric:Gold / Minute").fields[1].key,"Gold / Minute","summary follows the shared rate preference")
    PerHour.Session:Pause(); panels:RefreshDetails()
    equal(details.SessionRows[1].value,"Renamed live session","pausing does not add a status prefix")
    equal(table.concat(details.SessionFrames[1].Body.Value.textColor,","),table.concat(PerHour.Theme.gold.text,","),"the paused session title turns gold")
    PerHour.Session:Resume(); t.finish(); t.tick(0)
    equal(details.SessionRows[1].value,"Renamed live session","finishing does not add a status prefix")
    equal(table.concat(details.SessionFrames[1].Body.Value.textColor,","),table.concat(PerHour.Theme.gold.text,","),"the finished session title stays gold")
    equal(field(details.SessionRows,"session:","Started"),PerHour.Format:Date(panels.Record.startedAt),"Started includes the date and local hour and minute")
    details.SessionFrames[1].Body.Rename:Click()
    equal(panels.RenameCurrent,false,"the reused inline action follows Finish into the archive")
    panels.RenameDialog:Hide()

    local record=PerHour.Copy(PerHour.Stores.Sessions:GetHistory()[1])
    record.name=string.rep("漢",80)
    record.zones={string.rep("Long area name ",35),"Stormwind"}
    record.metrics.Gold.incomplete=true; record.metrics.Gold.pendingCount=2; record.metrics.Gold.pending=false
    local before=record.metrics.Gold.total
    local expanded=view:BuildSessionRows(record,false)
    local repRows=view:BuildMetricRows(record,false,"Reputation")
    equal(expanded[1].value,record.name,"long names remain complete without a status prefix")
    equal(expanded[1].height > 32,true,"wrapped names grow their own row with room for Rename")
    equal(byID(expanded,"session:Visited areas").height > 24,true,"long visited-area context grows instead of truncating")
    equal(table.concat(field(expanded,"metric:","Total Gold","tooltip").lines,"\n"):find("Excluded prices: 2",1,true) ~= nil,true,"finished unresolved prices are labeled as excluded")
    equal(table.concat(field(expanded,"metric:","Total Gold","tooltip").lines,"\n"):find("Incomplete · frozen",1,true) ~= nil,true,"frozen status stays with Gold")
    near(record.metrics.Gold.total,before,"building the view does not change recorded amounts")
    record.events=nil; record.detailsExpired=true
    equal(field(view:BuildMetricRows(record,false,"Income"),"events:","Events"),"Details expired; summary preserved","expired details remain distinguishable from zero events")

    equal(view:HasExperience(record),true,"archived XP visibility uses captured start context")
    t.progress({level=60,xp=0,maximum=0})
    equal(view:HasExperience(record),true,"the player's current level cannot hide archived XP")
    record.startLevel=60; record.startAtMaxLevel=true
    equal(view:HasExperience(record),false,"sessions started at max level omit Experience")
    equal(#view:BuildSessionRows(record,false),6,"a capped start omits only the XP summary row")

    record.metrics.Honor.available=false; record.metrics.Honor.partial=true
    record.metrics.Honor.issue="Honor data temporarily unavailable."
    record.metrics.Gold.total=-1; record.metrics.Gold.pending=true; record.metrics.Gold.incomplete=false
    local warnings=view:BuildSessionRows(record,false)
    local honor=table.concat(field(warnings,"metric:","Total Honor","tooltip").lines,"\n")
    equal(honor:find("Unavailable · Partial",1,true) ~= nil,true,"metric flags remain visible without their former tab")
    equal(honor:find(record.metrics.Honor.issue,1,true) ~= nil,true,"the affected metric retains its issue cause")
    equal(table.concat(field(warnings,"metric:","Total Gold","tooltip").lines,"\n"):find("Pending prices: 2",1,true) ~= nil,true,"open unresolved prices keep their pending label")
    equal(field(warnings,"metric:","Total Gold"),"- 0g 0s 1c (inc - exp)","negative net Gold uses the standard value style and keeps its sign")

    equal(PerHour.Format:TruncatedCompact(61794.85,1),"61.7k","rate matches the requested compact precision")
    equal(PerHour.Format:TruncatedCompact(230272,0),"230k","total uses whole compact units")
    equal(PerHour.Format:TruncatedCompact(53.13,1),"53.1","small rates keep one decimal")
    equal(PerHour.Format:MeasuredDuration(13415),"3h 43m 35s","long measured duration includes seconds")
    equal(PerHour.Format:MeasuredDuration(3600),"1h 0m 0s","whole hours keep minute and second units")
    equal(PerHour.Format:MeasuredDuration(0),"0s","zero duration remains explicit")
    record.gold={coins=284578,items=311336,expenses=9955}
    record.metrics.Gold.total=585959
    local arithmetic=view:BuildSessionRows(record,false)
    equal(field(arithmetic,"metric:","Total Gold"),"58g 59s 59c (inc - exp)","Gold total preserves net copper precision without extra lines")
    record.metrics.Gold.available=false; record.metrics.Gold.total=0
    local unavailable=view:BuildSessionRows(record,false)
    equal(field(unavailable,"metric:","Gold / Minute"),"—","an unreadable rate is not displayed as zero")
    equal(field(unavailable,"metric:","Total Gold"),"—","an unreadable zero total is not displayed as income")

    local frame=CreateFrame("Frame",nil,UIParent); frame:SetSize(690,100)
    renderers:Initialize(frame,byID(warnings,"metric:Honor / Minute"),panels)
    local hover=frame.Body.Fields[2].hover
    hover.scripts.OnEnter(hover)
    equal(GameTooltip:IsOwned(hover),true,"full metric context stays available on hover")
    equal(GameTooltip:IsShown(),true,"hover shows metric context")
    equal(frame.Body.Fields[2].value:GetText(),"25","compact total does not append quality warnings")
    renderers:Initialize(frame,byID(arithmetic,"metric:Gold / Minute"),panels)
    equal(frame.Body.Fields[2].value.justifyH,"LEFT","Gold total follows the standard value alignment")
    equal(table.concat(frame.Body.Fields[2].value.textColor,","),table.concat(PerHour.Theme.text,","),"Gold total follows the standard white value color")
    renderers:Initialize(frame,byID(expanded,"session:Character"),panels)
    equal(frame.Divider:IsShown(),false,"key/value cards do not draw table separators")
    renderers:Initialize(frame,byID(expanded,"session:Started"),panels)
    local second=frame.Body.Fields[2]
    renderers:Initialize(frame,byID(expanded,"session:Visited areas"),panels)
    equal(second.value:IsShown(),false,"wide properties hide a recycled second value")
    renderers:Initialize(frame,byID(repRows,"rep:47"),panels)
    equal(frame.Divider:IsShown(),true,"table rows retain their separators after recycling")
    renderers:Initialize(frame,byID(expanded,"session:heading"),panels)
    equal(frame.Divider:IsShown(),false,"the session heading hides a recycled table separator")

    PerHour.Session:Start(); panels:ShowCurrent()
    equal(details.Tabs.SelectedKey,"Income","a new session resets the tab to Income")
    equal(#details.SessionRows,6,"a level-60 start omits XP from the card")
    equal(select(2,details.Tabs.Buttons.Expenses:GetPoint()),details.Tabs.Buttons.Income,"the metric tabs are adjacent")
    local saved=PerHour.Stores.Sessions:GetHistory()[1]
    panels:ShowDetails(saved,false)
    equal(field(details.SessionRows,"metric:","Total Experience"),"150","archived XP remains visible after the character reaches 60")
    details.Tabs.Buttons.Reputation:Click()
    panels:ShowCurrent()
    equal(details.Tabs.SelectedKey,"Income","switching sessions resets the tab selection")
end
