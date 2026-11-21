return function(test)
    local equal, event, tick, click = test.equal, test.event, test.tick, test.click
    local fixture = test.fixture
    local function fresh(available)
        test.fresh()
        fixture.items[901] = { price = 10, class = 7, available = available }
        fixture.bags = { { id = 901, count = 10 } }
        local gold = PerHour.Modules.Gold
        click(gold)
        event("CHAT_MSG_LOOT", string.format(LOOT_ITEM_SELF_MULTIPLE, fixture.link(901), 10))
        return gold
    end
    local function confirm(gold, questID, quantity)
        local waiting = #gold.State.QuestDeliveries
        fixture.questID, fixture.requiredItems = questID, { { id = 901, quantity = quantity } }
        event("QUEST_PROGRESS")
        event("QUEST_TURNED_IN", questID, 0, 0)
        equal(#gold.State.QuestDeliveries, waiting + 1, "confirmed quest waits for its bag evidence")
    end
    local function pendingSave(paused)
        local gold = fresh(false)
        confirm(gold, 5001, 8)
        fixture.bags[1].count = 2
        event("BAG_UPDATE_DELAYED")
        equal(#gold.State.History, 2, "pending acquisition and delivery are both accepted")
        if paused then click(gold) end
        event("PLAYER_LOGOUT")
        fixture.requests = {}
        return test.copy(PerHourCharacter_Values)
    end

    for _, paused in ipairs({ false, true }) do
        local saved = pendingSave(paused)
        test.login(saved, 0, { autoReply = false })
        local gold = PerHour.Modules.Gold
        fixture.items[901].available = true
        event("ITEM_DATA_LOAD_RESULT", 901, true)
        equal(gold.State.History[1].pending, true, "load replies during verification cannot mutate unverified totals")
        equal(gold.State.Element, 0, "verification still owns the saved total until it finishes")
        event("TIME_PLAYED_MSG", test.playedTime(), 0)
        equal(gold.State.PendingRestore, nil, "played reply finishes session verification")
        equal(gold.State.Element, 20, "finishing restore settles the cached acquisition and its dependent expense")
        equal(gold.State.History[1].pending, nil, "cached pending receipt is resolved without another load event")
        equal(gold.State.History[2].pending, nil, "cached pending delivery is also resolved")
        equal(gold.State.HasPaused, paused, "price recovery preserves the saved pause choice")
        equal(fixture.requests[901], nil, "already cached data is settled before requesting another load")
        equal(gold.State.History[1].timestamp, saved.sessions.Gold.context.history[1].timestamp, "price recovery retains the event timestamp")
        event("GET_ITEM_INFO_RECEIVED", 901, true)
        equal(gold.State.Element, 20, "duplicate load replies cannot settle accepted values twice")
        equal(saved.sessions.Gold.context.history[1].pending, true, "cache settlement cannot rewrite the saved input fixture")
    end

    local saved = pendingSave(true)
    test.login(saved, 0)
    local gold = PerHour.Modules.Gold
    equal(fixture.requests[901], true, "unresolved native data is requested after verification")
    equal(gold.State.Element, 0, "missing cache data does not fabricate a price")
    fixture.items[901].available = true
    event("GET_ITEM_INFO_RECEIVED", 901, true)
    equal(gold.State.Element, 20, "a later load reply still settles values while paused")

    saved = pendingSave(false)
    local requestLoad = C_Item.RequestLoadItemDataByID
    C_Item.RequestLoadItemDataByID = function(itemID)
        requestLoad(itemID)
        fixture.items[itemID].available = true
        event("ITEM_DATA_LOAD_RESULT", itemID, true)
    end
    test.login(saved, 0)
    gold = PerHour.Modules.Gold
    C_Item.RequestLoadItemDataByID = requestLoad
    equal(gold.State.Element, 20, "a synchronous load reply after verification settles values exactly once")
    equal(next(gold.State.PendingPrices), nil, "synchronous replies cannot leave stale pending item IDs")

    saved = pendingSave(false)
    for _, entry in ipairs(saved.sessions.Gold.context.history) do
        entry.pricingVersion, entry.priceSource, entry.priceMetric, entry.valuations = nil, nil, nil, nil
    end
    TSM_API = { ToItemString = function() return "i:901" end,
        GetCustomPriceValue = function() return 1000 end }
    fixture.items[901].available = true
    test.login(saved, 0)
    gold = PerHour.Modules.Gold
    equal(gold.State.Element, 20, "restore retries retain the legacy vendor pricing policy")
    equal(gold.State.History[1].pricingVersion, nil, "retrying legacy prices introduces no migration")

    saved = pendingSave(false)
    test.login(saved, 0, { autoReply = false })
    gold = PerHour.Modules.Gold
    fixture.items[901].available = true
    event("TIME_PLAYED_MSG", test.playedTime() + 120, 0)
    equal(gold.State.RestoreStatus, "error", "cache settlement preserves a continuity warning")
    equal(gold.State.HasPaused, true, "an unverified restored session remains paused")
    equal(gold.State.Element, 20, "existing accepted entries can finish pricing after a continuity warning")

    pendingSave(true)
    gold = PerHour.Modules.Gold
    event("PLAYER_LEAVING_WORLD")
    fixture.items[901].available = true
    event("ITEM_DATA_LOAD_RESULT", 901, true)
    equal(gold.State.Element, 0, "load replies outside the world cannot mutate the session")
    event("PLAYER_ENTERING_WORLD")
    equal(gold.State.Element, 20, "world entry recovers a load reply lost during a loading screen")
    equal(gold.State.HasPaused, true, "world-entry recovery does not resume paused tracking")

    saved = pendingSave(false)
    test.login(saved, 0, { autoReply = false })
    gold = PerHour.Modules.Gold
    BaseModule:ResetModule(gold)
    fixture.items[901].available = true
    event("TIME_PLAYED_MSG", test.playedTime(), 0)
    event("ITEM_DATA_LOAD_RESULT", 901, true)
    equal(#gold.State.History, 0, "Reset prevents late restore/load replies from resurrecting entries")
    equal(gold.State.Element, 0, "late replies after Reset cannot restore old values")

    gold = fresh(true)
    confirm(gold, 5002, 10)
    local completedAt = GetServerTime()
    click(gold)
    equal(#gold.State.QuestDeliveries, 1, "pausing retains confirmed deliveries")
    tick(1)
    fixture.bags = {}
    event("BAG_UPDATE_DELAYED")
    equal(gold.State.Element, 0, "delayed bag evidence charges a pre-pause delivery while paused")
    equal(gold.State.HasPaused, true, "settling a confirmed delivery does not resume the run")
    equal(gold.State.History[2].timestamp, completedAt, "paused settlement keeps the original completion timestamp")
    equal(gold.State.History[2].elapsed, gold.State.History[1].elapsed, "paused settlement does not add paused time to the event")
    event("QUEST_TURNED_IN", 5003, 0, 10000)
    event("CHAT_MSG_MONEY", "You loot 1 Gold")
    event("BAG_UPDATE_DELAYED")
    equal(#gold.State.History, 2, "new paused gains and duplicate bag updates do not add journal entries")
    equal(gold.State.Element, 0, "new paused actions remain excluded")

    gold = fresh(true)
    confirm(gold, 5010, 10)
    click(gold)
    event("PLAYER_LEAVING_WORLD")
    fixture.bags = {}
    tick(1)
    event("PLAYER_ENTERING_WORLD")
    equal(gold.State.Element, 0, "world entry settles confirmed evidence already present in the inventory cache")
    equal(gold.State.HasPaused, true, "settling after world entry keeps the run paused")

    gold = fresh(true)
    fixture.bags[1].count = 20
    confirm(gold, 5004, 10)
    confirm(gold, 5005, 10)
    click(gold)
    fixture.bags[1].count = 10
    event("BAG_UPDATE_DELAYED")
    equal(#gold.State.History, 2, "one bag loss settles only one overlapping confirmed quest")
    click(gold)
    equal(#gold.State.History, 2, "resuming preserves debit allocation and cannot reuse the same loss")
    fixture.bags = {}
    event("BAG_UPDATE_DELAYED")
    equal(#gold.State.History, 3, "a second bag loss settles the remaining confirmed quest once")
    equal(gold.State.Element, -100, "twenty delivered units are charged, including old-stock remainder")

    gold = fresh(false)
    confirm(gold, 5006, 10)
    click(gold)
    fixture.bags = {}
    event("BAG_UPDATE_DELAYED")
    equal(#gold.State.History, 2, "a paused confirmed delivery may enter the pending-price journal")
    fixture.items[901].available = true
    event("ITEM_DATA_LOAD_RESULT", 901, true)
    equal(gold.State.Element, 0, "deferred delivery and acquisition prices settle together while paused")

    gold = fresh(true)
    confirm(gold, 5007, 10)
    click(gold)
    tick(3)
    fixture.bags = {}
    event("BAG_UPDATE_DELAYED")
    equal(#gold.State.History, 1, "pausing does not extend the confirmed delivery's deadline")

    gold = fresh(true)
    confirm(gold, 5008, 10)
    click(gold)
    fixture.bags = {}
    event("PLAYER_LOGOUT")
    equal(PerHourCharacter_Values.sessions.Gold.total, 0, "saving while paused reconciles confirmed delivery evidence")
    equal(#PerHourCharacter_Values.sessions.Gold.context.history, 2, "saved paused history includes the accepted delivery")

    gold = fresh(true)
    confirm(gold, 5009, 10)
    BaseModule:ResetModule(gold)
    click(gold)
    fixture.bags = {}
    event("BAG_UPDATE_DELAYED")
    equal(#gold.State.History, 0, "Reset still clears both candidates and confirmed deliveries")
end
