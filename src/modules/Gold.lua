local Module = {
    Name = "Gold", TagName = "gold", ShortName = "g",
    RateDivisor = 10000, RateDecimals = 2,
    UpdateWhilePaused = false,
    RegisteredEvents = {
        "CHAT_MSG_MONEY", "CHAT_MSG_LOOT", "QUEST_TURNED_IN", "PLAYER_MONEY",
        "BAG_UPDATE_DELAYED", "GET_ITEM_INFO_RECEIVED", "ITEM_DATA_LOAD_RESULT",
        "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED",
        "UNIT_SPELLCAST_INTERRUPTED",
        "MAIL_SHOW", "MAIL_CLOSED", "TRADE_SHOW", "TRADE_CLOSED",
        "MERCHANT_SHOW", "MERCHANT_CLOSED", "BANKFRAME_OPENED", "BANKFRAME_CLOSED",
        "TAXIMAP_OPENED", "MERCHANT_UPDATE", "UI_ERROR_MESSAGE",
    },
}
PerHour.Modules.Gold = Module

local CONTEXT_EVENTS = {
    MAIL_SHOW = "mail", MAIL_CLOSED = "mail", TRADE_SHOW = "trade", TRADE_CLOSED = "trade",
    MERCHANT_SHOW = "merchant", MERCHANT_CLOSED = "merchant", BANKFRAME_OPENED = "bank", BANKFRAME_CLOSED = "bank",
}
local SOURCES = { loot_money = true, loot_item = true, item_reward = true, quest_money = true,
    consumable = true, repair = true, transport = true }

local function Readable(value, kind)
    return not (issecretvalue and issecretvalue(value)) and type(value) == kind
end

local function Integer(value)
    return Utils:IsFiniteNumber(value) and value >= 0 and value == math.floor(value)
end

local function Running()
    local state = Module.State
    return state and state.HasStarted and not state.HasPaused and not state.PendingRestore
        and PerHour.Session.InWorld
end

local function ExternalItems()
    if Module.State and next(Module.State.ExternalContexts) then return true end
    for _, name in ipairs({ "MailFrame", "TradeFrame", "MerchantFrame", "BankFrame" }) do
        local frame = _G[name]
        if frame and frame:IsShown() then return true end
    end
    return false
end

