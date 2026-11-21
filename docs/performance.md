# Performance validation

Run `lua tests/forever.lua` with Lua 5.1. It also runs `tests/performance.lua`
against the same simulated client used by the tracking and session checks.
The suite also runs `tests/estimates.lua` for tooltip section order, live goal
updates, unrounded session means, minute rounding, pauses, level and standing
changes, maximum progress, faction changes and unavailable or special progress.
It also covers the General estimate toggle, centered panel text, gauge
coexistence, immediate updates, unchanged-text/color caching and saved visibility.
Status-color checks keep the button diamond, tooltip status and both estimates
in sync when starting, pausing, resuming, resetting and showing hidden panels.
These are simulation checks; tooltip layout and progress APIs still need
confirmation in WoW Forever.

`tests/gold.lua` covers the fourth tracker, including source classification,
consumption, delayed item prices and the saved journal. Gold shares the running
session timer and does not request periodic updates while paused. Its bag/spell
metadata is read on inventory changes rather than on every player ability cast.
`tests/gold-details.lua` checks that the history viewport reuses a bounded row
pool, a burst of 200 events produces one deferred repaint, hidden Details has no
repaint work, and prepended events preserve the reader's existing scroll anchor.
The native list handles clipping and scrolling; the panel adds no per-frame polling.
The three-panel before/after counts below describe the earlier optimization
comparison; they are not measurements of the new Gold module in the game.

The integration checks cover one shared timer, idle and loading-screen shutdown,
event bursts followed by fallback sampling, level-ups, paused gains, hidden panel
updates, presentation cache invalidation, overload, drag persistence and recovery
from an API error in one module without stopping the other trackers.
Mouse regressions route hover and drag input through decorative children, check
that buttons retain their own clicks, and open the complete settings form. The
simulation uses Forever's `region:IsMouseOver()` API without providing the removed
`MouseIsOver` global. Mouse script bindings also enable input in the simulation,
so accidentally making decorative layers intercept background gestures is detected.
The minimap checks load the real embedded LibStub, CallbackHandler, LibDataBroker
and LibDBIcon sources. They verify standard icon registration, shared-library
reuse, broker clicks with the minimap hidden, context-menu owner dismissal,
shape-aware placement and the existing per-character radian setting. They do not
load Leatrix or reproduce its runtime UI in the game.
Minimap dragging retains LibDBIcon's own update callback and sampling frequency;
the addon saves the resulting angle on release, hide or logout, without writing
saved settings every frame. Stationary-cursor coalescing applies to tracker
panel dragging; the library controls minimap positioning while it is dragged.
Restore-indicator checks cover immediate visibility, delayed dismissal, hidden
expiry and stale-timer protection. Simulations at 60 and 144 FPS verify no restore
frame callbacks or repeated opacity writes during the five-second success window.
The frame simulations include 60 and 144 FPS. They count Lua callbacks and UI
method calls; they do not measure WoW CPU time, rendering cost or actual FPS.

With three visible panels and no drag:

| Work | Before | After |
| --- | --- | --- |
| Tracker `OnUpdate` callbacks at 60 FPS | 180/s | 0 |
| Close-button `OnUpdate` callbacks at 60 FPS | 180/s | 0 |
| Restore indicator waiting to dismiss | Frame callback throughout the visible wait and fades | One delayed callback per dismissal; no frame callback |
| Lua overload rotation calls at 60 / 144 FPS | 180/s / 432/s | 0 while unchanged; native rotation animates the burst |
| Periodic scheduling during three active sessions | Three frame callbacks checking elapsed time | One shared one-second timer |
| Hidden runtime rate rendering | Every rate refresh | Deferred until Show |

The before counts come from the earlier implementation's Lua 5.1 simulation.
The new gauge draws four texture layers from two assets: the dial, pointer and
their black shadow copies. Matching native overload rotation groups for the
pointer and its shadow are created only on first overload. Their 0.36-second
tremor and 1.44-second rest repeat without Lua frame callbacks or animation timers.
Hiding the gauge or its parent stops the groups; showing it resumes them only if
still overloaded. Repeated rate refreshes do not restart the cycle. Shadow layers
and native animation still have rendering cost, which the simulation does not
measure. Text, unit, width and control state are updated only
when their displayed inputs change. Tracking close buttons use mouse enter/leave
events across the panel and its children, appearing instantly without fading.
Restore status appears at full opacity and hides after its deadline without
fading. Success waits five seconds; acknowledged errors wait half a second.
Unresolved errors persist. Dragging runs cursor tracking only while the mouse
button is held.

A local differential simulation also compared the earlier and optimized sources
over 500 mixed steps: gains, level-ups, pause/resume, resets, panel visibility,
world transitions and logout. All 1,503 snapshots matched for totals, active
duration, both rates, started/paused state and saved session totals/durations.
This comparison checks tracking behavior; the simplified presentation deliberately
differs from the earlier implementation.

XP capture uses the Forever client's
[`PLAYER_XP_UPDATE` event](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/UnitDocumentation.lua).
Reputation uses `UPDATE_FACTION`, which the existing settings panel already uses.
The shared timer retains periodic baseline sampling as a fallback. Saved-data
schemas, session continuity rules and scale settings are unchanged.

## In-game comparison

Gold's optional TSM/Auctionator providers run only while accepting an item
valuation or settling pending native item data. History rendering and hover use
saved price snapshots. FIFO acquisition queues are rebuilt once on restore and
consumed by item ID; the ledger has no timer or per-frame callback of its own.
New pricing tests check that opening Details and hovering an item make no market
API calls. This is a simulation result, not a measured in-game performance claim.

Use the same character, scene, graphics settings and other enabled addons:

1. Compare a baseline checkout with the optimized checkout after `/reload`.
2. Compare all panels hidden, three numeric panels visible, the normal XP gauge
   and an overloaded XP gauge. Keep the same tracking state in each comparison.
3. Check frame times and addon CPU measurements over a stable interval; repeat
   the comparison to separate addon work from world and combat fluctuations.
4. Exercise Start/Pause/Resume, XP level-ups, watched-faction changes, Honor gains
   and spending, loading screens and logout/reload with running and paused sessions.
5. Check that showing a hidden panel immediately displays its latest rate, changing
   units and gauge levels updates the display, and dragging saves on release or hide.
6. Move the cursor between the panel, footer controls and protruding X: the X
   must remain visible until leaving the whole panel and close-button area, with
   no fade. Check that pointer and shadow tremor stay synchronized, rest between
   bursts, and stop or resume together after hiding, reopening or leaving overload.

Actual Forever validation remains pending. Passing the simulation does not prove
that every client event ordering or rendering path behaves identically in-game.
