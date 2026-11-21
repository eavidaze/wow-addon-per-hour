# Gold tracking

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
| Items delivered to a completed quest | Subtract vendor unit price × confirmed required quantity, including items already in the bags before the session. |
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
zero vendor price is ignored, including unsellable quest items. A pending entry
is removed if its loaded price is zero; missing item data is never treated as a
zero price. Valuable quest rewards remain included. Resolved positive prices
stay fixed. Zero-value consumable uses are also omitted.

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

Quest deliveries capture item links and required quantities from the native
quest dialog (`GetNumQuestItems`, `GetQuestItemInfo("required", index)` and
`GetQuestItemLink("required", index)`), using `GetQuestID()` for identity.
`QUEST_TURNED_IN` must confirm that same quest, and carried inventory must show
the full required loss. Bag updates may precede completion or follow within two
seconds. Each item produces one `quest_turnin` expense for its required quantity;
extra copies remaining in the bags are not charged. Overlapping deliveries cannot
reuse the same observed loss. The recorded time is the completion time, even if
the bag evidence or vendor price arrives later. Known zero-value items are omitted;
uncached prices use the existing pending-price journal and survive reload once
the delivery has been recorded.

Canceled dialogs, unrelated quests, partial or missing losses, and requirements
without an identifiable item link never create speculative expenses. Opening a
quest dialog alone does not charge anything. Pause, Reset, world entry and external
inventory contexts clear unconfirmed runtime correlations. Dialog close allows
two seconds for the native completion event. Delivery evidence outside the short
window, items taken directly from bank storage, and simultaneous gains that mask
the required bag loss may be missed. Verify these boundaries and actual event
ordering in Forever; no past deliveries are reconstructed or migrated.

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

M1 records the journal; M1.5 displays it through Gold's **Details** action.
`Gold.State.History` contains active-session elapsed time, an event `timestamp`
from `GetServerTime()` for new records, source, signed amount
in copper, and direction (`1` or `-1`). Item entries also hold item ID/link,
quantity, vendor unit price or `pending = true`; quest money holds the quest ID.
Pushed item rewards use `item_reward`, distinct from corpse/self loot items.
When `QUEST_LOOT_RECEIVED` supplies an ID, it annotates a matching pushed item
receipt with `questID`, using the full item link and quantity within two seconds
in either event order. This metadata event never adds income or another history
entry. Ambiguous or unmatched receipts keep their generic origin. Only the native
quest-loot event establishes pushed-reward identity; the most recently completed
quest is never assumed to be the source. Runtime correlations are cleared on pause, world entry
and external inventory contexts. Existing history without item quest IDs remains
readable, with no backfill or migration.

The journal is saved per character in the existing session context:
`sessions.Gold.context = { version = 1, history = ... }`. Pending price entries
survive reload, and restoration checks that journal amounts sum to the saved
total. Malformed context is rejected through the existing restore warning.
The journal lasts until Reset, without a silent entry cap. Normal reload/logout
saves it; abrupt exits and unobserved offline events have the existing session
limitations. No previous data or settings are migrated, and the shared save
format remains version 2.

## Gold Details (M1.5)

Left-click the Gold tracker's background or rate to open Details, or choose
**Gold → Options → Details** between **Settings** and **Announce**. The tracker
tooltip shows **Left-click: Details**. Both actions open the same panel without
starting or pausing the session. Dragging still moves the tracker; Start/Pause,
Options and Close retain their own actions. The
560 × 512 panel shares Settings' border, boxed title, dragging and close controls.
It has three columns: **Time**, **Event** and **Value**. Headers sit below the
session summary, immediately above the event list. The summary
uses three rows: **Loot & rewards** (incoming money and vendor-valued items),
**Expenses & items used** (money spent and the value of consumed/delivered items),
and **Estimated net profit** (income minus expenses). Labels use the same normal
font size and left indentation as event names. Income labels and values use DS
white; expenses use DS red; net profit uses DS gold. Summary amounts stay
aligned with the right edge of Value. Pending prices appear between the summary
and headers. The left edge has 15 px of additional inset (30 px from the panel
edge), shared by the summary, headers, pending notice and event list. Value and
scrollbar positions on the right stay fixed; the window size and viewport height
are unchanged. Each event occupies one
26 px line; origin and quantity have no separate columns. Item quantities greater
than one appear in the name, such as `Healing Potion x2`; a single item has no
`x1` suffix. Native item buttons are scaled to half size (18.5 px), preserving
their artwork. A native yellow quest `!` sits between the event icon and name
only when a `questID` is recorded. Its slot is reserved on every row to align
names, with a hover area larger than the symbol. Fonts and money symbols use the
native game presentation.
**Items valued at vendor prices.** appears in the tracker tooltip and as a
discreet note below the Details event list. It describes item valuation; looted
money, quest money, repairs and transport keep their recorded amounts. The tooltip
also appends **Item prices pending.** while any accepted item price is unresolved.
Each row has a thin copper lower border. The DS owns its color
(`0.72, 0.45, 0.40` RGB), 3 px height and 20% opacity through `Theme.rowDivider`.
An identical border sits above the first visible row, at the top of the list;
it stays in place during scrolling and is hidden when there are no events.
The border uses a solid color so the copper stays visible. There is no alternating fill or full
outline around each row. Borders span the row width, sit beneath the row content
and do not receive mouse input. Recycled rows retain the same lower border.
Text, arrows and icons are vertically centered in the 23 px between borders,
excluding the lower separator from their content area. The full row stays 26 px.
Native up/down arrows at the leading edge of the event icon indicate incoming
and outgoing movements. They sit on the background layer, use DS green/red and
have no mouse interaction. Direction remains readable by shape as well as color.

