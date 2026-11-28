return function(t,fresh)
    local equal=t.equal
    fresh()
    local format=PerHour.Format
    for _,case in ipairs({
        {0,"0s"},{0.9,"0s"},{1,"1s"},{59.9,"59s"},
        {60,"1m"},{119.9,"1m"},{120,"2m"},{3599.9,"59m"},
        {3600,"1h 0m"},{3660,"1h 1m"},{7320,"2h 2m"},
    }) do equal(format:Duration(case[1]),case[2],"duration boundary at "..case[1].." seconds") end

    local session,dashboard,theme=PerHour.Session,PerHour.Dashboard,PerHour.Theme
    local duration=dashboard.Duration
    PerHour.Stores.Settings:SetEstimatesEnabled("Experience",true)
    PerHour.Stores.Settings:SetEstimatesEnabled("Reputation",true)
    dashboard:RefreshDisplays()
    local function color(label,expected)
        for index=1,3 do equal(label.textColor[index],expected[index],"duration/display status color channel "..index) end
    end
    local function statusColors(key)
        for _,display in ipairs({duration,dashboard.ExperienceEstimate,dashboard.ReputationEstimate}) do
            color(display.Value,theme.trackerStatus[key])
        end
    end
    equal(duration.Leading,false,"dashboard duration has no active indicator")
    equal(duration.Value:GetText(),"0s","idle duration starts at zero seconds")
    statusColors("idle")
    session:Start(); t.tick(59)
    equal(duration.Value:GetText(),"59s","first minute visibly counts seconds")
    statusColors("running")
    color(dashboard.Displays[1].Value,theme.gold.text)
    t.tick(1)
    equal(duration.Value:GetText(),"1m","first minute switches to minute precision")
    session:Pause(); t.tick(15)
    equal(duration.Value:GetText(),"1m","pause freezes measured duration")
    statusColors("paused")
    session:Resume(); t.tick(3540)
    equal(duration.Value:GetText(),"1h 0m","first hour switches to hours and minutes")
    statusColors("running")
    t.tick(60)
    equal(duration.Value:GetText(),"1h 1m","elapsed hour retains minute precision")
    t.finish()
    equal(duration.Value:GetText(),"0s","Finish resets duration")
    statusColors("idle")
end
