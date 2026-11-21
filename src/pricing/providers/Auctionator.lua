local Provider = {}
PerHour.Pricing.Providers.Auctionator = Provider

function Provider:GetQuote(itemID, itemLink)
    local api = type(Auctionator) == "table" and type(Auctionator.API) == "table" and Auctionator.API.v1
    if type(api) ~= "table" then return end
    local ok, value
    -- Prefer the full link so equipment variants retain their own valuation.
    if itemLink and type(api.GetAuctionPriceByItemLink) == "function" then
        ok, value = pcall(api.GetAuctionPriceByItemLink, "PerHour", itemLink)
    end
    local price = ok and PerHour.Pricing:MarketPrice(value)
    if not price and type(api.GetAuctionPriceByItemID) == "function" then
        ok, value = pcall(api.GetAuctionPriceByItemID, "PerHour", itemID)
        price = ok and PerHour.Pricing:MarketPrice(value)
    end
    if price then return { unitPrice = price, provider = "auctionator", metric = "lastScan" } end
end
