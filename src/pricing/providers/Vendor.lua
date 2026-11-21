local Provider = {}
PerHour.Pricing.Providers.Vendor = Provider

function Provider:GetQuote(itemID, itemLink)
    local _, _, _, _, _, _, _, _, _, _, price, classID, _, bindType = C_Item.GetItemInfo(itemLink or itemID)
    if not PerHour.Pricing:IsPrice(price) then return end
    -- ItemBind.None / OnEquip / OnUse can be traded before binding. Quest,
    -- bind-on-acquire and account-bound rewards must never receive AH values.
    local marketable = Utils:IsReadableNumber(classID) and classID ~= 12
        and Utils:IsReadableNumber(bindType) and (bindType == 0 or bindType == 2 or bindType == 3)
    return { unitPrice = price, provider = "vendor", marketable = marketable }
end
