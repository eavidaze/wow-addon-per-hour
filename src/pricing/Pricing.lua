local Pricing = { Providers = {} }
PerHour.Pricing = Pricing
local PRIORITY = { "TSM", "Auctionator" }

function Pricing:IsPrice(value)
    return Utils:IsFiniteNumber(value) and value >= 0 and value == math.floor(value)
        and value <= 9007199254740991
end

function Pricing:MarketPrice(value)
    if not Utils:IsFiniteNumber(value) or value <= 0 or value > 9007199254740991 then return end
    local rounded = math.floor(value + 0.5)
    if rounded > 0 then return rounded end
end

function Pricing:GetVendorQuote(itemID, itemLink)
    return self.Providers.Vendor:GetQuote(itemID, itemLink)
end

function Pricing:GetQuote(itemID, itemLink)
    local vendor = self:GetVendorQuote(itemID, itemLink)
    -- Native metadata establishes both the vendor floor and AH eligibility.
    if not vendor then return end
    if vendor.marketable then
        for _, name in ipairs(PRIORITY) do
            local quote = self.Providers[name]:GetQuote(itemID, itemLink)
            if quote then
                if quote.unitPrice > vendor.unitPrice then return quote end
                return vendor
            end
        end
    end
    return vendor
end

function Pricing:ApplyQuote(target, quote)
    target.unitPrice, target.priceSource, target.priceMetric = quote.unitPrice, quote.provider, quote.metric
end

function Pricing:SourceLabel(source, metric)
    if source == "tsm" then return "TSM (" .. (metric or "DBMarket") .. ")" end
    if source == "auctionator" then return "Auctionator (last scan)" end
    if source == "mixed" then return "Mixed recorded prices" end
    return "Vendor"
end

function Pricing:EntrySourceLabel(entry)
    if entry.pending then return "Price pending" end
    return self:SourceLabel(entry.priceSource, entry.priceMetric)
end
