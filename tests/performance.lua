return function(t,fresh)
    local equal=t.equal
    fresh()
    equal(PerHour.Capture.Token,nil,"no sampling timer before Start")
    PerHour.Session:Start()
    local original,calls=C_Container.GetContainerNumSlots,0
    C_Container.GetContainerNumSlots=function(...) calls=calls+1; return original(...) end
    t.tick(5)
    equal(calls,0,"ordinary timer sampling does not scan bags without evidence")
    PerHour.Dashboard:Toggle(); t.tick(5)
    equal(PerHour.Session.Current.duration,10,"hidden panel still advances shared clock")
    equal(PerHour.Dashboard.Frame:GetScript("OnUpdate"),nil,"dashboard has no per-frame polling")
    for _,module in pairs(PerHour.Modules) do equal(module.View.TrackerFrame:GetScript("OnUpdate"),nil,module.Name.." uses events and shared scheduler") end
    PerHour.Session:Pause(); t.tick(2)
    equal(PerHour.Capture.Token,nil,"paused session stops shared sampling timer")
    C_Container.GetContainerNumSlots=original
end
