# CurseForge listing

Local draft for the revamp; publication is a separate release step.

## Project name

Per Hour - XP, Honor, Reputation & Gold Tracker

## Summary

Track XP, honor, reputation and estimated net gold per hour or minute in WoW Forever. Pause one shared session, review its events and compare saved results.

## Description

### Per Hour - WoW Forever

See what your farming sessions earn with **XP, Honor Points, reputation and
estimated net gold** in one dashboard.

#### Your progress at a glance

- **One session:** Start, Pause and Resume all metrics together. Finish freezes the result in History.
- **Your layout:** Full, Extended or Focused; reorder metrics, choose /h or /m, and move or hide the dashboard.
- **Milestones:** independently show estimates for your next level and reputation standing, plus an XP gauge with ten scales.
- **Reputation by faction:** change the watched faction during a session. Each faction keeps its totals, tracked time and rates.
- **Session:** review all metrics, grouped Gold Income and Expenses with separate sums, and item/quest tooltips with recorded price sources.
- **History and Compare:** name your sessions, consult other characters and compare hourly XP, Gold, honor and tracked factions across two saved results.
- **Clear capture status:** unavailable, partial, pending and frozen incomplete values remain visible.

#### Start tracking

1. Left-click the minimap clock to show the dashboard and press **Start**.
2. Right-click the clock, or type `/perhour`, for **Settings**.
3. Use **Sessions > Current Session**, or click a readout, to review the current session.
4. Choose **Finish Session** in Sessions or the current Session window, keep or edit the suggested title, and confirm to save the result. Open **History** to
   rename, delete or compare saved sessions.

Use `/perhour xp`, `/perhour gold`, `/perhour honor` or `/perhour rep` to show the
same dashboard. `/perhour help` describes the commands. Broker displays share the
minimap actions; LibDBIcon organizers can manage the launcher.

Closing the dashboard keeps capture running. Pause excludes time and gains until
Resume. Normal logout/login restores the session paused; a verified `/reload`
restores its previous state. Offline and loading time are excluded. Uncertain
continuity requires review before Resume, with partial coverage indicated.

Gold includes looted money, quest rewards and collected items, subtracting
consumables, quest-delivered items, personal repairs and paid flights. Item prices
use optional **TSM DBMarket > Auctionator last scan > vendor**, with vendor as the
minimum. Gray items use vendor value. Quotes remain fixed; expenses reuse
session-local acquisition values when available. Transfers, mail, purchases and
vendor-sale receipts are excluded. Gold is estimated farming value.

Finish excludes unresolved Gold values and freezes the archived result. History
retains **100 summaries per character**, details for the latest **20**, and up to
**1,000 consultable Gold events** per session. These display limits do not truncate
active accounting. Announce in the current Session window shares a selected metric to the chat
channel you choose.

The revamp starts with fresh preferences and history; earlier tracker data is not
imported. The interface and number formatting use English.

[Usage guide](https://github.com/eavidaze/wow-addon-per-hour#readme)
· [Feedback and bug reports](https://github.com/eavidaze/wow-addon-per-hour/issues)
