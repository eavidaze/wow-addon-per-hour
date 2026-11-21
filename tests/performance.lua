-- Integration regressions for runtime work and tracking boundaries. Run via forever.lua.
return function(test)
    local equal, near = test.equal, test.near
    local tick, event, click = test.tick, test.event, test.click
    local function spy(object, method)
        local original, calls = object[method], 0
        object[method] = function(...)
            calls = calls + 1
            return original(...)
        end
        return function() return calls end, function() object[method] = original end
    end
    local function showAll()
        for _, module in pairs(PerHour.Modules) do
            module.Settings:Set("isShown", true)
            module.View.Frame:Show()
        end
    end

    test.fresh()
    showAll()
    equal(test.timers(), 0, "idle trackers have no runtime timer")
    equal(test.updates(), 0, "visible idle panels have no per-frame callbacks")
    local xp, honor, rep = PerHour.Modules.Experience, PerHour.Modules.Honor, PerHour.Modules.Reputation
    for _, module in ipairs({xp, honor, rep}) do
        equal(module.View.TrackerFrame:GetScript("OnUpdate"), nil, module.Name .. " has no per-frame tracker")
        click(module)
    end
    equal(test.timers(), 1, "three running trackers share one timer")
    for _ = 1, 10 do BaseModule:RefreshDisplayedValues(xp) end
    equal(test.timers(), 1, "repeated refreshes cannot duplicate the timer")

    -- Bursts are captured immediately, but the rate display still refreshes at one-second intervals.
    local texts, restoreText = spy(xp.View.RateValue, "SetText")
    test.progress({xp = 130, reputation = 20})
    event("PLAYER_XP_UPDATE", "pet")
    event("PLAYER_XP_UPDATE", {secret = true})
    equal(xp.State.Element, 0, "XP events for other or unreadable units are ignored")
    event("PLAYER_XP_UPDATE", "player")
    event("UPDATE_FACTION")
    equal(xp.State.Element, 30, "XP event captures a gain before the next timer")
    equal(rep.State.Element, 20, "faction event captures a gain before the next timer")
    for _ = 1, 10 do
        event("PLAYER_XP_UPDATE", "player")
        event("UPDATE_FACTION")
    end
    equal(xp.State.Element, 30, "repeated XP events do not duplicate gains")
    equal(rep.State.Element, 20, "repeated faction events do not duplicate gains")
    equal(texts(), 0, "event bursts do not redraw the rate display")
    tick(1)
    equal(xp.State.Element, 30, "fallback sample does not recount event XP")
    equal(rep.State.Element, 20, "fallback sample does not recount event reputation")
    equal(xp.View.RateValue:GetText(), "108,000", "timer displays the current hourly rate")
    equal(test.timers(), 1, "timer reschedules only one callback")
    restoreText()

    -- Handle a level-up whose XP and level APIs update in separate events.
    test.progress({xp = 0})
    event("PLAYER_XP_UPDATE", "player")
    equal(xp.State.Element, 30, "incomplete level-up snapshot is ignored")
    test.progress({xp = 50, maximum = 900, level = 11})
    event("PLAYER_XP_UPDATE", "player")
    equal(xp.State.Element, 950, "complete level-up snapshot includes the remaining previous level")
    tick(1)
    equal(xp.State.Element, 950, "timer does not recount a level-up event")

    -- Paused modules still establish fresh snapshots; resuming excludes all paused gains.
    click(xp)
    click(rep)
    local xpTotal, repTotal = xp.State.Element, rep.State.Element
    test.progress({xp = 100, reputation = 50})
    event("PLAYER_XP_UPDATE", "player")
    event("UPDATE_FACTION")
    tick(2)
    equal(xp.State.Element, xpTotal, "paused XP events and timer exclude gains")
    equal(rep.State.Element, repTotal, "paused reputation events and timer exclude gains")
    test.progress({xp = 150, reputation = 70}) -- No event before Resume.
    click(xp)
    click(rep)
    tick(1)
    equal(xp.State.Element, xpTotal, "resume snapshot excludes XP received without an event during pause")
    equal(rep.State.Element, repTotal, "resume snapshot excludes reputation received during pause")
    test.progress({xp = 175, reputation = 80})
    event("PLAYER_XP_UPDATE", "player")
    event("UPDATE_FACTION")
    tick(1)
    equal(xp.State.Element, xpTotal + 25, "resumed XP is counted exactly once")
    equal(rep.State.Element, repTotal + 10, "resumed reputation is counted exactly once")

    -- Hidden presentation is deferred, including gauge color and scale changes.
    PerHour.Stores.Settings:SetSpeedometerEnabled(true)
    PerHour.TrackerPanels:RefreshDisplays()
    local gauge = xp.View.Speedometer
    local rotations, restoreRotation = spy(gauge.Needle, "SetRotation")
    local shadowRotations, restoreShadowRotation = spy(gauge.NeedleShadow, "SetRotation")
    local hiddenTexts, restoreHiddenText = spy(xp.View.RateValue, "SetText")
    xp.View.Frame:Hide()
    equal(gauge.EffectActive, false, "hiding the parent stops native overload")
    if gauge.OverloadShadowAnimation then
        equal(gauge.OverloadShadowAnimation:IsPlaying(), false, "hiding the parent stops the native shadow")
    end
    test.progress({xp = 300})
    event("PLAYER_XP_UPDATE", "player")
    tick(2)
    equal(xp.State.Element, xpTotal + 150, "hidden panel still captures XP")
    equal(hiddenTexts(), 0, "hidden runtime updates do not set rate text")
    equal(rotations(), 0, "hidden runtime updates do not rotate the gauge")
    equal(shadowRotations(), 0, "hidden runtime updates do not rotate the shadow")
    xp.View.Frame:Show()
    equal(xp.View.RateValue:GetText(), Utils:DisplayRoundedNumber(xp.State.ElementPerHour, 0),
        "showing the panel synchronizes its latest rate")
    near(gauge.Fraction, math.min(1, xp.State.ElementPerHour / gauge.Maximum), "showing synchronizes the gauge")
    equal(gauge.EffectActive, gauge.Overloaded, "showing the parent synchronizes native overload")
    restoreHiddenText()
    restoreRotation()
    restoreShadowRotation()

    -- Screen loading suspends sampling; world entry restarts the same scheduler.
    event("PLAYER_LEAVING_WORLD")
    local beforeLoading = xp.State.Element
    test.progress({xp = 0, maximum = 0, level = 0})
    event("PLAYER_XP_UPDATE", "player")
    tick(20)
    equal(xp.State.Element, beforeLoading, "loading screens cannot alter XP totals")
    equal(test.timers(), 0, "scheduler stops outside the world")
    test.progress({xp = 300, maximum = 900, level = 11})
    event("PLAYER_ENTERING_WORLD")
    equal(test.timers(), 1, "world entry restarts one shared timer")
    tick(1)
    equal(xp.State.Element, beforeLoading, "returning to the world does not recount XP")
    for _, module in ipairs({xp, honor, rep}) do BaseModule:ResetModule(module) end
    tick(1)
    equal(test.timers(), 0, "resetting every session drains the last timer without rescheduling")
    click(honor)
    click(honor)
    tick(1)
    equal(test.timers(), 0, "paused event-only honor needs no periodic timer")
    click(honor)
    equal(test.timers(), 1, "resuming honor restarts the timer")
    BaseModule:ResetModule(honor)
    tick(1)

    -- An unchanged rendered number is free even if its fractional rate changes.
    local rate = PerHour.Components:CreateRateDisplay(xp.View.DisplayContent, "XP/h")
    rate:SetRate(123.1, "XP/h")
    local rateTexts, restoreRateText = spy(rate.Value, "SetText")
    local widths, restoreWidths = spy(rate.Value, "GetStringWidth")
    rate:SetRate(123.4, "XP/h")
    equal(rateTexts(), 0, "same rounded value avoids text writes")
    equal(widths(), 0, "same rounded value avoids width measurements")
    rate:SetRate(123.6, "XP/h")
    equal(rate.Value:GetText(), "124", "crossing the rounding boundary refreshes text")
    rate:SetRate(123.6, "XP/min")
    equal(rate.Unit:GetText(), "XP/min", "a unit change invalidates the presentation cache")
    local originalWidth = xp.View.DisplayContent:GetWidth()
    xp.View.DisplayContent:SetWidth(40)
    local beforeResize = rateTexts()
    rate:SetRate(123.6, "XP/min")
    equal(rateTexts() > beforeResize, true, "resizing invalidates the presentation cache")
    xp.View.DisplayContent:SetWidth(originalWidth)
    restoreRateText()
    restoreWidths()
    rate:Hide()

    local statusTexts, restoreStatusText = spy(xp.View.ToggleStartButton, "SetText")
    for _ = 1, 10 do BaseModule:RefreshDisplayedValues(xp) end
    equal(statusTexts(), 0, "unchanged tracking state never triggers footer layout")
    restoreStatusText()
    gauge:SetRate(60000, 50000)
    equal(gauge.OverloadAnimation:IsPlaying(), true, "overload runs a native animation")
    local plays = gauge.OverloadAnimation.playCount
    local staticRotations, restoreStatic = spy(gauge.Needle, "SetRotation")
    local staticShadows, restoreStaticShadow = spy(gauge.NeedleShadow, "SetRotation")
    local colors, restoreColors = spy(gauge.Needle, "SetVertexColor")
    for _, fps in ipairs({60, 144}) do
        for _ = 1, fps * 2 do tick(1 / fps) end
        equal(test.updates(), 0, "native overload has zero Lua frame callbacks at " .. fps .. " FPS")
        equal(staticRotations(), 0, "native overload never repeats Lua rotations at " .. fps .. " FPS")
        equal(staticShadows(), 0, "native shadow never repeats Lua rotations at " .. fps .. " FPS")
    end
    gauge:SetRate(70000, 50000)
    equal(staticRotations(), 0, "different overflow values share the same rotation")
    equal(colors(), 0, "unchanged overload state does not repeat its color")
    equal(gauge.OverloadAnimation.playCount, plays, "unchanged overload never restarts its native cycle")
    equal(test.timers(), 0, "native overload schedules no Lua timers")
    gauge:SetRate(50000, 50000)
    equal(colors(), 1, "leaving overload updates only the needle color")
    equal(gauge.OverloadAnimation:IsPlaying(), false, "leaving overload stops native motion")
    restoreStatic()
    restoreStaticShadow()
    restoreColors()

    -- Dragging uses geometry only when the cursor changes and persists once on release/hide.
    local frame = xp.View.Frame
    local saves, restoreSaves = spy(xp.Settings, "Set")
    local original = PerHourCharacter_Settings.Experience.position
    test.cursor(400, 400)
    frame.scripts.OnDragStart(frame)
    for _ = 1, 20 do frame.scripts.OnUpdate(frame) end
    equal(saves(), 0, "stationary dragging does not save settings")
    test.cursor(420, 410)
    frame.scripts.OnUpdate(frame)
    equal(PerHourCharacter_Settings.Experience.position, original, "dragging preserves saved position until release")
    equal(saves(), 0, "moving a panel does not allocate saved positions per frame")
    frame.scripts.OnDragStop(frame)
    equal(saves(), 1, "releasing a moved panel saves exactly once")
    equal(frame:GetScript("OnUpdate"), nil, "release stops cursor tracking")
    equal(xp.Settings:Get("position").x, frame:GetLeft(), "release saves the actual resolved X")
    test.cursor(420, 410)
    frame.scripts.OnDragStart(frame)
    test.cursor(440, 420)
    frame.scripts.OnUpdate(frame)
    frame:Hide()
    equal(saves(), 2, "hiding during a drag also saves the final position")
    equal(frame:GetScript("OnUpdate"), nil, "hiding during drag releases the callback")
    equal(xp.Settings:Get("position").x, frame:GetLeft(), "hiding a dragged panel saves its final X")
    restoreSaves()

    local minimap = PerHour.MinimapButton
    local angleSaves, restoreAngleSaves = spy(PerHour.Stores.Settings, "SetMinimapAngle")
    test.cursor(500, 200)
    minimap.scripts.OnDragStart(minimap)
    minimap.scripts.OnUpdate(minimap)
    local nativeUpdate = minimap:GetScript("OnUpdate")
    equal(debug.getinfo(nativeUpdate, "S").source:find("src/libs/LibDBIcon-1.0/", 1, true) ~= nil, true,
        "minimap dragging uses LibDBIcon's own update callback")
    for _ = 1, 20 do minimap.scripts.OnUpdate(minimap) end
    equal(minimap:GetScript("OnUpdate"), nativeUpdate, "addon does not replace the library's drag callback")
    equal(angleSaves(), 0, "minimap movement does not persist settings per frame")
    test.cursor(200, 500)
    minimap.scripts.OnUpdate(minimap)
    minimap.scripts.OnDragStop(minimap)
    equal(angleSaves(), 1, "minimap release persists its final angle once")
    equal(minimap:GetScript("OnUpdate"), nil, "minimap release stops cursor tracking")
    test.cursor(500, 200)
    minimap.scripts.OnDragStart(minimap)
    minimap.scripts.OnUpdate(minimap)
    minimap:Hide()
    equal(angleSaves(), 2, "hiding a dragged minimap button persists its angle")
    equal(minimap:GetScript("OnUpdate"), nil, "hiding the minimap button stops cursor tracking")
    minimap:Show()
    restoreAngleSaves()

    frame:Show()
    test.cursor(400, 400)
    frame.scripts.OnDragStart(frame)
    test.cursor(450, 420)
    frame.scripts.OnUpdate(frame)
    minimap.scripts.OnDragStart(minimap)
    test.cursor(200, 500)
    minimap.scripts.OnUpdate(minimap)
    local finalAngle = math.rad(minimap.db.minimapPos)
    event("PLAYER_LOGOUT")
    equal(xp.Settings:Get("position").x, frame:GetLeft(), "logout preserves a panel drag before release")
    equal(PerHour.Stores.Settings:GetMinimapAngle(), finalAngle, "logout preserves a minimap drag before release")
    frame.scripts.OnDragStop(frame)
    minimap.scripts.OnDragStop(minimap)

    for _, fps in ipairs({60, 144}) do
        test.fresh()
        showAll()
        local experience = PerHour.Modules.Experience
        PerHour.Stores.Settings:SetSpeedometerEnabled(true)
        PerHour.TrackerPanels:RefreshDisplays()
        for _, module in pairs(PerHour.Modules) do click(module) end
        experience.State.Element = 1000000
        tick(1)
        local overload = experience.View.Speedometer
        equal(overload.Overloaded, true, "benchmark begins above the gauge maximum")
        equal(overload.OverloadAnimation:IsPlaying(), true, "benchmark includes active native overload")
        local playCount = overload.OverloadAnimation.playCount
        local samples, restoreSamples = spy(experience, "CustomOnUpdate")
        local turns, restoreTurns = spy(overload.Needle, "SetRotation")
        local shadowTurns, restoreShadowTurns = spy(overload.NeedleShadow, "SetRotation")
        local maximumCallbacks = 0
        for _ = 1, fps * 18 do
            tick(1 / fps)
            maximumCallbacks = math.max(maximumCallbacks, test.updates())
        end
        equal(maximumCallbacks, 0, "three running panels and overload have no frame callbacks at " .. fps .. " FPS")
        equal(turns(), 0, "running overload repeats no Lua rotations at " .. fps .. " FPS")
        equal(shadowTurns(), 0, "running overload repeats no Lua shadow rotations at " .. fps .. " FPS")
        equal(overload.OverloadAnimation.playCount, playCount, "rate refreshes preserve the native overload cycle")
        equal(samples() >= 17 and samples() <= 18, true, "sampling stays near one second at " .. fps .. " FPS")
        equal(test.timers(), 1, "running benchmark retains exactly one timer at " .. fps .. " FPS")
        restoreSamples()
        restoreTurns()
        restoreShadowTurns()
    end

    local experience, reputation = PerHour.Modules.Experience, PerHour.Modules.Reputation
    local originalSample, originalHandler = experience.CustomOnUpdate, geterrorhandler
    local errors = 0
    geterrorhandler = function()
        return function(message)
            equal(message:find("simulated unavailable API", 1, true) ~= nil, true, "sample error reaches the client handler")
            errors = errors + 1
        end
    end
    experience.CustomOnUpdate = function() error("simulated unavailable API") end
    test.progress({xp = 150, reputation = 10})
    tick(1)
    equal(errors, 1, "one module error is reported once per sample")
    equal(reputation.State.Element, 10, "another tracker still samples after an earlier module fails")
    equal(test.timers(), 1, "module errors cannot cancel the shared scheduler")
    experience.CustomOnUpdate = originalSample
    tick(1)
    equal(experience.State.Element, 1000050, "sampling recovers after a temporary API failure")
    geterrorhandler = originalHandler
end
