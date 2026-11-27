return function(t,fresh)
    local equal=t.equal
    fresh()
    local display=PerHour.Dashboard.Displays[2]
    local function hover()
        display:GetScript("OnEnter")(display)
        equal(GameTooltip.text,"Gold","metric tooltip retains its title")
        equal(#GameTooltip.singleLines,0,"metric tooltip has no extra context lines")
        local count=0
        for _ in pairs(GameTooltip.lines) do count=count+1 end
        equal(count,2,"metric tooltip contains only Total and Rate")
    end
    hover()
    equal(GameTooltip.lines.Rate,"0 g/m","idle Gold keeps its numeric rate unit")
    t.progress({maximum=1000000})
    PerHour.Session:Start(); t.tick(3600)
    t.event("CHAT_MSG_MONEY","You loot 6 Gold")
    t.progress({xp=300100}); t.event("PLAYER_XP_UPDATE","player")
    PerHour.Dashboard:RefreshDisplays()
    equal(display.Value:GetText(),"6","tracked Gold converts copper to gold")
    equal(display.Unit:GetText(),"g/h","tracked Gold uses a text rate unit")

    -- The fixture renders coins as plain text. Mark the native money API to
    -- distinguish coin amounts from numeric rates without imitating WoW icons.
    local original=GetMoneyString
    GetMoneyString=function(value,icons)
        equal(icons,true,"absolute Gold requests native coin icons")
        return "coins:"..original(value)
    end
    hover()
    equal(GameTooltip.lines.Total,"coins:6g 0s 0c","Gold tooltip total uses native coins")
    equal(GameTooltip.lines.Rate,"0.1 g/m","hour display tooltip uses fractional gold per minute")
    equal(PerHour.Stores.Settings:GetRate(),"hour","opposite tooltip rate preserves the display preference")
    local xp=PerHour.Dashboard.Displays[1]
    equal(xp.Value:GetText(),"300.0k","XP display remains compact")
    equal(xp.Unit:GetText(),"xp/h","XP display identifies its tracked unit")
    xp:GetScript("OnEnter")(xp)
    equal(GameTooltip.lines.Rate,"5,000 xp/m","XP tooltip rate includes its metric unit")

    local function goldFields()
        local record=PerHour.Session:GetSnapshot(false)
        for _,row in ipairs(PerHour.DetailsView:BuildSessionRows(record,true)) do
            if row.id=="metric:Gold / Hour" then return row.fields end
        end
        error("Missing Gold fields")
    end
    local fields=goldFields()
    equal(fields[1].value,"6 g/h","Details formats tracked Gold as a numeric rate")
    equal(fields[2].value,"coins:6g 0s 0c (inc - exp)","Details shares the absolute Gold format")

    PerHour.Stores.Settings:SetRate("minute"); PerHour.Dashboard:RefreshDisplays()
    equal(display.Value:GetText(),"0.1","minute display shares fractional gold conversion")
    equal(display.Unit:GetText(),"g/m","minute display retains its tracked unit")
    hover()
    equal(GameTooltip.lines.Rate,"6 g/h","minute display tooltip uses gold per hour")
    equal(GameTooltip.lines.Total,"coins:6g 0s 0c","changing rate leaves the absolute total unchanged")
    PerHour.Modules.Gold.State.Element=-60000
    hover()
    equal(GameTooltip.lines.Total,"- coins:6g 0s 0c","absolute Gold retains its negative sign")
    equal(GameTooltip.lines.Rate,"-6 g/h","negative rates retain numeric gold and unit")
    PerHour.Modules.Gold.State.Available=false
    hover()
    equal(GameTooltip.lines.Total,"—","unavailable tooltip total stays unavailable")
    equal(GameTooltip.lines.Rate,"—","unavailable tooltip rate stays unavailable")
    GetMoneyString=original
end
