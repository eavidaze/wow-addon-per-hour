# Gold tracking

Gold participates in the same Start / Pause / Resume / Finish period as XP,
honor and reputation. The dashboard shows estimated net g/h or g/m; Session
Details keeps copper precision, composition and recorded events.

## What counts

| Event | Effect |
| --- | --- |
| Money looted by the player, including party share | Add only the player's amount, excluding guild deposits. |
| Looted items and item rewards | Add selected unit quote times quantity when received. |
| Quest money | Add the moneyReward from QUEST_TURNED_IN. |
| Items delivered to a completed quest | Subtract confirmed required quantity at recorded acquisition values or a fresh old-stock quote. |
| Consumable actually used | Subtract one recorded acquisition value, or quote unmatched old stock at use. |
| Personal repair | Subtract actual money debit matched to the native repair action. |
| Paid taxi flight | Subtract actual debit matched to the selected route. |

Selling an item already valued at collection never counts again. Ordinary wallet
changes, sales, trades, mail, purchases, buybacks, crafting, bank transfers and
guild-funded repairs are excluded. Purchases are not also deducted: a consumable
is valued when used. This measures estimated farming value, not cash profit or
purchase-cost accounting.

## Prices and session-local stock

The fixed priority is TSM DBMarket -> Auctionator last scan -> Vendor, with vendor
as the minimum. Providers are optional. Gray items always use vendor value.
Binding/quality/quest-item metadata controls market eligibility. Prices use integer
copper; invalid, unavailable or restricted market values fall through. Missing
native metadata stays pending; missing market data uses vendor immediately.

Accepted quotes stay fixed. Pending accepted entries can settle while the session
remains open, including pause and recovery, without adding a second income event.
Known zero-value items are omitted; missing data is not treated as zero.

The ledger allocates acquisitions FIFO within the current session. Observed bag
losses that are not expenses retire available lots, without changing collection
income. Replacements do not inherit a departed unit's acquisition value. Expenses
can contain several saved price/source parts, with separate old-stock provenance.

There is no stock ledger shared across finalized sessions. A potion valued at
10 g in A and used in B at a 12 g quote costs an estimated 12 g in B. Deleting or
expiring A has no effect on B.

## Capture boundaries

Loot and reward messages use the client's localized self formats. Bag additions
alone never create income. Native mail/trade/vendor/bank contexts suppress external
pushed receipts, including a short grace period after closing their windows.

Consumables require a successful matching player cast and observed item-count
loss. Failed uses, ambiguous item/spell losses and ordinary bag changes do not
establish consumption. Cast and bag order can vary; channels remain eligible when
interrupted after successful use.

Quest deliveries require the native required item links/quantities, the same
QUEST_TURNED_IN quest ID and a full observed inventory loss. Bag evidence can
precede completion or follow within two seconds. Confirmed deliveries retain their
deadline across pause/world transitions, but missing or ambiguous evidence does not
create a speculative expense. Consumed/delivered acquisitions retain their original
unit prices and source parts.

Repair/taxi secure post-hooks only observe existing game actions. They require a
matching money debit within two seconds; Per Hour never initiates a transaction.
Guild repair, failed action, unmatched debit or expired intent does not count.

Paused/offline/new actions during verification are excluded. Pending values for
already accepted events remain owned by their original open session.

## Freeze, persistence and Details

Finish archives immediately and freezes the result. Unknown prices or confirmation
evidence are excluded, with Incomplete · frozen on Gold. A late reply cannot alter
the archive, revive a deleted record or create old income in the next session.
The result can be above or below fully observed value because unknown expenses
are also excluded.

The new current checkpoint stores Gold context under
PerHourRevampSession.current.modules.Gold. Gold context version 1 retains the full
active journal and inventory-loss evidence needed to restore FIFO; its amounts
must match the saved summary. The revamp never imports older SavedVariables.

Finalized records live in PerHourRevampHistory by character. History keeps 100
summaries, details for 20 and at most 1,000 latest consultable events per session.
These bounds do not remove current data necessary for FIFO or pending prices.
Expired details never change the frozen totals.

Session Details combines Gold with XP, honor and every tracked reputation faction.
The card shows estimated net total followed by (inc - exp), plus the rate, with
numeric composition in its tooltip.
Income and Expenses split the former Gold tab. Their rows group retained journal
entries by item variant and direction, or non-item source (Dropped/Reward coins,
repairs and transport). Last shows the latest occurrence; Count sums item units
or counts non-item occurrences. Income is sorted by highest accumulated known
value; Expenses by largest cost. Grouping sums recorded amounts and preserves
pending/excluded flags, source quotes and quest identities. It does not alter
the journal, FIFO, frozen summaries or prices, and requires no migration. Native
item tooltips and single-quest tooltips remain available; multi-quest groups show
their quest count. Rendering never calls market providers.

Both grids pin Sum above the Total column and keep column headers fixed while
only body rows scroll. Sum includes known retained values in that tab, so it may
differ from the full session totals. An asterisk identifies unresolved/excluded
prices or the latest-1,000-events limit; the tooltip explains why. Expired detail
shows a dash rather than a fabricated zero. Item/source icons and quest markers
remain; direction arrows are redundant with the Income/Expenses tabs and omitted.

## Validation

Run lua tests/forever.lua with Lua 5.1. The preserved Gold/provider regressions cover
localized loot, rewards, external transfers, expenses, FIFO retirement, pending
entries, quest deliveries, pause/load/save boundaries and source reconstruction.
Revamp cases additionally cover shared controls, frozen incomplete archives,
independent stock between sessions and retention.

In Forever, test solo/group loot, guild deposits, quest rewards and item deliveries,
food/potions through bags/actions/macros, canceled/failed actions, personal/guild
repair and taxi routes. Repeat with no market addon and with installed optional
providers. Verify actual order of native bag/cast/quest/money events, hidden capture,
reload/logout, tooltips, scrolling and copper values. These remain client checks.

API references: [item prices and spells](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/ItemDocumentation.lua),
[quest item receipts](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/LootDocumentation.lua),
[quest rewards](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/QuestLogDocumentation.lua),
[native required quest items](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestFrame.lua),
[native quest item links](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/QuestInfo.lua),
[cast events](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua),
[native repair actions](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Mainline/MerchantFrame.xml)
and [native taxi actions](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Shared/TaxiFrame.xml).

Clock reference: [native time APIs](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SystemTimeDocumentation.lua).

Pricing references: [TSM addon API](https://support.tradeskillmaster.com/en_US/api-documentation/what-is-the-tsm-addon-api-and-how-do-i-use-it),
[TSM source definitions](https://support.tradeskillmaster.com/en_US/custom-strings/which-price-sources-can-i-use-and-what-do-they-mean).
Provider signatures were also checked in the published Forever-compatible
[Auctionator 349](https://www.curseforge.com/wow/addons/auctionator/files/9690303)
(`Source/API/v1/GetAuctionPrice.lua`) and
[TSM 4.15.9](https://www.curseforge.com/wow/addons/tradeskill-master/files/9718554)
(`App/API.lua`) packages. These packages were inspected, not loaded into the game.
