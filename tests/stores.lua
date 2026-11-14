-- Store contracts run through tests/forever.lua, which supplies the addon and assertion counter.
return function(equal)
    local account, character = PerHourAccount_Settings, PerHourCharacter_Values
    local settings, sessions = PerHour.Stores.Settings, PerHour.Stores.Sessions
    local xp, honor, rep = PerHour.Modules.Experience, PerHour.Modules.Honor, PerHour.Modules.Reputation

    PerHourAccount_Settings = false
    settings:Init()
    equal(xp.Settings:Get("isShown"), false, "malformed settings root recovers defaults")
    equal(xp.Settings:Get("rate"), "hour", "missing rate defaults to hourly display")
    equal(settings:GetMinimapAngle(), math.rad(225), "missing minimap recovers default angle")

    PerHourAccount_Settings = {
        minimap = { angle = 0 },
        Experience = { isShown = false, rate = "minute", position = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0 } },
        Honor = { isShown = true, rate = "day" },
        Reputation = "invalid",
        futureSetting = "preserved",
    }
    local loaded = PerHourAccount_Settings
    settings:Init()
    settings:Init()
    equal(PerHourAccount_Settings, loaded, "settings initialization preserves the saved table")
    equal(settings:GetMinimapAngle(), 0, "zero angle survives initialization")
    equal(xp.Settings:Get("isShown"), false, "false visibility survives initialization")
    equal(xp.Settings:Get("rate"), "minute", "saved minute rate survives initialization")
    equal(honor.Settings:Get("rate"), "hour", "invalid saved rate recovers hourly display")
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
    equal(rep.Settings:Get("isShown"), false, "XP settings do not change reputation settings")
    equal(honor.Settings:Get("position"), nil, "XP position does not change honor position")
    rep.Settings:Set("rate", "minute")
    equal(rep.Settings:Get("rate"), "minute", "rate preference is written per module")
    equal(honor.Settings:Get("rate"), "hour", "reputation rate does not change honor rate")
    equal(pcall(function() rep.Settings:Set("rate", "day") end), false, "invalid rate write is rejected")
    equal(rep.Settings:Get("rate"), "minute", "rejected rate write preserves the previous value")
    equal(pcall(function() xp.Settings:Set("isShown", 1) end), false, "invalid visibility is rejected")
    equal(pcall(function() xp.Settings:Set("position", { x = 1, y = 2 }) end), false, "invalid position is rejected")
    equal(xp.Settings:Get("position").x, 25, "rejected writes preserve the previous setting")
    equal(pcall(function() settings:SetMinimapAngle(math.huge) end), false, "nonfinite angle writes are rejected")

    for _, invalid in ipairs({ false, "bad", math.huge, 0 / 0 }) do
        PerHourAccount_Settings.minimap.angle = invalid
        PerHourAccount_Settings.Experience.isShown = invalid
        PerHourAccount_Settings.Experience.rate = invalid
        PerHourAccount_Settings.Experience.position = { point = "INVALID", relativePoint = "CENTER", x = 0, y = 0 }
        settings:Init()
        equal(settings:GetMinimapAngle(), math.rad(225), "invalid saved angle recovers default")
        equal(xp.Settings:Get("isShown"), false, "invalid saved visibility recovers default")
        equal(xp.Settings:Get("rate"), "hour", "invalid saved rate recovers default")
        equal(xp.Settings:Get("position"), nil, "invalid saved anchor is discarded")
        equal(honor.Settings:Get("isShown"), true, "settings repair preserves another module")
    end
    PerHourAccount_Settings.minimap = "bad"
    PerHourAccount_Settings.Experience.position = { point = "TOPLEFT", relativePoint = "CENTER", x = math.huge, y = 0 }
    settings:Init()
    equal(settings:GetMinimapAngle(), math.rad(225), "malformed minimap settings recover defaults")
    equal(xp.Settings:Get("position"), nil, "nonfinite saved coordinates are discarded")

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
end
