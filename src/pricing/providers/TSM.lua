local Provider = {}
PerHour.Pricing.Providers.TSM = Provider

function Provider:GetQuote(itemID, itemLink)
    local api = TSM_API
    if type(api) ~= "table" or type(api.ToItemString) ~= "function"
        or type(api.GetCustomPriceValue) ~= "function" then return end
    local ok, itemString = pcall(api.ToItemString, itemLink or ("item:" .. itemID))
    if not ok or (issecretvalue and issecretvalue(itemString)) or type(itemString) ~= "string" or itemString == "" then return end
    local success, value = pcall(api.GetCustomPriceValue, "DBMarket", itemString)
    local price = success and PerHour.Pricing:MarketPrice(value)
    if price then return { unitPrice = price, provider = "tsm", metric = "DBMarket" } end
end
