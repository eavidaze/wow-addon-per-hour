return function(test)
    local equal, event, tick, click = test.equal, test.event, test.tick, test.click
    local fixture, marketPrice = test.fixture, 100
    local function count()
        return fixture.bags[1] and fixture.bags[1].count or 0
    end
    local function bags(quantity)
        fixture.bags = quantity > 0 and { { id = 901, count = quantity } } or {}
    end
    local function fresh(oldStock)
        test.fresh()
        marketPrice = 100
        fixture.items[901] = { price = 10, class = 0, spell = 9901 }
        TSM_API = {
            ToItemString = function() return "i:901" end,
            GetCustomPriceValue = function() return marketPrice end,
        }
        bags(oldStock or 0)
        local gold = PerHour.Modules.Gold
        click(gold)
        return gold
    end
    local function loot(quantity, price)
        marketPrice = price or marketPrice
        bags(count() + quantity)
        event("CHAT_MSG_LOOT", string.format(LOOT_ITEM_SELF_MULTIPLE, fixture.link(901), quantity))
        event("BAG_UPDATE_DELAYED")
    end
    local castID = 0
    local function consume(bagFirst)
        castID = castID + 1
        local guid = "stock-cast-" .. castID
        event("UNIT_SPELLCAST_SENT", "player", "", guid, 9901)
        if bagFirst then bags(count() - 1); event("BAG_UPDATE_DELAYED") end
        event("UNIT_SPELLCAST_SUCCEEDED", "player", guid, 9901)
        if not bagFirst then bags(count() - 1); event("BAG_UPDATE_DELAYED") end
    end
    local function deliver(quantity, bagFirst)
        fixture.questID, fixture.requiredItems = 6001, { { id = 901, quantity = quantity } }
        event("QUEST_PROGRESS")
        if bagFirst then bags(count() - quantity); event("BAG_UPDATE_DELAYED") end
        event("QUEST_TURNED_IN", 6001, 0, 0)
        if not bagFirst then bags(count() - quantity); event("BAG_UPDATE_DELAYED") end
    end
    local function withdraw(quantity, opening, closing, bagAfterClose)
        if opening then event(opening) end
        bags(count() - quantity)
        if not bagAfterClose then event("BAG_UPDATE_DELAYED") end
        if closing then event(closing) end
        if bagAfterClose then event("BAG_UPDATE_DELAYED") end
    end

    for _, context in ipairs({
        { "MERCHANT_SHOW", "MERCHANT_CLOSED" }, { "MAIL_SHOW", "MAIL_CLOSED" },
        { "TRADE_SHOW", "TRADE_CLOSED" }, { "BANKFRAME_OPENED", "BANKFRAME_CLOSED" },
    }) do
        for _, bagAfterClose in ipairs({ false, true }) do
            local gold = fresh()
            loot(1)
            withdraw(1, context[1], context[2], bagAfterClose)
            equal(#gold.State.History, 1, "external withdrawals never create an expense or another income")
            equal(gold.State.Element, 100, "leaving the bags preserves the original collection value")
            equal(gold.State.History[1].unitPrice, 100, "retiring stock never reprices the acquisition")
            event("BAG_UPDATE_DELAYED")
            event("PLAYER_LOGOUT")
            test.login(test.copy(PerHourCharacter_Values), 0)
            gold = PerHour.Modules.Gold
            equal(gold.State.RestoreStatus, "success", "retired stock survives session verification")
            marketPrice = 300
            bags(1) -- A purchased, returned or transferred unit is not farming income.
            event("BAG_UPDATE_DELAYED")
            consume()
            equal(gold.State.History[2].amount, -300, "replacement stock cannot reuse a departed acquisition's price")
            equal(gold.State.History[2].valuations[1].acquired, false, "replacement is quoted as unmatched stock")
            equal(gold.State.Element, -200, "the old collection value remains while the replacement use is charged")
        end
    end

    local gold = fresh()
    loot(3, 100)
    loot(3, 200)
    consume() -- Spend one unit before a later withdrawal from that same lot.
    withdraw(3, "TRADE_SHOW", "TRADE_CLOSED")
    marketPrice = 500
    deliver(1)
    equal(gold.State.History[4].amount, -200, "partial withdrawals retire the oldest remaining units across lots")
    equal(gold.State.Element, 600, "transfers do not subtract their value from the farming total")
    event("PLAYER_LOGOUT")
    local saved = test.copy(PerHourCharacter_Values)
    test.login(saved, 0)
    gold = PerHour.Modules.Gold
    equal(gold.State.RestoreStatus, "success", "retirement metadata preserves earlier expense allocations")
    consume()
    equal(gold.State.History[5].amount, -200, "reload retains the last available unit at its original price")
    bags(1)
    event("BAG_UPDATE_DELAYED")
    consume()
    equal(gold.State.History[6].amount, -500, "exhausted lots cannot price a later replacement")
    for _, invalidQuantity in ipairs({ 0, -1, 3, 4, 0.5, "1", math.huge }) do
        local invalid = test.copy(saved)
        invalid.sessions.Gold.context.history[1].retiredQuantity = invalidQuantity
        test.login(invalid, 0)
        equal(PerHour.Modules.Gold.State.RestoreStatus, "error", "invalid retirement quantities are rejected")
    end
    local invalid = test.copy(saved)
    invalid.sessions.Gold.context.history[3].retiredQuantity = 1
    test.login(invalid, 0)
    equal(PerHour.Modules.Gold.State.RestoreStatus, "error", "expenses cannot carry retired acquisition quantities")

    gold = fresh()
    loot(1)
    withdraw(1) -- Destruction or another unexplained bag loss is not consumption.
    loot(1, 300)
    marketPrice = 500
    consume()
    equal(gold.State.History[3].amount, -300, "a new counted acquisition keeps its own price after an unexplained loss")
    equal(gold.State.Element, 100, "unexplained losses change availability without charging expenses")

    for _, bagFirst in ipairs({ false, true }) do
        gold = fresh()
        loot(2)
        marketPrice = 300
        consume(bagFirst)
        deliver(1, bagFirst)
        equal(gold.State.History[2].amount, -100, "cast event order cannot retire a unit before its consumption")
        equal(gold.State.History[3].amount, -100, "quest event order cannot retire a unit before its delivery")
        equal(gold.State.Element, 0, "recognized expenses cancel acquisition values exactly once")
        event("PLAYER_LOGOUT")
        test.login(test.copy(PerHourCharacter_Values), 0)
        equal(PerHour.Modules.Gold.State.RestoreStatus, "success", "consumed units are not also saved as retired")
    end

    gold = fresh()
    loot(1)
    click(gold)
    withdraw(1, "MAIL_SHOW", "MAIL_CLOSED")
    bags(1)
    event("BAG_UPDATE_DELAYED")
    marketPrice = 300
    click(gold)
    consume()
    equal(gold.State.History[2].amount, -300, "paused transfers still remove stale acquisition prices")

    gold = fresh()
    loot(1)
    click(gold)
    bags(0) -- No bag event before resume: the fresh baseline must not hide the loss.
    click(gold)
    marketPrice = 300
    bags(1)
    event("BAG_UPDATE_DELAYED")
    consume()
    equal(gold.State.History[2].amount, -300, "resume reconciles unsampled losses before replacing its baseline")

    gold = fresh()
    loot(1)
    bags(0)
    event("PLAYER_LOGOUT") -- Save must sample even when there are no pending casts or quests.
    test.login(test.copy(PerHourCharacter_Values), 0)
    gold = PerHour.Modules.Gold
    marketPrice = 300
    bags(1)
    event("BAG_UPDATE_DELAYED")
    consume()
    equal(gold.State.History[2].amount, -300, "saving captures an unsampled withdrawal before reload")

    gold = fresh()
    loot(1)
    event("PLAYER_LEAVING_WORLD")
    bags(0)
    event("PLAYER_ENTERING_WORLD", false, false)
    marketPrice = 300
    bags(1)
    event("BAG_UPDATE_DELAYED")
    consume()
    equal(gold.State.History[2].amount, -300, "world entry reconciles losses before replacing its baseline")

    gold = fresh()
    loot(1)
    fixture.questID, fixture.requiredItems = 6002, { { id = 901, quantity = 1 } }
    event("QUEST_PROGRESS")
    bags(0)
    event("BAG_UPDATE_DELAYED")
    event("QUEST_FINISHED") -- The dialog was canceled, so the loss is not a quest expense.
    tick(3)
    marketPrice = 300
    bags(1)
    event("BAG_UPDATE_DELAYED")
    consume()
    equal(gold.State.History[2].amount, -300, "expired quest evidence releases an unexplained loss from the FIFO")
    equal(#gold.State.History, 2, "an unconfirmed quest never adds an expense")

    gold = fresh()
    loot(1)
    fixture.questID, fixture.requiredItems = 6003, { { id = 901, quantity = 1 } }
    event("QUEST_PROGRESS")
    bags(0)
    event("BAG_UPDATE_DELAYED")
    event("PLAYER_LOGOUT") -- Observed loss is still reserved for an unconfirmed dialog.
    saved = test.copy(PerHourCharacter_Values)
    test.login(saved, 0)
    gold = PerHour.Modules.Gold
    equal(gold.State.RestoreStatus, "success", "reload accepts a reserved observed bag loss")
    event("PLAYER_LOGOUT")
    test.login(test.copy(PerHourCharacter_Values), 0)
    gold = PerHour.Modules.Gold
    marketPrice = 300
    bags(1)
    event("BAG_UPDATE_DELAYED")
    consume()
    equal(gold.State.History[2].amount, -300, "reload retires reserved losses once when their runtime correlation is gone")
    equal(#gold.State.History, 2, "restoring reserved loss does not invent a quest expense")
    invalid = test.copy(saved)
    invalid.sessions.Gold.context.inventoryLosses[901] = -1
    test.login(invalid, 0)
    equal(PerHour.Modules.Gold.State.RestoreStatus, "error", "malformed saved bag evidence is rejected")

    gold = fresh()
    fixture.items[901].available = false
    loot(1)
    withdraw(1, "MERCHANT_SHOW", "MERCHANT_CLOSED")
    event("PLAYER_LOGOUT")
    test.login(test.copy(PerHourCharacter_Values), 0)
    gold = PerHour.Modules.Gold
    fixture.items[901].available = true
    event("GET_ITEM_INFO_RECEIVED", 901, true)
    equal(gold.State.Element, 100, "a departed pending receipt still settles its original farming value")
    marketPrice = 300
    bags(1)
    event("BAG_UPDATE_DELAYED")
    consume()
    equal(gold.State.History[2].amount, -300, "settling a retired pending receipt does not restore its availability")
    fixture.reset()
end
