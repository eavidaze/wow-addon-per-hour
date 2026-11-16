local Scales = {
    DefaultLevel = 5,
    -- Hourly maxima are approximate; minute levels 7-9 are rounded to the nearest hundred.
    Levels = {
        { minute = 160, hour = 10000 },
        { minute = 320, hour = 20000 },
        { minute = 480, hour = 30000 },
        { minute = 640, hour = 40000 },
        { minute = 800, hour = 50000 },
        { minute = 960, hour = 60000 },
        { minute = 1100, hour = 70000 },
        { minute = 1300, hour = 80000 },
        { minute = 1400, hour = 90000 },
        { minute = 1600, hour = 100000 },
    },
}
PerHour.SpeedometerScales = Scales

function Scales:IsLevel(level)
    return type(level) == "number" and level == math.floor(level)
        and level >= 1 and level <= #self.Levels
end

function Scales:GetMaximum(level, rate)
    assert(self:IsLevel(level), "Invalid speedometer level")
    assert(rate == "hour" or rate == "minute", "Speedometer rate must be hour or minute")
    return self.Levels[level][rate]
end
