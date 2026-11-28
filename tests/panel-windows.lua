return function(t,fresh)
    fresh()
    local equal,near=t.equal,t.near
    local panels=PerHour.SessionPanels
    PerHour.Session:Start(); t.tick(1); t.finish()
    local first=PerHour.Stores.Sessions:GetHistory()[1]
    PerHour.Session:Start(); t.tick(1); t.finish()
    local second=PerHour.Stores.Sessions:GetHistory()[1]
    PerHour.SettingsPanel:Show()
    local settings=PerHour.SettingsPanel.Frame
    panels:ShowHistory()
    local history=panels.History
    near(history:GetLeft(),settings:GetLeft()+32,"history cascades beside Settings")
    near(history:GetTop(),settings:GetTop()-32,"history leaves the Settings header exposed")
    panels:ShowDetails(first,false)
    near(panels.Details:GetLeft(),history:GetLeft()+32,"Details cascades beside History")
    near(panels.Details:GetTop(),history:GetTop()-32,"Details leaves the History header exposed")
    panels.Selected={[first.id]=first,[second.id]=second}
    panels:ShowComparison()
    near(panels.Comparison:GetLeft(),panels.Details:GetLeft()+32,"Compare joins the same cascade")
    panels:ShowRename(first,false)
    panels:ShowDelete(second)
    for _,window in ipairs({settings,history,panels.Details,panels.Comparison,panels.RenameDialog,panels.DeleteDialog}) do
        equal(window:IsToplevel(),true,"standard windows use native toplevel behavior")
        equal(window:GetFlattensRenderLayers(),true,"standard window subregions render together")
    end
    equal(settings:GetFrameStrata(),"DIALOG","Settings retains the dialog strata")
    equal(panels.RenameDialog:GetFrameStrata(),"FULLSCREEN_DIALOG","Rename retains its higher dialog strata")
    near(panels.RenameDialog:GetLeft(),(UIParent:GetWidth()-panels.RenameDialog:GetWidth())/2,
        "first confirmation is not displaced by lower-strata windows")

    panels.Details:ClearAllPoints()
    panels.Details:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",120,800)
    panels.Details:Hide(); panels:ShowDetails(first,false)
    near(panels.Details:GetLeft(),120,"reopening Details preserves a manually adjusted horizontal position")
    near(panels.Details:GetTop(),800,"reopening Details preserves a manually adjusted vertical position")
    local tracker=PerHour.Dashboard.Frame
    equal(rawget(tracker,"WindowPlaced"),nil,"tracker does not participate in the standard-window cascade")

    fresh()
    local components=PerHour.Components
    local a=components:CreatePanel(UIParent,{name="TestWindowA",title="A",width=400,height=300,draggable=true})
    a:SetFrameStrata("DIALOG"); a:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",1500,320); a:Show()
    local b=components:CreatePanel(UIParent,{name="TestWindowB",title="B",width=600,height=500,draggable=true})
    b:SetFrameStrata("DIALOG"); b:SetPoint("CENTER",UIParent,"CENTER",0,0); b:Show()
    equal(b:GetLeft()+b:GetWidth() <= UIParent:GetWidth()-16,true,"cascade stays inside the right screen edge")
    equal(b:GetTop()-b:GetHeight() >= 16,true,"cascade stays above the bottom screen edge")
    b:Hide()
    local c=components:CreatePanel(UIParent,{name="TestWindowC",title="C",width=200,height=200,draggable=true})
    c:SetFrameStrata("DIALOG"); c:SetPoint("CENTER",UIParent,"CENTER",0,0); c:Show()
    near(c:GetLeft(),a:GetLeft()+32,"hidden windows do not determine the cascade position")

    local wide=components:CreatePanel(UIParent,{name="TestWideWindow",title="Wide",width=2400,height=600,draggable=true})
    wide:SetFrameStrata("DIALOG"); wide:SetPoint("CENTER",UIParent,"CENTER",0,0); wide:Show()
    equal(wide:GetWidth()*wide:GetScale() <= UIParent:GetWidth()-32,true,"standard windows also fit the screen width")
    equal(wide:GetHeight()*wide:GetScale() <= UIParent:GetHeight()-60,true,"scaled windows retain screen margins")
    equal(wide:GetScript("OnUpdate"),nil,"window management has no per-frame polling")
end
