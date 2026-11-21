return function(test)
    local equal, tick, event, click = test.equal, test.tick, test.event, test.click
    local fixture = test.fixture
    local function fresh()
        test.fresh()
        return PerHour.Modules.Gold
    end
    local function money(delta)
        fixture.money = fixture.money + delta
        event("PLAYER_MONEY")
    end
    local function loot(id, count, pushed)
        local format = pushed and LOOT_ITEM_PUSHED_SELF_MULTIPLE or LOOT_ITEM_SELF_MULTIPLE
        event("CHAT_MSG_LOOT", string.format(format, fixture.link(id), count))
    end
    local gold = fresh()
    equal(gold.Settings:Get("isShown"), false, "Gold starts hidden")
    equal(gold.View.Frame.TitleText:GetText(), "Gold", "Gold uses shared tracker panel")
    equal(gold.View.RateUnit:GetText(), "g/h", "Gold starts in gold per hour")
    fixture.items[101] = { price = 5000, class = 7 }
    loot(101, 3)
    equal(gold.State.Element, 0, "unstarted Gold ignores loot")
    click(gold)
    local beforeUnreadable = gold.State.Element
    event("CHAT_MSG_MONEY", { secret = true })
    event("CHAT_MSG_LOOT", { secret = true })
    event("QUEST_TURNED_IN", 123, 0, { secret = true })
    event("UNIT_SPELLCAST_SUCCEEDED", "player", "restricted", { secret = true })
    equal(gold.State.Element, beforeUnreadable, "restricted values are ignored without parsing or arithmetic")
    tick(60)
    money(20000)
    event("CHAT_MSG_MONEY", "You loot 2 Gold")
    loot(101, 3)
    equal(gold.State.Element, 35000, "coins plus three vendor-valued items total 3g50s")
    equal(#gold.State.History, 2, "each accepted source has its own history event")
    equal(gold.State.History[2].quantity, 3, "history keeps item quantity")
    equal(gold.State.History[2].unitPrice, 5000, "history fixes vendor unit price at pickup")
    equal(gold.State.History[2].elapsed, 60, "history records active-session time")
    equal(gold.State.ElementPerHour, 2100000, "Gold rates use active duration and copper internally")
    gold.View.Frame:Show()
    equal(gold.View.RateValue:GetText(), "210", "panel converts copper to gold")
    PerHour.Stores.Settings:SetRate("minute")
    PerHour.TrackerPanels:RefreshDisplays()
    equal(gold.View.RateValue:GetText(), "3.5", "minute display retains fractional gold")
    equal(gold.View.RateUnit:GetText(), "g/min", "Gold follows shared minute preference")
    gold.View.Frame.scripts.OnEnter(gold.View.Frame)
    equal(GameTooltip.lines["Total Gold"], "3g 50s 0c", "tooltip formats total in gold silver and copper")
    equal(GameTooltip.singleLines[2], "Estimated net value (vendor prices).", "tooltip identifies estimate")
    BaseModule:SendTo(gold, "say")
    fixture.items[101].price = 9000
    event("GET_ITEM_INFO_RECEIVED", 101, true)
    equal(gold.State.Element, 35000, "price changes do not revalue accepted items")
    money(15000) -- A sale, old stock or otherwise, has no farming income event.
    equal(gold.State.Element, 35000, "vendor sales never count the same items again")
    money(30000)
    money(-30000)
    equal(gold.State.Element, 35000, "unclassified balance changes include neither mail nor trade")
    fixture.bags[1] = { id = 101, count = 5 }
    event("BAG_UPDATE_DELAYED")
    equal(gold.State.Element, 35000, "bag additions are never mistaken for farming loot")
    event("CHAT_MSG_LOOT", string.format(LOOT_ITEM_SELF_MULTIPLE, fixture.link(101), 2):gsub("You receive loot", "Other receives loot"))
    equal(gold.State.Element, 35000, "another player's loot is excluded")
    for _, frameName in ipairs({ "MailFrame", "TradeFrame", "MerchantFrame", "BankFrame" }) do
        _G[frameName] = { IsShown = function() return true end }
        loot(101, 1, true)
        _G[frameName] = nil
    end
    equal(gold.State.Element, 35000, "external transfers and vendor purchases cannot become pushed loot")
    event("CHAT_MSG_LOOT", "You create: " .. fixture.link(101) .. ".")
    equal(gold.State.Element, 35000, "crafted items are outside pickup valuation")
    event("QUEST_TURNED_IN", 123, 100, 12345)
    equal(gold.State.Element, 47345, "quest money is session income")
    equal(gold.State.History[3].questID, 123, "quest income retains quest identity")
    loot(101, 1, true)
    equal(gold.State.Element, 56345, "quest reward item notification is valued once")
    event("CHAT_MSG_MONEY", "Your share of the loot is 2 Gold 3 Silver 4 Copper.")
    event("CHAT_MSG_MONEY", "You loot 1 Gold (20 Silver deposited to guild bank)")
    equal(gold.State.Element, 86649, "shared and guild loot count only the player's own money")

    -- Use native localized format placeholders rather than English text matching.
    local previousGold, previousLoot = GOLD_AMOUNT, LOOT_ITEM_SELF_MULTIPLE
    GOLD_AMOUNT, LOOT_ITEM_SELF_MULTIPLE = "%d moedas de ouro", "Recebeu %2$dx %1$s!"
    event("CHAT_MSG_MONEY", "You loot 2 moedas de ouro")
    event("CHAT_MSG_LOOT", "Recebeu 2x " .. fixture.link(101) .. "!")
    equal(gold.State.Element, 124649, "localized coin names and positional loot formats work")
    GOLD_AMOUNT, LOOT_ITEM_SELF_MULTIPLE = previousGold, previousLoot

    click(gold)
    local pausedTotal, pausedCount = gold.State.Element, #gold.State.History
    tick(10)
    loot(101, 1)
    event("QUEST_TURNED_IN", 124, 0, 10000)
    event("CHAT_MSG_MONEY", "You loot 1 Gold")
    money(-1000)
    equal(gold.State.Element, pausedTotal, "pause excludes all new gains and expenses")
    equal(#gold.State.History, pausedCount, "pause does not append journal events")
    equal(gold.State.Time, 60, "pause excludes elapsed time")
    click(gold)

    -- Unknown prices remain pending and survive save/load; no invented zero price.
    fixture.items[102] = { price = 25, available = false }
    loot(102, 4)
    equal(gold.State.Element, pausedTotal, "uncached item is not guessed")
    equal(gold.State.History[#gold.State.History].pending, true, "uncached item keeps pending journal event")
    equal(fixture.requests[102], true, "uncached price requests native item data")
    event("GET_ITEM_INFO_RECEIVED", 102, false)
    equal(gold.State.Element, pausedTotal, "failed data lookup does not settle the item")
    click(gold)
    fixture.items[102].available = true
    event("GET_ITEM_INFO_RECEIVED", 102, true)
    event("ITEM_DATA_LOAD_RESULT", 102, true)
    equal(gold.State.Element, pausedTotal + 100, "accepted item settles once even while paused")
    click(gold)

    -- Actual repair/flight transactions are expenses; item purchases are excluded.
    fixture.repairCost = 123
    RepairAllItems(false)
    money(-123)
    equal(gold.State.History[#gold.State.History].source, "repair", "repair-all expense uses native money debit")
    local afterRepair = gold.State.Element
    RepairAllItems(true)
    event("PLAYER_MONEY")
    equal(gold.State.Element, afterRepair, "guild-funded repair has no player expense")
    fixture.repairMode = true
    PickupInventoryItem(1)
    money(-10)
    fixture.repairMode = false
    equal(gold.State.Element, afterRepair - 10, "individual repair is included")
    fixture.taxiCost = 200
    TakeTaxiNode(1)
    money(-200)
    equal(gold.State.History[#gold.State.History].source, "transport", "flight is recorded at actual money cost")
    local afterFlight = gold.State.Element
    money(-500)
    equal(gold.State.Element, afterFlight, "item purchases are not charged again before consumption")
    TakeTaxiNode(1)
    tick(3)
    money(-200)
    equal(gold.State.Element, afterFlight, "failed or expired transport intent cannot classify later spending")
    TakeTaxiNode(1)
    money(-300)
    money(-100)
    equal(gold.State.Element, afterFlight, "unmatched debit clears flight intent instead of charging later spending")
    TakeTaxiNode(1)
    event("UI_ERROR_MESSAGE", 1, "Flight failed")
    money(-200)
    equal(gold.State.Element, afterFlight, "native action error clears expense intent before unrelated spending")
    fixture.repairMode = true
    money(-100)
    fixture.repairMode = false
    equal(gold.State.Element, afterFlight, "repair cursor alone cannot classify an item purchase as repair")
    event("TRADE_SHOW")
    loot(101, 1, true)
    event("TRADE_CLOSED")
    loot(101, 1, true)
    equal(gold.State.Element, afterFlight, "transfer receipts stay excluded after native trade window closes")

    -- Food channels consume once at successful start, even if interrupted later.
    gold = fresh()
    fixture.items[301] = { price = 15, spell = 10001 }
    fixture.bags[1] = { id = 301, count = 3 }
    click(gold)
    local originalInfo, itemQueries = C_Item.GetItemInfo, 0
    C_Item.GetItemInfo = function(...)
        itemQueries = itemQueries + 1
        return originalInfo(...)
    end
    for index = 1, 10 do
        event("UNIT_SPELLCAST_SUCCEEDED", "player", "ability-" .. index, 99999)
    end
    equal(itemQueries, 0, "ordinary player abilities do not query every item in the bags")
    C_Item.GetItemInfo = originalInfo
    event("UNIT_SPELLCAST_SENT", "player", "", "food-cast", 10001)
    event("UNIT_SPELLCAST_SUCCEEDED", "player", "food-cast", 10001)
    event("UNIT_SPELLCAST_INTERRUPTED", "player", "food-cast", 10001)
    fixture.bags[1].count = 2
    event("BAG_UPDATE_DELAYED")
    equal(gold.State.Element, -15, "interrupted channel still charges food already used")
    event("UNIT_SPELLCAST_SUCCEEDED", "player", "food-cast", 10001)
    fixture.bags[1].count = 1
    event("BAG_UPDATE_DELAYED")
    equal(gold.State.Element, -15, "duplicate cast success cannot charge an unrelated later removal")
    click(gold)
    tick(1)
    equal(PerHour.TrackerPanels.UpdateScheduled, false, "paused Gold alone does not keep the shared timer alive")

    -- Consume preexisting inventory, with both native bag/cast event orderings.
    gold = fresh()
    fixture.items[201] = { price = 50, spell = 9001 }
    fixture.bags[1] = { id = 201, count = 5 }
    click(gold)
    event("UNIT_SPELLCAST_SENT", "player", "", "cast-1", 9001)
    event("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-1", 9001)
    equal(gold.State.Element, 0, "successful spell without item loss is not consumption")
    fixture.bags[1].count = 4
    event("BAG_UPDATE_DELAYED")
    equal(gold.State.Element, -50, "consumption of preexisting potion can produce negative net value")
    equal(gold.State.History[1].direction, -1, "consumption is an outgoing journal event")
    event("BAG_UPDATE_DELAYED")
    equal(gold.State.Element, -50, "bag refresh does not deduct consumption twice")
    event("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-1", 9001)
    event("UNIT_SPELLCAST_SENT", "player", "", "cast-2", 9001)
    fixture.bags[1].count = 3
    event("BAG_UPDATE_DELAYED")
    event("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-2", 9001)
    equal(gold.State.Element, -100, "bag update before successful spell also deducts once")
    event("UNIT_SPELLCAST_SENT", "player", "", "cast-3", 9001)
    event("UNIT_SPELLCAST_FAILED", "player", "cast-3", 9001)
    fixture.bags[1].count = 2
    event("BAG_UPDATE_DELAYED")
    equal(gold.State.Element, -100, "failure plus unrelated removal is not consumption")
    event("UNIT_SPELLCAST_SUCCEEDED", "party1", "cast-4", 9001)
    fixture.bags[1].count = 1
    event("BAG_UPDATE_DELAYED")
    equal(gold.State.Element, -100, "other units and ordinary bag removals do not deduct")
    event("UNIT_SPELLCAST_SENT", "player", "", "cast-5", 9001)
    click(gold)
    fixture.bags[1] = nil
    event("BAG_UPDATE_DELAYED")
    event("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-5", 9001)
    click(gold)
    event("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-5", 9001)
    equal(gold.State.Element, -100, "consumption during pause cannot leak through resume")
    fixture.items[204] = { price = 0, class = 7 }
    loot(204, 1)
    equal(gold.State.History[#gold.State.History].unitPrice, 0, "known zero vendor value is resolved rather than pending")
    equal(next(gold.State.PendingPrices), nil, "zero vendor value does not request endless lookups")

    fixture.items[202] = { price = 100, class = 7 }
    loot(202, 3)
    fixture.items[203] = { price = 10, available = false }
    loot(203, 2)
    local count = #gold.State.History
    event("PLAYER_LOGOUT")
    local saved = test.copy(PerHourCharacter_Values)
    equal(#saved.sessions.Gold.context.history, count, "journal is persisted with Gold's session")
    equal(saved.sessions.Gold.total, 200, "save includes negative consumption and positive farming")
    test.login(saved, 0)
    gold = PerHour.Modules.Gold
    equal(gold.State.Element, 200, "Gold restores its estimated net total")
    equal(#gold.State.History, count, "Gold restores the complete journal")
    equal(gold.State.HasPaused, false, "running Gold resumes after continuity check")
    fixture.items[203].available = true
    event("GET_ITEM_INFO_RECEIVED", 203, true)
    equal(gold.State.Element, 220, "pending price is settled after reload")
    equal(saved.sessions.Gold.context.history[count].pending, true, "live settlement cannot mutate saved fixture")
    click(gold)
    event("PLAYER_LOGOUT")
    test.login(test.copy(PerHourCharacter_Values), 0)
    gold = PerHour.Modules.Gold
    equal(gold.State.HasPaused, true, "manually paused Gold restores paused")
    equal(#gold.State.History, count, "paused restore retains journal")
    BaseModule:ResetModule(gold)
    equal(#gold.State.History, 0, "Reset clears journal and pending prices")
    equal(PerHourCharacter_Values.sessions.Gold, nil, "Reset clears saved Gold session")
    event("GET_ITEM_INFO_RECEIVED", 203, true)
    equal(gold.State.Element, 0, "late item response cannot revive reset session")

    saved.sessions.Gold.context.history[1].amount = -999
    test.login(saved, 0)
    gold = PerHour.Modules.Gold
    equal(gold.State.HasStarted, false, "inconsistent journal cannot restore misleading totals")
    equal(gold.State.RestoreStatus, "error", "invalid journal exposes existing restore warning")
    equal(#gold.State.History, 0, "rejected history leaves a clean runtime")

    gold = fresh()
    fixture.items[201] = { price = 50, spell = 9001 }
    fixture.bags[1] = { id = 201, count = 2 }
    click(gold)
    event("UNIT_SPELLCAST_SENT", "player", "", "logout-cast", 9001)
    event("UNIT_SPELLCAST_SUCCEEDED", "player", "logout-cast", 9001)
    fixture.bags[1].count = 1
    event("PLAYER_LOGOUT")
    equal(PerHourCharacter_Values.sessions.Gold.total, -50, "logout captures confirmed consumption before delayed bag event")
    equal(PerHourCharacter_Values.sessions.Gold.context.history[1].amount, -50, "logout history matches its final sampled total")
    event("PLAYER_LEAVING_WORLD")
    fixture.bags[1] = nil
    event("PLAYER_ENTERING_WORLD")
    event("UNIT_SPELLCAST_SUCCEEDED", "player", "logout-cast", 9001)
    equal(gold.State.Element, -50, "world-entry baseline cannot treat loading-time item loss as consumption")
end
