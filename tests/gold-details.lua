return function(t,fresh)
    local equal=t.equal
    fresh(); PerHour.Session:Start(); t.tick(60)
    t.event("CHAT_MSG_MONEY","You loot 1 Copper")
    PerHour.SessionPanels:ShowCurrent()
    local panels=PerHour.SessionPanels
    equal(panels.Details.TitleText:GetText(),"Session","one Session window covers all metrics")
    equal(panels.Details.ScrollBox.template,"WowScrollBoxList","Details uses native virtualized list")
    equal(panels.Details:GetScript("OnUpdate"),nil,"Details has no per-frame update")
    local record=t.finish(); t.tick(0)
    equal(panels.CurrentDetails,false,"Finish converts open Details to the archived session")
    equal(panels.Details:IsShown(),true,"archived Details remains visible")
    equal(panels.Details.Notice:GetText():find("Finished ",1,true) ~= nil,true,"archived Details identifies its finished state")
    local saved=PerHour.Stores.Sessions:GetHistory()[1]
    equal(saved.metrics.Gold.total,1,"copper remains in archived summary")
    PerHour.Stores.Settings:SetRate("minute"); panels:RefreshDetails()
    local found=false
    for _,row in ipairs(panels.Details.SessionRows) do
        if row.id=="metric:Gold / Minute" then found=true end
    end
    equal(found,true,"Details follows shared /m unit")
    panels:ShowDelete(saved)
    equal(#PerHour.Stores.Sessions:GetHistory(),1,"opening Delete does not remove record")
    panels.DeleteDialog.Actions.cancel:Click()
    equal(#PerHour.Stores.Sessions:GetHistory(),1,"cancel preserves record")
    panels:ShowDelete(saved); panels.DeleteDialog.Actions.delete:Click(); t.tick(0)
    equal(#PerHour.Stores.Sessions:GetHistory(),0,"explicit confirmation deletes record")
    equal(panels.Details:IsShown(),false,"deleted record closes its Details view")
    PerHour.SettingsPanel:Show()
    equal(PerHour.SettingsPanel.Frame.TitleText:GetText(),"Per Hour Settings","Settings uses shared native panel")
    PerHour.SettingsPanel:Swap("Experience","Gold")
    equal(PerHour.Stores.Settings:GetOrder()[1],"Gold","metric selectors swap preferred positions")
end
