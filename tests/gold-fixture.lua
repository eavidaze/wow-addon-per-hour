-- Native APIs exercised by the Gold tracker; no price lookup or bag gain is mocked
-- at the module boundary, so tests cover the client events and their ordering.
local fixture = { money = 1000000, items = {}, bags = {}, requests = {}, repairCost = 0, taxiCost = 0 }
YOU_LOOT_MONEY = "You loot %s"
LOOT_MONEY_SPLIT = "Your share of the loot is %s."
YOU_LOOT_MONEY_GUILD = "You loot %s (%s deposited to guild bank)"
LOOT_MONEY_SPLIT_GUILD = "Your share of the loot is %s (%s deposited to guild bank)."
GOLD_AMOUNT, SILVER_AMOUNT, COPPER_AMOUNT = "%d Gold", "%d Silver", "%d Copper"
LOOT_ITEM_SELF, LOOT_ITEM_SELF_MULTIPLE = "You receive loot: %s.", "You receive loot: %sx%d."
LOOT_ITEM_PUSHED_SELF, LOOT_ITEM_PUSHED_SELF_MULTIPLE = "You receive item: %s.", "You receive item: %sx%d."

function fixture.link(id) return "|cffffffff|Hitem:" .. id .. ":0:0:0|h[Item " .. id .. "]|h|r" end
function GetMoney() return fixture.money end
function GetRepairAllCost() return fixture.repairCost end
function InRepairMode() return fixture.repairMode or false end
function RepairAllItems() end
function PickupInventoryItem() end
function TakeTaxiNode() end
function TaxiNodeCost() return fixture.taxiCost end
function NumTaxiNodes() return 1 end
C_Item = {
    GetItemInfo = function(value)
        local id = type(value) == "number" and value or tonumber(value:match("item:(%d+)"))
        local item = fixture.items[id]
        if not item or item.available == false then return end
        return "Item " .. id, fixture.link(id), 1, 1, 1, "Type", "Subtype", 20, "", 0,
            item.price, item.class or 0, 1
    end,
    GetItemSpell = function(value)
        local id = tonumber(value:match("item:(%d+)"))
        local item = fixture.items[id]
        if item and item.spell then return "Use", item.spell end
    end,
    RequestLoadItemDataByID = function(id) fixture.requests[id] = true end,
}
C_Container = {
    GetContainerNumSlots = function(bag) return bag == 0 and 20 or 0 end,
    GetContainerItemInfo = function(bag, slot)
        local item = bag == 0 and fixture.bags[slot]
        if item then return { itemID = item.id, stackCount = item.count, hyperlink = fixture.link(item.id) } end
    end,
}
function fixture.reset()
    fixture.money, fixture.items, fixture.bags, fixture.requests = 1000000, {}, {}, {}
    fixture.repairCost, fixture.taxiCost, fixture.repairMode = 0, 0, false
    MailFrame, TradeFrame, MerchantFrame, BankFrame = nil, nil, nil, nil
end
return fixture
