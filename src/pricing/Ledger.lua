local Pricing = PerHour.Pricing
local Ledger = {}
Ledger.__index = Ledger

function Ledger:AddIncome(entry)
    if not entry.pending and entry.unitPrice == 0 then return end
    local queue = self.Items[entry.itemID]
    if not queue then queue = { first = 1 }; self.Items[entry.itemID] = queue end
    queue[#queue + 1] = { entry = entry, remaining = entry.quantity }
end

function Ledger:Take(itemID, quantity)
    local parts, remaining = {}, quantity
    local queue = self.Items[itemID]
    while queue and queue.first <= #queue and remaining > 0 do
        local lot = queue[queue.first]
        if lot.remaining == 0 then queue.first = queue.first + 1
        else
            local quantity = math.min(remaining, lot.remaining)
            parts[#parts + 1] = { quantity = quantity, origin = lot.entry }
            lot.remaining, remaining = lot.remaining - quantity, remaining - quantity
        end
    end
    if remaining > 0 then parts[#parts + 1] = { quantity = remaining } end
    return parts
end

function Ledger:Allocate(entry)
    local bindings = self:Take(entry.itemID, entry.quantity)
    self.Bindings[entry] = bindings
    return bindings
end

function Ledger:HasIncome(itemID)
    local queue = self.Items[itemID]
    while queue and queue.first <= #queue and queue[queue.first].remaining == 0 do
        queue.first = queue.first + 1
    end
    return queue and queue.first <= #queue
end

function Ledger:AddExpense(entry)
    local bindings = self:Allocate(entry)
    if entry.valuations then return end
    entry.valuations = {}
    for _, binding in ipairs(bindings) do
        entry.valuations[#entry.valuations + 1] = { quantity = binding.quantity, acquired = binding.origin ~= nil }
    end
end

function Ledger:RestoreExpense(entry)
    local bindings = {}
    for index, part in ipairs(entry.valuations) do
        -- Zero-valued receipts may already have been discarded from history.
        -- Old-stock parts never consume acquired lots during reconstruction.
        if part.acquired and part.unitPrice ~= 0 then
            local taken = self:Take(entry.itemID, part.quantity)
            if #taken ~= 1 or not taken[1].origin then return false end
            local origin = taken[1].origin
            if part.unitPrice ~= nil and (origin.pending or origin.unitPrice ~= part.unitPrice
                or (origin.priceSource or "vendor") ~= part.priceSource or origin.priceMetric ~= part.priceMetric) then return false end
            bindings[index] = taken[1]
        elseif not part.acquired and self:HasIncome(entry.itemID) then return false
        else bindings[index] = { quantity = part.quantity } end
    end
    self.Bindings[entry] = entry.pending and bindings or nil
    return true
end

local function Summary(parts)
    local total, unitPrice, source, metric = 0, parts[1].unitPrice, parts[1].priceSource, parts[1].priceMetric
    for _, part in ipairs(parts) do
        total = total + part.unitPrice * part.quantity
        if part.unitPrice ~= parts[1].unitPrice then unitPrice = nil end
        if part.priceSource ~= parts[1].priceSource or part.priceMetric ~= parts[1].priceMetric then
            source, metric = "mixed", nil
        end
    end
    return total, unitPrice, source, metric
end

function Ledger:ResolveExpense(entry)
    local complete = true
    for index, part in ipairs(entry.valuations) do
        if part.unitPrice == nil then
            local binding = self.Bindings[entry][index]
            local origin = binding and binding.origin
            if origin then
                if origin.pending then complete = false
                else
                    part.unitPrice = origin.unitPrice
                    part.priceSource, part.priceMetric = origin.priceSource or "vendor", origin.priceMetric
                end
            else
                local quote = Pricing:GetQuote(entry.itemID, entry.itemLink)
                if quote then Pricing:ApplyQuote(part, quote) else complete = false end
            end
        end
    end
    if not complete then return false end
    local total, unitPrice, source, metric = Summary(entry.valuations)
    entry.unitPrice, entry.priceSource, entry.priceMetric = unitPrice, source, metric
    entry.amount, entry.pending = -total, nil
    self.Bindings[entry] = nil
    return true
end

function Ledger:Discard(entry)
    self.Bindings[entry] = nil
    if entry.direction > 0 then
        local queue = self.Items[entry.itemID]
        for _, lot in ipairs(queue or {}) do if lot.entry == entry then lot.remaining = 0 end end
    end
end

function Pricing:CreateLedger(history)
    local ledger = setmetatable({ Items = {}, Bindings = {} }, Ledger)
    for _, entry in ipairs(history) do
        if entry.itemID then
            if entry.direction > 0 then ledger:AddIncome(entry)
            elseif entry.valuations then
                if not ledger:RestoreExpense(entry) then return end
            else
                ledger:Allocate(entry)
                ledger.Bindings[entry] = nil
            end
        end
    end
    return ledger
end

local function DenseArray(parts)
    if type(parts) ~= "table" or #parts == 0 then return false end
    local count = 0
    for index in pairs(parts) do
        if not Pricing:IsPrice(index) or index < 1 or index > #parts then return false end
        count = count + 1
    end
    return count == #parts
end

local function Metadata(value)
    return (value.priceSource == "vendor" and value.priceMetric == nil)
        or (value.priceSource == "tsm" and value.priceMetric == "DBMarket")
        or (value.priceSource == "auctionator" and value.priceMetric == "lastScan")
end

function Pricing:ValidateEntry(entry)
    if entry.pricingVersion ~= 1 then return false end
    if entry.pending ~= nil and entry.pending ~= true then return false end
    if entry.valuations then
        if entry.direction ~= -1 or (entry.source ~= "consumable" and entry.source ~= "quest_turnin")
            or not DenseArray(entry.valuations) then return false end
        local quantity, missing = 0, false
        for _, part in ipairs(entry.valuations) do
            if type(part) ~= "table" or not self:IsPrice(part.quantity) or part.quantity < 1
                or type(part.acquired) ~= "boolean" then return false end
            quantity = quantity + part.quantity
            if part.unitPrice == nil then
                if not entry.pending or part.priceSource ~= nil or part.priceMetric ~= nil then return false end
                missing = true
            elseif not self:IsPrice(part.unitPrice) or not Metadata(part) then return false end
        end
        if quantity ~= entry.quantity then return false end
        if entry.pending then
            return missing and entry.unitPrice == nil and entry.amount == 0
                and entry.priceSource == nil and entry.priceMetric == nil
        end
        local total, unitPrice, source, metric = Summary(entry.valuations)
        return self:IsPrice(total) and entry.amount == -total and entry.unitPrice == unitPrice
            and entry.priceSource == source and entry.priceMetric == metric
    end
    if entry.direction ~= 1 or (entry.source ~= "loot_item" and entry.source ~= "item_reward") then return false end
    if entry.pending then
        return entry.unitPrice == nil and entry.priceSource == nil and entry.priceMetric == nil and entry.amount == 0
    end
    return self:IsPrice(entry.unitPrice) and Metadata(entry)
        and entry.amount == entry.quantity * entry.unitPrice
end