-- Escape localized format strings, including positional placeholders and literal percent signs.
local function FormatPattern(format)
    if not Readable(format, "string") then return end
    local captures = {}
    local pattern = format:gsub("%%(%d+)%$([sd])", function(index, kind)
        captures[#captures + 1] = tonumber(index)
        return kind == "s" and "\001" or "\002"
    end)
    if #captures == 0 then
        pattern = format:gsub("%%([sd])", function(kind)
            captures[#captures + 1] = #captures + 1
            return kind == "s" and "\001" or "\002"
        end)
    end
    pattern = pattern:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
        :gsub("\001", "(.-)"):gsub("\002", "(%%d+)")
    return "^" .. pattern .. "$", captures
end

local function MatchFormat(text, format)
    local pattern, order = FormatPattern(format)
    if not pattern then return end
    local values = { text:match(pattern) }
    if #values == 0 then return end
    local result = {}
    for index, value in ipairs(values) do result[order[index]] = value end
    return unpack(result)
end

local function MoneyFromText(text)
    local total, found = 0, false
    for _, coin in ipairs({ { GOLD_AMOUNT, 10000 }, { SILVER_AMOUNT, 100 }, { COPPER_AMOUNT, 1 } }) do
        local pattern = FormatPattern(coin[1])
        local value = pattern and text:match(pattern:sub(2, -2))
        if value then
            total, found = total + tonumber(value) * coin[2], true
        end
    end
    if found and Integer(total) then return total end
end

local function Refresh()
    BaseModule:UpdateRates(Module)
end

local function ResolveEntry(entry)
    local _, _, _, _, _, _, _, _, _, _, price = C_Item.GetItemInfo(entry.itemLink or entry.itemID)
    if not Integer(price) then return false end
    entry.unitPrice, entry.pending = price, nil
    entry.amount = entry.quantity * price * entry.direction
    Module.State.Element = Module.State.Element + entry.amount
    return true
end

local function Record(source, amount, itemLink, quantity, direction, questID)
    local state = Module.State
    local entry = {
        elapsed = state.Time + math.max(0, GetTime() - state.UpdatedAt),
        source = source, amount = amount, direction = direction or (amount < 0 and -1 or 1),
        questID = questID,
    }
    if itemLink then
        entry.itemLink, entry.quantity = itemLink, quantity
        entry.itemID = tonumber(itemLink:match("item:(%d+)"))
        entry.amount, entry.pending = 0, true
    end
    table.insert(state.History, entry)
    if itemLink then
        if not ResolveEntry(entry) then
            local pending = state.PendingPrices[entry.itemID] or {}
            state.PendingPrices[entry.itemID] = pending
            table.insert(pending, entry)
            C_Item.RequestLoadItemDataByID(entry.itemID)
        end
    else
        state.Element = state.Element + amount
    end
    Refresh()
end

-- Inventory is evidence of consumption, never evidence of income. Transfers and sales
-- must not become farming gains or consumable expenses just because bag counts change.
local function Inventory()
    local items = {}
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and Integer(info.itemID) and Integer(info.stackCount) and Readable(info.hyperlink, "string") then
                local item = items[info.itemID]
                if item then item.count = item.count + info.stackCount
                else items[info.itemID] = { count = info.stackCount, link = info.hyperlink } end
            end
        end
    end
    -- Build spell metadata when bags change, not on every player ability cast.
    for _, item in pairs(items) do
        local _, _, _, _, _, _, _, _, _, _, _, classID = C_Item.GetItemInfo(item.link)
        if Utils:IsReadableNumber(classID) and classID == 0 then
            local _, spellID = C_Item.GetItemSpell(item.link)
            if Utils:IsReadableNumber(spellID) then item.spellID = spellID end
        end
    end
    return items
end

local function ResetRuntime()
    local state = Module.State
    state.LastMoney = GetMoney()
    state.Inventory = Inventory()
    state.Casts, state.LastCasts, state.Expense = {}, {}, nil
    state.ExternalContexts, state.IgnorePushedUntil = {}, 0
    state.RepairCost = GetRepairAllCost()
    state.TaxiCosts = {}
    if NumTaxiNodes then
        for index = 1, NumTaxiNodes() do state.TaxiCosts[index] = TaxiNodeCost(index) end
    end
end

local function ReconcileCasts(current)
    for spellID, cast in pairs(Module.State.Casts) do
        if GetTime() - cast.at > (cast.succeeded and 2 or 60) or ExternalItems() then
            Module.State.Casts[spellID] = nil
        elseif cast.succeeded then
            local consumed, ambiguous
            for itemID, before in pairs(cast.items) do
                local count = current[itemID] and current[itemID].count or 0
                if count < before.count then
                    if consumed then ambiguous = true end
                    consumed = before
                end
            end
            if consumed then
                Module.State.Casts[spellID] = nil
                if not ambiguous then Record("consumable", 0, consumed.link, 1, -1) end
            end
        end
    end
end

Module.CustomReset = function()
    Module.State.History, Module.State.PendingPrices = {}, {}
    Module.State.Inventory, Module.State.Casts, Module.State.LastCasts, Module.State.Expense = {}, {}, {}, nil
    Module.State.ExternalContexts, Module.State.IgnorePushedUntil = {}, 0
end

Module.CustomStart = ResetRuntime
Module.CustomTrackingChanged = ResetRuntime
Module.CustomWorldEntered = ResetRuntime
Module.CustomOnUpdate = function()
    if Running() and next(Module.State.Casts) then ReconcileCasts(Inventory()) end
    return true
end

Module.CustomSaveSession = function()
    return { version = 1, history = Module.State.History }
end

Module.CustomRestoreSession = function(context)
    if type(context) ~= "table" or context.version ~= 1 or type(context.history) ~= "table" then return false end
    local total, count = 0, 0
    for index, entry in pairs(context.history) do
        if not Integer(index) or index < 1 or type(entry) ~= "table"
            or not Utils:IsFiniteNumber(entry.elapsed) or entry.elapsed < 0
            or not Readable(entry.source, "string") or not SOURCES[entry.source]
            or not Utils:IsFiniteNumber(entry.amount) or entry.amount ~= math.floor(entry.amount)
            or (entry.direction ~= 1 and entry.direction ~= -1) then return false end
        if entry.amount * entry.direction < 0 then return false end
        if entry.itemID then
            if not Integer(entry.itemID) or entry.itemID < 1 or not Integer(entry.quantity) or entry.quantity < 1
                or not Readable(entry.itemLink, "string") then return false end
            if entry.pending then
                if entry.pending ~= true or entry.amount ~= 0 then return false end
            elseif not Integer(entry.unitPrice)
                or entry.amount ~= entry.quantity * entry.unitPrice * entry.direction then return false end
        elseif entry.pending then return false end
        total, count = total + entry.amount, count + 1
    end
    if count ~= #context.history or total ~= Module.State.Element then return false end
    for index = 1, count do if context.history[index] == nil then return false end end
    Module.State.History, Module.State.PendingPrices = context.history, {}
    ResetRuntime()
    for _, entry in ipairs(context.history) do
        if entry.pending then
            local pending = Module.State.PendingPrices[entry.itemID] or {}
            Module.State.PendingPrices[entry.itemID] = pending
            table.insert(pending, entry)
        end
    end
    for itemID in pairs(Module.State.PendingPrices) do C_Item.RequestLoadItemDataByID(itemID) end
    return true
end

Module.FormatValue = function(value)
    local rounded = math.floor(math.abs(value) + 0.5)
    return (value < 0 and "-" or "") .. string.format("%dg %ds %dc",
        math.floor(rounded / 10000), math.floor(rounded / 100) % 100, rounded % 100)
end

Module.CustomFormatAnnouncement = function(total, duration, perHour)
    return string.format("%s/h - %s (%s estimated net total)", perHour, duration, total)
end

Module.CustomGetContext = function()
    return next(Module.State.PendingPrices) and "Estimated net value; item prices pending."
        or "Estimated net value (vendor prices)."
end

Module.CustomOnEvent = function(self, event, ...)
    local state = Module.State
    local first, second, third, fourth = ...
    if event == "UI_ERROR_MESSAGE" then
        state.Expense = nil
        return
    end
    local context = CONTEXT_EVENTS[event]
    if context then
        local closed = event:match("CLOSED$")
        state.ExternalContexts[context] = not closed or nil
        if closed then state.IgnorePushedUntil = GetTime() + 1 end
        state.Casts = {}
        state.RepairCost = GetRepairAllCost()
        return
    end
    if event == "TAXIMAP_OPENED" or event == "MERCHANT_UPDATE" then
        -- Native calls may close their window before the secure post-hook runs.
        -- Keep the quote while it is still available, then require an actual debit.
        state.RepairCost = GetRepairAllCost()
        if event == "TAXIMAP_OPENED" and NumTaxiNodes then
            for index = 1, NumTaxiNodes() do state.TaxiCosts[index] = TaxiNodeCost(index) end
        end
        return
    end
    -- A delayed item lookup belongs to the original accepted event, even while paused.
    if event == "GET_ITEM_INFO_RECEIVED" or event == "ITEM_DATA_LOAD_RESULT" then
        if not Integer(first) or not Readable(second, "boolean") or not second then return end
        local pending = state.PendingPrices[first]
        if pending then
            for index = #pending, 1, -1 do
                if ResolveEntry(pending[index]) then table.remove(pending, index) end
            end
            if #pending == 0 then state.PendingPrices[first] = nil end
            Refresh()
        end
        if Running() then state.Inventory = Inventory() end
        return
    end
    if event == "PLAYER_MONEY" then
        local current, previous = GetMoney(), state.LastMoney
        state.LastMoney = current
        if Running() and Integer(current) and Integer(previous) and current < previous then
            local expense = state.Expense
            state.Expense = nil
            if expense and GetTime() - expense.at <= 2 and previous - current <= expense.maximum
                and (not expense.exact or previous - current == expense.maximum) then
                Record(expense.source, current - previous)
            end
        end
        return
    end
    if not Running() then return end
    if event == "CHAT_MSG_MONEY" then
        if not Readable(first, "string") then return end
        local money = MatchFormat(first, YOU_LOOT_MONEY_GUILD) or MatchFormat(first, LOOT_MONEY_SPLIT_GUILD)
            or MatchFormat(first, YOU_LOOT_MONEY) or MatchFormat(first, LOOT_MONEY_SPLIT)
        local amount = money and MoneyFromText(money)
        if amount and amount > 0 then Record("loot_money", amount) end
    elseif event == "CHAT_MSG_LOOT" then
        if not Readable(first, "string") or ExternalItems() then return end
        local link, quantity, source
        for index, format in ipairs({ LOOT_ITEM_SELF_MULTIPLE, LOOT_ITEM_PUSHED_SELF_MULTIPLE,
            LOOT_ITEM_SELF, LOOT_ITEM_PUSHED_SELF }) do
            link, quantity = MatchFormat(first, format)
            if link then
                if (index == 2 or index == 4) and GetTime() < state.IgnorePushedUntil then return end
                source = (index == 2 or index == 4) and "item_reward" or "loot_item"
                break
            end
        end
        quantity = tonumber(quantity) or 1
        if link and link:match("item:%d+") and Integer(quantity) and quantity > 0 then
            Record(source, 0, link, quantity, 1)
        end
    elseif event == "QUEST_TURNED_IN" then
        if Integer(first) and Integer(third) and third > 0 then Record("quest_money", third, nil, nil, nil, first) end
    elseif event == "BAG_UPDATE_DELAYED" then
        local current = Inventory()
        ReconcileCasts(current)
        state.Inventory = current
    elseif event:match("^UNIT_SPELLCAST_") then
        local spellID = event == "UNIT_SPELLCAST_SENT" and fourth or third
        if not Readable(first, "string") or first ~= "player" or not Integer(spellID) then return end
        if event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
            local pending = state.Casts[spellID]
            if pending and not pending.succeeded then state.Casts[spellID] = nil end
            return
        end
        if ExternalItems() then return end
        if event == "UNIT_SPELLCAST_SUCCEEDED" and Readable(second, "string")
            and state.LastCasts[spellID] == second then return end
        local cast = state.Casts[spellID]
        if event == "UNIT_SPELLCAST_SENT" or not cast then
            cast = { at = GetTime(), items = {} }
            for itemID, item in pairs(state.Inventory) do
                if item.spellID == spellID then cast.items[itemID] = item end
            end
            if not next(cast.items) then return end
            state.Casts[spellID] = cast
        end
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            if Readable(second, "string") then state.LastCasts[spellID] = second end
            cast.succeeded, cast.at = true, GetTime()
            local current = Inventory()
            ReconcileCasts(current)
            state.Inventory = current
        end
    end
end

local function ExpenseIntent(source, maximum, exact)
    if PerHour.Modules.Gold ~= Module or not Running() or not Integer(maximum) or maximum <= 0 then return end
    Module.State.Expense = { source = source, maximum = maximum, exact = exact, at = GetTime() }
end

-- Observe native actions without replacing secure functions or initiating transactions.
if RepairAllItems then
    hooksecurefunc(_G, "RepairAllItems", function(useGuildBank)
        if not useGuildBank then
            local price = GetRepairAllCost()
            ExpenseIntent("repair", Integer(price) and price > 0 and price or (Module.State and Module.State.RepairCost), true)
        end
    end)
end
if TakeTaxiNode then
    hooksecurefunc(_G, "TakeTaxiNode", function(index)
        local price = TaxiNodeCost(index)
        ExpenseIntent("transport", Integer(price) and price > 0 and price or (Module.State and Module.State.TaxiCosts[index]), true)
    end)
end

local function SingleRepairIntent()
    if InRepairMode and InRepairMode() then
        local price = GetRepairAllCost()
        ExpenseIntent("repair", Integer(price) and price > 0 and price or (Module.State and Module.State.RepairCost))
    end
end
for _, method in ipairs({ "PickupContainerItem", "UseContainerItem" }) do
    if C_Container[method] then hooksecurefunc(C_Container, method, SingleRepairIntent) end
end
if PickupInventoryItem then hooksecurefunc(_G, "PickupInventoryItem", SingleRepairIntent) end
