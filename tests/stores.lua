-- Store contracts run through tests/forever.lua, which supplies the addon and assertion counter.
return function(equal)
    local account, character = PerHourAccount_Settings, PerHourCharacter_Values
    local characterSettings = PerHourCharacter_Settings
    local settings, sessions = PerHour.Stores.Settings, PerHour.Stores.Sessions
    local xp, honor, rep = PerHour.Modules.Experience, PerHour.Modules.Honor, PerHour.Modules.Reputation

    PerHourAccount_Settings = false
    PerHourCharacter_Settings = false
    settings:Init()
    equal(xp.Settings:Get("isShown"), false, "malformed settings root recovers defaults")
    equal(settings:GetRate(), "hour", "missing shared rate defaults to hourly display")
    equal(settings:GetSpeedometerEnabled(), false, "missing speedometer preference defaults to disabled")
    equal(settings:GetSpeedometerLevel(), 5, "missing speedometer level defaults to five")
    equal(settings:GetSpeedometerMaximum("hour"), 50000, "missing hourly maximum defaults to 50000")
    equal(settings:GetSpeedometerMaximum("minute"), 800, "missing minute maximum defaults to 800")
    equal(settings:GetMinimapAngle(), math.rad(225), "missing minimap recovers default angle")

    for _, fixture in ipairs({
        { rates = { "minute", "minute", "minute" }, expected = "minute" },
        { rates = { "hour", "hour", "hour" }, expected = "hour" },
        { rates = { "minute", "hour", "minute" }, expected = "hour" },
        { rates = { "minute", "invalid", "minute" }, expected = "hour" },
        { rates = { "minute", "minute" }, expected = "hour" },
    }) do
        PerHourAccount_Settings = {
            Experience = { rate = fixture.rates[1] }, Honor = { rate = fixture.rates[2] },
            Reputation = { rate = fixture.rates[3] },
        }
        PerHourCharacter_Settings = {}
        settings:Init()
        equal(settings:GetRate(), fixture.expected, "legacy rates migrate by agreement with an hourly fallback")
        equal(PerHourAccount_Settings.Experience.rate, fixture.rates[1], "migration preserves account preferences for other characters")
        local chosen = fixture.expected == "hour" and "minute" or "hour"
        settings:SetRate(chosen)
        settings:Init()
        equal(settings:GetRate(), chosen, "initialization does not repeat migration over a character preference")
    end

    PerHourAccount_Settings = {
        minimap = { angle = 0 },
        Experience = { isShown = false, rate = "minute", position = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 } },
        Honor = { isShown = true, rate = "day" },
        Reputation = "invalid",
        futureSetting = "preserved",
    }
    PerHourCharacter_Settings = nil
    local loaded = PerHourAccount_Settings
    settings:Init()
    equal(honor.Settings:Get("isShown"), false, "previous account visibility is ignored")
    equal(settings:GetRate(), "hour", "conflicting or malformed account rates migrate to hourly display")
    equal(xp.Settings:Get("position"), nil, "previous account position is ignored")
    equal(settings:GetMinimapAngle(), math.rad(225), "previous account minimap angle is ignored")
    PerHourCharacter_Settings = {
        rate = "minute",
        minimap = { angle = 0 },
        Experience = { isShown = false, position = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 } },
        Honor = { isShown = true },
        Reputation = "invalid",
    }
    local loadedSettings = PerHourCharacter_Settings
    settings:Init()
    settings:Init()
    equal(PerHourAccount_Settings, loaded, "settings initialization preserves the saved table")
    equal(PerHourCharacter_Settings, loadedSettings, "settings initialization preserves the character table")
    equal(settings:GetMinimapAngle(), 0, "zero angle survives initialization")
    equal(xp.Settings:Get("isShown"), false, "false visibility survives initialization")
    equal(settings:GetRate(), "minute", "saved character rate survives initialization")
    equal(loaded.Honor.rate, "day", "initialization leaves legacy account rates untouched")
    equal(xp.Settings:Get("position").x, 0, "zero coordinates survive initialization")
    equal(honor.Settings:Get("isShown"), true, "valid neighbor survives malformed module settings")
    equal(rep.Settings:Get("isShown"), false, "malformed module settings recover defaults")
    equal(PerHourAccount_Settings.futureSetting, "preserved", "unrelated settings are preserved")

    local position = { point = "TOPLEFT", relativePoint = "BOTTOMLEFT", x = 25, y = 50 }
    xp.Settings:Set("position", position)
    position.x = 999
    equal(xp.Settings:Get("position").x, 25, "position writes do not retain the caller's table")
    local returned = xp.Settings:Get("position")
    returned.y = 999
    equal(xp.Settings:Get("position").y, 50, "position reads cannot mutate saved settings")
    xp.Settings:Set("isShown", true)
    equal(loaded.Experience.isShown, false, "visibility writes preserve the legacy account preference")
    equal(loaded.Experience.position.x, 0, "position writes preserve the legacy account preference")
    settings:SetMinimapAngle(1)
    equal(loaded.minimap.angle, 0, "minimap writes preserve the legacy account preference")
    equal(rep.Settings:Get("isShown"), false, "XP settings do not change reputation settings")
    equal(honor.Settings:Get("position"), nil, "XP position does not change honor position")
    settings:SetRate("minute")
    equal(settings:GetRate(), "minute", "shared rate is written for the character")
    equal(loadedSettings.rate, "minute", "rate uses the character settings root")
    equal(loaded.rate, nil, "rate writes do not add an account preference")
    equal(pcall(function() settings:SetRate("day") end), false, "invalid shared rate write is rejected")
    equal(settings:GetRate(), "minute", "rejected rate write preserves the previous value")
    equal(pcall(function() rep.Settings:Get("rate") end), false, "module handles do not expose a misleading independent rate")
    equal(pcall(function() xp.Settings:Set("isShown", 1) end), false, "invalid visibility is rejected")
    equal(pcall(function() xp.Settings:Set("position", { x = 1, y = 2 }) end), false, "invalid position is rejected")
    equal(xp.Settings:Get("position").x, 25, "rejected writes preserve the previous setting")
    equal(pcall(function() settings:SetMinimapAngle(math.huge) end), false, "nonfinite angle writes are rejected")
    settings:SetSpeedometerEnabled(true)
    settings:SetSpeedometerLevel(10)
    settings:Init()
    equal(settings:GetSpeedometerEnabled(), true, "saved speedometer preference survives initialization")
    equal(settings:GetSpeedometerMaximum("hour"), 100000, "one level selects the hourly upper bound")
    equal(settings:GetSpeedometerMaximum("minute"), 1600, "minute maximum accepts its upper bound")
    equal(loaded.speedometer, nil, "speedometer preferences are not written to the account")
    equal(pcall(function() settings:SetSpeedometerEnabled(1) end), false, "speedometer toggle rejects nonboolean values")
    for _, invalid in ipairs({ 0, 11, math.huge, -math.huge, 0 / 0, "5", 5.5, false }) do
        equal(pcall(function() settings:SetSpeedometerLevel(invalid) end), false, "invalid speedometer level is rejected")
        equal(settings:GetSpeedometerLevel(), 10, "rejected level preserves the selection")
    end
    equal(pcall(function() settings:GetSpeedometerMaximum("day") end), false, "unknown maximum rate is rejected")
    PerHourCharacter_Settings.speedometer = { enabled = "bad", level = "bad" }
    settings:Init()
    equal(settings:GetSpeedometerEnabled(), false, "malformed speedometer toggle recovers its default")
    equal(settings:GetSpeedometerMaximum("hour"), 50000, "invalid saved level resolves the default hourly maximum")
    equal(settings:GetSpeedometerMaximum("minute"), 800, "invalid saved level resolves the default minute maximum")

    local speedometer = PerHourCharacter_Settings.speedometer
    PerHourCharacter_Settings.speedometer = { enabled = true, hour = 100000, minute = 1600 }
    settings:Init()
    equal(settings:GetSpeedometerLevel(), 5, "previous independent maxima do not migrate into the level")
    equal(settings:GetSpeedometerEnabled(), true, "defaulting the level preserves the current toggle")
    PerHourCharacter_Settings.speedometer = speedometer
    for _, invalid in ipairs({ false, 0, 11, 5.5, math.huge, 0 / 0 }) do
        PerHourCharacter_Settings.speedometer.level = invalid
        settings:Init()
        equal(settings:GetSpeedometerLevel(), 5, "malformed saved level recovers the default")
    end
    local expectedMinutes = { 160, 320, 480, 640, 800, 960, 1100, 1300, 1400, 1600 }
    for level, minute in ipairs(expectedMinutes) do
        settings:SetSpeedometerLevel(level)
        settings:SetRate("minute")
        equal(settings:GetSpeedometerMaximum("minute"), minute, "level resolves its agreed minute maximum")
        settings:SetRate("hour")
        equal(settings:GetSpeedometerLevel(), level, "switching units preserves the single level")
        equal(settings:GetSpeedometerMaximum("hour"), level * 10000, "level resolves its rounded hourly maximum")
        equal(PerHourCharacter_Settings.speedometer.hour, nil, "hourly maximum is derived instead of saved")
        equal(PerHourCharacter_Settings.speedometer.minute, nil, "minute maximum is derived instead of saved")
    end

    for _, invalid in ipairs({ false, "bad", math.huge, 0 / 0 }) do
        PerHourCharacter_Settings.minimap.angle = invalid
        PerHourCharacter_Settings.Experience.isShown = invalid
        PerHourCharacter_Settings.rate = invalid
        PerHourCharacter_Settings.Experience.position = { point = "INVALID", relativePoint = "CENTER", x = 0, y = 0 }
        settings:Init()
        equal(settings:GetMinimapAngle(), math.rad(225), "invalid saved angle recovers default")
        equal(xp.Settings:Get("isShown"), false, "invalid saved visibility recovers default")
        equal(settings:GetRate(), "hour", "invalid saved character rate recovers default")
        equal(xp.Settings:Get("position"), nil, "invalid saved anchor is discarded")
        equal(honor.Settings:Get("isShown"), true, "settings repair preserves another module")
    end
    PerHourCharacter_Settings.minimap = "bad"
    PerHourCharacter_Settings.Experience.position = { point = "TOPLEFT", relativePoint = "CENTER", x = math.huge, y = 0 }
    settings:Init()
    equal(settings:GetMinimapAngle(), math.rad(225), "malformed minimap settings recover defaults")
    equal(xp.Settings:Get("position"), nil, "nonfinite saved coordinates are discarded")

    -- Layout, display rate and gauge preferences are independent between characters.
    local firstCharacter = PerHourCharacter_Settings
    settings:SetRate("minute")
    settings:SetSpeedometerEnabled(true)
    settings:SetSpeedometerLevel(8)
    PerHourCharacter_Settings = {
        minimap = { angle = 0 },
        Honor = { isShown = false, position = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 } },
        futureSetting = "preserved",
    }
    local secondCharacter = PerHourCharacter_Settings
    settings:Init()
    equal(settings:GetRate(), "hour", "another character has its own migrated rate")
    equal(settings:GetSpeedometerEnabled(), false, "another character starts with the gauge disabled")
    equal(settings:GetSpeedometerMaximum("minute"), 800, "another character has its own dial maximum")
    settings:SetSpeedometerLevel(4)
    equal(honor.Settings:Get("isShown"), false, "initialization preserves a character's existing false preference")
    equal(honor.Settings:Get("position").x, 0, "initialization preserves an existing character position")
    equal(settings:GetMinimapAngle(), 0, "initialization preserves an existing zero character angle")
    equal(secondCharacter.futureSetting, "preserved", "initialization preserves unrelated character settings")
    equal(xp.Settings:Get("position"), nil, "another character has no position for an unconfigured panel")
    honor.Settings:Set("position", nil)
    settings:Init()
    equal(honor.Settings:Get("isShown"), false, "initialization preserves hidden character visibility")
    equal(honor.Settings:Get("position"), nil, "initialization preserves a cleared character position")
    xp.Settings:Set("position", { point = "CENTER", relativePoint = "CENTER", x = 10, y = 20 })
    settings:Init()
    equal(xp.Settings:Get("position").x, 10, "initialization preserves another character's panel position")
    settings:SetRate("hour")
    settings:SetMinimapAngle(0.5)
    PerHourCharacter_Settings = firstCharacter
    settings:Init()
    equal(honor.Settings:Get("isShown"), true, "switching characters restores its own visibility")
    equal(settings:GetSpeedometerEnabled(), true, "switching characters restores its own gauge preference")
    equal(settings:GetSpeedometerLevel(), 8, "switching characters restores its own dial level")
    equal(settings:GetSpeedometerMaximum("minute"), 1300, "switching characters derives its own dial maximum")
    equal(secondCharacter.speedometer.level, 4, "another character's dial level is preserved")
    equal(xp.Settings:Get("position"), nil, "another character's panel movement leaves the first character unchanged")
    equal(settings:GetMinimapAngle(), math.rad(225), "switching characters restores its own minimap angle")
    equal(settings:GetRate(), "minute", "returning restores the first character rate")
    equal(secondCharacter.rate, "hour", "the second character retains its own rate")
    equal(secondCharacter.minimap.angle, 0.5, "initializing one character preserves the other's minimap angle")

    PerHourCharacter_Values = { version = 1, sessions = { Experience = { total = 0, duration = 0, paused = false } } }
    loaded = PerHourCharacter_Values
    sessions:Init()
    equal(PerHourCharacter_Values, loaded, "supported legacy sessions remain intact at initialization")
    equal(xp.Store:ReadSession().total, 0, "zero legacy total is readable")
    equal(xp.Store:ReadSession().paused, false, "legacy running choice is readable")

    local snapshots = {
        Experience = { total = 100, duration = 10, paused = false },
        Honor = { total = 25, duration = 5, paused = true },
        Reputation = { total = -50, duration = 10, paused = false, context = { factionID = 72, name = "Stormwind" } },
    }
    sessions:SaveAll(snapshots, 100000)
    equal(PerHourCharacter_Settings, firstCharacter, "saving sessions preserves the separate character settings")
    equal(PerHourCharacter_Values.version, 2, "batch save writes the current version")
    equal(sessions:GetPlayedAtSave(), 100000, "batch save uses one played-time reference")
    snapshots.Experience.total = 999
    snapshots.Reputation.context.name = "changed"
    equal(xp.Store:ReadSession().total, 100, "batch writes detach module snapshots")
    equal(rep.Store:ReadSession().context.name, "Stormwind", "batch writes detach module context")
    returned = rep.Store:ReadSession()
    returned.context.name = "changed again"
    returned.total = 999
    equal(rep.Store:ReadSession().context.name, "Stormwind", "session reads detach nested context")
    equal(rep.Store:ReadSession().total, -50, "session reads preserve negative reputation totals")

    honor.Store:ClearSession()
    equal(honor.Store:ReadSession(), nil, "clearing honor removes only its session")
    equal(xp.Store:ReadSession().total, 100, "clearing honor preserves XP")
    equal(rep.Store:ReadSession().total, -50, "clearing honor preserves reputation")
    equal(sessions:GetPlayedAtSave(), 100000, "clearing one session preserves the shared reference")
    equal(honor.Settings:Get("isShown"), true, "clearing a session preserves its settings")

    PerHourCharacter_Values.sessions.Honor = { total = 10, duration = -1, paused = false }
    local data, invalid = honor.Store:ReadSession()
    equal(data, nil, "invalid sessions are not restored")
    equal(invalid, true, "invalid sessions remain distinguishable from absent sessions")
    equal(xp.Store:ReadSession().total, 100, "invalid honor does not invalidate XP")
    loaded = PerHourCharacter_Values
    equal(pcall(function() sessions:SaveAll({ Experience = { total = math.huge } }, 1) end), false,
        "invalid batch is rejected")
    equal(PerHourCharacter_Values, loaded, "rejected batches preserve the previous save")

    for _, invalidRoot in ipairs({ false, "bad", { version = 99, sessions = {} }, { version = 2, sessions = false } }) do
        PerHourCharacter_Values = invalidRoot
        sessions:Init()
        equal(xp.Store:ReadSession(), nil, "unsupported session root starts empty")
        equal(sessions:GetPlayedAtSave(), nil, "unsupported session root has no played-time reference")
    end

    PerHourAccount_Settings, PerHourCharacter_Values = account, character
    PerHourCharacter_Settings = characterSettings
end
