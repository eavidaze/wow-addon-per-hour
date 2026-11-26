return function(test)
    local equal, event, tick, click = test.equal, test.event, test.tick, test.click
    local fixture = test.fixture
    local calls, tsmPrice, auctionPrice, tsmError, auctionError
    local function fresh()
        test.fresh()
        calls, tsmPrice, auctionPrice, tsmError, auctionError = { tsm = 0, auctionator = 0 }, nil, nil, false, false
        fixture.items[901] = { price = 10, class = 7 }
        return PerHour.Modules.Gold, PerHour.Pricing
    end
    local function installTSM()
        TSM_API = {
            ToItemString = function(link)
                calls.link = link
                return "i:" .. (link:match("item:(%d+)"))
            end,
            GetCustomPriceValue = function(metric, itemString)
                calls.tsm = calls.tsm + 1
                equal(metric, "DBMarket", "TSM uses its explicitly selected market metric")
                equal(itemString, "i:901", "TSM receives the converted item string")
                if tsmError then error("TSM not ready") end
                return tsmPrice
            end,
        }
    end
    local function installAuctionator()
        Auctionator = { API = { v1 = {
            GetAuctionPriceByItemLink = function(callerID, link)
                calls.auctionator = calls.auctionator + 1
                equal(callerID, "PerHour", "Auctionator API identifies its caller")
                equal(link, fixture.link(901), "Auctionator preserves the complete item link")
                if auctionError then error("Auctionator not ready") end
                return auctionPrice
            end,
        } } }
    end
    local function loot(quantity)
        event("CHAT_MSG_LOOT", string.format(LOOT_ITEM_SELF_MULTIPLE, fixture.link(901), quantity))
    end
    local function deliver(questID, quantity)
        fixture.questID, fixture.requiredItems = questID, { { id = 901, quantity = quantity } }
        event("QUEST_PROGRESS")
        local left = (fixture.bags[1] and fixture.bags[1].count or 0) - quantity
        fixture.bags = left > 0 and { { id = 901, count = left } } or {}
        event("QUEST_TURNED_IN", questID, 0, 0)
        event("BAG_UPDATE_DELAYED")
    end

    local gold, pricing = fresh()
    local quote = pricing:GetQuote(901, fixture.link(901))
    equal(quote.unitPrice, 10, "vendor works without either optional addon")
    equal(quote.provider, "vendor", "native valuation identifies vendor")
    installAuctionator()
    auctionPrice = 200
    quote = pricing:GetQuote(901, fixture.link(901))
    equal(quote.provider, "auctionator", "Auctionator works when TSM is absent")
    equal(quote.unitPrice, 200, "Auctionator quote is expressed per unit in copper")
    installTSM()
    tsmPrice = 100
    local priorCalls = calls.auctionator
    quote = pricing:GetQuote(901, fixture.link(901))
    equal(quote.provider, "tsm", "TSM has priority even when Auctionator reports more")
    equal(quote.unitPrice, 100, "priority chooses the first valid source rather than the largest source")
    equal(calls.auctionator, priorCalls, "successful TSM lookup does not query lower-priority sources")
    equal(calls.link, fixture.link(901), "TSM conversion receives the complete item link")
    tsmPrice = 5
    quote = pricing:GetQuote(901, fixture.link(901))
    equal(quote.provider, "vendor", "vendor is the floor below a valid TSM estimate")
    equal(quote.unitPrice, 10, "the vendor floor never reduces the recorded value")
    equal(calls.auctionator, priorCalls, "a below-vendor TSM quote still keeps the declared priority")
    for _, bad in ipairs({ false, 0, -1, "100", math.huge, -math.huge, 0 / 0, { secret = true } }) do
        tsmPrice = bad
        equal(pricing:GetQuote(901, fixture.link(901)).provider, "auctionator", "invalid TSM values fall through to Auctionator")
    end
    tsmPrice = nil
    equal(pricing:GetQuote(901, fixture.link(901)).provider, "auctionator", "missing TSM data falls through per item")
    tsmError = true
    equal(pricing:GetQuote(901, fixture.link(901)).provider, "auctionator", "TSM API failures cannot stop the tracker")
    auctionError = true
    equal(pricing:GetQuote(901, fixture.link(901)).provider, "vendor", "failure of both integrations falls back to vendor")
    TSM_API = { ToItemString = function() return nil end }
    equal(pricing:GetQuote(901, fixture.link(901)).provider, "vendor", "partially initialized addons are optional")
    TSM_API, auctionError = nil, false
    Auctionator.API.v1.GetAuctionPriceByItemLink = nil
    Auctionator.API.v1.GetAuctionPriceByItemID = function(_, itemID)
        equal(itemID, 901, "ID lookup remains available when the link API is absent")
        return 123
    end
    equal(pricing:GetQuote(901, fixture.link(901)).unitPrice, 123, "Auctionator can fall back to its public item-ID API")

    gold, pricing = fresh()
    installTSM()
    tsmPrice = 100
    for _, binding in ipairs({ 1, 4, 7, 8, 9 }) do
        fixture.items[901].bindType = binding
        equal(pricing:GetQuote(901, fixture.link(901)).provider, "vendor", "bound and quest item types never receive speculative AH prices")
    end
    fixture.items[901].bindType, fixture.items[901].class = 0, 12
    equal(pricing:GetQuote(901, fixture.link(901)).provider, "vendor", "quest-class items do not use auction prices")
    equal(calls.tsm, 0, "non-tradable metadata prevents external API calls")
    fixture.items[901].class, fixture.items[901].price = 7, 0
    equal(pricing:GetQuote(901, fixture.link(901)).unitPrice, 100, "tradable zero-vendor items can still have valid AH value")
    fixture.items[901].available = false
    equal(pricing:GetQuote(901, fixture.link(901)), nil, "unknown native item data is pending rather than an invented zero")

    gold, pricing = fresh()
    installTSM()
    installAuctionator()
    tsmPrice, auctionPrice = 100, 200
    fixture.items[901].quality = 0
    quote = pricing:GetQuote(901, fixture.link(901))
    equal(quote.provider, "vendor", "poor gray items always use vendor despite higher market prices")
    equal(quote.unitPrice, 10, "gray item value is its vendor sell price")
    fixture.items[901].price = 0
    equal(pricing:GetQuote(901, fixture.link(901)).unitPrice, 0, "unsellable gray items do not acquire AH value")
    fixture.items[901].price, fixture.items[901].available = 10, false
    fixture.bags = { { id = 901, count = 10 } }
    click(gold)
    loot(10)
    deliver(4008, 8)
    equal(gold.State.History[1].pending, true, "uncached gray income waits for native metadata")
    equal(gold.State.History[2].pending, true, "dependent gray delivery waits for its acquisition price")
    fixture.items[901].available = true
    event("GET_ITEM_INFO_RECEIVED", 901, true)
    equal(gold.State.Element, 20, "pending gray income and delivery settle at vendor value")
    equal(gold.State.History[1].priceSource, "vendor", "settled gray income records vendor as its source")
    equal(gold.State.History[2].priceSource, "vendor", "gray delivery preserves the vendor acquisition value")
    equal(calls.tsm, 0, "gray quotes and pending settlement never query TSM")
    equal(calls.auctionator, 0, "gray quotes and pending settlement never query Auctionator")

    gold = fresh()
    installAuctionator()
    auctionPrice = 100
    fixture.bags = { { id = 901, count = 5 } }
    click(gold)
    loot(5)
    installTSM()
    tsmPrice = 300
    fixture.bags[1].count = 10
    loot(5)
    equal(gold.State.Element, 2000, "each acquisition freezes the provider available at pickup")
    equal(gold.State.History[1].priceSource, "auctionator", "income stores its original price source")
    equal(gold.State.History[2].priceMetric, "DBMarket", "income stores the TSM metric")
    tsmPrice = 1000
    deliver(4001, 8)
    local expense = gold.State.History[3]
    equal(gold.State.Element, 600, "quest delivery cancels acquisition values instead of creating a market-change profit")
    equal(expense.quantity, 8, "mixed acquisition prices remain one delivered-item row")
    equal(expense.amount, -1400, "FIFO uses five units at 100 and three at 300")
    equal(expense.unitPrice, nil, "mixed unit prices do not fabricate an average copper price")
    equal(expense.priceSource, "mixed", "mixed providers remain explicit in the journal")
    equal(expense.valuations[1].quantity, 5, "expense records the first lot's quantity")
    equal(expense.valuations[2].unitPrice, 300, "expense preserves the second lot's unit value")
    local beforeDisplay = calls.tsm + calls.auctionator
    PerHour.SessionPanels:ShowCurrent()
    equal(calls.tsm + calls.auctionator, beforeDisplay, "rendering and hovering history never query market addons")
    event("PLAYER_LOGOUT")
    local saved = test.copy(PerHourRevampSession)
    test.login(saved, 0)
    gold = PerHour.Modules.Gold
    equal(gold.State.Element, 600, "reload restores mixed-price history without repricing it")
    deliver(4002, 2)
    equal(gold.State.Element, 0, "reloaded FIFO retains the unspent portion at its acquisition price")
    equal(gold.State.History[4].amount, -600, "last two units cancel their recorded price rather than today's quote")
    for _, field in ipairs({ "amount", "quantity", "priceSource", "pricingVersion", "acquired" }) do
        local invalid = test.copy(saved)
        local value = invalid.current.modules.Gold.history[3]
        if field == "priceSource" then value.priceSource = "unknown"
        elseif field == "pricingVersion" then value.pricingVersion = 999
        elseif field == "acquired" then value.valuations[1].acquired = false
        else value.valuations[1][field == "amount" and "unitPrice" or "quantity"] = 1 end
        test.login(invalid, 0)
        equal(PerHour.Modules.Gold.State.Partial, true, "tampered valuation snapshots are rejected on restore")
    end

    gold = fresh()
    installTSM()
    tsmPrice = 100
    fixture.items[901].available = false
    fixture.bags = { { id = 901, count = 10 } }
    click(gold)
    loot(10)
    deliver(4003, 8)
    equal(#gold.State.History, 2, "both acquisition and delivery remain in history while prices are pending")
    event("PLAYER_LOGOUT")
    local pendingSave = test.copy(PerHourRevampSession)
    test.login(pendingSave, 0)
    gold = PerHour.Modules.Gold
    fixture.items[901].available = true
    event("GET_ITEM_INFO_RECEIVED", 901, true)
    equal(gold.State.Element, 200, "pending income and delivery restore and settle with the same price")
    equal(calls.tsm, 1, "pending delivery reuses the settled acquisition quote exactly once")
    equal(gold.State.History[2].pending, nil, "settlement clears the dependent expense's pending state")

    gold = fresh()
    installTSM()
    fixture.items[901].available = false
    fixture.bags = { { id = 901, count = 10 } }
    click(gold)
    loot(5)
    fixture.items[901].available, tsmPrice = true, 100
    loot(5)
    deliver(4005, 8)
    fixture.items[901].price, tsmPrice = 0, 0
    event("GET_ITEM_INFO_RECEIVED", 901, true)
    equal(#gold.State.History, 2, "zero-valued pending acquisition is removed without losing the mixed expense")
    equal(gold.State.Element, 200, "zero-valued acquisition contributes nothing to its expense part")
    event("PLAYER_LOGOUT")
    saved = test.copy(PerHourRevampSession)
    tsmPrice = 1000
    test.login(saved, 0)
    gold = PerHour.Modules.Gold
    deliver(4006, 2)
    equal(gold.State.Element, 0, "reload skips discarded zero-value parts when reconstructing remaining acquisitions")

    gold = fresh()
    installTSM()
    tsmPrice = 100
    fixture.bags = { { id = 901, count = 5 } }
    click(gold)
    loot(2)
    tsmPrice = 300
    deliver(4007, 5)
    equal(gold.State.Element, -900, "a single expense can combine acquired units and old stock")
    equal(gold.State.History[2].valuations[2].acquired, false, "old-stock provenance is saved independently of acquired lots")
    event("PLAYER_LOGOUT")
    saved = test.copy(PerHourRevampSession)
    test.login(saved, 0)
    gold = PerHour.Modules.Gold
    equal(gold.State.Element, -900, "old-stock parts survive reconstruction without consuming unrelated acquisitions")

    gold = fresh()
    fixture.bags = { { id = 901, count = 3 } }
    click(gold)
    loot(3)
    event("PLAYER_LOGOUT")
    local legacy = test.copy(PerHourRevampSession)
    for _, entry in ipairs(legacy.current.modules.Gold.history) do
        entry.pricingVersion, entry.priceSource, entry.priceMetric, entry.valuations = nil, nil, nil, nil
    end
    installTSM()
    tsmPrice = 1000
    test.login(legacy, 0)
    gold = PerHour.Modules.Gold
    equal(gold.State.History[1].pricingVersion, nil, "restoration does not migrate older journal entries")
    equal(gold.State.Element, 30, "legacy vendor totals remain fixed with TSM installed")
    deliver(4004, 3)
    equal(gold.State.Element, 0, "new delivery can cancel legacy acquisitions at their saved vendor value")
    equal(gold.State.History[2].priceSource, "vendor", "new expense identifies the inherited vendor valuation")

    gold = fresh()
    fixture.bags = { { id = 901, count = 2 } }
    fixture.items[901].available = false
    click(gold)
    loot(2)
    event("PLAYER_LOGOUT")
    legacy = test.copy(PerHourRevampSession)
    legacy.current.modules.Gold.history[1].pricingVersion = nil
    installTSM()
    tsmPrice = 1000
    test.login(legacy, 0)
    gold = PerHour.Modules.Gold
    fixture.items[901].available = true
    event("GET_ITEM_INFO_RECEIVED", 901, true)
    equal(gold.State.Element, 20, "legacy pending receipts retain their original vendor policy")
    equal(calls.tsm, 0, "legacy pending receipts do not silently opt into new pricing")
    loot(1)
    equal(gold.State.History[2].unitPrice, 1000, "new events use the new priority after restoring legacy history")

    gold = fresh()
    installTSM()
    tsmPrice = 100
    fixture.items[901] = { price = 10, class = 0, spell = 9901 }
    fixture.bags = { { id = 901, count = 3 } }
    click(gold)
    loot(1)
    tsmPrice = 300
    event("UNIT_SPELLCAST_SENT", "player", "", "cast-m2", 9901)
    event("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-m2", 9901)
    fixture.bags[1].count = 2
    event("BAG_UPDATE_DELAYED")
    equal(gold.State.Element, 0, "consumption cancels a collected unit at its acquisition value")
    event("UNIT_SPELLCAST_SENT", "player", "", "cast-old", 9901)
    event("UNIT_SPELLCAST_SUCCEEDED", "player", "cast-old", 9901)
    fixture.bags[1].count = 1
    event("BAG_UPDATE_DELAYED")
    equal(gold.State.Element, -300, "unmatched old-stock consumption uses the current priority quote")
    equal(gold.State.History[3].priceSource, "tsm", "old-stock expense records its own valuation source")
    tick(3)
    fixture.reset()
end
