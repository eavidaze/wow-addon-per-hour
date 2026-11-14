# Honor tracking in Forever

Honor tracks gains of **Honor Points, currency 1792**, through
`CURRENCY_DISPLAY_UPDATE(currencyType, quantity, quantityChange, ...)`.
The event supplies the numeric gain directly, so the module does not parse
localized chat messages or poll the player's balance.

Only finite positive `quantityChange` values for currency 1792 count. Spending,
generic refreshes without a gain, other currencies and unreadable values are
ignored. Gains count only during a running, unpaused session in the world, after
pending session restoration is resolved. The panel can remain hidden.

Using the event's gain preserves earned totals when the player spends honor and
then earns more before the next tracker update. The starting balance is never
added to a session. Reloads retain saved totals and count new events afterward;
no baseline is needed for this event-based module.

## Different counters

- `UnitHonor`, `UnitHonorMax` and `UnitHonorLevel` describe honor-level XP. In the
  reported client they returned `0`, `5500` and `1`, while the currency balance
  was 118. Those APIs cannot measure the reported currency gain.
- `C_MajorFactions.GetMajorFactionProgressionInfo(2800)` describes PvP rank
  progression. Honor currency and Rank Points are separate systems.
- Currency 1792's `totalEarned` returned zero in the reported client and is not
  used as an accumulated earnings counter. Currency 1901 returned no data.

Sources: the client's [currency event contract](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/CurrencyInfoDocumentation.lua),
the Forever [rank panel](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_UIPanels_Game/Camelot/PVPRankFrame.lua),
and Blizzard's [PvP progression overview](https://worldofwarcraft.blizzard.com/en-us/news/24303316/how-pvp-progression-in-world-of-warcraft-forever-works).

## Validation

Run `lua tests/forever.lua` with Lua 5.1 for simulated currency gains, spending,
pause/resume, hidden panels, invalid payloads and session continuity. The fixtures
keep honor-level XP fixed and the currency's `totalEarned` at zero.

The currency identification above was confirmed with in-game API output, and the
user confirmed that the fix captures honor gains in Forever. Spending,
pause/resume and reload without counting the existing balance again still need
in-game validation beyond the simulated checks.
Previously missed awards cannot be reconstructed from the current balance.