Example with illustrative values and Portuguese labels. Braced markers name the
intended native icons: `{item}` uses the actual item's icon, `{fly}` a flight
icon, `{anvil}` an anvil/repair icon and `{bag}` a native loot pouch
(`INV_Misc_Bag_10`) for money. Looted money is labeled **Looted**.
`{up}` and `{down}` represent the direction arrows behind the leading icon edge.
Times show when each event happened as `HH:MM:SS` in the player's local time,
with the newest events first. Saved timestamps survive reload and remain fixed
when pending prices resolve. Older records without a timestamp display `—`;
their time is not reconstructed and saved history is not migrated.

**Gold Details**

| Resumo | Valor |
| --- | ---: |
| Loot e recompensas | **3g 60s** |
| Despesas e itens usados | **87s** |
| Lucro líquido estimado | **2g 73s** |

| Tempo | Evento | Valor |
| --- | --- | ---: |
| 14:12:55 | {down} {item} ! Costela de javali x10 | 20s |
| 14:12:34 | {down} {fly} Transporte | 12s |
| 14:12:10 | {down} {anvil} Reparo | 30s |
| 14:10:42 | {down} {item} Poção de cura | 25s |
| 14:09:20 | {up} {item} ! Tecido de linho x4 | 40s |
| 14:08:15 | {up} {bag} ! Recompensa | 2g |
| 14:07:02 | {up} {bag} Moedas coletadas | 1g 20s |

The summary has no visible header or divider in the actual panel: its labels
align with event names, and its amounts align with event values.
The first outgoing item row represents ten ribs delivered to the quest: its
item icon opens the item tooltip and its `!` opens the completed quest tooltip.

Item rows use the actual item icon and the standard item tooltip on hover,
preferring the saved item link to preserve item-specific properties. Loot-pouch
icons show a standard GameTooltip with **Looted money** or **Quest reward** and
the recorded value using native money symbols. Flight and repair icons have no
tooltip. All event names remain passive and have no tooltip.
In this example, `!` represents the native quest icon, not a typed character.
For money or item entries with a saved `questID`, only the `!` opens the quest's
standard tooltip. The item tooltip appears only on the item's icon; all event
names are passive and have no tooltip. Generic `item_reward`
entries without a quest ID have no `!`; the view never infers an association.
Amounts use native gold, silver and copper symbols. Pending item prices remain
explicitly marked until resolved.
The Value column shows absolute amounts without plus or minus signs; arrows
identify direction. The net summary keeps a minus sign when negative. Outgoing
values use shared DS red
(`Theme.red.text`, matching Blizzard's standard red) rather than gray. Incoming
and pending values use normal DS text. Item names and rarity styling retain their
native presentation. Row reuse always reapplies the appropriate arrow and color.

The open list updates while preserving the scroll position when reviewing older
events. It remains available during a pause and shows an empty-state message
when the session has no events.
The native `WowScrollBoxList` and `MinimalScrollBar` recycle rows for the visible
viewport. Data changes are batched into one deferred refresh; the panel has no
per-frame polling. At the top, new events appear immediately; when scrolled,
the same older entry and fractional row position are retained, including when
reopening after hidden gains. Reset clears the list and summary. Pending item
data updates names, icons, values and the pending count. Closing Details leaves
Gold tracking active and unregisters the panel's metadata listeners. The window
and its position are kept only for the current UI session; no new settings or
data migrations are introduced.
Previously saved zero-value item entries are hidden from Details without
rewriting their journal. Scroll anchoring follows the same surviving event when
a pending zero-value item disappears above or below the current viewport.

## Validation

Run `lua tests/forever.lua` with Lua 5.1; it includes `tests/gold.lua` for income,
expenses, localization, delayed prices, pauses, negative totals, journal integrity
and save/restore behavior. These are simulations, not in-game validation.
`tests/gold-details.lua` also checks menu placement, the compact three-column
layout, native components, item and quest tooltips, summary accounting, pending
prices, bounded row reuse, scroll anchoring, pause, Reset and restored history.
`tests/gold-quest-deliveries.lua` covers required quantities, completion and bag
event ordering, multiple items, duplicate/overlapping deliveries, pending prices,
save/restore, native item/quest tooltips and rejected ambiguous or canceled cases.

In WoW Forever, verify solo/group looted coins, guild deposits, stacked loot and
quest rewards; confirm trade/mail/vendor receipts and old-item sales are excluded.
Turn in vendor-valued items such as meat, including split stacks and extra copies;
verify that each delivered quantity becomes a separate expense with its quest
tooltip. Also test canceled dialogs, repeatable quests and rapid consecutive
turn-ins involving the same item.
Consume food and potions through bags, action buttons and macros, including
failed uses and interrupted food channels. Test individual, personal repair-all,
guild repairs, item purchases and multi-hop taxi fares. Confirm the actual event
order against journal entries. Check money formatting, hidden/paused tracking,
map transitions, normal logout, `/reload`, Reset and independent characters.
For Details, verify native scrollbar dragging and mouse-wheel scrolling, full
item names in tooltips, long event-name truncation, 18.5 px icons, monetary column
alignment, local clock times and both Close controls. While reading older entries, collect more loot
and confirm that the same entry stays in view. Hover an item's icon and its
quest marker separately to check both standard tooltips. Native drawing,
clipping and mouse routing still need in-game validation.

API references: [item prices and spells](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua),
[quest item receipts](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/LootDocumentation.lua),
[quest rewards](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua),
[native required quest items](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestFrame.lua),
[native quest item links](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestInfo.lua),
[cast events](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua),
[native repair actions](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/MerchantFrame.xml)
and [native taxi actions](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Shared/TaxiFrame.xml).

Clock reference: [native time APIs](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SystemTimeDocumentation.lua).
