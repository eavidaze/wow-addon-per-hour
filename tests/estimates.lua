-- Goal estimates in the simulated client, run through forever.lua with Lua 5.1.
return function(test)
    local equal, tick, event, click = test.equal, test.tick, test.event, test.click
    test.fresh()
    local xp, rep, honor = PerHour.Modules.Experience, PerHour.Modules.Reputation, PerHour.Modules.Honor
    PerHour.SettingsPanel:Show()
    local settings = PerHour.SettingsPanel
    local store = PerHour.Stores.Settings
    equal(settings.EstimatesField, settings.Frame.Fields[1].Fields[2], "estimate toggle belongs to General after Rate")
    equal(settings.EstimatesField.Label:GetText(), "Show estimates", "estimate toggle uses the interface language")
    equal(settings.EstimatesField:GetValue(), false, "panel estimates start disabled")
    equal(xp.View.EstimateText:IsShown(), false, "disabled XP estimate has no visible line")
    settings.EstimatesField.Control:Click()
    equal(store:GetEstimatesEnabled(), true, "checkbox saves estimate visibility immediately")
    for _, module in ipairs({xp, rep}) do
        local text = module.View.EstimateText
        equal(text:IsShown(), true, module.Name .. " displays its estimate below the rate")
        equal(text:GetText(), "Not started", module.Name .. " displays the current estimate status")
        equal(select(2, text:GetFont()), 10, "panel estimate uses small text")
        equal(table.concat(text.textColor, ","), table.concat(PerHour.Theme.trackerStatus.idle, ","), "idle estimate uses DS status gray")
        equal(text.justifyH, "CENTER", "panel estimate text is centered")
        equal(text.point[1], "TOP", "estimate is anchored by its top center")
        equal(text.point[2], module.View.RateFrame, "estimate is anchored to the rate")
        equal(text.point[3], "BOTTOM", "estimate appears below the rate")
        equal(text.point[4], 0, "estimate has no horizontal offset")
        equal(text.point[5], -4, "estimate leaves a small gap below the rate")
        equal(module.View.Frame:GetHeight(), 112, "estimate line has its own vertical space")
    end
    equal(honor.View.EstimateText, nil, "the shared toggle does not add an Honor estimate")
    equal(honor.View.Frame:GetHeight(), 94, "Honor keeps its compact height")
    local function hover(module)
        module.View.Frame:Show()
        module.View.Frame.scripts.OnEnter(module.View.Frame)
        local lines = GameTooltip.singleLines
        for index, text in ipairs(lines) do
            if text == "Estimate" then return lines[index + 1], index end
        end
    end
    local function assertStatusColor(module, key)
        local _, index = hover(module)
        local expected = table.concat(PerHour.Theme.trackerStatus[key], ",")
        equal(table.concat(module.View.ActiveIndicator.vertexColor, ","), expected, key .. " diamond uses DS status color")
        equal(table.concat(module.View.EstimateText.textColor, ","), expected, key .. " panel estimate matches the diamond")
        equal(table.concat(GameTooltip.singleLineColors[1], ","), expected, key .. " tooltip status matches the diamond")
        equal(table.concat(GameTooltip.singleLineColors[index + 1], ","), expected, key .. " tooltip estimate matches the diamond")
    end
    equal(hover(xp), "Not started", "idle estimate explains that tracking must start")
    assertStatusColor(xp, "idle")
    click(xp)
    equal(hover(xp), "Estimating…", "new session waits for a sample")
    assertStatusColor(xp, "running")
    test.progress({xp = 200})
    tick(59)
    equal(hover(xp), "Estimating…", "positive gains still wait for one active minute")
    tick(1)
    local estimate, index = hover(xp)
    equal(estimate, "Level 11 in 8m", "XP estimate uses remaining level progress")
    equal(xp.View.EstimateText:GetText(), estimate, "panel and tooltip share the same current prediction")
    equal(index, 3, "Estimate is the first section after the status and separator")
    equal(GameTooltip.singleLines[index + 3], "Session", "Session follows Estimate")
    equal(GameTooltip.singleLines[index + 5], "Rates", "Rates follows Session")
    PerHour.Stores.Settings:SetRate("minute")
    equal(hover(xp), "Level 11 in 8m", "display unit does not affect the prediction")
    PerHour.Stores.Settings:SetRate("hour")
    tick(60)
    equal(GameTooltip.singleLines[index + 1], "Level 11 in 16m", "open tooltip reflects idle time in the mean")
    equal(xp.View.EstimateText:GetText(), "Level 11 in 16m", "panel estimate refreshes with the shared timer")
    local originalText, writes = xp.View.EstimateText.SetText, 0
    local originalColor, colorWrites = xp.View.EstimateText.SetTextColor, 0
    xp.View.EstimateText.SetText = function(self, value) writes = writes + 1; originalText(self, value) end
    xp.View.EstimateText.SetTextColor = function(self, ...) colorWrites = colorWrites + 1; originalColor(self, ...) end
    BaseModule:RefreshDisplayedValues(xp)
    equal(writes, 0, "unchanged estimate text is not rewritten")
    equal(colorWrites, 0, "unchanged tracker status does not rewrite the estimate color")
    xp.View.EstimateText.SetText = originalText
    xp.View.EstimateText.SetTextColor = originalColor
    local height = xp.View.Frame:GetHeight()
    click(xp)
    equal(GameTooltip.singleLines[index + 1], "Paused", "pause immediately replaces the estimate")
    equal(xp.View.EstimateText:GetText(), "Paused", "pause updates the panel estimate immediately")
    assertStatusColor(xp, "paused")
    test.progress({xp = 300})
    tick(120)
    click(xp)
    equal(GameTooltip.singleLines[index + 1], "Level 11 in 14m", "resume uses live progress without paused gains or time")
    equal(xp.State.Time, 120, "estimate does not change active duration")
    equal(xp.State.Element, 100, "estimate does not count paused XP")
    assertStatusColor(xp, "running")
    xp.View.Frame:Hide()
    click(xp)
    xp.View.Frame:Show()
    assertStatusColor(xp, "paused")
    settings.EstimatesField:SetValue(false)
    click(xp)
    settings.EstimatesField:SetValue(true)
    assertStatusColor(xp, "running")
    test.progress({xp = 0})
    event("PLAYER_XP_UPDATE", "player")
    equal(hover(xp), "No estimate available", "incomplete level-up progress cannot predict the old level")
    test.progress({xp = 50, maximum = 900, level = 11})
    tick(1)
    equal(hover(xp), "Level 12 in 3m", "level-up advances the goal without resetting the average")
    equal(xp.View.Frame:GetHeight(), height, "estimates keep the tracking panel compact")
    settings.SpeedometerField:SetValue(true)
    equal(xp.View.Frame:GetHeight(), 222, "gauge and estimate can be enabled together")
    equal(xp.View.RateFrame.point[2], xp.View.Speedometer, "rate remains below the gauge")
    equal(xp.View.EstimateText:GetWidth(), xp.View.DisplayContent:GetWidth(), "estimate stays centered across the gauge width")
    settings.EstimatesField:SetValue(false)
    equal(xp.View.Frame:GetHeight(), 204, "hiding the estimate preserves the gauge")
    equal(xp.View.EstimateText:IsShown(), false, "checkbox immediately hides panel estimates")
    equal(hover(xp), "Level 12 in 3m", "panel preference leaves the tooltip estimate available")
    settings.SpeedometerField:SetValue(false)
    equal(xp.View.Frame:GetHeight(), 94, "disabling extra displays restores compact height")
    settings.EstimatesField:SetValue(true)
    equal(hover(honor), nil, "Honor has no Estimate section")
    equal(GameTooltip.singleLines[3], "Session", "Honor retains its first Session section")

    -- Known durations also catch accidental use of rounded display rates.
    for _, case in ipairs({
        { remaining = 7930, total = 60, seconds = 60, expected = "2h 13m" },
        { remaining = 60, total = 60, seconds = 60, expected = "1m" },
        { remaining = 1, total = 60, seconds = 60, expected = "1m" },
        { remaining = 3600, total = 60, seconds = 60, expected = "1h" },
        { remaining = 90000, total = 60, seconds = 60, expected = "25h" },
        { remaining = 2, total = 3, seconds = 5401, expected = "1h 1m" },
    }) do
        test.progress({xp = 100, maximum = 100 + case.remaining})
        xp.State.Time, xp.State.Element = case.seconds, case.total
        equal(hover(xp), "Level 12 in " .. case.expected, "minute rounding for " .. case.expected)
    end
    xp.State.Time = 60
    for _, total in ipairs({0, -1}) do
        xp.State.Element = total
        equal(hover(xp), "No estimate available", "nonpositive mean cannot predict a gain")
    end
    xp.State.Element = 100
    for _, value in ipairs({{secret = true}, math.huge, 0 / 0, -1}) do
        test.progress({xp = value})
        equal(hover(xp), "No estimate available", "unreadable or invalid XP suppresses the estimate")
    end
    test.progress({xp = 0, maximum = 0, level = 60})
    equal(hover(xp), "Max level reached", "maximum level does not need a positive XP bar")
    test.progress({level = 59})
    equal(hover(xp), "No estimate available", "empty XP data is not mistaken for maximum level")
    test.progress({xp = 100, maximum = 1000, level = 11})
    equal(hover(xp), "Level 12 in 9m", "valid progress restores the prediction")
    xp.State.PendingRestore = true
    equal(hover(xp), "No estimate available", "unverified restoration cannot supply an estimate")
    xp.State.PendingRestore = nil

    -- Reputation uses absolute standing thresholds, including negative standings.
    local faction = { name = "Stormwind", factionID = 72, currentStanding = 5900,
        reaction = 5, currentReactionThreshold = 3000, nextReactionThreshold = 9000 }
    test.faction(faction)
    click(rep)
    faction.currentStanding = 6000
    tick(60)
    local repEstimate, repIndex = hover(rep)
    equal(repEstimate, "Honored in 30m", "reputation predicts the next standing for the current faction")
    equal(repIndex, 4, "reputation Estimate follows status and faction context")
    faction.currentStanding = 9100
    faction.reaction, faction.currentReactionThreshold, faction.nextReactionThreshold = 6, 9000, 21000
    tick(60)
    equal(hover(rep), "Revered in 8m", "standing change advances the goal using the same session")
    faction.currentStanding, faction.reaction = -500, 3
    faction.currentReactionThreshold, faction.nextReactionThreshold = -3000, 0
    rep.State.Element, rep.State.Time = 100, 60
    equal(hover(rep), "Neutral in 5m", "negative absolute standing can still have a positive gain rate")
    rep.State.Element = -100
    equal(hover(rep), "No estimate available", "negative reputation mean has no gain estimate")
    rep.State.Element = 100
    for _, flag in ipairs({"isMajorFaction", "isParagon", "friendshipFactionID"}) do
        faction[flag] = flag == "friendshipFactionID" and 123 or true
        equal(hover(rep), "No estimate available", "special reputation is excluded: " .. flag)
        faction[flag] = nil
    end
    faction.nextReactionThreshold = nil
    equal(hover(rep), "No estimate available", "missing reputation threshold cannot supply a goal")
    faction.nextReactionThreshold = {secret = true}
    equal(hover(rep), "No estimate available", "secret reputation threshold is never compared")
    faction.nextReactionThreshold = 0
    faction.reaction = {secret = true}
    equal(hover(rep), "No estimate available", "secret standing is never used as a table key")
    faction.reaction, faction.currentStanding = 8, 42000
    equal(hover(rep), "Exalted reached", "Exalted has no further standing goal")
    test.faction(nil)
    equal(hover(rep), "No estimate available", "temporarily missing faction suppresses the prediction")
    test.faction({ name = "Ironforge", factionID = 47, currentStanding = 100,
        reaction = 4, currentReactionThreshold = 0, nextReactionThreshold = 3000 })
    equal(hover(rep), "No estimate available", "new faction cannot use the previous faction average")
    tick(1)
    equal(rep.State.HasStarted, false, "faction change keeps the existing automatic reset")
    equal(hover(rep), "Not started", "faction reset clears the estimate")
    assertStatusColor(rep, "idle")
    click(rep)
    equal(hover(rep), "Estimating…", "new faction starts its own estimation sample")
    rep.View.Frame.scripts.OnLeave()
    tick(1)
    equal(GameTooltip:IsShown(), false, "runtime estimate updates do not reopen a dismissed tooltip")
    BaseModule:ResetModule(xp)
    assertStatusColor(xp, "idle")
end
