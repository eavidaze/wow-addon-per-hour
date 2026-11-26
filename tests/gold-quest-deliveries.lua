return function(test)
    local equal, event, tick, click = test.equal, test.event, test.tick, test.click
    local fixture = test.fixture
    local function fresh()
        test.fresh()
        local gold = PerHour.Modules.Gold
        click(gold)
        return gold
    end
    local function progress(questID, items)
        fixture.questID, fixture.requiredItems = questID, items
        event("QUEST_PROGRESS")
    end
    local function deliveries(gold)
        local result = {}
        for _, entry in ipairs(gold.State.History) do
            if entry.source == "quest_turnin" then result[#result + 1] = entry end
        end
        return result
    end

    local gold = fresh()
    fixture.items[801] = { price = 20, class = 7 }
    fixture.bags = { { id = 801, count = 8 }, { id = 801, count = 4 } }
    event("CHAT_MSG_LOOT", string.format(LOOT_ITEM_SELF_MULTIPLE, fixture.link(801), 10))
    progress(3001, { { id = 801, quantity = 10 } })
    fixture.requiredItems = {} -- The reward screen may no longer expose requirements.
    event("QUEST_COMPLETE")
    fixture.bags = { { id = 801, count = 2 } }
    event("BAG_UPDATE_DELAYED")
    equal(gold.State.Element, 200, "bag losses alone cannot establish a quest delivery")
    event("QUEST_TURNED_IN", 3001, 0, 500)
    local entry = deliveries(gold)[1]
    equal(gold.State.Element, 500, "delivered items cancel their loot value before quest money is added")
    equal(#gold.State.History, 3, "loot, delivered items and quest money have separate journal entries")
    equal(entry.quantity, 10, "delivery records the required stack quantity across bag stacks")
    equal(entry.amount, -200, "delivery subtracts vendor price times the delivered quantity")
    equal(entry.questID, 3001, "delivery retains its exact quest identity")
    equal(entry.itemLink, fixture.link(801), "delivery retains the standard item hyperlink")
    event("QUEST_TURNED_IN", 3001, 0, 0)
    event("BAG_UPDATE_DELAYED")
    equal(#deliveries(gold), 1, "repeated completion and bag events cannot deduct the same delivery twice")

    local details = PerHour.SessionPanels
    details:ShowCurrent()
    details.Details.ScrollBox:ScrollToOffset(#details.Details.Rows * 64)
    local row
    details.Details.ScrollBox:ForEachFrame(function(candidate)
        if candidate.Data.event and candidate.Data.event.source == "quest_turnin" then row = candidate end
    end)
    assert(row, "delivery must appear in Session Details")
    equal(row.Left:GetText(), "Item 801 x10", "Details shows delivered item and quantity")
    equal(row.Quest:IsShown(), true, "delivery exposes the native quest marker")
    equal(row.Right:GetText():find("-0g 2s 0c",1,true) ~= nil, true, "delivery preserves its negative copper value")
    equal(table.concat(row.Right.textColor, ","), table.concat(PerHour.Theme.red.text, ","), "expense keeps outgoing DS color")
    row.Icon.scripts.OnEnter(row.Icon)
    equal(GameTooltip.hyperlink, fixture.link(801), "item icon opens the native item tooltip")
    row.Quest.scripts.OnEnter(row.Quest)
    equal(GameTooltip.hyperlink, "quest:3001", "quest marker opens the native quest tooltip")
    local summary = PerHour.Session:GetSnapshot(false).gold
    equal(summary.coins + summary.items, 700, "summary includes loot and quest rewards")
    equal(summary.expenses, 200, "summary includes delivered item costs")

    gold = fresh()
    fixture.items[801] = { price = 20, class = 7 }
    fixture.items[802] = { price = 30, available = false }
    fixture.items[803] = { price = 0 }
    fixture.bags = { { id = 801, count = 5 }, { id = 802, count = 2 }, { id = 803, count = 4 } }
    progress(3002, { { id = 801, quantity = 3 }, { id = 802, quantity = 2 }, { id = 803, quantity = 4 } })
    event("QUEST_FINISHED") -- Native close can precede the completion event.
    event("QUEST_TURNED_IN", 3002, 0, 0)
    local completedAt = GetServerTime()
    equal(#gold.State.History, 0, "confirmed completion waits for actual item removal")
    tick(1)
    fixture.bags = { { id = 801, count = 2 } }
    event("BAG_UPDATE_DELAYED")
    equal(#deliveries(gold), 2, "multiple required items get separate expenses and zero-value items are omitted")
    equal(gold.State.Element, -60, "old inventory is charged by vendor value when delivered")
    local pending
    for _, candidate in ipairs(deliveries(gold)) do
        equal(candidate.timestamp, completedAt, "delayed bag evidence preserves the completion timestamp")
        if candidate.itemID == 802 then pending = candidate end
    end
    equal(pending.pending, true, "uncached delivery prices use the existing pending-price journal")
    equal(pending.quantity, 2, "pending delivery keeps the confirmed quantity")
    click(gold)
    event("PLAYER_LOGOUT")
    local saved = test.copy(PerHourRevampSession)
    test.login(saved, 0)
    gold = PerHour.Modules.Gold
    equal(gold.State.Element, -60, "reload preserves settled delivery expenses")
    fixture.items[802].available = true
    event("GET_ITEM_INFO_RECEIVED", 802, true)
    equal(gold.State.Element, -120, "pending delivery settles once after reload even while paused")
    equal(#deliveries(gold), 2, "settlement updates the original delivery entry")
    for _, invalid in ipairs({ "questID", "itemID" }) do
        local malformed = test.copy(saved)
        malformed.current.modules.Gold.history[1][invalid] = nil
        test.login(malformed, 0)
        equal(PerHour.Modules.Gold.State.Partial, true, "delivery context requires both item and quest identity")
    end

    gold = fresh()
    fixture.items[801] = { price = 20, class = 7 }
    fixture.bags = { { id = 801, count = 20 } }
    progress(3003, { { id = 801, quantity = 10 } })
    event("QUEST_TURNED_IN", 3003, 0, 0)
    progress(3004, { { id = 801, quantity = 10 } })
    event("QUEST_TURNED_IN", 3004, 0, 0)
    fixture.bags[1].count = 10
    event("BAG_UPDATE_DELAYED")
    equal(#deliveries(gold), 1, "overlapping quest confirmations cannot share the same observed item loss")
    fixture.bags = {}
    event("BAG_UPDATE_DELAYED")
    equal(#deliveries(gold), 2, "a second observed loss can settle the second quest")
    equal(gold.State.Element, -400, "overlapping deliveries deduct exactly twenty items")

    gold = fresh()
    fixture.items[801] = { price = 20, class = 7 }
    fixture.bags = { { id = 801, count = 20 } }
    progress(3007, { { id = 801, quantity = 10 } })
    event("QUEST_TURNED_IN", 3007, 0, 0)
    fixture.bags[1].count = 10 -- The count changes before the delayed bag event.
    progress(3008, { { id = 801, quantity = 10 } })
    event("QUEST_TURNED_IN", 3008, 0, 0)
    fixture.bags = {}
    event("BAG_UPDATE_DELAYED")
    equal(gold.State.Element, -400, "a new dialog settles earlier losses before capturing its own inventory baseline")

    gold = fresh()
    fixture.items[801] = { price = 20, class = 7 }
    fixture.bags = { { id = 801, count = 5 } }
    fixture.questID, fixture.requiredItems = 3009, { { id = 801, quantity = 2 }, { id = 801, quantity = 3 } }
    event("QUEST_COMPLETE")
    fixture.bags = {}
    event("QUEST_TURNED_IN", 3009, 0, 0)
    equal(#deliveries(gold), 1, "reward dialogs can establish delivery requirements without a progress event")
    equal(deliveries(gold)[1].quantity, 5, "repeated requirements for the same item combine into one delivered quantity")
    equal(gold.State.Element, -100, "combined requirements use their exact total quantity")

    gold = fresh()
    fixture.items[801] = { price = 20, class = 7 }
    fixture.bags = { { id = 801, count = 10 } }
    progress(3005, { { id = 801, quantity = 10, unavailable = true } })
    fixture.requiredItems[1].unavailable = false
    event("QUEST_ITEM_UPDATE")
    event("QUEST_TURNED_IN", 3005, 0, 0)
    fixture.bags = {}
    event("BAG_UPDATE_DELAYED")
    equal(gold.State.Element, -200, "late required-item links are captured before confirmed delivery")

    for _, boundary in ipairs({ "cancel", "wrong quest", "no loss", "partial loss", "pause", "reset", "world", "external" }) do
        gold = fresh()
        fixture.items[801] = { price = 20, class = 7 }
        fixture.bags = { { id = 801, count = 10 } }
        progress(3006, { { id = 801, quantity = 10 } })
        if boundary == "cancel" then event("QUEST_FINISHED"); tick(3); event("QUEST_ITEM_UPDATE")
        elseif boundary == "pause" then click(gold); click(gold)
        elseif boundary == "reset" then PerHour.Session:Finish(); click(gold)
        elseif boundary == "world" then event("PLAYER_ENTERING_WORLD")
        elseif boundary == "external" then event("MAIL_SHOW"); event("MAIL_CLOSED") end
        event("QUEST_TURNED_IN", boundary == "wrong quest" and 9999 or 3006, 0, 0)
        if boundary == "no loss" then tick(3)
        elseif boundary == "partial loss" then
            fixture.bags[1].count = 9
            event("BAG_UPDATE_DELAYED")
            equal(#deliveries(gold), 0, "partial item loss cannot be reported as the full required delivery")
            tick(3)
        end
        fixture.bags = {}
        event("BAG_UPDATE_DELAYED")
        equal(#deliveries(gold), 0, boundary .. " cannot create a speculative quest expense")
    end
end
