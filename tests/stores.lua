return function(t,fresh)
    local equal=t.equal
    PerHourCharacter_Settings={rate="minute"}
    PerHourCharacter_Values={version=2,sessions={Gold={total=999,duration=100,paused=false}}}
    fresh()
    equal(PerHour.Stores.Settings:GetRate(),"hour","new settings ignore legacy character preferences")
    equal(PerHour.Session.Current,nil,"old module sessions are not imported")
    equal(PerHourCharacter_Values.sessions.Gold.total,999,"initialization does not rewrite legacy data")
    local settings=PerHour.Stores.Settings
    settings:SetRate("minute"); settings:Set("panelType","focused"); settings:SetSpeedometerEnabled(true)
    settings:SetSpeedometerLevel(3); settings:SetEstimatesEnabled(true)
    settings:Init()
    equal(settings:GetRate(),"minute","new preferences survive repeated initialization")
    equal(settings:GetSpeedometerMaximum("hour"),30000,"gauge level maps to shared scale")
    PerHour.Session:Start(); t.tick(1); PerHour.Session:Finish()
    local account=t.copy(PerHourRevampHistory)
    local oldID=PerHour.Stores.Sessions.Character
    t.characterID,t.characterName,t.realm="Player-Other","Tester","Other Realm"
    t.fresh(nil,nil,account,false)
    equal(#PerHour.Stores.Sessions:GetHistory(),0,"other character has independent history")
    equal(#PerHour.Stores.Sessions:GetHistory(oldID),1,"account can consult earlier character")
    PerHour.Session:Start(); PerHour.Session:Finish()
    equal(#PerHour.Stores.Sessions:GetCharacters(),2,"same name across realms keeps distinct identity")
    t.characterID,t.characterName,t.realm=nil,nil,nil
    fresh(); PerHourRevampSession.current={broken=true}
    t.reload(t.copy(PerHourRevampSession),0)
    equal(PerHour.Session.Current,nil,"unreadable current session does not start capture")
    equal(PerHour.Stores.Sessions.Data.recovery.data.broken,true,"unreadable save is preserved for recovery")

    fresh()
    local store=PerHour.Stores.Sessions
    local sessions=store.Account.characters[store.Character].sessions
    for index=1,21 do sessions[index]="Unreadable preserved record" end
    PerHour.Session:Start(); PerHour.Session:Finish()
    equal(#store:GetHistory(),1,"unreadable history does not prevent archiving a new session")
    equal(sessions[22],"Unreadable preserved record","retention leaves unreadable details intact")
end
