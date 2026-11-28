# Session architecture and persistent stores

The revamp starts in new SavedVariables. It never imports or rewrites the
pre-revamp tracker sessions or settings.

| SavedVariable | Scope | Contents |
| --- | --- | --- |
| PerHourRevampSettings | Character | Version 1 display preferences, order, visibility, position, minimap angle. |
| PerHourRevampSession | Character | Version 1 current checkpoint, sequence and recoverable invalid data. |
| PerHourRevampHistory | Account | Version 1 character directory and independently retained archived sessions. |

Only SettingsStore.lua and SessionStore.lua access these globals. Account history
uses player GUIDs, with realm/name fallback, so same-named characters on different
realms remain separate. History can inspect one character or all characters.
On Forever, both values returned by UnitName("player") are name components:
first name and surname. BindCharacter stores their space-separated full name in
the existing name field; realm comes independently from GetRealmName(). GUIDs
and the existing fallback keys are unchanged. Normal login/Start binding refreshes
the current character's name; no migration scans or rewrites archived records.
History and Details share the same label, omitting the realm separator when the
client supplies an empty realm. See the [observed Forever API behavior](https://github.com/ATTWoWAddon/AllTheThings/issues/2630).

## Responsibilities

| File | Responsibility |
| --- | --- |
| core/Session.lua | One clock, shared lifecycle, checkpoints, continuity verification, snapshots and finalization. |
| core/Capture.lua | Per-module event frames and one running-session sampling timer. |
| modules/*.lua | Interpret native XP, currency, faction and farming events; Gold owns session-local FIFO accounting. |
| modules/BaseModule.lua | Common lifecycle status, estimates, rates and explicit announcements. |
| pricing/*.lua | Quote selection and recorded valuation parts; independent of presentation. |
| stores/*.lua | Validate/save preferences, checkpoints and bounded history. |
| core/MetricFormat.lua | Shared full/compact amounts, rates, flags, dates and fixed-font ellipsis. |
| core/Dashboard.lua | Focused/Extended/Full layout and session controls. |
| core/SettingsPanel.lua | Native form fields, metric swapping and faction selector. |
| core/SessionPanels.lua | History, Details and comparison coordination, Rename, Delete and Finish confirmation. |
| core/Bootstrap.lua | Initialize stores, module state, capture frames and views once. |

Modules keep capture state in State and the event frame in View.
They do not own a session clock, independent session store or independent window.
The session mirrors authoritative duration into each metric; Reputation uses the
sum of its selected faction's measured intervals for its rate and estimate.

A checkpoint contains a summary record, full module capture contexts and a
played-time reference. The full active Gold ledger is retained for FIFO and pending
prices even when the visible journal is capped. Checkpoints are copied at explicit
lifecycle/save boundaries; normal timer ticks do not deep-copy the ledger.

## Frozen records and retention

Finish samples the boundary once, creates a detached summary and event snapshot,
then resets capture state for the next Start. Late callbacks cannot modify the
archived snapshot or resurrect deleted records. Unknown prices/confirmations are
excluded and the Gold metric is marked incomplete/frozen.

Each character retains 100 completed summaries, with event/segment details for
the latest 20. At most 1,000 latest Gold events are consultable for one session.
Removing details never recomputes totals. Summaries retain faction totals and
tracked durations, Gold composition, start metadata, flags and context.

Names are independent from IDs. Duplicate names are valid, Rename trims outer
whitespace and accepts up to 80 UTF-8 characters, and renaming never changes
retention order. Delete removes only the selected stored record after confirmation.

## Unreadable data

Record validation keeps invalid records out of rates and comparison. Unreadable
current checkpoints are preserved in a recovery field. A malformed module context
isolates that metric for the remainder of the session while preserving readable
summary data; healthy modules can continue. It remains unavailable/partial and
Gold finalizes as incomplete. The isolated state survives another checkpoint/reload.
No migration or fabricated reconstruction is performed.

Run lua tests/forever.lua with Lua 5.1. The fixture loads the real TOC/XML,
native component contracts and embedded libraries; it does not validate drawing
or native event delivery inside the game.
