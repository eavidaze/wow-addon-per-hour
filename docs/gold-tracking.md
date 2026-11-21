# Gold tracking (M1)

Show **Gold** from the minimap menu or Settings, then use Start / Pause / Resume
and Reset as with the other trackers. The panel shows estimated net gold per
hour or minute (`g/h`, `g/min`), with up to two decimal places. The tooltip and
announcement show gold, silver and copper. Amounts remain in copper internally;
negative totals and rates are allowed.

## What counts

| Event | Effect on the session |
| --- | --- |
| Money looted by the player, including a party share | Add the player's amount, excluding guild deposits. |
| Looted items and received item rewards, including quest items | Add vendor unit price × quantity when received. |
| Quest money | Add the `moneyReward` from `QUEST_TURNED_IN`. |
| Consumable actually used, including food and potions already in the bags | Subtract vendor value of one consumed item. |
| Personal repair, including repair-all and individual repair | Subtract the actual money debit associated with the native repair action. |
| Paid taxi flight | Subtract the actual money debit associated with the selected route. |

An item contributes when collected, so selling it later does not contribute
again. Selling old inventory is also excluded. Ordinary money-balance changes
are never treated as income. Trades, mail, item purchases, buybacks, crafting,
bank transfers, and guild-funded repairs are excluded in M1. Purchases are not
deducted: consumables contribute their vendor cost when used, avoiding a charge
for both buying and consuming them. This is estimated farming value rather than
cash profit or acquisition-cost accounting. Auctionator is reserved for M2.

Item data may not yet be cached. The journal keeps such entries pending and
requests native item data; the tooltip reports pending prices. When data arrives,
only the original accepted entry is settled, including during a pause. A known
zero vendor price is a resolved zero-value entry. Resolved prices stay fixed.

## Detection and boundaries

Loot messages match the client's localized self-loot/item-reward formats; they
do not depend on English text. Money uses localized coin formats. Bag additions
alone never create income. Mail, trade, vendor and bank windows suppress item
receipts; a short grace period also excludes pushed receipts after closure.

Consumption requires both a successful player cast matching a consumable's
`C_Item.GetItemSpell` and a confirmed decrease in that item's carried count.
The sent-cast snapshot permits bag updates before or after cast success. A failed
cast, an ambiguous loss involving several items with the same spell, sales,
destroying items and ordinary bag movements do not establish consumption.
Successful channels remain eligible if interrupted after their initial use.
Only readable, non-secret values are inspected. Restricted casts cannot establish
consumption and are skipped; this must be checked in Forever combat.

Repair and taxi secure post-hooks only observe native actions. A matching money
debit must arrive within two seconds; no transaction is initiated by Per Hour.
Repair-all and flights require the quoted amount; individual repairs allow up
to the quoted repair-all cost. Native action errors and unmatched debits discard
pending intents. The short window bounds correlations with money changes but
cannot identify transactions by a server transaction ID. A server delay beyond
this window can leave an expense
unrecorded, so test actual event ordering and costs in the game.

New gains and consumption while paused, outside the world, or awaiting session
verification are excluded. Pausing, resuming and entering the world refresh
inventory and money baselines and discard pending runtime action correlations.
The existing shared timer samples a running Gold session; paused Gold does not
keep it running. Hiding the panel keeps tracking active.

## Journal and persistence

M1 records the journal; its player-facing history view belongs to M1.5.
`Gold.State.History` contains active-session elapsed time, source, signed amount
in copper, and direction (`1` or `-1`). Item entries also hold item ID/link,
quantity, vendor unit price or `pending = true`; quest money holds the quest ID.
Pushed item rewards use `item_reward`, distinct from corpse/self loot items.

The journal is saved per character in the existing session context:
`sessions.Gold.context = { version = 1, history = ... }`. Pending price entries
survive reload, and restoration checks that journal amounts sum to the saved
total. Malformed context is rejected through the existing restore warning.
The journal lasts until Reset, without a silent entry cap. Normal reload/logout
saves it; abrupt exits and unobserved offline events have the existing session
limitations. No previous data or settings are migrated, and the shared save
format remains version 2.

## Validation

Run `lua tests/forever.lua` with Lua 5.1; it includes `tests/gold.lua` for income,
expenses, localization, delayed prices, pauses, negative totals, journal integrity
and save/restore behavior. These are simulations, not in-game validation.

In WoW Forever, verify solo/group looted coins, guild deposits, stacked loot and
quest rewards; confirm trade/mail/vendor receipts and old-item sales are excluded.
Consume food and potions through bags, action buttons and macros, including
failed uses and interrupted food channels. Test individual, personal repair-all,
guild repairs, item purchases and multi-hop taxi fares. Confirm the actual event
order against journal entries. Check money formatting, hidden/paused tracking,
map transitions, normal logout, `/reload`, Reset and independent characters.

API references: [item prices and spells](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua),
[quest rewards](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua),
[cast events](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua),
[native repair actions](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/MerchantFrame.xml)
and [native taxi actions](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Shared/TaxiFrame.xml).
