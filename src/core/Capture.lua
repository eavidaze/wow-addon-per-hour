local Capture = {}
PerHour.Capture = Capture
function Capture:RefreshScheduler()
    local session = PerHour.Session
    local active = session.InWorld and session.Current and not session.Current.paused and not session.CheckingPlayed
    if not active then self.Token = nil; return end
    if self.Token then return end
    local token = {}
    self.Token = token
    C_Timer.After(1, function()
        if self.Token ~= token then return end
        self.Token = nil
        if not session.InWorld then return end
        session:Sample(true)
        session:Refresh()
        self:RefreshScheduler()
    end)
end
function Capture:Init()
    for _, name in ipairs(PerHour.MetricOrder) do
        local module = PerHour.Modules[name]
        local frame = CreateFrame("Frame", nil, UIParent)
        module.View.TrackerFrame = frame
        for _, event in ipairs(module.RegisteredEvents) do frame:RegisterEvent(event) end
        frame:SetScript("OnEvent", function(self, event, ...)
            local session = PerHour.Session
            if not session.InWorld or not session.Current or session.CheckingPlayed or module.State.Disabled then return end
            session:Touch()
            session:Call(module, "CustomOnEvent", self, event, ...)
            session:UpdateRates()
            PerHour.Dashboard:RequestRefresh()
        end)
    end
end
