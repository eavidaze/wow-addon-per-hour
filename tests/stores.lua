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
    settings:SetSpeedometerLevel(3); settings:SetEstimatesEnabled("Experience",true)
    settings:Init()
    equal(settings:GetRate(),"minute","new preferences survive repeated initialization")
    equal(settings:GetSpeedometerMaximum("hour"),30000,"gauge level maps to shared scale")
    PerHour.Session:Start(); t.tick(1); t.finish()
    PerHour.Stores.Sessions:GetHistory()[1].name="Session in Elwynn Forest"
    local account=t.copy(PerHourRevampHistory)
    local oldID=PerHour.Stores.Sessions.Character
    t.characterID,t.characterName,t.realm="Player-Other","Tester","Other Realm"
    t.fresh(nil,nil,account,false)
    equal(#PerHour.Stores.Sessions:GetHistory(),0,"other character has independent history")
    equal(#PerHour.Stores.Sessions:GetHistory(oldID),1,"account can consult earlier character")
    equal(PerHour.Stores.Sessions:GetHistory(oldID)[1].name,"Session in Elwynn Forest","existing session names are preserved without migration")
    PerHour.Session:Start(); t.finish()
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
    PerHour.Session:Start(); t.finish()
    equal(#store:GetHistory(),1,"unreadable history does not prevent archiving a new session")
    equal(sessions[22],"Unreadable preserved record","retention leaves unreadable details intact")

    t.characterName,t.characterSurname,t.realm="Kaska","Moonwhisper",""
    t.fresh()
    store=PerHour.Stores.Sessions
    equal(store.Account.characters[store.Character].name,"Kaska Moonwhisper","Forever captures both UnitName returns as the full name")
    equal(store.Account.characters[store.Character].realm,"","the surname is not stored as a realm")
    PerHour.Session:Start(); t.finish()
    local saved=store:GetHistory()[1]
    equal(PerHour.Format:Character(saved),"Kaska Moonwhisper","archived Details includes the surname without an empty-realm suffix")
    equal(store:GetCharacters()[1].label,"Kaska Moonwhisper","History uses the same complete character label")
    local firstID=store.Character
    account=t.copy(store.Account)
    t.characterID,t.characterSurname="Player-Other","Silverwind"
    t.fresh(nil,nil,account,false)
    store=PerHour.Stores.Sessions
    equal(store.Account.characters[firstID].name,"Kaska Moonwhisper","another character's surname stays with its GUID")
    equal(store.Account.characters[store.Character].name,"Kaska Silverwind","same first names preserve their own surnames")
    equal(#store:GetHistory(firstID),1,"capturing another surname preserves the archived history")
    t.characterSurname=""; store:BindCharacter()
    equal(store.Account.characters[store.Character].name,"Kaska","an empty surname does not add a trailing space")
    equal(PerHour.Format:Character(saved),"Kaska Moonwhisper","viewing another character never uses the current player's surname")
    fresh()
end
